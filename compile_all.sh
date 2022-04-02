#!/bin/bash
export WEBOTS_HOME=/usr/local/webots
# Compile external controller
cd external_controller
gprbuild -P external_controller.gpr
cd ..

# Compile webots
cd webots/controllers
./compile_webots.sh
