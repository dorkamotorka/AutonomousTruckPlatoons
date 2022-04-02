with GNAT.Sockets;          use GNAT.Sockets;
with Ada.Streams;           use Ada.Streams;

package webots_server is

   procedure tcp_socket(theport : in Port_Type);

end webots_server;
