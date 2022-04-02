# Webots follow line

## Overview

This is the controller of the trucks in the Webots World. Each controller is also the TCP/IP Client for the communication with the External Controller.

## Functionality

This package achieve that the Truck in our environment can follow different color line.
When we set one color as the follow line color,the camera first detect the color on the road and get the RGB value information of the color.Then it will calculate the difference of RGB value.When the result is less than 255,then the truck will follow the detected color,else do not change.
Every Robot in the Webots environment needs a controller to execute specific manouvers. 
This controller will send the measured data and the camera image to the External Controller via TCP/IP connection.
Based on this data the External Controller will do its calculations. 
Then it will received the wheel speed of each robot and execute this command. 

## How to compile

In order to compile all five follow_line codes, just type in terminal:

	./compile_all.sh
