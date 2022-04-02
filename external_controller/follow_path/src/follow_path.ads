with Ada.Text_IO;
with ProtectsObj; use ProtectsObj;

package follow_path is

   type dirc_speed is array (0 .. 1) of Float;
   type ds is array (0 .. 1) of Integer;


   -- @name		set_steering_angle
   -- @brief		calculate the steering angle according to the wheel angle
   --
   -- @param		input: wheel_angle between -0.5 to 0.5
   --
   -- @return		wheel_angle between -0.5 to 0.5
  -- function set_steering_angle (wheel_angle : in out Float) return Float;
   function set_steering_angle (wheel_angle : in out Float) return Float with
     Pre => wheel_angle <= 0.5 and wheel_angle >= -0.5,
     Post => wheel_angle <= 0.5 and wheel_angle >= -0.5,
     Contract_Cases =>
       ((wheel_angle > 0.1 and wheel_angle < 0.4) => set_steering_angle'Result = (wheel_angle+0.1),
        (wheel_angle < -0.1 and wheel_angle > -0.4) => set_steering_angle'Result = (wheel_angle-0.1),
        (wheel_angle > -0.1 and wheel_angle < 0.1) => set_steering_angle'Result = wheel_angle,
        wheel_angle > 0.5 => set_steering_angle'Result = 0.5,
        wheel_angle < -0.5 => set_steering_angle'Result = -0.5);


   ------------------------------check_distance----------------------------------------
   -- @name		check_distance
   -- @brief		check if the distance between truck and obstacle smaller than the set distance(200)
   --
   -- @param		input: ds_values of two values (900,1000)
   --
   -- @return		Return boolean true/false

   --function check_distance (ds_values : ds) return Boolean;
   function check_distance (ds_values : ds) return Boolean with
     SPARK_Mode => On,
     Pre => (ds_values(0) > 0 and ds_values(1) > 0),
     Contract_Cases =>
       ((ds_values(0) < 120 or ds_values(1) < 120) => check_distance'Result = True,
        (ds_values(0) >= 120 and ds_values(1) >= 120) => check_distance'Result = False);


   function color_diff (a : color_BGR; b : color_BGR) return Integer;
   function color_diff_1 (a : color_BGR; b : color_BGR) return Boolean;



   -------------------process_camera_image-------------------------------------------------
   -- @name		process_camera_image
   -- @brief		calculate the angle according to the camera image
   --
   -- @param		input: image_array of image;
   --                   color_BGR of color
   --
   -- @return		Returns the tan value of angle
   function process_camera_image
     (image : image_array; color : color_BGR) return Float with
     SPARK_Mode => On,
     Post => (process_camera_image'Result > 0.0 and process_camera_image'Result < Float'Last);


   -----------------------filter_angle---------------------------------------------------
   -- @name		filter_angle
   -- @brief		Make angle changes smoother
   --
   -- @param		input: float of value between -0.5 to 0.5
   --
   -- @return		Returns float of value between -0.5 to 0.5
   function filter_angle (new_value : Float) return Float with
     SPARK_Mode => On,
     Pre => (new_value <= 0.5 and new_value >= -0.5 and new_value < Float'Last),
     Post => filter_angle'Result <= 0.5 and filter_angle'Result >= -0.5,
     Depends => (filter_angle'Result => new_value),
     Contract_Cases =>
       (new_value = 99_999.99 => filter_angle'Result = 99_999.99);


   -------------------------applyPID---------------------------------------------------
   -- @name		applyPID
   -- @brief		Make angle changes smoother
   --
   -- @param		input: float of value between -0.5 to 0.5
   --
   -- @return		Returns float of value between -0.5 to 0.5
   function applyPID (line_angle : Float) return Float with
     SPARK_Mode => On,
     Pre => (line_angle <= 0.5 and line_angle >= -0.5 and line_angle < Float'Last),
     Post => applyPID'Result <= 0.5 and applyPID'Result >= -0.5,
     Depends => (applyPID'Result => line_angle);
     -- How can I tell line_angle is not going to change in the function


   -------------------------filter_angle---------------------------------------------------
   -- @name		follow_line
   -- @brief		calculate the speed of left and right wheel speed according the image
   --
   -- @param		input: Integer of distances from two distance sensor; e.g. (900,1000)
   --                   Image_Array of camera image  size:16*16*3; e.g. ((255,255,0),(0,255,255).....)
   --                   color_BGR of Color_Code; e.g. (255,255,255)
   --
   -- @return		Return the left wheel speed and right wheel speed
   function follow_path
     (ds0, ds1   : in Integer; Cam_Image : image_array; route_plan : Route; route_length : Integer) return dirc_speed with
     Post => follow_path'Result in dirc_speed;
     --Depends => (follow_path'Result => ds0,  follow_path'Result => ds1, follow_path'Result => Cam_Image, follow_path'Result => Color_Code);


end follow_path;
