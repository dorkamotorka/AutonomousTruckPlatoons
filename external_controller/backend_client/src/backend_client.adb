with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;
with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Message_Handle; use Message_Handle;
with ProtectsObj; use ProtectsObj;
with controller_peer; use controller_peer;
with Position_Algorithm; use Position_Algorithm;


package body backend_client is

   -- This package creates an TCP Server. It receives packages with a maximum size
   -- of 1024 characters. The loop waits for a new connection and print the Data.

   procedure evaluateMessageBackendMain (Input_string : in String ) is

      Len_string     : Integer := Input_string'Length;
      Grenzen_string : array (1 .. 20) of Integer; --20 values max
      lauf_var : Integer          := 1; --für : Suche & Data Image

      --protocol1
      Path_nr : Integer := 1;
      Path : Route;

      --protocol2
      IdPortPair : Integer := 1;
      TruckIDLead : Integer := 0;
      TruckIDFront :Integer := 0;
      AmountofTrucks : Integer := 0;

      reply    : Unbounded_String := Null_Unbounded_String;

   begin
      --Protocol 1: "1:150:white:pink:blue;" "Protocolnr:Cargo:Colorsequence..."

      -- Search the String for : and saves the borders in Array "Grenzen_String"
      for I in 3 .. Len_string loop -- cause first two chars are Protocolnr:
         exit when Len_string = 0;
         if Input_string (I) = ':' or Input_string (I) = ';' then
            Grenzen_string (lauf_var) := I;
            lauf_var                  := lauf_var + 1;
         end if;
      end loop;

      if (Input_string(Input_string'First) = '1') then

         CargoObj.SetAuftrag(Integer'Value(Input_string(Input_string'First + 2 .. Grenzen_string(1)-1)));

         for I in 1 .. lauf_var-2 loop ---2 cause 1 increment and 1 less cause I+1

            Path(Path_nr) := GetColorOutString(Input_string(Grenzen_string(I)+1 .. Grenzen_string(I+1)-1));

            Path_nr:= Path_nr + 1;

         end loop;

         RouteObj.SetRoute(Path, Path_nr-1);
         SpeedObj.SetSpeed(15.0,15.0); -- bringt ihm zum laufen aka START!!

         --Ping the Position_Algorithm that a new route was set
         Position_Algorithm.Task_Current_Position.GetRoute;

      elsif(Input_string(Input_string'First) = '2') then
         --Protocol 2.1: 2:Leader(True):TruckID:Port:...<sequence>;
         --Protocol 2.2: 2:Leader(false):TruckIDL:PortL:TruckIDF:PortF;
         --Protocol 2: TODO: new car Joins

         PlatooningObj.SetPlatoonMode(True);

         if Input_string(Input_string'First + 2) = '1' then --am i the leader

            PlatooningObj.SetLeader(True);
            PlatooningObj.SetDistance;
            AmountofTrucks := (lauf_var-2)/2 + 1; -- +1 cuase me incl
            Put_Line("**** DEBUG: BAckend- Anzahl Trucks:" & Integer'Image(AmountofTrucks));
            PlatooningObj.SetAmountofTrucks(AmountofTrucks);
            PlatooningObj.AddTruck2Seq(1, My_ID); --set me at the top of the sequence
            if My_ID = 1 then PlatooningObj.SetLookUpPorts(1, 9001); end if; --TODO MY Ports

            declare
               TheIDRead : Integer;
               ThePortRead : Port_Type;
            begin

               for I in 2 .. AmountofTrucks loop
                  TheIDRead := Integer'Value(Input_string(Grenzen_string(IdPortPair)+1 .. Grenzen_string(IdPortPair+1)-1));
                  ThePortRead := Port_Type'Value(Input_string(Grenzen_string(IdPortPair+1)+1 .. Grenzen_string(IdPortPair+2)-1));

                  controller_peer.ex_client(TheIDRead, ThePortRead); -- creates a client to conntet to that port
                  --Debug:
                  --Put_Line(Input_string(Grenzen_string(IdPortPair)+1 .. Grenzen_string(IdPortPair+1)-1));
                  --Put_Line(Input_string(Grenzen_string(IdPortPair+1)+1 .. Grenzen_string(IdPortPair+2)-1));

                  PlatooningObj.AddTruck2Seq(I, TheIDRead); --saves the ID at the index of the fleet
                  PlatooningObj.SetLookUpPorts(TheIDRead, ThePortRead); --saves the Port at the index of ID

                  IdPortPair := IdPortPair + 2;
               end loop;

            end;

         else
            -- i am not the leader
            PlatooningObj.SetLeader(False);
            TruckIDLead  := Integer'Value(Input_string(Grenzen_string(IdPortPair)+1 .. Grenzen_string(IdPortPair+1)-1));
            TruckIDFront := Integer'Value(Input_string(Grenzen_string(IdPortPair+2)+1 .. Grenzen_string(IdPortPair+3)-1));

            controller_peer.ex_client(TruckIDLead,
                                      Port_Type'Value(Input_string(Grenzen_string(IdPortPair+1)+1 .. Grenzen_string(IdPortPair+2)-1)));

            if TruckIDFront /= TruckIDLead then -- I am not the 2nd Car
                 controller_peer.ex_client(TruckIDFront,
                                           Port_Type'Value(Input_string(Grenzen_string(IdPortPair+3)+1 .. Grenzen_string(IdPortPair+4)-1)));
            end if;

            PlatooningObj.SetNeighbour(TruckIDFront, TruckIDLead);

            --TODO Lu: Search for Car, then send to Leader ENTRY

            My_Client(PlatooningObj.GetTaskNr(TruckIDLead)).Write("ENTRY:"&
                                                                    Integer'Image(My_ID) & ":"&
                                                                    Integer'Image(TruckIDLead) & ";");
            --controller_peer.PlatoonCost.StartCounting(My_Channel); TODO
            controller_peer.PlatoonCost.StartCounting;
         end if;

      end if;

   end evaluateMessageBackendMain;


   procedure Backend_Client is

      Address  : Sock_Addr_Type;
      Socket   : Socket_Type;
      Channel  : Stream_Access;
      Send_Msg : String :=
        "client_1 : deliver_status : client_1 : 500 : Depot : 2.5 : n";
      Receive  : Character;
      Recv_Msg : String (1 .. 2_048);
      Msg_Len  : Integer;

      FirstM : Boolean := True;

      task WritePosition is

         entry Set_Stream (S : in Stream_Access);

      end WritePosition;

      task body WritePosition is

         My_channel : Stream_Access;

         PosString : String(1..5); --fixed size
         AFloat : Float; -- ist nur >=0

      begin

         accept Set_Stream (S : in Stream_Access) do

            My_channel := S;

         end Set_Stream;

         while True loop
            -- Todo Exit
            delay 5.0;
            PosString := RouteObj.GetCurrentPos(AFloat);

            declare

               Float2String : constant String := Float'Image(AFloat);
               CargoSpaceLeft : Integer := ProtectsObj.CargoObj.GetMaxLoad - ProtectsObj.CargoObj.GetAuftrag;

               IDString : String := ProtectsObj.My_ID'Image;
               CargoSpaceLeftImage : String := CargoSpaceLeft'Image;

            begin

               --String'Write (Channel, PosString & ":"
               --              & Float2String(1..Float2String'Length) & ";");
               -- String'Write(Channel, Send_Msg);

               -- Send current position
               if CargoObj.GetAuftrag /= 0 then

                  String'Write(Channel, "client_" & IDString(2..2) & " : " & "deliver_status" & " : " & "client_" & IDString(2..2) & " : " & CargoSpaceLeftImage(2..CargoSpaceLeftImage'Length) & " : " & PosString & " : " & Float2String(2..Float2String'Length) & " : " & "y");

               else

                  String'Write(Channel, "client_" & IDString(2..2) & " : " & "deliver_status" & " : " & "client_" & IDString(2..2) & " : " & CargoSpaceLeftImage(2..CargoSpaceLeftImage'Length) & " : " & PosString & " : " & Float2String(2..Float2String'Length) & " : " & "n");
               end if;
            end;

         end loop;

      end WritePosition;


   begin

      Address.Addr := Inet_Addr ("127.0.0.1");
      Address.Port := 65_432;
      Create_Socket (Socket, Family_Inet, Socket_Stream);
      Put_Line ("Create Socket for Backend!");

      -- Allow reuse of local addresses.
      Set_Socket_Option (Socket, Socket_Level, (Reuse_Address, True));

      Connect_Socket (Socket, Address);
      Put_Line ("Connect to Address: " & Image (Address));
      -- Waiting for connection

      Channel := Stream (Socket);

      if (My_ID = 2) then
         Send_Msg := "client_2 : deliver_status : client_2 : 500 : Depot : 2.5 : n";
      elsif My_ID = 3 then
         Send_Msg := "client_3 : deliver_status : client_3 : 500 : Depot : 2.5 : n";
      elsif My_ID = 4 then
         Send_Msg := "client_4 : deliver_status : client_4 : 500 : Depot : 2.5 : n";
      elsif My_ID = 5 then
         Send_Msg := "client_5 : deliver_status : client_5 : 500 : Depot : 2.5 : n";
      end if;


      -- Send Message
      String'Write (Channel, Send_Msg);

      Put_Line ("Send Message: " & Send_Msg);

      -- Receive Message Char by Char until Separator ' '
      while True loop
         Msg_Len := 0;
         Character'Read (Channel, Receive);
         while (Receive /= ' ') loop
            Msg_Len            := Msg_Len + 1;
            Recv_Msg (Msg_Len) := Receive;
            Character'Read (Channel, Receive);
         end loop;
         if Msg_Len > 0 then
            Put_Line ("Received Message: " & Recv_Msg (1 .. Msg_Len));
         end if;

         evaluateMessageBackendMain(Recv_Msg(1..Msg_Len)& ";");

         if FirstM then --new
            WritePosition.Set_Stream(Channel);
            FirstM := False;
         end if;
         -- exit when ....;
      end loop;

      Free (Channel);
      Close_Socket (Socket);
      Put_Line ("Close Socket");

   end Backend_Client;


end backend_client;
