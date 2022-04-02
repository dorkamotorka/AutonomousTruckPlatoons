# Message Handle
## Overview

This package was initially thought as message handling for the Webots Communication. 

**Packages using**: follow_path, Position_Algorithm, ProtectsObj
**Used by**: backend_client, Webots_Server


## Functionality
### evaluateMessageWebots (Input_string : in String) return String 
Input_String :: is the received message from the webots controller
	Expected Message: `<DistanceSensor1> :  <DistanceSensor2> : <SimulationTime> : <ImageStreamSize16x16x4> ;`

return :: is the String send back to Webots Controller
	Message :  `<SpeedLeft> :  <SpeedRight> ;`

Variables _Len_string, Grenzen_string, lauf_var_ are used to analyse the Input_String barriers, and extract the information. The Information is then saved in “ds_val1”(Integer) , “ds_val2” (Integer) "Time" (Float) and Data_Image (Image_Array). The Image Values are saved in ProtectsObj under SensorDataObj.

The function then calls the Path from RouteObj. With that Information in calls the follow_path function. It returns an array size two Float and is saved in the array “speed_values”. 
When a Float is converted to String in Ada , the first Bytes make up a Space. C wants the String trimmed in order to convert it back to Float properly. Since the returned Values can be negative, the function is cautious with trimming the String, and therefore has to check whether it has a ‘-‘.
The function then replies with the string stored in “reply”.

### GetColorOutString (Color_String : String) return color_BGR
**Color_String** :: is the name of a Color. e.g. “pink”

**return** :: a color_BGR (array size 3 of Integer from -1 to 255 ) of the desired color given es an input

Idea of the function is to make it easier to get the desired BGR Code of a Color.
