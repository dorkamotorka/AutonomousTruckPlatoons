#!/usr/bin/env python

'''
Minimal requirements:
- All vertices must be reachable from the source vertex

Algorithm outline:
0. Aproximate the truck to the next node he is about to visit
1. Mark all nodes unvisited and store them.
2. Set the distance to zero for our initial node and to infinity for other nodes.
3. From each of the unvisited vertices, choose the vertex with the smallest distance and visit it.
4. Update the distance for each neighboring vertex, of the visited vertex, whose current distance is greater than its sum and the weight of the edge between them.
5. Repeat steps 3 and 4 until all the vertices are visited.
'''

from itertools import combinations

class DijkstraShortestPath:

    white = (255, 255, 255)
    red = (0, 0, 255)
    pink = (255, 85, 170)
    violett = (127, 0, 85)
    orange = (3, 129, 255)
    yellow = (0, 255, 255)
    green = (0, 255, 85)
    blue = (255, 0, 0)
    light_blue = (255, 255, 85)

    # Highways have a weight 1 - this way truck tend to drive through them
    graph_cost = {'Depot': {'Out_D': 11.15, 'NS_Ex': 1},
                  'In__D': {'In__1': 38.33, 'NS_Ex': 1, 'Depot': 15.85},
                  'Out_D': {'In__1': 25.33},
                  'PD__1': {'EW_Ex': 1, 'Out_1': 5.65},
                  'In__1': {'PD__1': 11.95, 'In__2': 45.53, 'EW_Ex': 1},
                  'Out_1': {'In__2': 34.93},
                  'PD_21': {'Out_2': 7.85},
                  'PD_22': {'Out_2': 9.15},
                  'In__2': {'PD_21': 9.15, 'In__3': 21.43},
                  'Out_2': {'In__3': 12.43},
                  'NS_Ex': {'PD_22': 7.57, 'Out_2': 1},
                  'In__3': {'PD__3': 9.15, 'In__4': 30.35},
                  'PD__3': {'Out_3': 6.15},
                  'Out_3': {'In__4': 23.05},
                  'EW_Ex': {'PD_42': 6.57, 'Out_4': 1},
                  'PD_41': {'Out_4': 6.15},
                  'PD_42': {'Out_4': 7.95},
                  'In__4': {'PD_41': 10.15, 'In__D': 30.93},
                  'Out_4': {'In__D': 20.63},
                  }

    graph_color = {'Depot': {'Out_D': 'pink', 'NS_Ex': ['pink', 'blue']},
                  'In__D': {'In__1': 'white', 'NS_Ex': 'blue', 'Depot': 'pink'},
                  'Out_D': {'In__1': 'white'},
                  'PD__1': {'EW_Ex': 'light_blue', 'Out_1': 'violett'},
                  'In__1': {'PD__1': 'violett', 'In__2': 'white', 'EW_Ex': 'light_blue'},
                  'Out_1': {'In__2': 'white'},
                  'PD_21': {'Out_2': 'orange'},
                  'PD_22': {'Out_2': 'orange'},
                  'In__2': {'PD_21': 'orange', 'In__3': 'white'},
                  'Out_2': {'In__3': 'white'},
                  'NS_Ex': {'PD_22': 'orange', 'Out_2': 'blue'},
                  'In__3': {'PD__3': 'yellow', 'In__4': 'white'},
                  'PD__3': {'Out_3': 'yellow'},
                  'Out_3': {'In__4': 'white'},
                  'EW_Ex': {'PD_42': 'green', 'Out_4': 'light_blue'},
                  'PD_41': {'Out_4': 'green'},
                  'PD_42': {'Out_4': 'green'},
                  'In__4': {'PD_41': 'green', 'In__D': 'white'},
                  'Out_4': {'In__D': 'white'},
                  }
    def __init__(self):
        self.color_path = [] 
        self.path = None
        self.cost = None

    def get_path(self):
        return self.path

    def get_cost(self):
        return self.cost

    def get_color_path(self):
        return self.color_path

    def dijkstra(self, src, dest, clean, visited=[], distances={}, predecessors={}, graph=graph_cost):
        """
        Calculates a shortest path tree with a root in src
        @arguments:
            graph: dictionary of initial_node = {neighbour_node: cost}
            src: source node
            dest: destination node
        @additional arguments:
            visited: array, that keeps track of already visited nodes
            distances: dicitonary, that keeps tracks of nodes distances
            predecessors: dicitonary that keeps track of parent node of a child
        @return: None
        """
        if clean:
            visited = []
            distances = {}
            predecessors = {}
        # Sanity checks
        if src not in graph:
            raise TypeError(
                'The root of the shortest path tree cannot be found')
        if dest not in graph:
            raise TypeError('The target of the shortest path cannot be found')

        if src == dest and len(distances) == 0:
            print("End node is already the same as Start node")
            return None

        # Tree build ending
        if src == dest:
            path = []
            pred = dest
            while pred is not None:
                path.append(pred)
                pred = predecessors.get(pred, None)

            # Save result to class variables
            self.path = path
            self.cost = distances[dest]

            self.color_path = []
            path = path[::-1] # Reverse array
            # Color code
            for i in range(len(path)):
                parent = path[i]
                try:
                    child = path[i+1]
                except: 
                    break
                    
                colors = self.graph_color[parent][child]
                if len(colors) == 2:
                    for color in colors:
                        self.color_path.append(color)
                else:
                    self.color_path.append(colors)
        else:
            # if it is the initial  run, initializes the cost
            if not visited:
                distances[src] = 0
            # visit the neighbors
            for neighbor in graph[src]:
                if neighbor not in visited:
                    new_distance = distances[src] + graph[src][neighbor]
                    if new_distance < distances.get(neighbor, float('inf')):
                        distances[neighbor] = new_distance
                        predecessors[neighbor] = src
            # mark as visited
            visited.append(src)
            # now that all neighbors have been visited: recurse
            # select the non visited node with lowest distance 'x'
            # run Dijskstra with src='x'
            unvisited = {}
            for k in graph:
                if k not in visited:
                    unvisited[k] = distances.get(k, float('inf'))
            x = min(unvisited, key=unvisited.get)
            self.dijkstra(x, dest, False, visited, distances, predecessors)


'''
Example code
'''
if __name__ == "__main__":

    nodes = ['Depot', 'In__D', 'Out_D', 'PD__1', 'In__1', 'Out_1', 'PD_21', 'In__2', 'Out_2', 'NS_Ex', 'In__3', 'PD__3', 'Out_3', 'EW_Ex', 'PD_41', 'In__4', 'Out_4', 'PD_22', 'PD_42']
    combs = combinations(nodes, 2)

    for node1,node2 in combs:
        dsp = DijkstraShortestPath()
        dsp.dijkstra(node1, node2, True)
        path = dsp.get_path()
        cost = dsp.get_cost()
        color_path = dsp.get_color_path()
        print('shortest path - array: ' + str(path))
        print('color path - array: ' + str(color_path))
        print("cost=" + str(cost))
        print(node1 + ' -----> ' + node2)
