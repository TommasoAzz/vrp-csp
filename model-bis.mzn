% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin

include "alldifferent_except_0.mzn";
include "path.mzn";
include "among.mzn";
include "cumulative.mzn";
include "at_most.mzn";

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

% Variables and variable-related constants
int: num_nodes = n+2; % There are n customers and one depot. The depot is split into the depot starting point (n+1) and the depot finishing point (n+2).

array [1..n+1, 1..n+1] of var int: distances; % Distances between locations.

array[1..num_nodes, dom_veh] of var 1..num_nodes: next;

% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).

% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.

% NEW CONSTRAINT
constraint forall(j in dom_veh)(next[n+2, j] = n+1); % Linking between an end visit by a vehicle to the next start visit from another vehicle (part 1)

% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

% Problem constraints
% NEW
constraint alldifferent_except([next[i,j] | i in 1..num_nodes, j in dom_veh], {n+1, n+2})::domain;

% NEW
constraint at_most(NumVehicles, [{next[i,j]} | i in 1..num_nodes, j in dom_veh], {n+1})::domain;

constraint at_most(NumVehicles, [{next[i,j]} | i in 1..num_nodes, j in dom_veh], {n+2})::domain;

% Objective values
% > Distance
0..10: total_distance_weigth = 10;
% > Vehicles
0..10: used_vehicles_weigth = 0;

% Output
% > Input data and output of the problem (objective function)
output [
"Dataset: \(Name)\n",
"------------------\n",
"Total number of customers: \(n)\n",
"Depot coordinates: (\(locX[n+1]), \(locY[n+1]))\n",
% "Total distance travelled by vehicles: \(total_distance)\n",
% "Number of vehicles that were moved: \(used_vehicles)\n"
];

output ["\n"];

output ["Distances between nodes\n"];
output ["\(i) -> \(j) = " ++ "\(distances[i,j])\n" | i,j in 1..n+1 where i<j];

output ["\n"];

output[
"Vehicle " ++ show_int(3, v) ++ " with capacity: " ++ show_int(3, Capacity[v]) ++ "\n" ++ 
"------------------------------\n" ++
% "- served customers: " ++ show([k | k in 1..n where visited_nodes[v, k]]) ++ "\n" ++ 
"- passed through:\n\t- " ++ 
% show(["\(starting_points[k]) -> \(ending_points[k])" | k in 1..num_edges where visited_edges[v, k]]) ++
"\n\n" | v in dom_veh
]
