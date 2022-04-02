[![pipeline status](https://gitlab.com/autonomous-platoon-2/autonomous-truck-platoon/badges/master/pipeline.svg)](https://gitlab.com/autonomous-platoon-2/autonomous-truck-platoon/-/commits/master)
[![coverage report](https://gitlab.com/autonomous-platoon-2/autonomous-truck-platoon/badges/master/coverage.svg)](https://gitlab.com/autonomous-platoon-2/autonomous-truck-platoon/-/commits/master)

# Project Overview

In this project, we developed an intelligent system, 'an autonomous truck fleet', that delivers cargo efficiently. The core concept of this system is that users can command the system to pick up a certain amount of freight/cargo from a specific location and drop it at a predefined area. Several trucks with predefined cargo space are available in the depot that can be assigned if more trucks are required to deliver more freight. However, using available trucks and space per truck will be decided by the system based on algorithm calculations to provide the best possible solution with one or more trucks to deliver the cargo efficiently and economically. The project mainly based on four major components Webots controller, external controller, back-end and front-end. 
Complete insight about each component is provided in the system architecture section that what is the purpose of each component and how they work together.   
 

# Project Goals 
The main objective or goal of this project is to develop and build an intelligent an autonomous truck fleet that delivers cargo efficiently. The main goals of this project are

* Pick up cargo at predefined locations. 
* Deliver cargo quickly to its destination. 
* Use available trucks and space per truck efficiently. 
* Platoon where possible and economical

# Project Approach 
To handle this project efficiently we used 
## Project Management
We worked in a Agile based model, where we plan and preview things on weekly basis.  We utilised a various quality assurance strategies to ensure the quality of our project, for example an automated deployment system to make sure the integrated piece code works well.
## Development

As mentioned above, we worked in component based teams (webots controller, external controller, back-end and front-end). Communication between these components are done through TCP/IP communication protocols. Up to first milestone we come up with some basic work on each component. Until the end of second milestone we achieved our requirements goals for environment and external controller. Up to the third milestone were accomplished to establish communication between external controller and back end. 
our Webots component is developed in C language, whereas external controller consist of Ada language. For back-end development we used Python, where as front-end is in React JS. 
A complete insight of each component will be discussed in system architect section.


# System Architecture

Our project consists of several components shown in a diagram below (just like the building pieces that comes together in a good solution), including webots-controller, external controller, back-end and front-end. Consequently, this makes the software development and system maintenance processes more manageable. Well-defined interfaces enable robust interactions between all the components that provide individual functionality. Our components are


* Webot
* External Controller
* Backend 
* Frontend



## Environment 

The environment will be the design as it will consist of multiple entries of (pickup and drop-off locations. It will contain at least one depot for unused parking truck. It will also consist of road marking and having multiple entry points and multiple exit points marked with a line.
Point of interest or specific locations on the map which can carry distinctive meaning and information about them. Possible packages will include,
Create_Station (i.e., pick-up / drop-off location)
this package will be used to create stations (there should be at least four stations/ locations for pickup and drop-off)

**Create_Depot**
this package will be used to create at least one depot for parking unused truck.

**Define_Directions_to_the_depot**
this package will be used to create road marking and having multiple entry points and multiple exit points marked with line on a

**Platooning_sections**
this package will be used to create multiple platooning sections, where your trucks can platoon for a longer time.

**Detect_lanes** : 
this package will be used to detect lanes.

**locate_points_of_interest**
this package will be used for robot locate points of interest (platooning sections, entries/exists


## Robot Design 

To avoids obstacles on the way, robots need knowledge about the environment by using sensory data. To collect that information, sensors will be used and to analyse that which sensor will be required to avoid collisions or to detect points of interest (depot, pick up locations, entries and exits   will be required. At least two robots in the environment 

**A Camera**: for line detection and maybe (depending on the final layout of the Environment) for detection of Points of Intrest

**A distance Sensor**: to detect obstacles in front of the truck (maybe also to stay in line) and send the data to the external Controller 

**A Trunk**: for storage of the objects


##	External Controller

This component will operate by sending a command to the webots controller. It will be responsible for providing the correct information about the truck. It will recognize the obstacle and execute an emergency stop if necessary. Process incoming jobs for planning a route. Following the lines on the road, to keep recognize of line intersection on multiple entries and multiple exits. 

**Backend_coms** : this package will handle communication with backend

**Ada.Text_IO** : will be used for standard text input output

**Ada.Real_Time** : Get the Real Time measure the Compute Time of the taskName	Last commit	Last update
ba

**GNAT.Sockets** : for communication between systems, e.g. with a TCP socket

**Ada.IO_Exceptions** : for exception handling

**Ada.Asynchronous_Task_Control** : give task a priority, e. g. highest priority for critical tasks

**Bot_sensor_data** :  this package will handle sending and receiving of sensor data

**Path_finding** :  this package will  calculate a route by applying some algorithms to graph representation.

**Line_following** : will process sensor data as well as navigation data and will provide information of recognition 


##  Backend 

Backend will be responsible for keep track of all the trucks. Following components/packages could be possible options to fulfil this task. 

**GET / Trucks**:  this package will provide information about the available trucks. 

**GET / locations**:  this package will provide information about the available locations.

**Robot_control_unit**: handles communication of trucks 

**map**: will implement a representation of environment and will also implement path finding algorithm. 


## Fault Tolerance

In order for the system to be robust, we defined a couple of safety/recovery maneuvers that will prevent and unwanted behaviour and keep the system in a controllable state.

### Communication failures

In case of a communication failure one of the sides should detect the connection is broken and respawn. <br>
	
1.) Webots Controller <--> External Controller
TODO:?

2.) External Controller <--> Backend
Trucks registers himself with an unique ID. 
If the socket goes down, external controller should be able reconnect to backend which will recognize him as a new TCP client but an already previously accepted truck. 
If that's the case, backend will create a new socket and delete previous one related to the truck

3.) Backend <--> Frontend
They communicate through a service call, where backend gives feedback on a succesful call. 
In case of a failed service, Frontend should be able to re-call service.

### Sensors failures

In case of a sensor failure in the Webots, Webost Controller is able to reset the sensor by enabling and disabling it.


### System failures

In case of a failure of the whole architectural part, the system gets rebooted, except for the environment since we want to preserve system state if at all possible.

### Corrupted TCP data

We are expecting a predefined length of TCP data messages on Backend. If that is not the case, packet is considered corrupted and trashed.

## How to install the dependencies for our project

In some cases you have to use pip3 instead of pip.

	sudo apt install python3-numpy python3-pip python3-setuptools
	cd backend/
	sudo pip install -e .

## How to compile our project

Compile external controller and webots controller

	./compile_all.sh

## How to run our project

Before running, make sure you compiled all the code. 
Sequence how programs are runned is important otherwise all sort of bogus things can happen.
Run the following command to spawn 5 external controller, one for each truck and it opens the frontend and the webots simulation.

	./run_all.sh

After a few seconds the simulation will start and you can select a freight, a pickup and a dropoff location in the frontend to start an order.
