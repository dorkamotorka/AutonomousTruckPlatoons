with Text_IO;               use Text_IO;
with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;
with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;           use Ada.Strings;

with Message_Handle; use Message_Handle;

package body webots_server is

   procedure tcp_socket (theport : in Port_Type) is

      Address  : Sock_Addr_Type;
      Server   : Socket_Type;
      Socket   : Socket_Type;
      Channel  : Stream_Access;
      --Send_Msg : String (1 .. 1_024);
      Receive  : Character;
      Recv_Msg : String (1 .. 2_048);
      Msg_Len  : Integer;

      Seperater : Integer := 0;

   begin

      Address.Addr := Inet_Addr ("127.0.0.1");
      Address.Port := theport;--9_876;
      Create_Socket (Server, Family_Inet, Socket_Stream);

      Put_Line ("Create Socket for Webots!");

      -- Allow reuse of local addresses.
      Set_Socket_Option (Server, Socket_Level, (Reuse_Address, True));

      ----- Client functions -----
      -- Connect_Socket (Server, Address); Put_Line ("Connect to Address: " &
      -- Image (Address)); Socket := Server;
      ----------------------------

      ----- Server functions -----
      Bind_Socket (Server, Address);
      -- Waiting for connection
      Listen_Socket (Server);
      Put_Line ("Listen_Socket");
      -- Accept connection
      Accept_Socket (Server, Socket, Address);
      Put_Line ("Accept connection from Address: " & Image (Address));
      ----------------------------

      Channel := Stream (Socket);

      while True loop
         Seperater := 0;
         Msg_Len := 0;

         --Put_Line ("Receive message!");

         Character'Read (Channel, Receive); -- ein char gelesen


         while (Receive /= ';') loop
            --Put(Receive);

            if Receive = ':' then
               Seperater:= Seperater + 1;
            end if;

            if Seperater = 3 then
               for I in 1 .. 1025 loop
                  Msg_Len            := Msg_Len + 1;
                  Recv_Msg (Msg_Len) := Receive;
                  Character'Read (Channel, Receive);
                  --Put(Receive);
               end loop;
               --Put(Receive);--
               Seperater := Seperater +1;
            else
               Msg_Len            := Msg_Len + 1;
               Recv_Msg (Msg_Len) := Receive;
               Character'Read (Channel, Receive);
            end if;


         end loop;

         if Msg_Len > 0 then
            --Put_Line("Received Message: " & Recv_Msg (1 .. Msg_Len));
            --Put_Line (" *** Länge der Nachricht : " & Integer'Image(Msg_Len));
            null;
         end if;

         String'Write (Channel, evaluateMessageWebots (Recv_Msg (1 .. Msg_Len) & ";"));
      end loop;

      Free (Channel);
      Close_Socket (Server);
      Put_Line ("Close Socket");

   end tcp_socket;

end webots_server;
