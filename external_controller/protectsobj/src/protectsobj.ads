--Here you find genreal types that are used between the packages
--all secured Variables
with GNAT.Sockets;          use GNAT.Sockets;

package ProtectsObj is
   --declaration of types
   
   type color_BGR is array (0 .. 2) of Integer range 0 .. 255;
   type image_array is
        array
          (1..16,
           1..16) of color_BGR;--The image in the form of a two-dimensional array with BGR
   type Route is array (1..25) of color_BGR;
   
   type LookUpTableCarsTaskNr is array (1..5) of Integer;
   type LookUpTablePorts is array (1..5) of Port_Type;
   --
   --My_Client : array (1..5) of Client_Type; --TODO vllr weg
   
   --[MAIN Info]-- TODO
   My_ID : Integer := 1;
   
   protected PortObj is 
      
      procedure SetExCoPort (Port : Port_Type);
      function GetExCoPort return Port_Type;
      
      private
      
      Webots_Port : Port_Type := 9876;
      Backend_Port : Port_Type := 65432;
      ExCo_Port : Port_Type;
      
   end PortObj;

   protected CargoObj is
      
      function GetMaxLoad return Integer;
      procedure SetAuftrag (V : Integer);
      function GetAuftrag return Integer;
      procedure PickUp;
      procedure DropOff;
      
   private
      
      Local       : Integer := 0;
      CurrentLoad : Integer := 0;
      MaxLoad : Integer := 500;
      
   end CargoObj;
   
   protected SpeedObj is
      
      procedure SetSpeed (WishSpeedL, WishSpeedR : Float);
      function GetSpeed return Float; --returns the lowe speed
      function GetAVGSpeed return Float; --return the avergae SPeed
      
   private
      
      SpeedL : Float := 0.0;  
      SpeedR : Float := 0.0;
      
   end SpeedObj;
   
   protected RouteObj is 
      
      procedure SetColorCodeDest (C1, C2, C3 : Integer);
      function GetColotCodeDest return color_BGR;
      
      procedure SetRoute (Given_Route: in Route; Len : in Integer);
      function GetRoute (Len: out Integer) return Route;
      
      procedure SetCurrentLineNr ( Number : in Integer);
      function GetCurrentLineNr return Integer;
      
      procedure SetCurrentPos (St : in String; Fl : Float); --TODO
      function GetCurrentPos (Fl : out Float) return String;
      
   private
      
      ColorCode_PickUp : color_BGR := (255,85,170); --TODO kann eig weg
      Route_path : Route; 
      LenRoute : Integer := 1;
      CurrentLineNr : Integer := 1;
      
      --Position TODO
      Astring : String(1..5) := "BEGIN";
      AFLoat : Float := 0.0;
      
   end RouteObj;
   ---
   protected PlatooningObj is
      
      procedure SetPlatoonMode(State : in Boolean);
      function GetPlatoonMode return Boolean;
      
      procedure IncFailures;
      function GetFailures return Integer;
      
      procedure SetLeader (State : in Boolean);
      function GetLeader return Boolean;
      
      procedure SetSOS (State : in Boolean);
      function GetSOS return Boolean;
      
      procedure SetAmountofTrucks (Amount : in Integer);
      function GetAmountofTrucks return Integer;
      
      procedure AddTruck2Seq (Index, ID : in Integer);
      function GetIDoutofSeq (Index : in Integer) return Integer;
      
      procedure SetLookUpPorts(ID: in Integer ; PortNumber : Port_Type);
      function GetPortofID (OfTruckID : in Integer) return Port_Type;
      
      procedure SetNeighbour (Front, Leader : in Integer);
      function GetNeighbour (WantLeader : in Boolean) return Integer;
      
      procedure SetDistance;
      function GetDistance return Integer; 
      
      procedure SetLookUpTable(IndexID, TaskNrCLient: in Integer);
      function GetTaskNr (OfTruckID : in Integer) return Integer;
      --TODO reset function
      procedure ResetValues;
      
   private
      
      PlatoonMode : Boolean := False;
      Failures_Count : Integer := 0;
      
      Leader : Boolean := False;
      SOS : Boolean := False;
      
      --leader:
      HowManyCars : Integer := 0;
      SequenceofTrucks : LookUpTableCarsTaskNr := (0,0,0,0,0);
      PortsaID : LookUpTablePorts;
      
      --Not Leader:
      TruckFrontID  : Integer := 0; -- max 5
      TruckLeaderID : Integer := 0;
      
      Distance_2_Front : Integer := 1500;
      ExClientTrID2TaskNr  : LookUpTableCarsTaskNr:= (0,0,0,0,0); -- weil max 5 Autos
          
   end PlatooningObj;
   ---
   protected SensorDataObj is
      
      procedure SaveImage (Picture : in image_array);
      function GetIamge return image_array;
      
      procedure SetTime (timeSim : in Float);
      function GetTime return Float;
      
   private
      
      Time : Float := 0.0;
      Current_Camera_Image : image_array;
      
   end SensorDataObj;
   
   ---
   protected ExCoObj is
      
      procedure IncTaskClientNr; --increment Tasknr_c
      function GetTaskClientNr return Integer;
      
      procedure IncTaskServerNr; --increment Tasknr_s
      function GetTaskServerNr return Integer;
      
      procedure ResetTaskNr; --todo
      
   private
      
      Tasknr_c : Integer := 1;
      Tasknr_s : Integer := 1;
      
   end ExCoObj;
   


end ProtectsObj;
