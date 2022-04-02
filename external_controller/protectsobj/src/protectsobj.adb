with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Sockets;          use GNAT.Sockets;

package body ProtectsObj is
   
   protected body PortObj is
      procedure SetExCoPort (Port : Port_Type) is
      begin
         ExCo_Port := Port;
      end SetExCoPort;
      
      function GetExCoPort return Port_Type is
      begin
         return ExCo_Port;
      end GetExCoPort;
   end PortObj;
      

   protected body CargoObj is
      
      function GetMaxLoad return Integer is
      begin
         return MaxLoad;
      end;
      
      procedure SetAuftrag (V : in Integer) is
      begin
         Local := V;
         Put_Line ("Auftrag von" & Integer'Image (V) & " Pakete!");
      end SetAuftrag;

      function GetAuftrag return Integer is
      begin
         return Local;
      end GetAuftrag;

      procedure PickUp is --vorrausgesezt er lädt nur an einer station
      begin
         CurrentLoad := Local;
         Put_Line ("Es wurden" & Integer'Image (CurrentLoad) & " geladen!");
      end PickUp;

      procedure DropOff is
      begin
         CurrentLoad := 0;
         Local := 0;
         Put_Line ("Die Pakete wurden geliefert!");
      end DropOff;

   end CargoObj;
   
   ------------------------

   protected body SpeedObj is
      procedure SetSpeed (WishSpeedL, WishSpeedR : Float) is
      begin
         SpeedL := WishSpeedL;
         SpeedR := WishSpeedR;
  
         Put_Line ("Set Speed to: Left: " & Float'Image (SpeedL) & " Right:" & Float'Image(SpeedR));
      end SetSpeed;
      
      function GetSpeed return Float is
      begin
         if SpeedR <= SpeedL then
            return SpeedR;
         else
            return SpeedL;
         end if;
      end GetSpeed;
      
      function GetAVGSpeed return Float is
      begin
         return (SpeedR + SpeedL)/2.0;
      end GetAVGSpeed;
                                          
   end SpeedObj;
   
   --------------------------
   
   protected body RouteObj is
      
      procedure SetColorCodeDest (C1, C2, C3 : Integer) is
      begin
         ColorCode_PickUp := (C1, C2, C3);
      end SetColorCodeDest;
      
      function GetColotCodeDest return color_BGR is
      begin
         return ColorCode_PickUp;
      end GetColotCodeDest;
      
      procedure SetRoute (Given_Route: in Route; Len : in Integer) is
      begin
         Route_path := Given_Route;
         LenRoute := Len;
      end SetRoute;
      
      function GetRoute (Len: out Integer) return Route is
      begin
         Len := LenRoute;
         return Route_path;
      end GetRoute;
      
      --new for follo path TODO
      procedure SetCurrentLineNr ( Number : in Integer) is
      begin
         CurrentLineNr := Number;
      end SetCurrentLineNr;
      
      function GetCurrentLineNr return Integer is
      begin
         return CurrentLineNr;
      end GetCurrentLineNr;
      
      --position
      
      procedure SetCurrentPos (St : in String; Fl : Float) is
      begin
         
         Astring := St;
         AFLoat := Fl;
         
      end SetCurrentPos;
      
      function GetCurrentPos (Fl : out Float) return String is
      begin
         
         Fl:= AFLoat;
         return Astring;
         
      end GetCurrentPos;     
      
   end RouteObj;
   
   ---------------------
   
   protected body PlatooningObj is
      
      procedure SetPlatoonMode(State : in Boolean) is
      begin
         PlatoonMode := State;
      end SetPlatoonMode;
      
      function GetPlatoonMode return Boolean is
      begin
         return PlatoonMode;
      end GetPlatoonMode;
      
      procedure IncFailures is 
      begin
         Failures_Count := Failures_Count +1;
      end IncFailures;
      
      function GetFailures return Integer is
      begin
         return Failures_Count;
      end GetFailures;
      
      procedure SetLeader (State : in Boolean) is
      begin
         Leader := State;
      end SetLeader;
      
      function GetLeader return Boolean is
      begin
         return Leader;
      end GetLeader;
      
      procedure SetSOS (State : in Boolean) is
      begin
         SOS := State;
      end SetSOS;
      
      function GetSOS return Boolean is
      begin
         return SOS;
      end GetSOS;
      
      procedure SetNeighbour (Front, Leader : in Integer) is
      begin
         TruckFrontID := Front;
         TruckLeaderID := Leader;
      end SetNeighbour;
      
      function GetNeighbour (WantLeader : in Boolean) return Integer is 
      begin
         if WantLeader then
            return TruckLeaderID;
         else
            return TruckFrontID;
         end if;
      end GetNeighbour;
      
      procedure SetAmountofTrucks (Amount : in Integer) is
      begin
         HowManyCars := Amount;
      end SetAmountofTrucks;
      
      function GetAmountofTrucks return Integer is
      begin
         return HowManyCars;
      end GetAmountofTrucks;
     
      procedure AddTruck2Seq (Index, ID : in Integer) is
      begin
         SequenceofTrucks(Index) := ID;
      end AddTruck2Seq;
     
      function GetIDoutofSeq (Index : in Integer) return Integer is
      begin
         return SequenceofTrucks(Index);
      end GetIDoutofSeq;
        
      procedure SetLookUpPorts(ID: in Integer ; PortNumber : Port_Type) is
      begin
         PortsaID(ID) := PortNumber;
      end SetLookUpPorts;
      
      function GetPortofID (OfTruckID : in Integer) return Port_Type is
      begin
         return PortsaID(OfTruckID);
      end GetPortofID;
      
      procedure SetDistance is
         
         Dist : Integer := 1_500; -- minimum distance 1m
         t_n  : Float   := 1.0; -- reaction defaulut time 1 s
         Velo : Float := SpeedObj.GetAVGSpeed;
      
      begin
         
         Distance_2_Front := Dist + Integer (t_n * Velo * 10.0) + Failures_Count*20;       
      end SetDistance;
      
      function GetDistance return Integer is
      begin
         return Distance_2_Front;
      end GetDistance;
      
      procedure SetLookUpTable(IndexID, TaskNrCLient: in Integer) is 
      begin
         ExClientTrID2TaskNr(IndexID) := TaskNrCLient;
      end SetLookUpTable;
      
      function GetTaskNr (OfTruckID : in Integer) return Integer is
      begin
         return ExClientTrID2TaskNr(OfTruckID);
      end GetTaskNr;
      
      procedure ResetValues is
      begin
         PlatoonMode := False;
         Failures_Count := 0;
         Leader := False;
         SOS := False;
         HowManyCars := 0;
         SequenceofTrucks := (0,0,0,0,0);
         PortsaID := (0,0,0,0,0);
         TruckFrontID  := 0; -- max 5
         TruckLeaderID := 0;
         Distance_2_Front   := 500;
         ExClientTrID2TaskNr  := (0,0,0,0,0);
      end ResetValues;
      
   end PlatooningObj;
   
   ----------------------
   
   protected body SensorDataObj is
      
      procedure SaveImage (Picture : in image_array) is
      begin
         Current_Camera_Image:= Picture;
      end SaveImage;
      
      function GetIamge return image_array is
      begin
         return Current_Camera_Image;
      end GetIamge;
      
      procedure SetTime (timeSim : in Float) is
      begin
         Time := timeSim;         
      end SetTime;
      
      function GetTime return Float is
      begin
         return Time;
      end GetTime;
      
   end SensorDataObj;
   
   ----------------------
   
   protected body ExCoObj is
      
      procedure IncTaskClientNr is --increment Tasknr_c
      begin
         Tasknr_c := Tasknr_c + 1;
      end IncTaskClientNr;
      
      function GetTaskClientNr return Integer is
      begin   
          return Tasknr_c;
      end GetTaskClientNr;
      
      procedure IncTaskServerNr is --increment Tasknr_s
      begin
         Tasknr_s := Tasknr_s + 1;
      end IncTaskServerNr;
      
      function GetTaskServerNr return Integer is
      begin
         return Tasknr_s;
      end GetTaskServerNr;
      
      procedure ResetTaskNr is
      begin
         Tasknr_s := 1;
         Tasknr_c := 1;
      end ResetTaskNr;
      
   end ExCoObj;
   
   
     
end ProtectsObj;
