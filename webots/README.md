# Webots

## Overview

In Webots we have build our environment, robot and webots controller. The environment will be the design as a highway system, it consists of multiple asphalt streets with road marking in different colors, 4 pickup and drop-off locations and a depot for unused trucks to park. The robot (Truck) is a simple rectangular prism with a big Trunk, it has 2 distance sensor and 1 camera. The Webots controller is uesd for each Truck in the environment. Each controller is also the TCP/IP Client for the communication with the External Controller.

## How to open the environment

At first, make sure you have already install Webots. Then open the Webots world from \webots\worlds, choose environment_final_1T.wbt.

## How to add Truck into environment

When you open the Webots world, then right click "add", choose USE PROTO, "TRUCK.proto".

## How to run the controller

When you open the Webots world, then open "follow_line.c", compile it and reload the whole world. There has totally 5 trucks in our environment, so you need to open "follow_line.c-follow_5.c". Then start the simulation.
Each robot in this world will automatically start the linked "follow_line.c" controller.

## How to build
First make sure you have webots installed and WEBOTS_PATH environmental variable set. Then invoke 

	make 

in the /follow_line directory.

