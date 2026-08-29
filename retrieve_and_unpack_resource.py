#!/usr/bin/env python3
"""Retrieve and unpack the resources needed to build Chromium on macOS."""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent
DOWNLOAD_CACHE = ROOT_DIR / "build" / "download_cache"
SRC_DIR = ROOT_DIR / "build" / "src"
MAIN_REPO = ROOT_DIR / "ungoogled-chromium"
UTILS_DIR = MAIN_REPO / "utils"
CLONE_STATE = DOWNLOAD_CACHE / "resource_stamps" / "chromium-clone.json"

# The ungoogled-chromium utilities use sibling imports when run as scripts.
sys.path.insert(0, str(UTILS_DIR))
from downloads import (  # pylint: disable=wrong-import-position
    DownloadInfo,
    HashMismatchError,
    check_downloads,
    retrieve_downloads,
    unpack_downloads,
)
from _common import get_logger  # pylint: disable=wrong-import-position


LOGGER = get_logger()


class _ResourceFormatter(logging.Formatter):
    """Format cache hits and diagnostics with terminal colors."""

    RESET = "\033[0m"
    CACHE_COLOR = "\033[1;36m"
    WARNING_COLOR = "\033[1;33m"
    ERROR_COLOR = "\033[1;31m"

    def __init__(self, use_color: bool) -> None:
        super().__init__("%(levelname)s: %(message)s")
        self._use_color = use_color

    def format(self, record: logging.LogRecord) -> str:
        if getattr(record, "cache_hit", False):
            formatted = f"CACHE HIT: {record.getMessage()}"
            color = self.CACHE_COLOR
        else:
            formatted = super().format(record)
            if record.levelno >= logging.ERROR:
                color = self.ERROR_COLOR
            elif record.levelno >= logging.WARNING:
                color = self.WARNING_COLOR
            else:
                color = ""

        if self._use_color and color:
            return f"{color}{formatted}{self.RESET}"
        return formatted


class _SkipUpstreamCacheMessage(logging.Filter):
    """Hide the downloader's pre-verification cache message."""

    def filter(self, record: logging.LogRecord) -> bool:
        return not record.getMessage().endswith("already exists. Skipping download.")


def _configure_logging() -> None:
    for handler in LOGGER.handlers:
        stream = getattr(handler, "stream", None)
        is_terminal = bool(stream and getattr(stream, "isatty", lambda: False)())
        use_color = "NO_COLOR" not in os.environ and (
            is_terminal or "FORCE_COLOR" in os.environ
        )
        handler.setFormatter(_ResourceFormatter(use_color))
        handler.addFilter(_SkipUpstreamCacheMessage())


_configure_logging()


def _run(*args: str | Path) -> None:
    """Run a command and stop at the first failure."""
    command = [str(arg) for arg in args]
    LOGGER.info("Running: %s", " ".join(command))
    subprocess.run(command, check=True)


def _remove(path: Path) -> None:
    """Remove a file, symlink, or directory if it exists."""
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def _replace_symlink(target: Path, link: Path) -> None:
    """Create link to target, replacing any existing directory entry."""
    if os.path.lexists(link):
        _remove(link)
    link.symlink_to(target)


def _retrieve_and_unpack(ini_path: Path) -> None:
    """Retrieve verified resources from one INI file, then unpack them.

    The upstream downloader already skips cached filenames. It verifies their
    declared hashes after retrieval; if an existing cache entry fails that
    verification, remove only that entry and download it again.
    """
    DOWNLOAD_CACHE.mkdir(parents=True, exist_ok=True)
    download_info = DownloadInfo([ini_path])
    cached_downloads = {
        DOWNLOAD_CACHE / properties.download_filename
        for _, properties in download_info.properties_iter()
        if (DOWNLOAD_CACHE / properties.download_filename).is_file()
    }

    refreshed_downloads: set[Path] = set()
    while True:
        retrieve_downloads(download_info, DOWNLOAD_CACHE, None, show_progress=True)
        try:
            check_downloads(download_info, DOWNLOAD_CACHE, None)
            break
        except HashMismatchError as error:
            bad_download = Path(error.args[0])
            if bad_download in refreshed_downloads:
                raise RuntimeError(
                    f"Downloaded resource still has an invalid hash: {bad_download}"
                ) from error
            LOGGER.warning("Discarding cached resource with an invalid hash: %s", bad_download)
            _remove(bad_download)
            _remove(bad_download.with_name(f"{bad_download.name}.partial"))
            refreshed_downloads.add(bad_download)

    for cached_download in sorted(cached_downloads - refreshed_downloads):
        LOGGER.info("%s", cached_download, extra={"cache_hit": True})

    unpack_downloads(download_info, DOWNLOAD_CACHE, None, SRC_DIR)


def _clone_recipe_hash() -> str:
    """Hash inputs that affect the source preparation performed by clone.py."""
    hasher = hashlib.sha256()
    for path in (
        UTILS_DIR / "clone.py",
        UTILS_DIR / "depot_tools.patch",
        UTILS_DIR / "gsutil.patch",
    ):
        hasher.update(path.name.encode())
        hasher.update(path.read_bytes())
    return hasher.hexdigest()


