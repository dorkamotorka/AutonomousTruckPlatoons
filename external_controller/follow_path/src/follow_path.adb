with Ada.Text_IO; use Ada.Text_IO;
with ProtectsObj; use ProtectsObj;
with controller_peer; use controller_peer;

package body follow_path is
   steering_angle : Float   := 0.0;
   PID_need_reset : Boolean := False;

   stop_signal    : Integer := 0;
   stop_counter   : Integer := 0;
   red_signal     : Boolean := True;
   pause_counter  : Integer := 0;
   subtype rows is Integer range 1 .. 16;
   subtype cols is Integer range 1 .. 16;
   camera_fov : Float   := 1.0;
   oldValue   : Float   := 0.0;
   integral   : Float   := 0.0;
   first_call : Boolean := True;
   type filter is array (0 .. 2) of Float;

   current_color : Integer := 1;

   old_value  : filter;
   line_angle : Float;

   speed_values : dirc_speed;

   White_bgr      : color_BGR                   := (255, 255, 255);
   Red_bgr        : color_BGR                   := (0, 0, 255);
   Pink_bgr       : color_BGR                   := (255, 85, 170);
   Violett_bgr    : color_BGR                   := (127, 0, 85);
   Orange_bgr     : color_BGR                   := (3, 129, 255);
   Yellow_bgr     : color_BGR                   := (0, 255, 255);
   Green_bgr      : color_BGR                   := (0, 255, 85);
   Blue_bgr       : color_BGR                   := (255, 0, 0);
   Light_Blue_bgr : color_BGR                   := (255, 255, 85);

   angle       : Float;
   init_speed  : Float;
   speed       : Float;
   left_speed  : Float;
   right_speed : Float;
   ds_values : ds;

   UNKNOWN : constant Float := 99_999.99;
   KP      : constant Float := 0.25;
   KI      : constant Float := 0.006;
   KD      : constant Float := 2.0;

   TIME_STEP : Integer;

   --- set the steering angle of the Truck ---
   function set_steering_angle (wheel_angle : in out Float) return Float is
   begin

      if (wheel_angle - steering_angle > 0.1) then
         wheel_angle := steering_angle + 0.1;
      end if;

      if (wheel_angle - steering_angle < -0.1) then
         wheel_angle := steering_angle - 0.1;
      end if;

      steering_angle := wheel_angle;

      if (wheel_angle > 0.5) then
         wheel_angle := 0.5;
      elsif (wheel_angle < -0.5) then
         wheel_angle := -0.5;
      end if;

      return wheel_angle;
   end set_steering_angle;

   ----Check the values of distance sensor (collision avoidance---
   function check_distance (ds_values : ds) return Boolean is
   begin
      if (ds_values (0) < 120 or else ds_values (1) < 120) then --ge�ndert
         return True;--Stop
      else
         return False;
      end if;
   end check_distance;

   ---Set speed---
   function set_speed (speed : Float) return Float is
   begin
      return speed;
   end set_speed;
   -------
   function signbit (x : Float) return Integer is
   begin
      if x < 0.0 then
         return 1;
      else
         return 0;
      end if;
   end signbit;

   ------------------[image process]----------------
   -------------color diff------------
   function color_diff (a : color_BGR; b : color_BGR) return Integer is
      diff : Integer := 0;
      d    : Integer;
   begin
      for i in 0 .. 2 loop
         d := a (i) - b (i);
         if d > 0 then
            diff := diff + d;
         else
            diff := diff - d;
         end if;
      end loop;
      return diff;
   end color_diff;

   function color_diff_1 (a : color_BGR; b : color_BGR) return Boolean is
      d    : Integer;
      check : Integer := 0;
   begin
      for i in 0 .. 2 loop
         d := a (i) - b (i);
         if (60 > d and then d >-60) then
            check := check + 1;
         end if;
      end loop;
      if check = 3 then
         return True;
      else

         return False;
      end if;

   end color_diff_1;

   --------------process camera image-------------
   function process_camera_image
     (image : image_array; color : color_BGR) return Float
   is
      num_pixels  : Integer := rows'Last * cols'Last;
      sumx        : Integer := 0;
      pixel_count : Integer := 0;
      pixel_row   : Integer := 1;
      pixel_col   : Integer := 1;
   begin
      for x in 0 .. num_pixels - 1 loop
         pixel_row := (x / cols'Last) + 1;
         pixel_col := (x rem cols'Last) + 1;
         if (color_diff_1 (image (pixel_row, pixel_col), color) = True or else color_diff(image (pixel_row, pixel_col), color) < 100) then
            sumx        := sumx + (x rem cols'Last);
            pixel_count := pixel_count + 1;
         end if;
      end loop;
      if pixel_count = 0 then
         return UNKNOWN;
      end if;
      --  else
      return
        (Float (sumx) / Float (pixel_count) / Float (cols'Last) - 0.5) *
        camera_fov;
      --  end if;
   end process_camera_image;

   ---------------filter angle of the line----------------
   function filter_angle (new_value : Float) return Float is
      sum : Float;
   begin
      if (first_call or else new_value = UNKNOWN) then
         first_call := False;
         for i in 0 .. 2 loop
            old_value (i) := 0.0;
         end loop;
      else
         for i in 0 .. 1 loop
            old_value (i) := old_value (i + 1);
         end loop;
      end if;
      if (new_value = UNKNOWN) then
         return UNKNOWN;
      else
         old_value (2) := new_value;
         sum           := 0.0;
         for i in 0 .. 2 loop
            sum := sum + old_value (i);
         end loop;
         return Float (sum / 3.0);
      end if;
   end filter_angle;

   ------------------------PID----------------------------
   function applyPID (line_angle : Float) return Float is
      diff : Float;
   begin
      if PID_need_reset then
         oldValue       := line_angle;
         integral       := 0.0;
         PID_need_reset := False;
      end if;
      if signbit (line_angle) /= signbit (oldValue) then
         integral := 0.0;
      end if;
      diff := line_angle - oldValue;
      if abs (integral) < 30.0 then
         integral := integral + line_angle;
      end if;
      oldValue := line_angle;
      return KP * line_angle + KI * integral + KD * diff;
   end applyPID;

   function follow_path
     (ds0, ds1   : in Integer; Cam_Image : image_array; route_plan : Route; route_length : Integer) return dirc_speed is


      img : image_array := Cam_Image;

   begin
      TIME_STEP  := 16;
      init_speed := SpeedObj.GetSpeed;
      speed      := init_speed;

      --Parameters passed from Webots controller-----------
      --Ada.Text_IO.Put_Line ("ds_values is:");
      ds_values (0) := ds0; --Integer'Value (Ada.Text_IO.Get_Line);
      ds_values (1) := ds1; --Integer'Value (Ada.Text_IO.Get_Line);
      --Ada.Text_IO.Put_Line("Links: " & Integer'Image(ds_values(0)) & " Rechts: " & Integer'Image(ds_values(1)));
      -----------------------------------------------------

      if check_distance (ds_values) then
         --Put_Line("**** DEBUG : follow_path I WILl STOP collision");
         speed       := set_speed (0.0);
         left_speed  := speed;
         right_speed := speed;

         -------- [ Platoon ] -------
         --save old speed
         -- SpeedObj.SetSpeed(0.0,0.0);
         if PlatooningObj.GetPlatoonMode then

            if PlatooningObj.GetSOS = False then

               WriteEMERGE(True);

            else
              null;
            end if;
         end if;
         --return (0.0, 0.0);
         ----------------------------

      else

         ------ [Platoon] ------

         if PlatooningObj.GetSOS then
            --SpeedObj.SetSpeed(Oldvales)/10?
            WriteEMERGE(False);
         end if;

         ----------------------

         left_speed := init_speed;
         right_speed := init_speed;
         --speed := 15.0;

         if (current_color < route_length and then (filter_angle (process_camera_image (img, route_plan(current_color+1))) /= UNKNOWN)) then
            current_color:= current_color + 1 ;
            line_angle := filter_angle (process_camera_image (img, route_plan(current_color)));
            angle       := applyPID (line_angle);
            left_speed  := speed + set_steering_angle (angle) * 300.0;
            right_speed := speed - set_steering_angle (angle) * 300.0;
         elsif ((process_camera_image (img, route_plan(current_color))) /= UNKNOWN) then

            line_angle := filter_angle (process_camera_image (img, route_plan(current_color)));
            angle       := applyPID (line_angle);
            left_speed  := speed + set_steering_angle (angle) * 300.0;
            right_speed := speed - set_steering_angle (angle) * 300.0;

         end if;


         if (red_signal and then filter_angle (process_camera_image (img, Red_bgr)) /= UNKNOWN) then
            pause_counter := 640 / TIME_STEP;
            stop_counter  := 5120 / TIME_STEP;
            red_signal    := False;
            stop_signal   := stop_signal + 1;

         elsif(stop_counter > 0) then
            stop_counter := stop_counter - 1;

         elsif (stop_signal < 4 and then stop_counter = 0) then
            red_signal := True;

         end if;


         if (pause_counter > 0) then
            left_speed    := 0.0;
            right_speed   := 0.0;
            pause_counter := pause_counter - 1;
            --if (stop_signal = 1) then
               --Ada.Text_IO.Put_Line ("From Depot");
            if (stop_signal = 2 and pause_counter = 39) then
               CargoObj.PickUp;
            elsif (stop_signal = 3 and pause_counter = 39) then
               CargoObj.DropOff;
            end if;
         end if;

         if (stop_signal = 4) then
            left_speed    := 0.0;
            right_speed   := 0.0;
         end if;

         if (current_color = 1) then
            if (ds_values (0) < 900 or else ds_values (1) < 900) then
               left_speed := 0.0;
               right_speed := 0.0;
            end if;
         end if;
         if (current_color = route_length) then
            if PlatooningObj.GetPlatoonMode then
               controller_peer.WriteEXITE;
            end if;
            current_color := 1;
         end if;

      end if;

      --------------Parameters passed to webots controller--------------
      --Ada.Text_IO.Put_Line ("left speed:" & Float'Image (left_speed));
      --Ada.Text_IO.Put_Line ("right speed:" & Float'Image (right_speed));
      --Ada.Text_IO.Put_Line ("current color:" & Integer'Image (current_color));
      --Ada.Text_IO.Put_Line ("stop signal:" & Integer'Image (stop_signal));
      --Ada.Text_IO.Put_Line ("pause counter:" & Integer'Image (pause_counter));
      --Ada.Text_IO.Put_Line ("stop counter:" & Integer'Image (stop_counter));
      --Ada.Text_IO.Put_Line ("red signal:" & Boolean'Image (red_signal));
      ------------------------------------------------------------------
      speed_values (0) := left_speed;
      speed_values (1) := right_speed;
      return speed_values;

   end follow_path;

end follow_path;
