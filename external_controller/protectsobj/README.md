# ProtectsObj
## Overview

This Projects work a lot with Task who write and read the same variables. Therefore creating Protected Objects is just suitable to prevent conflicts.

**Used by**: backend_client, Webots_Server, Message_Handle , Position_Algorithm, Controller_Peer

This Packages is devided into multiple Objects which have access to variables through subprogramms. Here are also specific types stored that are used by other packages.

## Types
- color_BGR;
- image_array
- Route
- LookUpTableCarsTaskNr
- LookUpTablePorts

## Objects
### CargoObj

-  Local -- Here is stored how much kg the Truck should Pick up
-  CurrentLoad -- is the Load that the Truck currently Holds
-  MaxLoad -- max  capacity to carry
### ExCoCObj
- Tasknr_c : Integer := 1; --current Index of next available Client
- Tasknr_s : Integer := 1; --current Index of next available Server

### PlatoonObj
-	PlatoonMode : Boolean -- True if Platooning
-	Leader : Boolean – wether I am the Leader
-	SOS : Boolean – if there is currently an amergency
-	Distance_2_Front : Integer – the distance that should be between trucks
-	ExClientTrId2TaskNr  -- a lookuptable with <ID>:<TaskNrClient>
-	Leader :
	-  Failures_Count : Int -- Counts how many Problems there are to adjust the Distance
	-  HowManyCars : Int – How many cars are in a fleet (incl me)
	-  SequenceofTrucks  -- LookupTable  `<Index>:<ID>`
	-  PortsaID – LookupTable  `<ID>:<PortNr>`
-   Not Leader:
	- TruckFrontID : Int – the ID of the Car in front of it 
	- TruckLeaderID : Int – ID of the Leader

### RouteObj
- Route_path -- stores the sequence of colors the Truck should follow
- LenRoute -- says how many colors in Route_path is
- Astring -- tells which is the next Node
- Afloat -- the distance to that next Node

### SensorDataObj
- Time -- the current Simulationtime from Webots
- Current_Camera_Image  -- the current Image of  the Robot

### SpeedObj
- SpeedL -- Speed of the Left weels
- SpeedR -- Speed of the Right weels
