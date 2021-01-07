% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin

include "alldifferent_except_0.mzn";
include "path.mzn";

% Parameters
% > Dataset name
string: Name; % Dataset name.
% > Customers
array[int] of int: Demand; % Demand of customer i, i in 1..n (n is defined later).
int: n = length(Demand); % Total number of customers. The n+1 customer is the depot.

array[1..n+1] of float: locX; % Coordinate X of the n locations and the only depot.
array[1..n+1] of float: locY; % Coordinate Y of the n locations and the only depot.

% > Vehicles
int: NumVehicles; % Total number of available vehicles.
set of int: dom_veh = 1..NumVehicles; % Domain of vehicles.
array [dom_veh] of int: Capacity; % Capacity of vehicle j, j in dom_veh.

% Variables
array [1..n+1, 1..n+1] of var int: distances; % Distances between locations.
array [1..n+2, dom_veh] of var 0..n+2: routes; % routes[i,j] <-> vehicle j visited customer i as the (routes[i,j])-th visit %TODO: serve?

% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).

% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.

constraint forall(i in 1..n+2, j in dom_veh)(if(i == n+1) then routes[i,j] = 1 else routes[i,j] = 0 endif); % All vehicles start their route from the depot (aka customer n+1); if routes[i,j] is zero it means that vehicle j did not visit customer i.

constraint forall(i in 1..n)(alldifferent_except_0([routes[i,j] | j in dom_veh])::domain); % Only a vehicle can visit a customer (Hamiltonian cycle condition).

% Implied constraints
constraint sum(d in Demand)(d) <= sum(c in Capacity)(c); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

% Problem constraints

int: num_nodes = n+2; % There are n customers and one depot. The depot is split into the depot starting point (n+1) and the depot finishing point (n+2).
int: num_edges = round(((num_nodes*(num_nodes-1))/2))-1; % Total numbers of possible edges in a complete graph. The "-1" removes the edge (n+1,n+2) between the depot starting and finishing points, since it is the same node.
array[int] of int: starting_from = [i | i in 1..n+2, j in 1..n+1 where (i<=j /\ i != n+1)]; % Edges' starting points.
array[int] of int: ending_to = [j | i in 1..n+2, j in 1..n+2 where (i<j /\ i != n+1)]; % Edges' finishing points.

array[dom_veh, 1..num_nodes] of var bool: visited_nodes; % visited_nodes[i,j] <-> vehicle i visites customer j
array[dom_veh, 1..num_edges] of var bool: visited_edges; % visited_edges[i,l] <-> vehicle i pass through edge l

constraint forall(node in 1..n)(
  sum(vehicle in dom_veh)(visited_nodes[vehicle, node]) == 1
); % Ensures that a node (customer) is visited by just one vehicle.

constraint forall(v in dom_veh) (
  path(num_nodes, num_edges, starting_from, ending_to, n+1, n+2, [visited_nodes[v, i] | i in 1..num_nodes], [visited_edges[v, i] | i in 1..num_edges])
); % Finds a path for each vehicle v starting from n+1 (depot starting point) and ending into n+2 (depot ending point).

constraint forall(v in dom_veh) (
  sum(node in 1..n where visited_nodes[v, node]) (Demand[node]) <= Capacity[v]
); % Ensures that capacity of a vehicle v is not exceeded in its path.


var int: obj = sum(v in dom_veh, e in 1..num_edges where visited_edges[v, e])(
  distances[
    if starting_from[e] == n+2 then n+1 else starting_from[e] endif,
    if ending_to[e] == n+2 then n+1 else ending_to[e] endif
  ]
);

% Output
% > Input data and output of the problem (objective function)
output [
"Dataset: \(Name)\n",
"------------------\n",
"Total number of customers: \(n)\n",
"Depot coordinates: (\(locX[n+1]), \(locY[n+1]))\n",
"Total distance travelled by vehicles: \(obj)\n",
];

output ["\n"];

output ["Distances between nodes\n"];
output ["\(i) -> \(j) = " ++ "\(distances[i,j])\n" | i,j in 1..n+1 where i<j];

output ["\n"];

output[
"Vehicle " ++ show_int(3, v) ++ " with capacity: " ++ show_int(3, Capacity[v]) ++ "\n" ++ 
"------------------------------\n" ++
"- served customers: " ++ show([k | k in 1..n where visited_nodes[v, k]]) ++ "\n" ++ 
"- passed through:\n\t- " ++ 
show(["\(starting_from[k]) -> \(ending_to[k])" | k in 1..num_edges where visited_edges[v, k]]) ++
"\n\n" | v in dom_veh
]
