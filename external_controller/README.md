# External Controller

## Overview
External Controller responsible for providing the correct information about the truck.It will sending commands to the webots controller and also receiving commands from the backend.

## Functionalities
There are multiple service External controller provides:
1. Communication with backend and webots controller
2. Sending and receiving sensor data
3. Platooning in our webots environment
4. The position of the truck
5. The fuel cost of the Truck Platoon 
 
## Installation
External controller are written in Ada, so you need at first make sure you have GNAT installed.

	sudo apt install asis-programs
	sudo apt install gnat
	sudo apt install gnat-gps
	
## How to Build the project

	gprbuild -P external_controller.gpr


## How to Format code

	gnatpp -U -P position_algorithm.gpr
	gprbuild -U -P controller_peer.gpr
	gprbuild -U -P follow_path.gpr
	gprbuild -U -P message_handle.gpr
	gprbuild -U -P protectsobj.gpr
	gprbuild -U -P position_algorithm.gpr
	gprbuild -U -P webots_server.gpr
