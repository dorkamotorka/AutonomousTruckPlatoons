--------------- Current Position Algorithm-------------------------
-- Inputs: camera_image, velocity and color path you get all the information
-- from protectedobj
--
-- Output: next_node as String (1 .. 5), distance left to next_nope as float
-- this will saved in protectedobj
--

with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Strings;         use Ada.Strings;
with Ada.Real_Time;       use Ada.Real_Time;
with Ada.Numerics.Elementary_Functions;

with ProtectsObj; use ProtectsObj;

package body Position_Algorithm is

   White          : color_BGR                   := (255, 255, 255);
   Red            : color_BGR                   := (45, 45, 200);
   Pink           : color_BGR                   := (255, 85, 170);
   Violett        : color_BGR                   := (127, 0, 85);
   Orange         : color_BGR                   := (40, 130, 210);   --(3, 129, 255);
   Yellow         : color_BGR                   := (30, 200, 200);   --(0, 255, 255);
   Green          : color_BGR                   := (0, 255, 85);
   Blue           : color_BGR                   := (255, 0, 0);
   Light_Blue     : color_BGR                   := (255, 255, 85);
   last_color     : color_BGR                   := (0, 0, 0);
   Last_Found_Color : color_BGR                 := (0, 0, 0);
   Red_Counter    : Integer;
   Distance       : Float;
   Next_Node      : String (1 .. 5);
   Start_Time     : Float;
   Distance_Left  : Float;
   Timestep       : Float;
   Curr_Line_Col  : color_BGR;
   Next_Line_Col  : color_BGR;
   Curr_Route_Pos : Integer;
   Last_Route_Pos : Integer;
   Curr_Route     : Route;
   Red_Indicator  : Boolean;
  -- Same_Cross     : Boolean;
   Colors         : array (1 .. 9) of color_BGR :=
     (White, Pink, Violett, Orange, Yellow, Green, Blue, Light_Blue, Red);
   type White_Node is (In_D, In_1, In_2, In_3, In_4);


   ------------- color_diff ------------
   -- calculate the difference between two colors and say that they are equal
   -- or not
   function color_diff (a : color_BGR; b : color_BGR) return Integer with SPARK_Mode => On is
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
         if (30 > d and then d >-30) then
            check := check + 1;
         end if;
      end loop;
      if check = 3 then
         return True;
      else

         return False;
      end if;

   end color_diff_1;

     function color_diff_sqrt (a : color_BGR; b : color_BGR) return Boolean is
      d    : Integer;
      check : Integer := 0;
   begin
      d := ((a(0)-b(0))**2+(a(1)-b(1))**2+(a(2)-b(2))**2);
      d := Integer(Ada.Numerics.Elementary_Functions.Sqrt(Float(d)));
      if d <= 80 then
         return True;
      else

         return False;
      end if;

   end color_diff_sqrt;


   ------------- find_new_color ------------
   -- search for a new color which is different to the current followed color
   function find_new_color
     (image : image_array; find_color : color_BGR) return Boolean
   is
      subtype rows is Integer range 1 .. 16;
      subtype cols is Integer range 1 .. 16;
      num_pixels : Integer := rows'Last * cols'Last;
      pixel_row  : Integer := 1;
      pixel_col  : Integer := 1;
      curr_pixel : color_BGR;

   begin
      for X in 0 .. num_pixels - 1 loop
         pixel_row := (X / cols'Last) + 1;
         pixel_col := (X rem cols'Last) + 1;
         curr_pixel := image (pixel_row, pixel_col);
         if (curr_pixel(0) > 70 or curr_pixel(1) > 70 or curr_pixel(2) > 70) and (color_diff_1 (curr_pixel, find_color) = True or else color_diff (curr_pixel, find_color) < 30) then
            --Put_Line ("Position Algorithm: Found new color: (" & find_color(0)'Image & ", " & find_color(1)'Image & ", " & find_color(2)'Image & ")");
            return True;
         end if;
      end loop;
      return False;
   end find_new_color;


   ------------- get_next_node ------------
   -- get the next_node of the current line we are following and the lenght of
   -- the current line
   --
   -- distance saved in global Distance variable next_node is the return string
   --
   -- every corossroad in the environment is uniqe, so we can find each
   -- crossroad with the current_line_color and the new color we are found
   -- with the find_new__color function
   function get_next_node
     (Curr_Line_Col : color_BGR; Next_Line_Col : color_BGR;
      found_Color   : color_BGR) return String with SPARK_Mode => On
   is
   begin

      -- follow White line
      if (Curr_Line_Col = White) and (Next_Line_Col = White) then
         if found_Color = Blue then
            Distance := 38.33;
            return "In__1";
         elsif found_Color = Pink then
            Distance := 38.33;
            return "In__1";
         elsif found_Color = Violett then
            Distance := 45.53;
            return "In__2";
         elsif found_Color = Orange then
            Distance := 21.43;
            return "In__3";
         elsif found_Color = Yellow then
            Distance := 30.35;
            return "In__4";
         elsif found_Color = Light_Blue then
            Distance := 30.93;
            return "In__2";
         elsif found_Color = Green then
            Distance := 30.93;
            return "In__D";
         end if;

         -- Depot
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Pink) and
         (found_Color = Pink))
      then
         Distance := 15.85;
         return "Depot";
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Pink) and
         (found_Color = Blue))
      then
         Distance := 15.85;
         return "Depot";
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Blue) and
         (found_Color = Blue))
      then
         Distance := 66.87;
         return "NS_Ex";
      elsif
        ((Curr_Line_Col = Pink) and (Next_Line_Col = White) and
         (found_Color = Red))
      then
         Distance := 11.15;
         return "Out_D";
      elsif
        ((Curr_Line_Col = Pink) and (Next_Line_Col = White) and
         (found_Color = White))
      then
         Distance := 25.33;
         return "In__1";
      elsif
        ((Curr_Line_Col = Pink) and (Next_Line_Col = Blue) and
         (found_Color = Red))
      then
         Distance := 49.33;
         return "NS_Ex";
      elsif
        ((Curr_Line_Col = Pink) and (Next_Line_Col = Blue) and
         (found_Color = Blue))
      then
         Distance := 49.33;
         return "NS_Ex";

         -- Pickup/Dropoff 1
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Violett) and
         (found_Color = Violett))
      then

         Distance := 11.95;
         return "PD__1";
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Violett) and
         (found_Color = Light_Blue))
      then
         Distance := 11.95;
         return "PD__1";
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Light_Blue) and
         (found_Color = Light_Blue))
      then
         Distance := 60.81;
         return "EW_Ex";
      elsif
        ((Curr_Line_Col = Violett) and (Next_Line_Col = Violett) and
         (found_Color = Red))
      then
         Distance := 5.65;
         return "Out_1";
      elsif
        ((Curr_Line_Col = Violett) and (Next_Line_Col = White) and
         (found_Color = White))
      then
         Distance := 34.93;
         return "In__2";
      elsif
        ((Curr_Line_Col = Violett) and (Next_Line_Col = Light_Blue) and
         (found_Color = Red))
      then
         Distance := 46.67;
         return "EW_Ex";
      elsif
        ((Curr_Line_Col = Violett) and (Next_Line_Col = Light_Blue) and
         (found_Color = Light_Blue))
      then
         Distance := 46.67;
         return "EW_Ex";
      elsif
        ((Curr_Line_Col = Violett) and (Next_Line_Col = White) and
         (found_Color = Light_Blue))
      then
         Distance := 5.65;
            return "Out_1";

         -- Pickup/Dropoff 2
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Orange) and
         (found_Color = Orange))
      then
         Distance := 9.15;
         return "PD_21";
      elsif
        ((Curr_Line_Col = Orange) and (Next_Line_Col = Orange) and
         (found_Color = Red))
      then
         Distance := 9.15;
         return "Out_2";
      elsif
        ((Curr_Line_Col = Blue) and (Next_Line_Col = Orange) and
         (found_Color = Orange))
      then
         Distance := 7.57;
         return "PD_22";
      elsif
        ((Curr_Line_Col = Blue) and (Next_Line_Col = Blue) and
         (found_Color = Orange))
      then
         Distance := 18.61;
         return "Out_2";
      elsif
        ((Curr_Line_Col = Orange) and (Next_Line_Col = White) and
         (found_Color = White))
      then
         Distance := 12.43;
         return "In__3";

         -- Pickup/Dropoff 3
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Yellow) and
         (found_Color = Yellow))
      then
         Distance := 9.15;
         return "PD__3";
      elsif
        ((Curr_Line_Col = Yellow) and (Next_Line_Col = Yellow) and
         (found_Color = Red))
      then
         Distance := 6.15;
         return "Out_3";
      elsif
        ((Curr_Line_Col = Yellow) and (Next_Line_Col = White) and
         (found_Color = White))
      then
         Distance := 23.05;
         return "In__4";

         -- Pickup/Dropoff 4
      elsif
        ((Curr_Line_Col = White) and (Next_Line_Col = Green) and
         (found_Color = Green))
      then
         Distance := 10.15;
         return "PD_41";
      elsif
        ((Curr_Line_Col = Green) and (Next_Line_Col = Green) and
         (found_Color = Red))
      then
         Distance := 7.95;
         return "Out_4";
      elsif
        ((Curr_Line_Col = Light_Blue) and (Next_Line_Col = Green) and
         (found_Color = Green))
      then
         Distance := 6.57;
         return "PD_42";
      elsif
        ((Curr_Line_Col = Light_Blue) and (Next_Line_Col = Light_Blue) and
         (found_Color = Green))
      then
         Distance := 17.81;
         return "Out_4";
      elsif
        ((Curr_Line_Col = Green) and (Next_Line_Col = White) and
         (found_Color = White))
      then
         Distance := 20.63;
         return "In__D";
      end if;
      Put_Line ("Position Algorithm: No node found!");
      return "00000";
   end get_next_node;


   ------------- get_current_position ------------
   -- calculate the distance to the next_node
   function get_current_position (Image : image_array) return String is

      Speed       : Float;
      found_color : color_BGR;

   begin
      for I in 1 .. 9 loop -- loop all colors
