with Text_IO;               use Text_IO;
with Ada.Text_IO;           use Ada.Text_IO;
--with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;
with Ada.Exceptions;use Ada.Exceptions;
with Ada.Command_Line; use Ada.Command_Line;

--with test;
with follow_path; use follow_path;
with ProtectsObj; use ProtectsObj;
with backend_client; use backend_client;
with webots_server; use webots_server;
with controller_peer ; use controller_peer;

--todo kann ggf weg
with GNAT.Sockets;          use GNAT.Sockets;
with Message_Handle; use Message_Handle;


procedure Main is

   MyExCoPort : Port_Type := Port_Type'Value (Argument(1));


   -----------------------------------[ TASKS ]------------------------------
   task WebotsCommunication is
   end WebotsCommunication;
   task body WebotsCommunication is
      WebotsPort: Port_Type;
   begin
      if MyExCoPort = 9001 then --easier for debug
         WebotsPort := 9876;
      elsif MyExCoPort = 9002 then
         WebotsPort := 9877;
      elsif MyExCoPort = 9003 then
         WebotsPort := 9878;
      elsif MyExCoPort = 9004 then
         WebotsPort := 9879;
      elsif MyExCoPort = 9005 then
         WebotsPort := 9880;
      end if;
      Put_Line("**** DEBUG : Webots Port is" & Port_Type'Image(WebotsPort));
      tcp_socket(WebotsPort);
   end WebotsCommunication;

   task BackendCommunication is
   end BackendCommunication;
   task body BackendCommunication is
   begin
       delay 0.1;
      backend_client.Backend_Client;
   end BackendCommunication;

   task EXCommunication is
   end EXCommunication;
   task body EXCommunication is
   begin
      --Please uncommment just when MyExCoPort is uncommented
      ProtectsObj.PortObj.SetExCoPort(MyExCoPort);
      StartExCoServer;
      null;
   end EXCommunication;


begin
   --  Insert code here
   ------------------------------------------
   -- [ INITIAL ID ]
   if MyExCoPort = 9001 then --easier for debug
      My_ID := 1;
   elsif MyExCoPort = 9002 then
      My_ID := 2;
   elsif MyExCoPort = 9003 then
      My_ID := 3;
   elsif MyExCoPort = 9004 then
      My_ID := 4;
   elsif MyExCoPort = 9005 then
      My_ID := 5;
   end if;
   Put_Line("My ID is:" & Integer'Image(My_ID));

   ---------------------------------------------
   -- [FOR INITIAL PATH ON PINK]
   declare
      TestRoute : Route;
      Pink : color_BGR := (255,85,170);
   begin

      TestRoute(1) := Pink;
      RouteObj.SetRoute(TestRoute, 1);

   end;


   ------------------------------------------
   --Test External communictaiiion
   --Connet1  := Port_Type'Value (Get_Line);
   --Connet2  := Port_Type'Value (Get_Line);
   --delay 20.0;
   --ex_client(2, Connet1);
   --delay 1.0;
   --ex_client(3, Connet2);
   --delay 20.0;
   --My_Client(1).Write(Port_Type'Image(PortObj.GetExCoPort) & " This is a Client Trigger Test;");
   --My_Client(1).Write("SET_S:10.50000E00:1.20000E04:1:4;");
   --delay 1.0;
   --My_Client(1).Read(rECV,lenrecv);
   --delay 10.0;
   --ut_Line(rECV(1..lenrecv));

   ----------------------------------------------
   --Test for evaluate recv Message from backend
   --evaluateMessageBackend("1:100:white:pink:red;");
   --FirstRoute := RouteObj.GetRoute(lenFirstRoute);
   --Put_Line(Integer'Image(lenFirstRoute));
   --for Path_nr in 1..lenFirstRoute loop

     -- Help_bgr := FirstRoute(Path_nr);
      --Put_Line("Gew�hlte Farbe: " & Integer'Image(Help_bgr(0)) & Integer'Image(Help_bgr(1)) & Integer'Image(Help_bgr(2)));

   --end loop;


   --------------------------------------------------------
   --Test Plattoning evaluation message backend
   -- evaluateMessageBackendMain("2:1:2:9002:3:9003:4:9004:5:9005;");
   --Put_Line("not blocking");

   ------------------------------------------------------------------------------
   --[Test} Platoon eval + client task nr:
   -- 3 @Param Port, ID, Message
   -- 9001 / 1 / 2:1:2:9002:3:9003;
   -- 9002 / 2 / 2:0:1:9001:1:9001;
   -- 9003 / 3 / 2:0:1:9001:2:9002;
   --My_ID := My_ID_get_line;



   --evaluateMessageBackendMain("1:150:pink:blue:blue:white:yellow:yellow:white:pink;");
   --evaluateMessageBackendMain("1:150:pink:white:violett:violett:white:yellow:yellow:pink;");

   --evaluateMessageBackendMain("1:350:pink:blue:blue:orange:orange:white:green:green:white:pink;");

   --evaluateMessageBackendMain("1:350:pink:white:pink;");

   --delay 15.0;
--   if My_ID = 1 then
      --evaluateMessageBackendMain("2:1:2:9002;" );
--      evaluateMessageBackendMain("1:350:pink:blue:white:yellow:white:green:white:pink;");
   --elsif My_ID = 2 then
    --evaluateMessageBackendMain("2:0:1:9001:1:9001;");
   --elsif My_ID = 3 then
   -- evaluateMessageBackendMain("2:0:1:9001:2:9002;");
   --elsif My_ID = 4 then
   -- evaluateMessageBackendMain("2:0:1:9001:3:9003;");
   --else
   -- evaluateMessageBackendMain("2:0:1:9001:4:9004;");
--   end if;

   ----------[TEST FWD]------------
   --delay 10.0;
   --Test one was Foward
   --if My_ID = 3 then
      --My_Client(PlatooningObj.GetTaskNr(2)).Write("ENTRY:3:1;");
     -- null;

   --end if;


   --------- [Truck 1]--------------
   --delay 40.0;
   --if My_ID = 1 then

      --------[test EMERG]-----------
      --WriteEMERGE(True);
      --delay 10.0;
      --WriteEMERGE(False);
      -- null;

   --   WriteEXITE;

   --end if;


   ----------[TRUCK 2]---------
   --delay 5.0;
   --Test : EXITE 2nd Car
   --Put_Line("Now 2 tries to exit");
   --if My_ID = 2 then
      --controller_peer.When2Exit.ArrivedEnd;
   --   WriteEXITE;
      --null;
   --end if;

   ----------[TRUCK 3]---------------
   --delay 5.0;
   --if My_ID = 3 then
      ---------[ EXITE ]---------------
      --WriteEXITE;
        --------[test EMERG]-----------
    --  WriteEMERGE(True);
     --- delay 10.0;
    --  WriteEMERGE(False);
      -- null;

      --null;
   --end if;

   ----------[TRUCK 4]---------------
   --delay 15.0;
   --if My_ID = 4 then

      -----[EMERG]-----
      --WriteEMERGE(True);
      --delay 20.0;
      --WriteEMERGE(False);


      ---------[ EXITE ]---------------
      --WriteEXITE;

    --  null;
   --end if;


   ----------[TRUCK 2 - REENTER ]---------
   --delay 20.0;
   --Test : EXITE 2nd Car
   --Put_Line("Now 2 tries to exit");
   --if My_ID = 2 then
     -- Put_Line("**** DEBUG : My Platoon Status is " & Boolean'Image(PlatooningObj.GetPlatoonMode));
      --evaluateMessageBackendMain("2:0:1:9001:5:9005;");

      --delay 5.0;

     -- WriteEXITE;

   --end if;

    ----------[TRUCK 5]---------------
   --delay 5.0;
   --if My_ID = 5 then

      -----[EMERG]-----
      --WriteEMERGE(True);
      --delay 20.0;
      --WriteEMERGE(False);

      ---------[ EXITE ]---------------
    --  if PlatooningObj.GetPlatoonMode then
         --Put_Line("MEIN MODE IS AN UND WERDE EXITEN");
     --    WriteEXITE;
    --  end if;


    --  null;
   --end if;

   ----------[ TEST New Platoon ] -------------

   --------- [Truck 1]--------------
   --delay 40.0;
   --if My_ID = 1 then

      --------[test EMERG]-----------
      --Put_Line("");
      --evaluateMessageBackendMain("2:1:3:9003;");
     -- null;
   --end if;

   --------- [Truck 3]--------------
   --delay 15.0;
   --if My_ID = 3 then

      --------[test EMERG]-----------
     -- evaluateMessageBackendMain("2:0:1:9001:1:9001;");

      --delay 20.0;

      --WriteEXITE;

     -- null;
   --end if;



   -------------[TEST LEADER SEND 2 ALL]-------------------
   --delay 25.0;
   --declare
      --TempTasknr : Integer;
   --begin
     -- if PlatooningObj.GetLeader then
       --  for C in 1..5 loop
          --  TempTasknr := PlatooningObj.GetTaskNr(C);
            --if TempTasknr /= 0 then
              -- Put_Line("TempTasknr:"&Integer'Image(TempTasknr)&" Car ID:" & Integer'Image(C));
               --My_Client(TempTasknr).Write("SET_S:10.50000E00:1.20000E04:" & Integer'Image(My_ID) & ":" & Integer'Image(C) & ";");
           -- end if;
         --end loop;
     -- end if;
   --end;

   -------------------------------------------------------------
   --[TEST ENTRY function]
   --PlatooningObj.SetLeader(True);
   --Put_Line( evaluateMessageExServerMain("ENTRY: 2: 1;"));
   --My_ID_get_line:= Integer'Value(" 1");

   --------------------------------------------------------------
   --[TEST] RemoveID
   --PlatooningObj.AddTruck2Seq(1,3);
   --PlatooningObj.AddTruck2Seq(2,4);
   --PlatooningObj.AddTruck2Seq(3,5);
   --PlatooningObj.AddTruck2Seq(4,1);
   --PlatooningObj.AddTruck2Seq(5,2);
   --PlatooningObj.SetAmountofTrucks(5);

   --Put_Line("settet the sequence");

   --Put_Line(Integer'Image(RemoveCarSeq(2)));


   -------------------------------------------------------------------
   --[ Test Platoon Cost]
   --PlatooningObj.SetPlatoonMode(True);
   --Put_Line("DIstance2:" & Integer'Image(PlatooningObj.GetDistance));
   --controller_peer.PlatoonCost.StartCounting;
   --delay 100.0;
   --PlatooningObj.ResetValues;


   ---------------------------[ EXCEPTIONS ]----------------------------------
   exception
      when E : others =>
         Ada.Text_Io.Put_Line
           ("*************** MAIN"& Exception_Name (E) & ": " & Exception_Message (E));

end Main;
