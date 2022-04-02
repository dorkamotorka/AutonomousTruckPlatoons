with Text_IO;               use Text_IO;
with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;

with Ada.Streams;           use Ada.Streams;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;           use Ada.Strings;

--with follow_line; use follow_line;
with follow_path; use follow_path;
with Position_Algorithm; use Position_Algorithm;
with ProtectsObj; use ProtectsObj;
--with controller_peer; use controller_peer; that doesnt work

package body Message_Handle is

   function evaluateMessageWebots (Input_string : in String) return String is

      Len_string     : Integer := Input_string'Length;
      Grenzen_string : array (1 .. 4) of Integer; --3 values expected to recv
      lauf_var : Integer          := 1; --für : Suche & Data Image
      reply    : Unbounded_String := Null_Unbounded_String;
      --Outputs:
      ds_val1    : Integer := 0;
      ds_val2    : Integer := 0;
      Time : Float := 0.0;
      Data_Image : ProtectsObj.Image_Array;
      --Color_code : color_BGR; --array (1 .. 3) of Integer;
      My_Path    : Route;
      LenofMyPath: Integer;
      speed_values : follow_path.dirc_speed; --Output of Line Dec

   begin
      
      --Put_Line("WiLLkommen bei evaluate message");

      -- Search the String for : and saves the borders in Array "Grenzen_String"
      for I in 1 .. Len_string loop
         exit when lauf_var = 4 ;
         if Input_string (I) = ':' or Input_string (I) = ';' then
            Grenzen_string (lauf_var) := I;
            lauf_var                  := lauf_var + 1;
         end if;
      end loop;
      Grenzen_string (4) := Len_string ;
      
      --Put_Line("Debug Nenn mir die Grenzen: " & Integer'Image(Grenzen_string(1)) & Integer'Image(Grenzen_string(2)) & Integer'Image(Grenzen_string(3)));

      -- Now Looking at athe borders of the array to get the information out
      ds_val1 :=
        Integer'Value
          (Input_string (Input_string'First .. Grenzen_string (1) - 1));
      ds_val2 :=
        Integer'Value
          (Input_string (Grenzen_string (1) + 1 .. Grenzen_string (2) - 1));
      
      Time := Float'Value
        (Input_string (Grenzen_string (2) + 1 .. Grenzen_string (3) - 1));
      --Put_Line("**** DEBUG : Message Handle SimTime :" & Float'Image(Time));

      -- Image put it in a 16 x 16 x 3 Char array
      lauf_var :=  Grenzen_string (3) + 1; --where we start at the InputString

      for X in 1..16 loop
         for Y in 1..16 loop
            Data_Image(X,Y) := (Character'Pos(Input_string(lauf_var + 0)), --wegen chengs bgr andersrum
                                Character'Pos(Input_string(lauf_var + 1)),
                                Character'Pos(Input_string(lauf_var + 2)));
            lauf_var := lauf_var + 4;
         end loop;
      end loop;
      --Put_Line(" ");
      SensorDataObj.SaveImage(Data_Image);
      SensorDataObj.SetTime(Time);
      
      --Ping the Position_Algorithm that a new images was saved
      --Position_Algorithm.Task_Current_Position.Start_Calculate_Position;
      
      --Put_Line("DistanceValues are:" & Integer'Image(ds_val1) & Integer'Image(ds_val2));
      
      My_Path := RouteObj.GetRoute(LenofMyPath);
      --Calling the Line Detection
      speed_values := follow_path.follow_path (ds_val1, ds_val2, Data_Image, My_Path, LenofMyPath);
      

      --Retuurn: Converts Float to string, looks for the '-' and returns String
      declare
         Raw_Stringtoconvert1 : constant String :=
           Float'Image (speed_values (0));
         Raw_Stringtoconvert2 : constant String :=
           Float'Image (speed_values (1));
         Dot1 : Integer := 2;
         Dot2 : Integer := 2;
      begin
         for I in 1 .. 5 loop
            if (Raw_Stringtoconvert1 (I) = '-') then
               Dot1 := I;
               exit;
            end if;
         end loop;
         for I in 1 .. 5 loop
            if (Raw_Stringtoconvert2 (I) = '-') then
               Dot2 := I;
               exit;
            end if;
         end loop;
         
           reply:= reply & Raw_Stringtoconvert1 (Dot1 .. Raw_Stringtoconvert1'Length) & ":" & Raw_Stringtoconvert2 (Dot2 .. Raw_Stringtoconvert2'Length) & ";";
      end;
      
      --Put_Line (To_String(reply));--TODO: entfernen
      
      return To_String (reply);

   end evaluateMessageWebots;
   
   function GetColorOutString (Color_String : String) return color_BGR is
      
      type Colours is (white, red, pink, violett, orange, yellow, green, blue, light_blue);
      
      White_bgr      : color_BGR                   := (255, 255, 255);
      Red_bgr        : color_BGR                   := (0, 0, 255);
      Pink_bgr       : color_BGR                   := (255, 85, 170);
      Violett_bgr    : color_BGR                   := (127, 0, 85);
      Orange_bgr     : color_BGR                   := (3, 129, 255);
      Yellow_bgr     : color_BGR                   := (0, 255, 255);
      Green_bgr      : color_BGR                   := (0, 255, 85);
      Blue_bgr       : color_BGR                   := (255, 0, 0);
      Light_Blue_bgr : color_BGR                   := (255, 255, 85);
      
      NoColor_exp : exception;

   begin
      
      case  Colours'Value(Color_String) is
         when white => return White_bgr;
         when red => return Red_bgr;
         when pink => return Pink_bgr;
         when violett => return Violett_bgr;
         when orange => return Orange_bgr;
         when yellow => return Yellow_bgr;
         when green => return Green_bgr;
         when blue => return Blue_bgr;
         when light_blue => return Light_Blue_bgr;
         when others =>
            raise NoColor_exp with "Couldn't recognize Color";
      end case;        
      
      --null;
   end GetColorOutString;
   
   
     
end Message_Handle;
