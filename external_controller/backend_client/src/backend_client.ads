with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;

package backend_client is

   --procedure evaluateMessageBackendMain (Input_string : in String; My_Channel : Stream_Access) ;
   procedure evaluateMessageBackendMain (Input_string : in String);

   procedure Backend_Client;

end backend_client;
