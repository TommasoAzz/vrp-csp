% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin
include "globals.mzn";
include "alldifferent_except.mzn";

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
int: num_nodes = n+1; % There are n customers and one depot. The depot is split into the depot starting point (n+1) and the depot finishing point (n+2).

array [1..n+1, 1..n+1] of var int: distances; % Distances between locations.

array [1..n+1, dom_veh] of var 0..n+1: next;


% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).

% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.

% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

% Problem constraints

% Every vehicles must either leave the depot or stay in it
constraint alldifferent_except([next[n+1, v] | v in dom_veh], {n+1}); % From the depot every vehicles leaves for one node (can go to the end-depot)
constraint among(0, [next[n+1, v] | v in dom_veh], {0}); % 0 is not allowed in this row since every vehicle must do something

% A node must be visited exactly from one vehicle
constraint forall(i in 1..n)(
  among(NumVehicles-1, [next[i, v] | v in dom_veh], {0})
);

% A vehicle can vist a node only once
constraint forall(v in dom_veh)(
  alldifferent_except_0([next[i, v] | i in 1..n+1])
);

% The matrix can't have repeated elements except for 0 and for n+1 (the depot)
constraint alldifferent_except(array1d(next), {0, n+1});

% In the matrix there must be exactly NumVehicles visits to the depot
constraint among(NumVehicles, array1d(next), {n+1});

constraint forall(i in 1..n+1, v in dom_veh)(
  (next[i, v] > 0 <-> (next[next[i, v], v] > 0 /\ next[next[i, v], v] != i)) /\ %if vehicle v vists node i then the same vehicle must visit next[i, v]
  next[i, v] != i % After visiting a node, next[i, v] can't be the same node
);


% Objective values
% > Distance
0..10: total_distance_weigth = 10;
% > Vehicles
0..10: used_vehicles_weigth = 0;
output["  1:"];
output [if (v mod NumVehicles == 0) then show_int(3, next[i, v]) ++ "\n"++ show_int (3, i+1)++":" else show_int(3, next[i, v]) ++" " endif | i in 1..n+1, v in dom_veh];