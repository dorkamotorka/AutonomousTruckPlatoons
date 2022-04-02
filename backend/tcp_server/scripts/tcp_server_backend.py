#!/usr/bin/python

import sys
import time
import numpy as np
import socket
import selectors  # This module allows high-level and efficient I/O multiplexing of sockets
import types
from itertools import combinations
import math
sys.path.append('../../shortest_path/scripts') # must be before DijsktraShortestPath import
from dijkstra import DijkstraShortestPath

MAX_TRUCKS = 5

def get_key(my_dict, val):
    for key, value in my_dict.items():
        if val == value:
            return key
    return None

real_to_virt = {"Reichstag": 'Depot',
            "Brandenburg": 'In__D',
            "Spandau": 'Out_D',
            "Mitte": 'PD__1',
            "Humboldt": 'In__1',
            "Gendarmenmarkt": 'Out_1',
            "Kurfürstendamm": 'PD_21',
            "Berliner Dom": 'PD_22',
            "Berliner Fernsehturm": 'In__2',
            "Aquarium Berlin": 'Out_2',
            "ZOO Berlin": 'NS_Ex',
            "Hauptbahnhof": 'PD__3',
            "Charlottenburg": 'In__3',
            "Teufelssee": 'Out_3',
            "Technische Universitat Berlin": 'EW_Ex',
            "Grunewald": 'PD_41',
            "Britz": 'PD_42',
            "Kreuzberg": 'In__4',
            "Pankow": 'Out_4',
            }

