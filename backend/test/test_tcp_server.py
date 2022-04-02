#!/usr/bin/env python

import sys
import unittest
sys.path.append('../tcp_server/scripts')
sys.path.append('../shortest_path/scripts')
from tcp_server_backend import TCPServerBackend 

class TCPServerBackendUnitTest(unittest.TestCase):
    '''
    Unit test class for testing TCP server backend.
    '''
    def setUp(self):
        self.server = TCPServerBackend()
        
    # Test are called in the alphabetical order (test_X)
    # Each test function should have prefix test_
    def test_a_get_status(self):
        '''
        Tests whether clients status is correct.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        self.assertEqual(self.server.get_status('client_1'), ('100', 'x', 'n'))
        
    def test_b_update_status(self):
        '''
        Tests whether status is updated.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        msg = 'client_1 : 150 : y : 6.0 : y'
        self.server.update_status(msg)
        self.assertEqual(self.server.get_status('client_1'), ('150', 'y', 'y'))
        
    def test_c_free_clients(self):
        '''
        Tests whether free clients are returned.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['100', 'x', '5.5', 'y']
        self.server.client_statuses['client_3'] = ['100', 'x', '5.5', 'n']
        self.server.client_statuses['client_4'] = ['100', 'x', '5.5', 'y']
        free_clients = self.server.get_free_clients()
        self.assertIn('client_1', free_clients)
        self.assertIn('client_3', free_clients)

    def test_d_get_combs(self):
        '''
        Tests whether correct combinations are returned.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['100', 'x', '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        self.assertIn(('client_1',), combs)
        self.assertIn(('client_2',), combs)
        self.assertIn(('client_1', 'client_2'), combs)


    def test_e_get_available_options(self):
        '''
        Tests available options are returned.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['100', 'x', '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        self.assertEqual(self.server.get_available_options(free_clients, combs, 200), [('client_1', 'client_2')])

    def test_f_get_optimal_option(self):
        '''
        Tests whether optimal option is returned.
        '''
        self.server.client_statuses['client_1'] = ['100', 'x', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['200', 'x', '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        available_options = self.server.get_available_options(free_clients, combs, 100)
        self.assertEqual(self.server.get_optimal_option(available_options), [('client_1',), ('client_2',)])

    def test_i_get_optimum(self):
        #Tests whether optimum is returned.
        self.server.client_statuses['client_1'] = ['100', 'Out_1', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['200', 'Out_1', '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        available_options = self.server.get_available_options(free_clients, combs, 100)
        optimal_option = self.server.get_optimal_option(available_options)
        start = 'Depot'
        final = 'Out_4'
        self.assertEqual(self.server.get_optimum(optimal_option, start, final), ('client_1',))

    def test_j_get_distribution(self):
        #Tests whether distribution is correct.
        self.server.client_statuses['client_1'] = ['100', 'Out_1', '5.5', 'n']
        self.server.client_statuses['client_2'] = ['200', 'In__1', '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        cargo_request = 300
        available_options = self.server.get_available_options(free_clients, combs, cargo_request)
        optimal_option = self.server.get_optimal_option(available_options)
        start = 'Depot'
        final = 'Out_4'
        optimum = self.server.get_optimum(optimal_option, start, final)
        self.assertEqual(self.server.get_distribution(free_clients, cargo_request, optimum), {'client_1': 100, 'client_2': 200})

    def test_k_get_platoons(self):
        #Tests whether platoons are coupled correctly.
        next_node = 'Out_1'
        self.server.client_statuses['client_1'] = ['100', next_node, '3.5', 'n']
        self.server.client_statuses['client_2'] = ['200', next_node, '1.5', 'n']
        self.server.client_statuses['client_3'] = ['300', next_node, '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        cargo_request = 600
        available_options = self.server.get_available_options(free_clients, combs, cargo_request)
        optimal_option = self.server.get_optimal_option(available_options)
        start = 'Depot'
        final = 'Out_4'
        optimum = self.server.get_optimum(optimal_option, start, final)
        distribution = self.server.get_distribution(free_clients, cargo_request, optimum)
        self.assertEqual(self.server.get_platoons(distribution)[next_node], ['client_1', 'client_2', 'client_3'])

    def test_l_order_platoons(self):
        #Tests whether platoons are ordered correctly.
        next_node = 'Out_1'
        self.server.client_statuses['client_1'] = ['100', next_node, '3.5', 'n']
        self.server.client_statuses['client_2'] = ['200', next_node, '1.5', 'n']
        self.server.client_statuses['client_3'] = ['300', next_node, '5.5', 'n']
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        cargo_request = 600
        available_options = self.server.get_available_options(free_clients, combs, cargo_request)
        optimal_option = self.server.get_optimal_option(available_options)
        start = 'Depot'
        final = 'Out_4'
        optimum = self.server.get_optimum(optimal_option, start, final)
        distribution = self.server.get_distribution(free_clients, cargo_request, optimum)
        platoons = self.server.get_platoons(distribution)
        self.assertEqual(self.server.order_trucks_in_platoon(platoons)[next_node], ['client_2', 'client_1', 'client_3'])

    def test_m_construct_leader_msg(self):
        #Tests whether leader_msg is constructed correctly.
        next_node = 'Out_1'
        self.server.client_statuses['client_1'] = ['100', next_node, '3.5', 'n']
        self.server.client_statuses['client_2'] = ['200', next_node, '1.5', 'n']
        self.server.client_statuses['client_3'] = ['300', next_node, '5.5', 'n']
        self.server.clients['client_1'] = 9001 
        self.server.clients['client_2'] = 9002 
        self.server.clients['client_3'] = 9003 
        self.server.ext_con_ports['9001'] = '9001' 
        self.server.ext_con_ports['9002'] = '9002' 
        self.server.ext_con_ports['9003'] = '9003' 
        free_clients = self.server.get_free_clients()
        combs = self.server.get_combs(free_clients, range(len(self.server.client_statuses)))
        cargo_request = 600
        available_options = self.server.get_available_options(free_clients, combs, cargo_request)
        optimal_option = self.server.get_optimal_option(available_options)
        start = 'Depot'
        final = 'Out_4'
        optimum = self.server.get_optimum(optimal_option, start, final)
        distribution = self.server.get_distribution(free_clients, cargo_request, optimum)
        platoons = self.server.get_platoons(distribution)
        ordered_platoons = self.server.order_trucks_in_platoon(platoons)
        self.assertEqual(self.server.construct_leader_msg(ordered_platoons[next_node]), '2:1:1:9001:3:9003 ')

if __name__ == '__main__':
    unittest.main()

