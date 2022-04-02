with ProtectsObj; use ProtectsObj;

package Position_Algorithm is


   -- @name		color_diff
   -- @brief		calculate the difference between two colors if its <128 then its the same color
   --
   -- @param		input: colorcode of two colors a and b
   --
   -- @return		Returns the different between the two colors
   -- @note color_BGR is a custom type that restricts the number between 0 and 255
   function color_diff (a : color_BGR; b : color_BGR) return Integer with
     SPARK_Mode => On,
     Contract_Cases => (a(0) - b(0) + a(1) - b(1) + a(2) - b(2) > 128  => color_diff'Result > 128,
                        a(0) - b(0) + a(1) - b(1) + a(2) - b(2) <= 128  => color_diff'Result <= 128);


   -- @name		find_new_color
   -- @brief		search for a new color which is different to the current followed line color
   --
   -- @param		input: camera image and the color we are looking for
   --
   -- @return		Returns True if we found the color in the image, otherwise false
   --
   -- @example  	image : image_array := ((White,White,White,Green,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White),(White,White,White,White,White,White,White,White,White,White,White,White,White,White,White,White));
   --				find_color : color_BGR := (0, 255, 85) = Green
   --				Return True
   -- @note find_new_color no need to be tested since only uses color_diff in a for loop
   function find_new_color (image : image_array; find_color : color_BGR) return Boolean;

   -- @name		get_next_node
   -- @brief		get the next_node of the current line we are following and the lenght of the current line
   --
   -- @param		input: current line color, next line color, new color we found in the image
   --
   -- @return		Returns the node we driving next to it
   --
   -- @note		saved the distance to the next node in a globale variable (Distance)
   --
   -- @example	Curr_Line_Col : color_BGR := (255, 255, 255) = White
   --				Next_Line_Col : color_BGR := (0, 255, 85) = Green
   --				found_Color   : color_BGR := (0, 255, 85) = Green
   --				Return "PD_41"
   --				set Distance := 10.15
   function get_next_node (Curr_Line_Col : color_BGR; Next_Line_Col : color_BGR; found_Color   : color_BGR) return String with
     SPARK_Mode => On,
     Contract_Cases =>
          ((Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 0, 0)) => get_next_node'Result = "In__1",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 85, 170)) => get_next_node'Result = "In__1",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (127, 0, 85)) => get_next_node'Result = "In__2",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (3, 129, 255)) => get_next_node'Result = "In__3",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (0, 255, 255)) => get_next_node'Result = "In__4",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 85)) => get_next_node'Result = "In__D",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (0, 255, 85)) => get_next_node'Result = "In__D",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 85, 170) and found_Color = (255, 85, 170)) => get_next_node'Result = "Depot",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 85, 170) and found_Color = (255, 0, 0)) => get_next_node'Result = "Depot",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 0, 0) and found_Color = (255, 0, 0)) => get_next_node'Result = "NS_Ex",
           (Curr_Line_Col = (255, 85, 170) and Next_Line_Col = (255, 85, 170) and found_Color = (0, 0, 255)) => get_next_node'Result = "Out_D",
           (Curr_Line_Col = (255, 85, 170) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 255)) => get_next_node'Result = "In__1",
           (Curr_Line_Col = (255, 85, 170) and Next_Line_Col = (255, 0, 0) and found_Color = (0, 0, 255)) => get_next_node'Result = "NS_Ex",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (127, 0, 85) and found_Color = (127, 0, 85)) => get_next_node'Result = "PD__1",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (127, 0, 85) and found_Color = (255, 255, 85)) => get_next_node'Result = "PD__1",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (255, 255, 85) and found_Color = (255, 255, 85)) => get_next_node'Result = "EW_Ex",
           (Curr_Line_Col = (127, 0, 85) and Next_Line_Col = (127, 0, 85) and found_Color = (0, 0, 255)) => get_next_node'Result = "Out_1",
           (Curr_Line_Col = (127, 0, 85) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 255)) => get_next_node'Result = "In__2",
           (Curr_Line_Col = (127, 0, 85) and Next_Line_Col = (255, 255, 85) and found_Color = (0, 0, 255)) => get_next_node'Result = "EX_Ex",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (3, 129, 255) and found_Color = (3, 129, 255)) => get_next_node'Result = "PD_21",
           (Curr_Line_Col = (3, 129, 255) and Next_Line_Col = (3, 129, 255) and found_Color = (0, 0, 255)) => get_next_node'Result = "Out_2",
           (Curr_Line_Col = (255, 0, 0) and Next_Line_Col = (3, 129, 255) and found_Color = (3, 129, 255)) => get_next_node'Result = "PD_22",
           (Curr_Line_Col = (255, 0, 0) and Next_Line_Col = (255, 0, 0) and found_Color = (3, 129, 255)) => get_next_node'Result = "Out_2",
           (Curr_Line_Col = (3, 129, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 255)) => get_next_node'Result = "In__3",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (0, 255, 255) and found_Color = (0, 255, 255)) => get_next_node'Result = "Pd__3",
           (Curr_Line_Col = (0, 255, 255) and Next_Line_Col = (0, 255, 255) and found_Color = (0, 0, 255)) => get_next_node'Result = "Out_3",
           (Curr_Line_Col = (0, 255, 255) and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 255)) => get_next_node'Result = "In__4",
           (Curr_Line_Col = (255, 255, 255) and Next_Line_Col = (0, 255, 85) and found_Color = (0, 255, 85)) => get_next_node'Result = "PD_41",
           (Curr_Line_Col = (0, 255, 85) and Next_Line_Col = (0, 255, 85) and found_Color = (0, 0, 255)) => get_next_node'Result = "Out_4",
           (Curr_Line_Col = (255, 255, 85) and Next_Line_Col = (0, 255, 85) and found_Color = (0, 255, 85)) => get_next_node'Result = "PD_42",
           (Curr_Line_Col = (255, 255, 85) and Next_Line_Col = (255, 255, 85) and found_Color = (0, 255, 85)) => get_next_node'Result = "Out_4",
           (Curr_Line_Col =  (0, 255, 85)and Next_Line_Col = (255, 255, 255) and found_Color = (255, 255, 255)) => get_next_node'Result = "In__D");


   -- @name		get_current_position
   -- @brief		calculate the distance to the next_node
   --
   -- @param		input: camera image
   --
   -- @return		Returns the node we driving next to it
   --
   -- @note		- saved the distance left to the next node in a globale variable (Distance_Left)
   --				- gets the current speed velocity from ProtectsObj.SpeedObj.GetSpeed
   function get_current_position (Image : image_array) return String;


   -- @name		Task_Current_Position
   -- @brief		runs as a thread and loops the functions to get the current position each timestep
   --
   -- @param		waits for a signal to get the path and for a signal to get the next image
   --
   -- @return		set the next node and distance to this nod in ProtectsObj.RouteObj.SetCurrentPos
   --
   -- @note 		- get the path and path length from ProtectsObj.RouteObj.GetRoute
   -- 				- get the image from ProtectsObj.SensorDataObj.GetIamge
   task Task_Current_Position is
      entry GetRoute;
      --entry Start_Calculate_Position;
   end Task_Current_Position;


end Position_Algorithm;