class TCPServerBackend:
    def __init__(self, host=None, port=None):

        if host is not None:
            self.sock = socket.socket(
                socket.AF_INET, socket.SOCK_STREAM)  # IPv4, TCP
            self.sock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR, 1)
            try:
                self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                self.sock.bind((host, port))  # Network interface(NI) of a Server
            except OSError:
                sys.exit("Backend ERROR: Socket address already in use")
            self.sock.listen()  # Server listens on a previosly defined NI
            # Socket in non-blocking mode ~ .select() will block socket until ready
            self.sock.setblocking(False)
            self.sel = selectors.DefaultSelector()  # Socket I/O handler object
            # Registers socker to be monitored with .select()~ we use EVENT_READ since socket is a listener, everytime new client registers is sends "Hello" to server
            self.sel.register(self.sock, selectors.EVENT_READ, data="Hello")
            print('TCP server listening on', (host, port))

        self.start = None
        self.end = None
        self.weight = None
        self.pickup = None
        self.dropoff = None
        self.color_path = None
        self.json_file = None
        self.client_id = -1
        self.clients = {}  # client_name - port map
        self.sockets = {}  # client_name - socket map
        self.client_statuses = {}
        self.init_services()
        self.ext_con_ports = {}


    def init_services(self):
        self.services = {
            'deliver_status': self.update_status,
            'get_status': self.get_status,
            'default': "No Task",
        }

        self.frontend_services = {
            'distribute_cargo': self.distribute_cargo,
        }
        
    def get_status(self, args):
        client = args
        if client in self.client_statuses:
            free_cargo, position, distance, busy = self.client_statuses[client]
            return (free_cargo, position, busy)
        print("Backend: Client status is not yet available")
        return None

    def update_status(self, args):
        try:
            client, free_cargo, position, distance, busy = args.split(':')
        except ValueError:
            print('Corrupted message received')
            return

        self.client_statuses[client.strip()] = (
            free_cargo.strip(), position.strip(), distance.strip(), busy.strip())
        # print(self.client_statuses)
        return "Status Updated"

    def serve_client(self, key, mask):
        #print('serve_client called')
        sock = key.fileobj
        data = key.data

        #print('before')
        service = sock.recv(1024)  # Read 1024 bytes of data
        #print('blocks')
        try:
            client, service, args = service.decode('utf-8').split(':', maxsplit=2)
            print(client)
            print(service)
            print(args)
        except ValueError:
            print('Corrupted message received')
            return
        print(service)
        service = service.strip()
        if service in self.services:
            print('external controller service')
            print(args.strip())
            feedback = self.services[service](args.strip())
            print(feedback)
            if feedback == 'Status Updated':
                data.outb = 'OK '
            else:
                data.outb = ':'.join(feedback)
                data.outb += ' '

            # Give Service feedback
            if data.outb:
                try:
                    # Bytes are send and removed from the buffer
                    #sent = sock.send(bytes(data.outb, 'utf-8'))
                    #print('Backend: Sending', repr(data.outb), 'to', data.addr)
                    #data.outb = data.outb[sent:]
                    self.end = time.time()
                    print('---------------------------------NORMAL----------------------------------')
                    print(self.start - self.end)
                except BrokenPipeError:
                    print('Backend: Socket already closed, data not send!')

        elif service in self.frontend_services:
            print('frontend service')
            try:
                self.weight, pick, drop = args.split(':')
                self.pickup = real_to_virt[pick.strip()]
                self.dropoff = real_to_virt[drop.strip()]
                #self.pickup = 'Out_1'
                #self.dropoff = 'In__1'
                self.weight = float(self.weight)
                self.multicast_task(key, service)
                self.end = time.time()
                print('---------------------------------FRONTEND----------------------------------')
                print(self.start - self.end)
            except ValueError as e:
                print(e)
                print('Corrupted message received')
                return
        else:
            print('Service does not exits - this is a bug in the client code!')

    def accept_client(self, sock):
        # Returns a NEW(different from the one server is listening on) socket object (host, port) once client connects
        conn, addr = sock.accept()
        print('conn', conn)
        print('addr', addr)
        # New socket should be non-blocking ~ One socket blocks all the sockets!
        conn.setblocking(False)
        data = types.SimpleNamespace(addr=addr, inb=b'', outb=b'')
        # Notify server when client is ready either for reading or writing
        events = selectors.EVENT_READ | selectors.EVENT_WRITE
        # register socket to be monitored with .select()
        self.sel.register(conn, events, data=data)

        # TODO: Organize this better
        self.clients["client_%s" % self.client_id] = addr[1]
        self.sockets["client_%s" % self.client_id] = conn
        self.ext_con_ports[str(addr[1])] = str(9000 + self.client_id)
        print(self.clients)
        self.client_id += 1
        print('Backend: New socket established with', addr)

    def get_free_clients(self):
        clients_free = {}
        for client, args in self.client_statuses.items():
            free, _, _, _ = self.client_statuses[client]
            clients_free[client] = free

        return clients_free

    def get_combs(self, clients_free, length):
        combs = []
        for n in length:
            combs += combinations(clients_free, n + 1)

        return combs

    def get_available_options(self, clients_free, combs, cargo_request):
        available_options = []
        sum_of_free = 0
        for comb in combs:

            # Sum available free cargo space for each combination of trucks
            for client in comb:
                free = clients_free[client]
                sum_of_free += float(free)

            # Evaluate whether a combination is feasible and can deliver the cargo or not
            if cargo_request <= sum_of_free:
                available_options.append(comb)

            sum_of_free = 0

        #print('available', available_options)

        return available_options

    def get_optimal_option(self, available_options):
        optimal_option = []
        min_length = MAX_TRUCKS 
        for opt in available_options:
            l = len(opt)
            if l <= min_length:
                optimal_option.append(opt)
                min_length = l

        return optimal_option

    def Cost_fuel_Platoon (m, Ss, Cd, Cy, enc, v, t, d, n):
        """
           Calculate the Fuel cost
           Args:
               m (float):  Cargo space each Truck (kg)
               Ss (float): Cross-sectional area of each Truck (m^2)
               Cd(float): Air resistance coefficient of Single Leader Truck
               Cy(float): Rolling resistance coefficient of each Truck
               enc(float): Energy conversion constant
               v(float): velocity of the Truck (m/s)
               t(float): driving time (in second)
               d(float): distance between two Trucks (m)
               n(int): Number of Trucks in Platoon
           Returns:
               Cost of Fuel(Liter: float)
        """
        g = 9.81      # constant
        ρ = 1.29      # constant
        phi1 = 0.53   # constant
        phi2 = 0.81   # constant
        tao = d/v
        Cd0 = Cd/(1-(phi1/(1+phi1*tao)))
        Cost = enc*(m*g*Cy + 0.5*Cd*ρ*Ss*v*v)*v*t + (n-1)*enc*(m*g*Cy + 0.5*Cd0*ρ*Ss*v*v)*v*t

        return Cost

    def get_optimum(self, optimal_option, start, final):
        dsp = DijkstraShortestPath()
        optimum = None
        min_cost = 100000
        print('optimal options', optimal_option)
        for optims in optimal_option:
            cost = 0
            for optim in optims:
                # next_node, distance_to_next_node 
                _, truck_next_node, dist_from_next, _ = self.client_statuses[optim]

                # From truck to pickup
                try:
                    dsp.dijkstra(truck_next_node, start, True)
                except TypeError as e:
                    print(e)

                node_cost = dsp.get_cost()
                self.color_path = dsp.get_color_path()

                # From pickup to drop off
                try:
                    dsp.dijkstra(start, final, True)
                except TypeError as e:
                    print(e)

                node_cost += dsp.get_cost()
                self.color_path += dsp.get_color_path()

                # TODO: From drop off to depot
                try:
                    dsp.dijkstra(final, 'Depot', True)
                except TypeError as e:
                    print(e)

                node_cost += dsp.get_cost()
                self.color_path += dsp.get_color_path()
                print('node cost', node_cost)

                try:
                    cost += 1 / 2 * float(dist_from_next) + node_cost
                except TypeError as e:
                    print(e)
                    return None
            if cost < min_cost:
                optimum = optims
                min_cost = cost

        return optimum

    def get_distribution(self, clients_free, cargo_request, optimum):
        distrib = {}
        for truck in optimum:
            cargo_free = clients_free[truck]
            if cargo_request > float(cargo_free):
                distrib[truck] = int(cargo_free)
                cargo_request -= int(cargo_free)
            else:
                distrib[truck] = int(cargo_request)
                cargo_request = 0
        print('distribution', distrib)

        return distrib

    def distribute_cargo(self, clients):
        # Unpack request
        cargo_request = self.weight
        start = self.pickup
        final = self.dropoff
        
        clients_free = self.get_free_clients()

        #print('cargo', clients_free)
        length = range(len(clients_free))
        combs = self.get_combs(clients_free, length)

        available_options = self.get_available_options(clients_free, combs, cargo_request)

        if not available_options:
            print('No trucks combination can carry the cargo.')
            return None

        # Exclude options that are not optimal (e.g. multiple trucks if the payload can be driven by one)
        optimal_option = self.get_optimal_option(available_options)

        optimum = self.get_optimum(optimal_option, start, final)
        if optimum is None:
            return None

        distrib = self.get_distribution(clients_free, cargo_request, optimum)

        return distrib

    def get_platoons(self, distribution):
        platoons = {}
        for truck in distribution:
            _,next_node,_,_ = self.client_statuses[truck]
            if next_node in platoons:
                platoons[next_node].append(truck)
            else:
                platoons[next_node] = [truck]

        return platoons

    def order_trucks_in_platoon(self, platoons):
        ordered_platoons = {}
        for platoon in platoons:
            print('DIST', self.client_statuses['client_1'][2])
            print('platoon', platoons[platoon])
            trucks = platoons[platoon] if isinstance(platoons[platoon], list) else [platoons[platoon]]
            ordered = sorted(trucks, key=lambda t: self.client_statuses[t][2]) # NOTE: Order truck according to descending order
            ordered_platoons[platoon] = ordered 
        print('ordered: ', ordered_platoons)

        return ordered_platoons

    def construct_leader_msg(self, trucks):
        leader_msg = '2:1'

        # LEADER PROTOCOL
        # LEADER~ 2:1:<TRUCK-ID>:<PORT>:<TRUCK-SEQUENCE> 
        print('-------', self.clients)
        leader = True
        for truck in trucks:
            if not leader:
                leader_msg += ':' + truck[-1] + ':' + self.ext_con_ports[str(self.clients[truck])]
            leader = False

        leader_msg += ' '

        return leader_msg

    def multicast_task(self, key, service):
        data = key.data
        # Making sure we multicast only available clients (not busy)
        available_clients = []
        for client, args in self.client_statuses.items():
            _, _, _, busy = self.client_statuses[client]
            if busy == 'n':
                available_clients.append(client)

        print(available_clients)
        distribution = self.frontend_services[service](available_clients)
        print('distribution', distribution)
        if distribution:
            color_path = ":".join(self.color_path)

            platoons = self.get_platoons(distribution)

            # Determine the Leader

            ordered_platoons = self.order_trucks_in_platoon(platoons)

            for truck in distribution:
                print(truck)
                # Bytes are send and removed from the buffer
                data.outb = '1:' + str(distribution[truck]) + ':' + color_path + ' ' # <how-much-cargo> <color path sequence>
                print('output:', data.outb)
                sent = self.sockets[truck].send(bytes(data.outb, 'utf-8')) 

                # Clean buffer
                data.outb = data.outb[sent:]

            # TODO: Send plattoning protocol in the correct order!

            for platoon in ordered_platoons:
                trucks = ordered_platoons[platoon]
                # Only platoon if multiple trucks
                if len(trucks) > 1:
                    leader_id = trucks[0]
                    leader_port = str(self.clients[leader_id])

                    # LEADER PROTOCOL
                    data.outb = self.construct_leader_msg(trucks)
                    self.sockets[leader_id].send(bytes(data.outb, 'utf-8'))
                    print('Send to port: ', self.sockets[leader_id])
                    print('Backend: Sending', repr(data.outb), 'to', leader_id)
                    print('LEADER PROTOCOL SEND')
                    data.outb = data.outb[sent:]

                    # TRUCK PROTOCOL
                    # TRUCK~ 2:0:<LEADER-ID>:<LEADER-PORT>:<TRUCK-ID-IN-FRONT>:<TRUCK-PORT-IN-FRONT> 
                    # NOTE: For the second truck in a row is weird because it is a sequence ot two times the leader - but this is correct 
                    leader = True
                    last_id = None
                    last_port = None
                    truck_msg = '2:0:' + leader_id[-1] + ':' + self.ext_con_ports[leader_port]
                    for truck in trucks:
                        # Exclude leader from trucks
                        if not leader:
                            data.outb = truck_msg + ':' + last_id[-1] + ':' + self.ext_con_ports[last_port] + ' ' 
                            print('Backend: Sending', repr(data.outb), 'to', truck)
                            self.sockets[truck].send(bytes(data.outb, 'utf-8'))
                            print('Send to port: ', self.sockets[truck])
                            print('TRUCK PROTOCOL SEND')
                            data.outb = data.outb[sent:]
                        last_id = truck
                        last_port = str(self.clients[truck])
                        leader = False

    def run_network(self):
        while True:
            # Block until there are sockets ready ~ returns key (maps file object to file descriptor) and an event mask(read or write)
            events = self.sel.select(timeout=None)
            self.start = time.time()
            for key, mask in events:
                # Client need to send a "Hello" data to Server to init a Socket
                if key.data == "Hello":
                    self.accept_client(key.fileobj)
                try:
                    # Returns Socket port once client is connected to the Server
                    cli_port = key.fileobj.getpeername()[1]
                    if cli_port in self.clients.values():
                        self.serve_client(key, mask)
                    else:
                        print("Backend: Client not in Server lookup table")
                except OSError:
                    # print("Client not connected")
                    pass
            time.sleep(1)



"""
Main function
"""
if __name__ == '__main__':

    HOST = '127.0.0.1'  # loopback (localhost)
    PORT = 65432  # Arbitrary port (> 1023)
    server = TCPServerBackend(HOST, PORT)
    server.run_network()
