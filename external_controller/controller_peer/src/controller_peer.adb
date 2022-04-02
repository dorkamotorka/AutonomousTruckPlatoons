with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;
with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions;use Ada.Exceptions;

with ProtectsObj; use ProtectsObj;
--with Message_Handle; use Message_Handle;

package body controller_peer is
   
   task body Server_handle is
         
      Send_Msg : String:= " ";
      Receive  : Character;
      Recv_Msg : String (1 .. 2_048);
      Msg_Len  : Integer;
         
      My_channel : Stream_Access;
      my_socket : Socket_Type;
      my_Address : Sock_Addr_Type;
                  
   begin
      
      while True loop
   
         accept Start_Server (Socket : Socket_Type; Address : Sock_Addr_Type) do
         
            my_socket := Socket;
            My_channel := Stream(my_socket);
            my_Address := Address;
                  
         end Start_Server;
         
         while True loop
  
            Msg_Len := 0;
            --Put_Line ("Something to Read!");
               
            Character'Read (My_channel, Receive); -- ein char gelesen

            while (Receive /= ';') loop 

               Msg_Len            := Msg_Len + 1;
               Recv_Msg (Msg_Len) := Receive;
               Character'Read (My_channel, Receive);  

            end loop;
         
            --f�r das extra ;
            Msg_Len            := Msg_Len + 1;
            Recv_Msg (Msg_Len) := Receive;
         
            if Msg_Len > 0 then
            
               Put_Line( "++ ExCo Server Received Message:" & Recv_Msg (1 .. Msg_Len));
               Put_Line ("**** DEBUG : L�nge der Nachricht : " & Integer'Image(Msg_Len));
            
            end if;
         
            String'Write (My_channel, evaluateMessageExServerMain(Recv_Msg(1..Msg_Len)));
         
            if Recv_Msg(1..5) = "EXITE" and Integer'Value(Recv_Msg(Msg_Len-1 .. Msg_Len-1)) = My_ID then
               exit;
            end if;
      
         end loop;
     
         Free (My_channel);
         Close_Socket (my_socket);
         Put_Line ("++ ExCo Sever closed");
      
      end loop;
      
   exception
      when E : others =>
         Ada.Text_Io.Put_Line
           ("++ ExCoServer"& Exception_Name (E) & ": " & Exception_Message (E));
         
   end Server_handle ;
   ----------------------------------
   procedure StartExCoServer is

      Address  : Sock_Addr_Type; -- stores the adress
      
      Server   : Socket_Type; -- my fd
      Socket   : Socket_Type; -- fd of client
      
      --CurrentTasknr : Integer;
      
   begin
      
      GNAT.Sockets.Initialize;

      Address.Addr := Inet_Addr ("127.0.0.1");
      Address.Port := PortObj.GetExCoPort; 
      
      Create_Socket (Server, Family_Inet, Socket_Stream);
      Put_Line ("Create Server for other Controllers!");

      -- Allow reuse of local addresses.
      Set_Socket_Option (Server, Socket_Level, (Reuse_Address, True));
      
      ----- Server functions -----
      Bind_Socket (Server, Address);
              
      while True loop --ExCoObj.GetTaskServerNr <= MAX_COM loop 
         
         -- Waiting for connection
         Listen_Socket (Server);
         Put_Line ("Listen_Socket Server-Ex");
         -- Accept connection
         Accept_Socket (Server, Socket, Address);
         Put_Line ("++ ExCo Server: Accept connection from Address: " & Image (Address));
         ---------------------------- 
         
         My_Server(ExCoObj.GetTaskServerNr).Start_Server(Socket, Address);
         ExCoObj.IncTaskServerNr;
         
      end loop;
      
      -- when platoon finsh close TODO
      
 
   end StartExCoServer;
   
   ---------------------------------[ CLIENT ]-------------------------------------   

   task body Client_Type is
      
      My_Channel : Stream_Access;
      My_Client_Number : Integer; -- welche stelle des Arrays    
      My_Socket : Socket_Type;
      
      --------------------------- [ READING ] ----------------------------------
      task ExcoReadClient is
         entry startreadclient;
      end ExcoReadClient;
      
      task body ExcoReadClient is
      
         Receive  : Character;
         Recv_Msg : String (1 .. 2_048);
         Msg_Len  : Integer;
         
      begin
         while True loop --tostart from beginning
            accept startreadclient;
            loop
               Character'Read(My_Channel, Receive);
               Msg_Len := 0;
               while (Receive /= ';') loop 

                  Msg_Len            := Msg_Len + 1;
                  Recv_Msg (Msg_Len) := Receive;
                  Character'Read (My_channel, Receive);  
               
               end loop;
            
               evaluateMessageExClient(Recv_Msg(1..Msg_Len) & ";", My_Client_Number); 
            
               if Recv_Msg(1..5) = "EXITE" then -- TODO and me!
                  Free (My_Channel);
                  Close_Socket (My_Socket);
                  Put_Line ("++ ExCo Client Closed Channel");
                  exit;
                  
               end if;

            end loop;
         end loop;
         
      exception
         when E : others =>
            Put_Line("*******ExCoClient"& Exception_Name (E) & ": " & Exception_Message (E)); 
            RestartCom(My_Client_Number);

      end ExcoReadClient;
      --------------------------------------------------------------------------
   
   begin
      -- Trigger SEtSTream to start the client
      loop
         select
           
            accept Set_Stream (S : in Socket_Type; Tasknr : Integer) do
               
               My_Socket := S;
               My_Channel := Stream(My_Socket);
               My_Client_Number := Tasknr; --saving an welcher stelle des Arrays ich bin
               ExcoReadClient.startreadclient; --trigger to read
         
            end Set_Stream;
 
         or

            accept Write (Message : in String) do
               
               Put_Line( "++ ExCo Client" & Integer'Image(My_Client_Number) & "Writing: " & Message);
               String'Write ( My_Channel, Message );
               
            end Write;

         end select;
      end loop;
      
   end Client_Type;    
   
   -----------------------------------------------------------------------------
   procedure ex_client (TruckID_2Port: in Integer; Port : in Port_Type) is
      
      Address  : Sock_Addr_Type;
      Socket   : Socket_Type;
      
      currentTask : Integer;
      
   begin
      
      currentTask := ExCoObj.GetTaskClientNr;
      
      Put_Line("Started Client-Ex" & Integer'Image(currentTask));
      
      Address.Addr := Inet_Addr ("127.0.0.1");
      Address.Port := Port_Type(Port); 
      Create_Socket (Socket, Family_Inet, Socket_Stream);
      Put_Line ("Client-Ex: Create Socket");

      -- Allow reuse of local addresses.
      Set_Socket_Option (Socket, Socket_Level, (Reuse_Address, True));
      Connect_Socket (Socket, Address);
      
      Put_Line ("++ ExCo CLient"&Integer'Image(currentTask)&": Connect to Address: " & Image (Address));
            
      My_Client(currentTask).Set_Stream(Socket, currentTask);
      ExCoObj.IncTaskClientNr;
      
      --save truckid2port lookup table
      PlatooningObj.SetLookUpTable(TruckID_2Port, currentTask);
   
   end ex_client;
   
   -------------------------------[ MESSAGE ]-------------------------------------
   function evaluateMessageExServerMain (Input_string : in String) return String is
      
      Len_string     : Integer := Input_string'Length;
      Grenzen_string : array (1 .. 20) of Integer; --20 values max
      lauf_var : Integer          := 1; --f�r : Suche & Data Image
      
      From : Integer;
      Dest : Integer;
      Command : String(1..5); --Stores the command of the request SIZE
      
      Wishspeed : Float;
      WishDist  : Integer;
      
      reply    : Unbounded_String := Null_Unbounded_String;
      
   begin
      -- Determine the barriers
      for I in 1 .. Len_string loop 
         exit when Len_string = 0;
         if Input_string (I) = ':' or Input_string (I) = ';' then
            Grenzen_string (lauf_var) := I;
            lauf_var                  := lauf_var + 1;
         end if;
      end loop;
      
      From := Integer'Value(Input_string(Grenzen_string(lauf_var-3)+1 .. Grenzen_string(lauf_var-2)-1));
      Dest := Integer'Value(Input_string(Grenzen_string(lauf_var-2)+1 .. Grenzen_string(lauf_var-1)-1));
      
      --------------------------[ FORWARDING ]----------------------------------
      
      if Dest /= My_ID  then -- Am i the desitation if not Forward to Car infront
         
         Put_Line("**** DEBUG : NOT ME SO FOWARDING");
         
         if PlatooningObj.GetLeader then
            null;
         else
            
            if Dest = PlatooningObj.GetNeighbour(True) then -- Is Dest leader?
               My_Client(PlatooningObj.GetTaskNr(PlatooningObj.GetNeighbour(True))).Write(Input_string);
            else
               My_Client(PlatooningObj.GetTaskNr(PlatooningObj.GetNeighbour(False))).Write(Input_string);
            end if;
            
         end if;
         
         return "FORWARDING;";
         
      end if;
      
      --------------------------------------------------------------------------
      
      Command := Input_string(Input_string'First .. Grenzen_string(1)-1);
      
      if Command = "ENTRY" then
         -- ENTRY:FROM:TO;
         CommandENTRY (From);
 
      end if;
      
      if Command = "SET_S" then
         --SET_Speed:SpeedVAl:Distance:From:To; 
  
         PlatooningObj.SetSOS(False); -- of there was a emegency break
         
         Wishspeed := Float'Value(Input_string(Grenzen_string(1)+1..Grenzen_string(2)-1));
         WishDist  := Integer'Value(Input_string(Grenzen_string(2)+1..Grenzen_string(3)-1));
         
         --TODO: Call Lu'S Function here
         
         SpeedObj.SetSpeed(Wishspeed,Wishspeed); -- probably not nessecary cause its calles in Lu
           
      end if;
      
      if Command = "EMERG" then
         --EMERG:STATUS:From:To;
         CommandEMERG(Integer'Value(Input_string(Grenzen_string(1)+1 .. Grenzen_string(2)-1)));
         
      elsif Command = "EXITE" then
         --EXITE:From:To;
         CommandEXITE(From);
            
      elsif Command = "NEWTF" then
         -- "NEWTF:NEWID:NEWPORT:FROM:TO;"
         
         CommandNEWTF(Integer'Value(Input_string(Grenzen_string(1)+1 .. Grenzen_string(2)-1)),
                     Port_Type'Value(Input_string(Grenzen_string(2)+1 .. Grenzen_string(3)-1)));
         
      elsif Command = "FAILE" then
         -- FAILE:FROM:TO;
         CommandFAILE;
         
      elsif Command = "NEWLE" then
         
         CommandNEWLE(Input_string);
         
      end if;
      
      reply := To_Unbounded_String(Command & " From ID:" & Integer'Image(My_ID)& 
                                     ": Done --> " & Float'Image(SpeedObj.GetAVGSpeed) & ";");
      
      Put_Line("++ ExCo Server Writes :" & To_String(reply)); 
      
      return To_String(reply);
         
   end evaluateMessageExServerMain;
   
   ----------------------------[ HELP COMMAND FUCNTIONS ]-----------------------
   
   function RemoveCarSeq (ID : in Integer; Index : out Integer) return Integer is --return Id of Car behind
 
      laufVar : Integer := 0;                                                       
      FoundIndex : Integer := 0;
      AnzahlderTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      IDbehind : Integer;
      
   begin
      -- search Index of ID
      for I in 1 .. AnzahlderTrucks loop
         if PlatooningObj.GetIDoutofSeq(I) = ID then
            FoundIndex := I;
            exit;
         end if;
      end loop;
      
      laufVar := FoundIndex;
      --Put_Line("**** DEBUG :" & Integer'Image(FoundIndex));
      
      while laufVar < AnzahlderTrucks loop --nachr�cken
         --SequenceofTrucks(laufVar) := SequenceofTrucks(laufVar + 1 );
         IDbehind := PlatooningObj.GetIDoutofSeq(laufVar +1);
         PlatooningObj.AddTruck2Seq(laufVar, IDbehind );
         laufVar := laufVar + 1;
      end loop;
      
      PlatooningObj.AddTruck2Seq(AnzahlderTrucks, 0);-- letzte stelle jz leer 
                                    
      PlatooningObj.SetAmountofTrucks(AnzahlderTrucks -1); --decrease size of trucks
      
      Index := FoundIndex;
      return PlatooningObj.GetIDoutofSeq(FoundIndex);
         
   end RemoveCarSeq;	
   
   procedure newTruckwantsEntry (From_id : in  Integer) is
      
      Port2Connect : Port_Type;
      Amount_Of_Trucks : Integer := PlatooningObj.GetAmountofTrucks;
      NewTaskNr : Integer;
      
   begin
      Put_Line("**** DEBUG : Truck is unregistered but will be Added");
      if From_id = 1 then --get the Port of the new Truck
         Port2Connect := 9001;
      elsif From_id = 2 then
         Port2Connect := 9002;
      elsif From_id = 3 then
         Port2Connect := 9003;
      elsif From_id = 4 then
         Port2Connect := 9004;
      elsif From_id = 5 then
         Port2Connect := 9005;
      else
         Put_Line("**** DEBUG : I don't know what the Port is");
      end if;
      
      ex_client(From_id, Port2Connect);
      PlatooningObj.SetAmountofTrucks(Amount_Of_Trucks +1); -- increase Size 
      PlatooningObj.AddTruck2Seq(Amount_Of_Trucks + 1, From_id); --saves the ID at the index of the fleet
      PlatooningObj.SetLookUpPorts(From_id, Port2Connect); --saves the Port at the index of ID
      
      --SET_S
      NewTaskNr := PlatooningObj.GetTaskNr(From_id); 
      My_Client(NewTaskNr).Write("SET_S:"& Float'Image(SpeedObj.GetAVGSpeed) & ":" 
                                 & Integer'Image(PlatooningObj.GetDistance) & ":"
                                 & Integer'Image(My_ID) & ":" & Integer'Image(From_id) & ";");
      --NEWTF --> vllt? --n� bavkend sagt schon
      
   end newTruckwantsEntry;
   
   procedure CommandENTRY (From_ID : in Integer) is
      
      RegistredID : Boolean := False; -- Checks wether its a new Joining one
      AnzahlderTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      
   begin
      
      if PlatooningObj.GetLeader then
         
         Put_Line("**** DEBUG : In CommandENTRY AnzahlderTrucks is:" & Integer'Image(AnzahlderTrucks));
         
         for T in 2..AnzahlderTrucks loop 
            
            if PlatooningObj.GetIDoutofSeq(T) = From_ID then
                  
               My_Client(PlatooningObj.GetTaskNr(From_ID)).Write("SET_S:"& Float'Image(SpeedObj.GetAVGSpeed) & ":" 
                                                                 & Integer'Image(PlatooningObj.GetDistance) & ":"
                                                                 & Integer'Image(My_ID) & ":" & Integer'Image(From_ID) & ";");
               RegistredID := True;
               Put_Line("**** DEbug SET_S:"& Float'Image(SpeedObj.GetAVGSpeed) & ":" 
                        & Integer'Image(PlatooningObj.GetDistance) & ":"
                        & Integer'Image(My_ID) & ":" & Integer'Image(From_ID) & ";"); --DEbug
                                                                                      
            end if;
               
         end loop;
            
         if RegistredID = False then
           
            newTruckwantsEntry(From_ID);
              
         end if;
            
      end if;
      
   end CommandENTRY;
   
   procedure CommandEMERG (Status : in Integer) is
      
      TempID : Integer ;
      TempTasknr : Integer;
      AnzahlDTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      
   begin
      --EMERG:Status:From:To;
      Put_Line("**** DEBUG : entered CommandEMERG");
      Put_Line("**** DEBUG : SOS Mode is:" & Boolean'Image(PlatooningObj.GetSOS));
      
      if Status = 1 then
         SpeedObj.SetSpeed(0.0,0.0);
      else
         SpeedObj.SetSpeed(15.0,15.0);
      end if;
      
         
      --IF I AM the leader weiterleiten!
      if PlatooningObj.GetLeader then
         for C in 2.. AnzahlDTrucks loop -- c ist die Stelle in der Sequence, ab 2 weil ich nicht
            TempID := PlatooningObj.GetIDoutofSeq(C);
            TempTasknr := PlatooningObj.GetTaskNr(TempID);
            if Status = 1 then
               My_Client(TempTasknr).Write("EMERG:1:" & Integer'Image(My_ID) & ":" & Integer'Image(TempID) & ";");
            else
               My_Client(TempTaskNr).Write("SET_S:" & Float'Image(15.0) & ":" --todo might be another speed like SpeedObj.GetAVGSpeed
                                           & Integer'Image(PlatooningObj.GetDistance) & ":"
                                           & Integer'Image(My_ID) & ":"
                                           & Integer'Image(TempID) & ";");
            end if;
            
         end loop;
      end if;
      
   end CommandEMERG;
   
   procedure CommandEXITE (From : in Integer) is
      
      NextIDifExit : Integer;
      
      TaskNrofNextID : Integer;
      FoundIndex : Integer := 0;
      IDofNextTruckFront : Integer;
      PortofNextTruckFront : Port_Type;
      AnzahlAutos : Integer := PlatooningObj.GetAmountofTrucks;
      
   begin
      
      if PlatooningObj.GetLeader and From /= PlatooningObj.GetNeighbour(True) then -- wenn sich der alte leader trennen will
         -- Close Communcation with this Car from leaders side
         My_Client(PlatooningObj.GetTaskNr(From)).Write("EXITE:" & Integer'Image(My_ID) & ":"
                                                        & Integer'Image(From) & ";");  
          
         NextIDifExit := RemoveCarSeq(From, FoundIndex); --gets the Truck behind teh leaving one
         Put_Line("**** DEBUG: in Exite- NextIDifExit:" & Integer'Image(NextIDifExit));
               
         if (AnzahlAutos > 2) then  
            if (NextIDifExit /= 0) then -- a there is a Car behind the one leaving
               -- Tell the car behind leaving truck ot has a new car infront
                                                                                 
               IDofNextTruckFront := PlatooningObj.GetIDoutofSeq(FoundIndex-1); --gets id pf the Car infront pf leaving truck
               PortofNextTruckFront := PlatooningObj.GetPortofID(IDofNextTruckFront); --gets port off truck infront leaving
               TaskNrofNextID := PlatooningObj.GetTaskNr(NextIDifExit); --gets the ClientTasknr of Truck behind leaving TRuck
                  
               Put_Line("**** DEBUG: in Exite- TaskNrOFNextID:" & Integer'Image(TaskNrofNextID));
               My_Client(TaskNrofNextID).Write("NEWTF:" & Integer'Image(IDofNextTruckFront) & ":"
                                               & Port_Type'Image(PortofNextTruckFront) & ":"
                                               & Integer'Image(My_ID) & ":"
                                               & Integer'Image(NextIDifExit) & ";");
            end if;
         else
            -- Two cars left --> second Truck wants to exit --> end platoon
            Put_Line("**** DEBUG: WENIGER als 3 Autos"); 
            ExCoObj.ResetTaskNr;
            PlatooningObj.ResetValues;
         end if;
      
      else
         null;
         --if im not the leader i will close the this Server at @Server_handle
         --TODO: LEader leaves
      end if;
      
   end CommandEXITE;
   
   procedure CommandNEWTF (NewTruckID : in Integer ; NewPort : Port_Type) is
      -- "NEWTF:NEWID:NEWPORT:FROM:TO;"
      --1. Close connection the car front
      --2. check if new front car is Leader
      --3. if leader just equal front = leader at protecs
      --4. if not leader new connection and store it 
      
      
      MyTruckInfrontID : Integer := PlatooningObj.GetNeighbour(False);
      --NewTruckID: Integer := Integer'Value(Input_string(Grenzen_string(1)+1 .. Grenzen_string(2)-1));
      --NewPort: Port_Type := Port_Type'Value(Input_string(Grenzen_string(2)+1 .. Grenzen_string(3)-1));
      LeaderID : Integer := PlatooningObj.GetNeighbour(True);
      
   begin
      --1:
      Put_Line("**** DEBUG : NEWTF : After declare");
      My_Client(PlatooningObj.GetTaskNr(MyTruckInfrontID)).Write("EXITE:"
                                                                 & Integer'Image(My_ID) & ":"
                                                                 & Integer'Image(MyTruckInfrontID) &";");
      --2:
      if LeaderID = NewTruckID then
         PlatooningObj.SetNeighbour(NewTruckID,NewTruckID); --sets the CArFRont same id as Leader
      else
         --4:
         ex_client(NewTruckID, NewPort);
         PlatooningObj.SetNeighbour(NewTruckID, LeaderID);
         --My_Client(PlatooningObj.GetTaskNr(NewTruckID)).Write("ENTRY:"&Integer'Image(My_ID) & ":"&Integer'Image(NewTruckID) & ";");
      end if;
      
   end CommandNEWTF;
   
   procedure CommandFAILE is
      
      AnzahlTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      TempID : Integer := 0;
      TempTaskNr : Integer := 0;
      
   begin
      Put_Line("**** DEBUG : Now Start Command FAILE");
      if PlatooningObj.GetLeader then
         
         PlatooningObj.IncFailures;
         PlatooningObj.SetDistance; -- sets new Disstance
         
         for I in 2..AnzahlTrucks loop
            
            TempID:= PlatooningObj.GetIDoutofSeq(I);
            TempTaskNr := PlatooningObj.GetTaskNr(TempID);
            
            My_Client(TempTaskNr).Write("SET_S:"& Float'Image(SpeedObj.GetAVGSpeed) & ":" 
                                        & Integer'Image(PlatooningObj.GetDistance) & ":"
                                        & Integer'Image(My_ID) & ":" & Integer'Image(TempID) & ";");
            
         end loop;
         
      else
         null; --actually noone excepts leader gets this message
      end if;
       
   end CommandFAILE;
   
   procedure CommandNEWLE (Input_string : in String) is
      --NEWLE : BoolifIam (1) : HowManyTrucks : <(ID : Port) Sequence> : FROM : TO ; 
      --NEWLE : BoolifIam (0) : IDLeader : PortLeader : FROM : TO ;
      
      Len_string     : Integer := Input_string'Length;
      Grenzen_string : array (1 .. 20) of Integer; --20 values max
      lauf_var : Integer          := 1; --f�r : Suche & Data Image
      
      BoolIfIamNewLeader : Integer := 0;
      
      --1
      HowManyTrucks : Integer := 0;
      TempID : Integer := 0;
      TempPort : Port_Type ;
      Shifter : Integer := 1;
      
      --0
      NewLeaderID : Integer := 0;
      NewLeaderPort : Port_Type ;
      IDFront : Integer := 0 ;
      
      OldLeaderID : Integer := 0;
      OLdLeaderTaskNr : Integer := 0;
      
   begin
      
      for I in 1 .. Len_string loop 
         exit when Len_string = 0;
         if Input_string (I) = ':' or Input_string (I) = ';' then
            Grenzen_string (lauf_var) := I;
            lauf_var                  := lauf_var + 1;
         end if;
      end loop;
      
      BoolIfIamNewLeader := Integer'Value(Input_string(Grenzen_string(1)+1 .. Grenzen_string(2)-1));
      
      if BoolIfIamNewLeader = 1 then
         
         HowManyTrucks := Integer'Value(Input_string(Grenzen_string(2)+1 .. Grenzen_string(3)-1));
         Put_Line("**** DEBUG : CommandNEWLE HowManyTrucks:" & Integer'Image(HowManyTrucks));
         
         if HowManyTrucks = 0 then
            WriteEXITE;
            
         else
            
            PlatooningObj.SetLeader(True);
            PlatooningObj.SetDistance;
            PlatooningObj.SetAmountofTrucks(HowManyTrucks+1);
            PlatooningObj.AddTruck2Seq(1, My_ID);
            
            for I in 1..HowManyTrucks loop
               TempID := Integer'Value(Input_string(Grenzen_string(2+Shifter)+1 .. Grenzen_string(3+Shifter)-1));
               Put_Line("**** DEBUG : In CommandNEWLE NewL ReadID:" & Input_string(Grenzen_string(2+Shifter)+1 .. Grenzen_string(3+Shifter)-1));
               TempPort := Port_Type'Value(Input_string(Grenzen_string(2 + 1 + Shifter )+1 .. Grenzen_string(3 + 1 + Shifter)-1)); 
               Put_Line("**** DEBUG : In CommandNEWLE NewL PortID:" & Input_string(Grenzen_string(2 + 1 + Shifter )+1 .. Grenzen_string(3 + 1 + Shifter)-1));
               
               Shifter := Shifter+2;
               
               PlatooningObj.AddTruck2Seq(I+1, TempID);
               ex_client(TempID, TempPort);
               PlatooningObj.SetLookUpPorts(TempID, TempPort);
               
            end loop;
            
            --exite old leader
            OldLeaderID := PlatooningObj.GetNeighbour(True);
            OLdLeaderTaskNr := PlatooningObj.GetTaskNr(OldLeaderID);
            My_Client(OLdLeaderTaskNr).Write("EXITE:" & Integer'Image(My_ID) & ":"
                                          & Integer'Image(OldLeaderID) & ";");
            
         end if;
         
      else
         -- boolifIamNewLeader = 0
         NewLeaderID := Integer'Value(Input_string(Grenzen_string(2)+1 .. Grenzen_string(3)-1));
         NewLeaderPort := Port_Type'Value(Input_string(Grenzen_string(3)+1 .. Grenzen_string(4)-1));
         IDFront := PlatooningObj.GetNeighbour(False);
         if  IDFront= NewLeaderID then --new 2nd Car
     
            --exite old leader
            OldLeaderID := PlatooningObj.GetNeighbour(True);
            OLdLeaderTaskNr := PlatooningObj.GetTaskNr(OldLeaderID);
            My_Client(OLdLeaderTaskNr).Write("EXITE:" & Integer'Image(My_ID) & ":"
                                             & Integer'Image(OldLeaderID) & ";");
            
            PlatooningObj.SetNeighbour(IDFront, IDFront);
            
         else
            
            ex_client(NewLeaderID, NewLeaderPort);
            
            --exite old leader
            OldLeaderID := PlatooningObj.GetNeighbour(True);
            OLdLeaderTaskNr := PlatooningObj.GetTaskNr(OldLeaderID);
            My_Client(OLdLeaderTaskNr).Write("EXITE:" & Integer'Image(My_ID) & ":"
                                             & Integer'Image(OldLeaderID) & ";");
            
            PlatooningObj.SetNeighbour(IDFront, NewLeaderID);
            --My_Client(PlatooningObj.GetTaskNr(NewLeaderID)).Write("ENTRY:" & Integer'Image(My_ID) & ":" -- unneccary?
              --                                                    & Integer'Image(NewLeaderID) & ";");
            
         end if;
          
      end if;
      
      
   end CommandNEWLE;
   
   procedure WriteEXITE is 
      
      HowManyTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      TempID : Integer := 0;
      TempTaskNr : Integer := 0;
      TempPort : Port_Type ;
      
      --Leader
      ID2ndTruck : Integer := 0;
      Port2ndTruck : Port_Type;
      TaskNr2nd : Integer := 0;
      NewLeString : Unbounded_String := To_Unbounded_String("NEWLE:");
      
      --NotLeader
      IDLeader : Integer := 0;
      IDFront : Integer := 0;
      
   begin
      
      if PlatooningObj.GetLeader then
         -- send SencondTruck in th seq NEWLEADER
         -- TODO NEW LEADER
         PlatooningObj.SetLeader(False);
         
         ID2ndTruck := PlatooningObj.GetIDoutofSeq(2);
         Port2ndTruck := PlatooningObj.GetPortofID(ID2ndTruck);
         TaskNr2nd := PlatooningObj.GetTaskNr(ID2ndTruck);
         
         --NEWLE : BoolifIam (1) : HowManyTrucks : <(ID : Port) Sequence> : FROM : TO ; 
         --NEWLE : BoolifIam (0) : IDLeader : PortLeader : FROM : TO ;
         if HowManyTrucks = 2 then 
            -- tell the Truck behind me to exit
            
            TempID := PlatooningObj.GetIDoutofSeq(2);
            TempTaskNr := PlatooningObj.GetTaskNr(TempID);
            
            My_Client(TempTaskNr).Write("NEWLE:1:0:" & Integer'Image(My_ID) & ":" 
                                        & Integer'Image(TempID) & ";");
            
         else
            -- decide new Leader
            NewLeString := NewLeString & To_Unbounded_String("1:" & Integer'Image(HowManyTrucks-2) & ":"); -- -2 bc myself will be out and the 2nd car out 
            
            for T in 3..HowManyTrucks loop
            
               TempID := PlatooningObj.GetIDoutofSeq(T);
               TempPort := PlatooningObj.GetPortofID(TempID);
               
               NewLeString := NewLeString & To_Unbounded_String(Integer'Image(TempID) & ":"
                                                               & Port_Type'Image(TempPort) & ":");
            end loop;
            
            NewLeString := NewLeString & To_Unbounded_String(Integer'Image(My_ID)) 
              & To_Unbounded_String(":") &  To_Unbounded_String(Integer'Image(ID2ndTruck)) & 
              To_Unbounded_String(";");
            
            My_Client(TaskNr2nd).Write(To_String(NewLeString)); 
            
            --------for TRucks behind 2nd
            NewLeString := Null_Unbounded_String;
            NewLeString := To_Unbounded_String("NEWLE:0:" & Integer'Image(ID2ndTruck) & ":" 
                                               & Port_Type'Image(Port2ndTruck) & ":" );
            
            for T in 3..HowManyTrucks loop
            
               TempID := PlatooningObj.GetIDoutofSeq(T);
               TempTaskNr := PlatooningObj.GetTaskNr(TempID);
               --TempPort := PlatooningObj.GetPortofID(TempID);
               
               My_Client(TempTaskNr).Write(To_String(NewLeString) 
                                           & Integer'Image(My_ID) & ":"
                                           & Integer'Image(TempID) & ";");
                                                               
            end loop;
                                               
            
         end if;
         
         --NOW EXIT
         --delay 0.5; --let the new leader Time tp process
         
         for T in 2..HowManyTrucks loop
            
            TempID := PlatooningObj.GetIDoutofSeq(T);
            My_Client(PlatooningObj.GetTaskNr(TempID)).Write("EXITE:" & Integer'Image(My_ID) & ":" &
                                                              Integer'Image(TempID)& ";");
            
         end loop;
         
      else
         
         IDLeader := PlatooningObj.GetNeighbour(True);
         IDFront := PlatooningObj.GetNeighbour(False);
         
         My_Client(PlatooningObj.GetTaskNr(IDLeader)).Write("EXITE:"& Integer'Image(My_ID) & ":" &
                                                              Integer'Image(IDLeader)& ";");
         if IDFront /= IDLeader then
            
            My_Client(PlatooningObj.GetTaskNr(IDFront)).Write("EXITE:"& Integer'Image(My_ID) & ":" &
                                                              Integer'Image(IDFront)& ";");
         end if;
         
      end if;
      
      ExCoObj.ResetTaskNr;
      PlatooningObj.ResetValues;
      
      Put_Line("**** DEBUG : Platoon Mode is now : " & Boolean'Image(PlatooningObj.GetPlatoonMode));
      
   end WriteEXITE;
   
   procedure WriteEMERGE (Status : in Boolean) is
      --STATUS: true  --> there is a problem
      --STATUS: false --> problem git resolved
      
      --Leader
      TempID : Integer := 0;
      TempTaskNr : Integer := 0;
      AnzahlTrucks : Integer := PlatooningObj.GetAmountofTrucks;
      
      --notLeader
      IDLeader : Integer := 0;
      TaskNrLeader : Integer := 0;
      
   begin
      -- there is a problem
      PlatooningObj.SetSOS(Status);
      --TODO WEg weil schon in chengs function

      --if Status then
        -- SpeedObj.SetSpeed(0.0,0.0);
      --else
        -- SpeedObj.SetSpeed(15.0,15.0);
      --end if;

      
      
      if PlatooningObj.GetLeader then
         for T in 2..AnzahlTrucks loop
            TempID := PlatooningObj.GetIDoutofSeq(T);
            TempTaskNr := PlatooningObj.GetTaskNr(TempID);
            
            if Status then
               My_Client(TempTaskNr).Write("EMERG:1:" & Integer'Image(My_ID) & ":"
                                          & Integer'Image(TempID) & ";");
            else               

               My_Client(TempTaskNr).Write("SET_S:" & Float'Image(15.0) & ":" --TODO SpeedObj.GetAVGSpeed
                                           & Integer'Image(PlatooningObj.GetDistance) & ":"
                                           & Integer'Image(My_ID) & ":"
                                           & Integer'Image(TempID) & ";");
            end if;
         end loop;
           
      else   
         IDLeader := PlatooningObj.GetNeighbour(True);
         TaskNrLeader := PlatooningObj.GetTaskNr(IDLeader);
         
         if Status then
            
            My_Client(TaskNrLeader).Write("EMERG:1:" & Integer'Image(My_ID) & ":"
                                          & Integer'Image(IDLeader) & ";");
         else
            --Notify Leader that Issue got resolved 
            My_Client(TaskNrLeader).Write("EMERG:0:" & Integer'Image(My_ID) & ":"
                                       & Integer'Image(IDLeader) & ";");
            
         end if;
         
      end if;   
      
      --followpath
      --if underthreshold then
         --save old speed
        -- SpeedObj.SetSpeed(0.0,0.0); 
         --if platoonmode then
         
     -- if PlatooningObj.GetSOS = False then
               
             --  WriteEMERGE(True);
                                
            --else 
              --- ignore
            --end if;
         ---end if;
         --return (0.0, 0.0);
      --else
        -- if sos then
            --SpeedObj.SetSpeed(Oldvales)/10?
         --   WriteEMERGE(False);
         --end if;
       
     -- end if;
   
   end WriteEMERGE;
   
   
   procedure RestartCom (TaskNr : in Integer) is
      
      AnzahlTRucks : Integer := PlatooningObj.GetAmountofTrucks;
      ID_Behind_Lost : Integer:=0; --bc 2 Fwd
      
      TempTaskNr : Integer := 0;
      TempID : Integer := 0;
      
      ID : Integer := 0;
      Port : Port_Type;
      
   begin
      
      for N in 1..5 loop
         
         TempTaskNr := PlatooningObj.GetTaskNr(N);
         
         if TaskNr = TempTaskNr then
            Put_Line("**** DEBUG : ID 2 Reconnect:" & Integer'Image(N));
            ID := N;
            Port := PlatooningObj.GetPortofID(ID);
            exit;
         end if;
         
      end loop;
      
     
      if PlatooningObj.GetLeader then
         --TODO: check who we lost, then send the car behind him th emssage ti FWD, look at extra case if it was the last truck
         PlatooningObj.IncFailures;
         PlatooningObj.SetDistance; -- sets new Disstance
         
         for I in 2..AnzahlTRucks loop
            
            TempID:= PlatooningObj.GetIDoutofSeq(I);
            TempTaskNr := PlatooningObj.GetTaskNr(TempID);
            
            if TempTaskNr = TaskNr and I < AnzahlTRucks then -- this Client doesnt work
               -- Get the Trcuk behind it so it can Fwd The Message
               ID_Behind_Lost:= PlatooningObj.GetIDoutofSeq(I+1);
               TempTaskNr := PlatooningObj.GetTaskNr(ID_Behind_Lost);
               PlatooningObj.SetLookUpTable(TempID, TempTaskNr); -- from now on conntact ist through this task nr (truck behind)
                                                                 -- when called Ex_client its gets overritten again
               
            end if;
            
            My_Client(TempTaskNr).Write("SET_S:"& Float'Image(SpeedObj.GetAVGSpeed) & ":" 
                                        & Integer'Image(PlatooningObj.GetDistance) & ":"
                                        & Integer'Image(My_ID) & ":" & Integer'Image(TempID) & ";");
            
         end loop;
         
      else
         -- NOTIFY/Foward Leader
         TempID := PlatooningObj.GetNeighbour(True);
         
         if ID = TempID then --leader connection lost
            
            TempTaskNr := PlatooningObj.GetTaskNr(PlatooningObj.GetNeighbour(False)); -- so it fwd
            PlatooningObj.SetLookUpTable(TempID, TempTaskNr); -- from now on conntact ist through this task nr (truck infront)
                                                              -- when called Ex_client its gets overritten again
         else
            
            TempTaskNr := PlatooningObj.GetTaskNr(TempID); 
            
         end if;
         
         My_Client(TempTaskNr).Write("FAILE:"
                                        & Integer'Image(My_ID) & ":" & Integer'Image(TempID) & ";");
         
      end if;
      
      Put_Line("----------[ RESTARTING COM ]---------");
      
      ex_client(ID,Port);
      
   end RestartCom;
   
   task body PlatoonCost is
      
      --My_Channel : Stream_Access; --TODO
      Time : Integer := 0;
      
      --function values
      g : Float := 9.81;
      p : Float := 1.29;
      phi1 : Float := 0.53;
      phi2 : Float := 0.81;
      m : Float := 4000.0;
      Cd0 : FLoat := 0.5;
      Ss : Float := 15.0;
      Cy : Float := 0.018;
      enc : Float := 3.0E-7;
      
      d : Float;
      v :Float;
      tao : Float;
      Cd : Float;
      
      returnVAL : Float := 0.0;
      rool : Float :=0.0;
      air0 : Float :=0.0;
      follow : Float :=0.0;
      links : FLoat := 0.0;
      
   begin
      while True loop
         --accept StartCounting (Channel : in Stream_Access) do
         accept StartCounting do
            --My_Channel := Channel;
            null;
         end StartCounting;
         
         while PlatooningObj.GetPlatoonMode loop
            delay 1.0;
            Time := Time + 1;
         end loop;
         
         --function
         m := 4000.0;--m + Float(CargoObj.GetAuftrag);
         v := SpeedObj.GetAVGSpeed;
         d := 8.0;--Float(PlatooningObj.GetDistance)/187.5; --converts to m
         Put_Line("**** DEBUG : d:" & FLoat'Image(d));
         tao := v/d;
         Cd := Cd0*(1.0 -(phi1/(1.0+phi1*tao)));
                       
         rool := m*g*Cy;
         air0 := 0.5*Cd0*p*Ss*v*v;
         follow := enc*(rool + 0.5*Cd*p*Ss*v*v)*v*Float(Time);
         links := enc*( rool + air0 )*v*FLoat(Time);
         returnVAL :=   (links - follow) * 1000.0 ; -- converts to ml
         
         Put_Line("**** DEBUG : Roll:" & Float'Image(rool));
         Put_Line("**** DEBUG : Air0:" & Float'Image(air0));
         Put_Line("**** DEBUG : follow:" & Float'Image(follow));
         Put_Line("**** DEBUG : links:" & Float'Image(links));
         Put_Line("**** DEBUG : Cost of Platoon saved [ml]:" & Float'Image(returnVAL));
         
         --TODO: String'Write(My_Channel, "client_1 : " & Float'Image(returnVAL));
      
      end loop;
   end PlatoonCost;
   
   task body When2Exit is
   begin
      while True loop
         
         accept ArrivedEnd  do
            WriteEXITE;
         end ArrivedEnd;
         
         --CHeng:
         --if PlatooningObj.GetPlatoonMode then
            --if currentNr = LenofPath
              --controller_peer.When2Exit.ArrivedEnd;
            --end if;
            --actually just call the function
         
      end loop;
   end When2Exit;
   
   procedure evaluateMessageExClient (Input_string : in String; Tasknr : in Integer) is
      
      --Len_string     : Integer := Input_string'Length;
      --Grenzen_string : array (1 .. 20) of Integer; --20 values max
      --lauf_var : Integer          := 1; --f�r : Suche & Data Image
      
   begin
      
      --TODO PLatooning befehle
      Put_Line("++ Client" & Integer'Image(Tasknr) & " Hat gelesen:");
      Put_Line(Input_string);
      
   end evaluateMessageExClient;
   
end controller_peer;
