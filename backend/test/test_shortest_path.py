#!/usr/bin/env python

import sys
import unittest
import time
sys.path.append('../shortest_path/scripts')
from dijkstra import DijkstraShortestPath

class ShortestPathUnitTest(unittest.TestCase):
    '''
    Unit test class for testing Shortest Path algorithm.
    '''
    def setUp(self):
        self.dsp = None
        self.dsp = DijkstraShortestPath()

    # Test are called in the alphabetical order (test_X)
    # Each test function should have prefix test_
    def test_a_shortest_path(self):
        '''
        Tests whether path is optimal.
        '''
        self.dsp.dijkstra('Depot', 'Out_4', True)
        self.assertEqual(self.dsp.get_path(), ['Out_4', 'EW_Ex', 'In__1', 'Out_D', 'Depot'])

        self.dsp.dijkstra('NS_Ex', 'Out_3', True)
        self.assertEqual(self.dsp.get_path(), ['Out_3', 'PD__3', 'In__3', 'Out_2', 'NS_Ex'])

        self.dsp.dijkstra('In__1', 'In__4', True)
        self.assertEqual(self.dsp.get_path(), ['In__4', 'In__3', 'Out_2', 'NS_Ex', 'In__D', 'Out_4', 'EW_Ex', 'In__1'])

    def test_b_cost(self):
        '''
        Tests whether cost is optimal.
        '''
        self.dsp.dijkstra('Out_1', 'Out_4', True)
        self.assertEqual(int(self.dsp.get_cost()), 103)

    def test_c_color_sequence(self):
        '''
        Tests whether color sequence is optimal.
        '''
        self.dsp.dijkstra('Depot', 'Out_4', True)
        self.assertEqual(self.dsp.get_color_path(), ['pink', 'white', 'light_blue', 'light_blue'])
        self.dsp.dijkstra('NS_Ex', 'Out_3', True)
        self.assertEqual(self.dsp.get_color_path(), ['blue', 'white', 'yellow', 'yellow'])

        self.dsp.dijkstra('In__1', 'In__4', True)
        self.assertEqual(self.dsp.get_color_path(), ['light_blue', 'light_blue', 'white', 'blue','blue', 'white', 'white'])

if __name__ == '__main__':
    unittest.main()
