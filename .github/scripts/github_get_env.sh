#!/bin/bash -ux
env
set
uname -a
sw_vers
xcodebuild -version
system_profiler -timeout 30 -detailLevel basic
sudo launchctl list
launchctl list
sudo sysctl -a
sudo kextstat
df -h && ls -kahl
sudo mdutil -a -i off # disable spotlight
sudo mdutil -d /