-- ((Colors (I) = Red) and find_new_color(Image, Colors (I))) or
         -- when we found a new color which is not our current line color, we are on a new crossroad
         if   (Colors (I) /= Curr_Line_Col and Colors (I) /= last_color and find_new_color(Image, Colors (I)) and Last_Found_Color /= Colors (I))
         then
            found_color := Colors (I);
            Last_Found_Color := found_color;
            last_color  := Curr_Line_Col;

            -- fixed the problem if you get two times a picture with red mark
            if (Colors (I) /= Red) then
               Red_Indicator := False;
            end if;
            if (Red_Indicator = False) then
               if (Colors (I) = Red) then
                  Red_Counter := Red_Counter + 1;
                       -- Put_Line ("Position Algorithm: Found Red!");
                  Red_Indicator := True;
               end if;

               -- print the found color, current line color, follow next line
               -- color
               --Put_Line ("Position Algorithm: Found new crossroad!");
               --Put_Line
                 --("Position Algorithm: Found color: (" &
                  --found_color (0)'Image & ", " & found_color (1)'Image & ", " &
                  --found_color (2)'Image & ")");
               --Put_Line
                 --("Position Algorithm: Next_Line_Col: (" &
                  --Next_Line_Col (0)'Image & ", " & Next_Line_Col (1)'Image &
                  --", " & Next_Line_Col (2)'Image & ")");
               --Put_Line
                 --("Position Algorithm: Curr_Line_Col: (" &
                  --Curr_Line_Col (0)'Image & ", " & Curr_Line_Col (1)'Image &
                  --", " & Curr_Line_Col (2)'Image & ")");

               Start_Time := SensorDataObj.GetTime; -- save the current time
               Timestep   := 0.0;

               -- get the next destination node and distance to this node
               Next_Node  := get_next_node(Curr_Line_Col, Next_Line_Col, Colors (I));
               Distance_Left := Distance;

               -- get the next color in our path
               if (Curr_Route_Pos <= Last_Route_Pos and ((found_color = Next_Line_Col or (found_color = Red and Curr_Line_Col /= Pink and Curr_Line_Col /= Violett) or (found_color = Red and Next_Line_Col = Violett) or (Curr_Line_Col = White and Next_Line_Col = White and found_color /= Blue and found_color /= Light_Blue))))
               then
                  Curr_Line_Col  := Next_Line_Col;
                  --Put_Line("Position Algorithm: Current path position: " & Curr_Route_Pos'Image);
                  Curr_Route_Pos := Curr_Route_Pos + 1;
                  Next_Line_Col  := Curr_Route (Curr_Route_Pos);
                  if Next_Line_Col = (3, 129, 255) then
                     Next_Line_Col := Orange;
                  elsif Next_Line_Col = (0, 255, 255) then
                     Next_Line_Col := (30, 200, 200);
                  end if;

               elsif (Next_Line_Col = (0,0,0)) then
                  Curr_Route_Pos := Curr_Route_Pos + 1;
               end if;
               exit;
            end if;
         end if;
      end loop;
      Speed    := SpeedObj.GetSpeed; --get the current truck speed
      Speed    := (Speed / (2.0*Ada.Numerics.Pi)) * (2.0*Ada.Numerics.Pi*0.04);
      Timestep :=
        SensorDataObj.GetTime - Start_Time -
        Timestep; -- time left from the last position
      Distance_Left := Distance_Left - Timestep * Speed; -- calculate distance to the next_node
      if Distance_Left < 0.0
      then -- set Distance_Left to 0, when we calculate a negative distance
         Distance_Left := 0.0;
      end if;

      -- print the Next_Node and the Distance_Left
      --Put_Line
        --("Position Algorithm: Next Node: " & Next_Node & ", Distance left: " &
         --Distance_Left'Image);

      return Next_Node;
   end get_current_position;


   task body Task_Current_Position is
      Image : image_array;
      Last_Time : Float := 0.0;
      bla : integer;
   begin
      Next_Node      := "00000";
      Curr_Route_Pos := 1;
      Last_Route_Pos := -1;
      Timestep       := 0.0;
      Distance_Left  := 0.0;
      Curr_Line_Col  := (0, 0, 0);
      Next_Line_Col  := (0, 0, 0);
      

      while True loop
         if (Last_Route_Pos+2 <= Curr_Route_Pos or Red_Counter = 4) then
            --Put_Line ("Position Algorithm: Wait for new Route!");
            accept GetRoute;
            Red_Counter    := 0;
            Curr_Route     := RouteObj.GetRoute (Last_Route_Pos);
            Curr_Line_Col  := Curr_Route (Curr_Route_Pos);
            Curr_Route_Pos := Curr_Route_Pos + 1;
            Next_Line_Col  := Curr_Route (Curr_Route_Pos);
                  if Next_Line_Col = (3, 129, 255) then
               Next_Line_Col := Orange;
                  elsif Next_Line_Col = (0, 255, 255) then
                     Next_Line_Col := (30, 200, 200);
                  end if;
            if ((Curr_Line_Col = Pink) and (Next_Line_Col = Blue))
            then
               Next_Node := "NS_Ex";
               Distance := 49.33;
               RouteObj.SetCurrentPos(Next_Node, Distance);
            elsif
               ((Curr_Line_Col = Pink) and (Next_Line_Col = white))
            then
               Next_Node := "Out_D";
               Distance := 11.15;
               RouteObj.SetCurrentPos(Next_Node, Distance);
            end if;
         end if;
         --Put_Line ("Position Algorithm: Wait for new Image!");
         --accept Start_Calculate_Position;
         

         while (Last_Time = SensorDataObj.GetTime) loop
            bla := 0;
         end loop;
         Last_Time := SensorDataObj.GetTime;
         Image := SensorDataObj.GetIamge; -- get the camera image

         -- initialize the current line color
         if Curr_Line_Col = (0, 0, 0) then
            Start_Time := SensorDataObj.GetTime;
            for I in 1 .. 9 loop
               --Put_Line ("Position Algorithm: Find first Color!");
               if (find_new_color (Image, Colors (I))) then
                  Curr_Line_Col := Colors (I);
                  --Put_Line
                    --("Position Algorithm: Found first color: (" &
                     --Curr_Line_Col (0)'Image & ", " & Curr_Line_Col (1)'Image &
                     --", " & Curr_Line_Col (2)'Image & ")");
                  exit;
               end if;
            end loop;
         end if;
         RouteObj.SetCurrentPos (get_current_position (Image), Distance_Left);
      end loop;

   end Task_Current_Position;

end Position_Algorithm;
