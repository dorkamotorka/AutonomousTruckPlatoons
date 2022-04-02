# Controller Peer
## Overview
Multiple communications in Ada is rough and quite not very good documented. Therefore each Truck has an array of Serverconnections and Clients. This is possible through Tasktypes _Server_handle_ and _Client_type_. The following picture shows the Implementation.

![controller_peer](external_controller/controller_peer/images/controller_peer.png)

The Leader has is connected through Clients to every following car, while the other Trucks have just two Client-connections: one with the Leader and one with the Truck infront. This assure more safety in case of communications errors. In a degraded mode messages can be forwarded through the other Truck.

Note: We declare that in our world there are max 5 Trucks + only 5 Trucks can Platoon at a Time for safety reason.

## functionality
### Triggering to Platoon --- Start
The Truck gets notified through the Backend if it should platoon and with whom. There are 2 Protocols: one for a Leader (2.1) and the other one for a following Truck (2.2):
```
Protocol 2.1: 2:Leader(True):2ndTruckID:2ndTruckPort:...<sequence of ID and Ports of following Trucks>;
Protocol 2.2: 2:Leader(false):TruckIDL:PortL:TruckIDF:PortF;

```
These information are read in the package **backend_client** in function _evaluateMessagebackendMain_. An Example:
```
   if My_ID = 1 then
    	evaluateMessageBackendMain("2:1:2:9002:3:9003:4:9004:5:9005;" );
   elsif My_ID = 2 then
    	evaluateMessageBackendMain("2:0:1:9001:1:9001;");
   elsif My_ID = 3 then
    	evaluateMessageBackendMain("2:0:1:9001:2:9002;");
   elsif My_ID = 4 then
    	evaluateMessageBackendMain("2:0:1:9001:3:9003;");
   elsif My_ID = 5 then
    	evaluateMessageBackendMain("2:0:1:9001:4:9004;");
   end if;
```

### Necessary Data to Store
The Information given my Backend are stored in **ProtectsObj** in the **PlatoonObj** and **ExCoObj**. These include:
* 	PlatoonMode : Boolean -- True if Platooning
*	Leader : Boolean – wether I am the Leader
*	SOS : Boolean – if there is currently an amergency
*	Distance_2_Front : Integer – the distance that should be between trucks
*	ExClientTrId2TaskNr  -- a lookuptable with <ID>:<TaskNrClient>
*	Leader :
	-  Failures_Count : Int -- Counts how many Problems there are to adjust the Distance
	-  HowManyCars : Int – How many cars are in a fleet (incl me)
	-  SequenceofTrucks  -- LookupTable  `<Index>:<ID>`
	-  PortsaID – LookupTable  `<ID>:<PortNr>`
*   Not Leader:
	- TruckFrontID : Int – the ID of the Car in front of it 
	- TruckLeaderID : Int – ID of the Leader
* Tasknr_c : Integer := 1; --current Index of next available Client
* Tasknr_s : Integer := 1; --current Index of next available Server

### Client
This function **ex_client(TruckID_2Port: in Integer; Port : in Port_Type))** connects to the desired Server and triggers the next available Client in the Client-Array _My_Client_ to Start. It then saves the ID and currentTaskNr in the _PlatoonObj_. 

The writing in _Client_Type_ is trigger based with the enry **Write(Message : in String)**. Due to the blocking nature of Reading, _Client_Type consists of an extra Task just dedicated for reading. If it recieves a successful reply to its *EXITE* request, the Communication will be closed. The Client will then be resettet for future reusage.

### Server
The Procedure **StartExCoServer** is started from the beginning in main. It sets a Server with the given Port. If a Client connects, it triggers the next available ServerTask from the Type _Server_Handle_ in the Server-Array. Each task reads and then writes in a loop. The read Message is given the function **evaluateMessageExServerMain** which will handle the evaluation and the reply for the request. If the Request is an "EXITE" command, with the destination being itself, then the Server will close the Communication and resets the Server.  