def _git_bytes(*args: str) -> bytes | None:
    result = subprocess.run(
        ["git", "-C", str(SRC_DIR), *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def _git_output(*args: str) -> str | None:
    output = _git_bytes(*args)
    if output is None:
        return None
    return output.decode(errors="surrogateescape").strip()


def _source_status() -> str | None:
    # uc_staging is deliberately retained by clone.py and is not Chromium source.
    return _git_output(
        "status", "--porcelain", "--untracked-files=normal", "--", ".", ":(exclude)uc_staging"
    )


def _source_contents_hash() -> str | None:
    """Hash tracked changes and non-ignored untracked source files."""
    diff = _git_bytes("diff", "--binary", "HEAD", "--", ".", ":(exclude)uc_staging")
    untracked = _git_bytes(
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
        "--",
        ".",
        ":(exclude)uc_staging",
    )
    if diff is None or untracked is None:
        return None

    hasher = hashlib.sha256()
    hasher.update(diff)
    for relative_path_bytes in filter(None, untracked.split(b"\0")):
        relative_path = Path(os.fsdecode(relative_path_bytes))
        source_path = SRC_DIR / relative_path
        try:
            file_status = source_path.lstat()
            hasher.update(relative_path_bytes)
            hasher.update(file_status.st_mode.to_bytes(4, byteorder="big"))
            if source_path.is_symlink():
                hasher.update(os.fsencode(os.readlink(source_path)))
            elif source_path.is_file():
                with source_path.open("rb") as source_file:
                    for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
                        hasher.update(chunk)
        except OSError:
            return None
    return hasher.hexdigest()


def _expected_clone_state(pgo_profile: str) -> dict[str, str | int]:
    return {
        "schema": 2,
        "chromium_version": (MAIN_REPO / "chromium_version.txt").read_text().strip(),
        "pgo_profile": pgo_profile,
        "clone_recipe_sha256": _clone_recipe_hash(),
    }


def _source_clone_is_reusable(pgo_profile: str) -> bool:
    """Return whether SRC_DIR is a complete, unchanged clone for this request."""
    try:
        saved_state = json.loads(CLONE_STATE.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return False
    if not isinstance(saved_state, dict):
        return False

    expected_state = _expected_clone_state(pgo_profile)
    if any(saved_state.get(key) != value for key, value in expected_state.items()):
        return False

    required_outputs = (
        SRC_DIR / "DEPS",
        SRC_DIR / "build" / "util" / "LASTCHANGE",
        SRC_DIR / "gpu" / "webgpu" / "DAWN_VERSION",
        SRC_DIR / "tools" / "gn" / "bootstrap" / "last_commit_position.h",
    )
    if not all(path.is_file() for path in required_outputs):
        return False

    head_commit = _git_output("rev-parse", "HEAD")
    tagged_commit = _git_output(
        "rev-parse", f"{expected_state['chromium_version']}^{{commit}}"
    )
    if not head_commit or head_commit != tagged_commit or head_commit != saved_state.get("commit"):
        return False

    source_status = _source_status()
    if source_status is None:
        return False
    status_hash = hashlib.sha256(source_status.encode(errors="surrogateescape")).hexdigest()
    if status_hash != saved_state.get("source_status_sha256"):
        return False

    return _source_contents_hash() == saved_state.get("source_contents_sha256")


def _write_clone_state(pgo_profile: str) -> None:
    state = _expected_clone_state(pgo_profile)
    commit = _git_output("rev-parse", "HEAD")
    source_status = _source_status()
    contents_hash = _source_contents_hash()
    if commit is None or source_status is None or contents_hash is None:
        raise RuntimeError("Unable to record the cloned Chromium source state")
    state["commit"] = commit
    state["source_status_sha256"] = hashlib.sha256(
        source_status.encode(errors="surrogateescape")
    ).hexdigest()
    state["source_contents_sha256"] = contents_hash

    CLONE_STATE.parent.mkdir(parents=True, exist_ok=True)
    temporary_state = CLONE_STATE.with_suffix(".tmp")
    temporary_state.write_text(f"{json.dumps(state, indent=2, sort_keys=True)}\n")
    temporary_state.replace(CLONE_STATE)


def _retrieve_generic(target_cpu: str, clone: bool) -> None:
    if clone:
        pgo_profile = "mac-arm" if target_cpu == "arm64" else "mac"
        if _source_clone_is_reusable(pgo_profile):
            LOGGER.info(
                "Chromium %s source at %s",
                (MAIN_REPO / "chromium_version.txt").read_text().strip(),
                SRC_DIR,
                extra={"cache_hit": True},
            )
            return

        _remove(CLONE_STATE)
        _run(sys.executable, MAIN_REPO / "utils" / "clone.py", "-p", pgo_profile,
             "-o", SRC_DIR)
        _write_clone_state(pgo_profile)
    else:
        _remove(CLONE_STATE)
        _retrieve_and_unpack(MAIN_REPO / "downloads.ini")


def _host_architecture() -> str:
    host_arch = platform.machine()
    if host_arch not in ("arm64", "x86_64"):
        raise RuntimeError(f"Unsupported macOS host architecture: {host_arch}")
    return host_arch


def _retrieve_platform_specific(target_cpu: str) -> None:
    host_arch = _host_architecture()

    _remove(SRC_DIR / "third_party" / "llvm-build" / "Release+Asserts")
    _remove(SRC_DIR / "third_party" / "rust-toolchain")
    _remove(SRC_DIR / "third_party" / "node" / "mac")
    _remove(SRC_DIR / "third_party" / "node" / "mac_arm64")
    (SRC_DIR / "third_party" / "llvm-build" / "Release+Asserts").mkdir(
        parents=True, exist_ok=True)

    if host_arch == "arm64":
        node_dir = SRC_DIR / "third_party" / "node" / "mac_arm64" / "node-darwin-arm64"
        node_dir.mkdir(parents=True, exist_ok=True)
        _retrieve_and_unpack(ROOT_DIR / "downloads-arm64.ini")
        if target_cpu == "x86_64":
            _retrieve_and_unpack(ROOT_DIR / "downloads-x86-64-rustlib.ini")
    else:
        node_dir = SRC_DIR / "third_party" / "node" / "mac" / "node-darwin-x64"
        node_dir.mkdir(parents=True, exist_ok=True)
        _retrieve_and_unpack(ROOT_DIR / "downloads-x86-64.ini")
        if target_cpu == "arm64":
            _retrieve_and_unpack(ROOT_DIR / "downloads-arm64-rustlib.ini")

    rust_name = f"{'aarch64' if host_arch == 'arm64' else 'x86_64'}-apple-darwin"
    rust_dir = SRC_DIR / "third_party" / "rust-toolchain"
    rust_bin_dir = rust_dir / "bin"
    rust_lib_dir = rust_dir / f"rust-std-{rust_name}" / "lib" / "rustlib" / rust_name / "lib"
    rustc_lib_dir = rust_dir / "rustc" / "lib" / "rustlib" / rust_name / "lib"

    rust_bin_dir.mkdir(parents=True, exist_ok=True)
    (rust_dir / "lib").mkdir(parents=True, exist_ok=True)
    (rust_bin_dir / "rustc").symlink_to(rust_dir / "rustc" / "bin" / "rustc")
    (rust_bin_dir / "cargo").symlink_to(rust_dir / "cargo" / "bin" / "cargo")
    (rust_bin_dir / "rustfmt").symlink_to(
        rust_dir / "rustfmt-preview" / "bin" / "rustfmt")
    rustc_lib_dir.symlink_to(rust_lib_dir)
    (rust_dir / "rustfmt-preview" / "lib").symlink_to(rust_dir / "rustc" / "lib")

    llvm_bin_dir = SRC_DIR / "third_party" / "llvm-build" / "Release+Asserts" / "bin"
    (llvm_bin_dir / "install_name_tool").symlink_to(
        llvm_bin_dir / "llvm-install-name-tool")

    go_binary = shutil.which("go")
    if go_binary is None:
        raise RuntimeError("The Go executable is required but was not found in PATH")
    dawn_go_platform = "mac-arm64" if host_arch == "arm64" else "mac-amd64"
    dawn_go_bin_dir = (
        SRC_DIR / "third_party" / "dawn" / "tools" / "golang" / dawn_go_platform / "bin"
    )
    dawn_go_bin_dir.mkdir(parents=True, exist_ok=True)
    _replace_symlink(Path(go_binary), dawn_go_bin_dir / "go")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-d",
        "--download",
        action="store_false",
        dest="clone",
        help="use the source archive instead of cloning Chromium",
    )
    parser.add_argument(
        "-g",
        "--generic",
        action="store_true",
        help="retrieve and unpack Chromium source and general resources",
    )
    parser.add_argument(
        "-p",
        "--platform-specific",
        action="store_true",
        help="retrieve and unpack platform-specific resources",
    )
    parser.add_argument(
        "-a",
        "--all",
        action="store_true",
        help="retrieve and unpack both generic and platform-specific resources",
    )
    parser.add_argument(
        "target_cpu",
        nargs="?",
        default="arm64" if _host_architecture() == "arm64" else "x86_64",
        choices=("arm64", "x86_64"),
        help="Chromium target CPU (default: %(default)s)",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    combined_retrieval = args.all or (args.generic and args.platform_specific)
    if args.generic or args.all:
        _retrieve_generic(args.target_cpu, args.clone)
    if args.platform_specific or args.all:
        _retrieve_platform_specific(args.target_cpu)
    if combined_retrieval and args.clone:
        pgo_profile = "mac-arm" if args.target_cpu == "arm64" else "mac"
        _write_clone_state(pgo_profile)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        LOGGER.error("%s", error)
        sys.exit(1)
