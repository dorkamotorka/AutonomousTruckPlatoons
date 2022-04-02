with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Integer_Text_IO;   use Ada.Integer_Text_IO;
with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with ProtectsObj; use ProtectsObj;


package controller_peer is

   MAX_COM : Integer := 5; -- TODO Max Pltooning members

   task type  Server_handle is
      entry Start_Server(Socket : Socket_Type; Address : Sock_Addr_Type);
   end  Server_handle;

   My_Server : array (1..MAX_COM) of Server_handle;

   task type  Client_Type is

      entry Set_Stream (S : in Socket_Type; Tasknr : in Integer);
      entry Write (Message : in String);

   end Client_Type;

   My_Client : array (1..MAX_COM) of Client_Type;

   procedure StartExCoServer;
   procedure ex_client (TruckID_2Port: in Integer; Port : in Port_Type);

   function evaluateMessageExServerMain (Input_string : in String) return String;

   procedure newTruckwantsEntry (From_id : in Integer);
   procedure CommandENTRY (From_ID : in Integer);
   procedure CommandEMERG (Status : in Integer);
   procedure CommandEXITE (From : in Integer);
   function RemoveCarSeq (ID : in Integer; Index : out Integer) return Integer; --return Id of Car behind
   procedure CommandNEWTF (NewTruckID : in Integer; NewPort : in Port_Type);
   procedure CommandFAILE;
   procedure CommandNEWLE (Input_string : in String);

   procedure WriteEXITE;
   procedure WriteEMERGE (Status : in Boolean);

   procedure RestartCom (TaskNr : in Integer);

   task PlatoonCost is
      --entry StartCounting( Channel : Stream_Access); TODO
      entry StartCounting;
   end PlatoonCost;

   task When2Exit is
      --entry StartLooking;
      entry ArrivedEnd;
   end When2Exit;

   procedure evaluateMessageExClient (Input_string : in String; Tasknr : in Integer);

end controller_peer;