## functions
### function evaluateMessageExServerMain (Input_string : in String) return String
The Variables _Len_String_ and _Lauf_var_ are being used to determine the Borders (“:” and “;”) of the Message and their indexes are stored in _Grenzen_String_. Each message consists at leat of an _Command, From and a Destination_. _From and Dest_ are always last two Information of the String, while the Command makes up the five first Bytes. The Function return then a String once the Request is done. `--Command: From ID: My_ID: Done --> SpeedValues;`

#### Forwarding
The function checks if the Destiantion of the message equals to the ID of the Truck that recieved the message. If they not equal a fowarding will take place. 
	* I case of the **Leader**: the Client who is registered in _ExClientTrId2TaskNr_ for the ID _Dest_ will forward the Message.
	* In case of a **following Truck** : since it only has two connections it checks from which Trcuk it recieved the Message and then forward it to the other connection.

Once it checked that itself is the right Destination, the Command will be filtered. Dpening on the Command a subfunction will be called:
| Command | function |
| ------ | ------ |
| ENTRY | CommandENTRY() |
| EMERG | CommandEMERG() |
| EXITE | CommandEXITE() |
| NEWTF | CommandNEWTF() |
| FAILE | CommandFAILE() |
| NEWLE | CommandNEWLE() |

#### SET_S Set Speed and Distance:
`--SET_S:SpeedVAl:Distance:From:To;`
This is the only Commmand that haven't gotten its own function. This Command tells the reciever to regulate its Speed and Distance to the Truck infront as wished. Ideally here would have been the PID-Controller integrated which wasn't finsihed due to a sudden drop of a member.

#### ENTRY and CommandENTRY (From_ID : in Integer) 
`-- ENTRY:FROM:TO;` The Input _From_ID_ is the ID of the Sender. Every following Truck sends an "ENTRY" request to Leader once it got triggered to Platoon. Therefore the procedure CommandENTRY() is specifically for the Leader. The Leader then replies with a "SET_S" Command through its Client-Connection it got with the Sender. 

This funcion is also flexible for Truck who want to join an already existing Platoon. Therefore the Leader checks if the incomming Truck is registered as one of the Trucks initially given by the Backend. If its unregistered, so a new Truck, the procedure `newTruckwantsEntry(From_ID);` gets called.

####  newTruckwantsEntry (From_id : in Integer)
The Input _From_ID_ is the ID of the Sender. In this procedure the **PlatoonObj** variables get updated, since a new Truck just joined. After that a "SET_S" Command is send to that Truck.


#### EXITE CommandEXITE ( From : in Integer)
`--EXITE:FROM:TO;`The Input _From_ is the ID of the Sender. As already stated in _Server_handle_, the communication gets closed there. CommandEXITE is a procedure specifally for the Leader. The Leader will send an "EXITE" request too to the Sender through its Client, so its Client and the Senders's Server can properly close.   

After that the Values in **PlatoonObj** need to vbe updated. Therefore the procedure `RemoveCarSeq(From, FoundIndex)` gets call. It will return the ID of the Truck behind the leaving one, if there is one. The goal is to tell this Truck that it has now a new Truck infront of it. The Leader send a "NEWTF" (NewTruckinFront) Command.

There is one extra case that is checked. If there are cuurently just two Trucks in a Platoon and the second one wants to exit, then the Platoon gets dissolved and the Leader will reset all its **PlatoonObj** Values. 

#### RemoveCarSeq (ID : in Integer; Index : out Integer) return Integer
The input ID is the ID of the Truck that wants to exit. This function removed properly the ID out of the Sequence and updates how many Trucks in the fleet currently are. If there was no Truck behind the lleaving one it will return 0. If there is one, the function return the ID of that Truck behind and output in _Index_ the Index of that car.

#### NEWTF and CommandNEWTF (NewTruckID : in Integer ; NewPort : Port_Type)
`"NEWTF:NEWID:NEWPORT:FROM:TO;"` This function is for folling Trucks. The procedure can be simplified in four steps:
1. Close connection to the Truck infront: Writing an "EXITE" request.
2. Check if the new FrontTruck is the Leader
	2.1. if yes: update `TruckFrontID = TruckLeaderID` in PlatoonObj
	2.2	 if no: call `ex_client(NewTruckID, NewPort);`  and update `TruckFrontID = NewTruckID`

#### EMERG and CommandEMERG (Status : in Integer) 
`--EMERG:Status:From:To;` Status is 1 if an emergency occured and sets its Speed to 0 whiel if Status is 0 it got resolved and the Speed wil be set to 15 again. When the Leader recieves and EMERGE Command it will forward it to every other Truck in the fleet. Once its got resolved it send a "SET_S" to the other Trucks again, so they will move.

#### WriteEMERGE (Status : in Boolean) 
This procedure is called by the package **follow_path** once it detects an obstacle. Status refers wether its detected something (True) or it got resolved (False). _SOS_ in PlatoonObj is updated.

- as a following Car it will send an "EMERG" Command to the Leader with the correct Status
- the Leader will weither send an "EMERG" command if there is an obstacle and a "SET_S" once it got resolved.

#### WriteEXITE
This procedure is called by the package **follow_path** once it arrived at its Exit. All the PlatoonObj ans ExCoObj values will be reset.  

- a following Truck will send a "EXITE" request to the Leader and TruckinFront.
- a Leader has o determine who the Next Leader will be and then notify all the following Trucks of the new Leader. 
```
--NEWLE : BoolifIam (1) : HowManyTrucks : <(ID : Port) Sequence> : FROM : TO ; 
--NEWLE : BoolifIam (0) : IDLeader : PortLeader : FROM : TO ;
```

#### NEWLE and CommandNEWLE (Input_string : in String)
```
--NEWLE : BoolifIam (1) : HowManyTrucks : <(ID : Port) Sequence> : FROM : TO ; 
--NEWLE : BoolifIam (0) : IDLeader : PortLeader : FROM : TO ;
```
Input_String is the Message recieved.  

- when BoolifIam is 0, it means that the Truck has to connect to a new Leader ans sends and EXITE Request to the Oldleader. There is and extra case if the NewLeader is also the Truckinfront.

- when BoolifIam is 1, it means that it is now the New Leader. Once every Information is extracted from the Protocol, it will connect to every following Truck and "EXITE" the old Leader. There is an extra case if HowManyTrucks = 0, i t means there is no Truck left and therefore calls `WriteEXITE()`.

## Degradation Platoon
The task _Client_Type_ has an exepction handeling, meaning if a communication is suddenly lost without proper closing if will call the procedure `RestartCom()`. The Forwarding function is very useful here.

### RestartCom(TaskNr : in Integer)
The Input is the TaskNr that lost the communication.  

- Leader : Increases the Number of failures and then recaculate the distance between the Trucks. Then it has to be found out which Truck is behind the Truck which communication git lost. With this information the Tasknr gets updated to tHE truck behind, so everytime there is gonna be a request or command to the Truck-Lost, the Leader will sen dit to the Truck behind and it will then forward it to his Truck infront. 
Once that is ready, the Leader send a new "SET_S" Command with the new Distance.

- Following Truck: Also updates the TaskNr for Truck-Lost to the other connection, so forwarding is possible from now on. After that it notfies the Leader with the Command "FAILE" that there is a failure.

After that a try to reconnect is startet with `ex_client(IDLost, Port)`(, which should work immediatly since a Truck has many Servers!). Once it reconnects succesfully, _ec_client_ will update the right TaskNr again so the Forwarding is not used anymore.

### FAILE and CommandFAILE()
The Leader increases the amount of failures and updates the Distance to other trucks via a "SET_S".

## Task PlatoonCost
The Task is triggered in the _evaluateMessageBackendMain()_ for only following Trucks in order to caculate the Fuel saving out of the Platooning. The Task counts the Time the Truck is in a Fleet and checks if it is currently platooning. With the time it can roughly caculate how many ml is saved during the Platoon and prints it out.


