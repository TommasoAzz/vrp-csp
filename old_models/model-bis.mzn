% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin

include "alldifferent_except_0.mzn";
include "alldifferent_except.mzn";
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
int: num_nodes = n+1; % There are n customers and one depot. The depot is split into the depot starting point (n+1) and the depot finishing point (n+2).

array [1..n+1, 1..n+1] of var int: distances; % Distances between locations.

array [dom_veh] of var 1..num_nodes: next_after_start; % The first node that is visited after a vehicle has left the depot.
% TODO: Creare la variante di next_after_start con dominio 1..n+1 (n+2 è ridondante forse)

array [1..n] of var 1..num_nodes: next; % next[i] = n <-> some vehicle visits node n after visiting node i.

array [1..n] of var dom_veh: visit; % visit[i] = v <-> node i is visited by vehicle v.

array [1..n] of var bool: visited_nodes; % visited_nodes[i] <-> i in next_after_start \/ i in next.

% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).

% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.

% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

% Problem constraints
constraint alldifferent_except(next_after_start, {n+1})::domain;

constraint forall(i in 1..n)(next[i] != i); % After visiting i a vehicle cannot visit i again.

% TODO: Remove this constraint.
% constraint forall(v in dom_veh)(next_after_start[v] != n+1); % After leaving the depot entry vehicle v cannot go to the vehicle entry.

constraint alldifferent_except(next, {n+1})::domain;

constraint forall(i in 1..n)(visited_nodes[i]); % Every nodes must be visited

constraint forall(i in 1..n)(visited_nodes[i] <-> (count(next, i) + count(next_after_start, i) == 1));

constraint count(next, n+1) == sum(v in dom_veh)(next_after_start[v] != n+1);

constraint forall(v in dom_veh)(sum([Demand[i] | i in 1..n where visit[i] == v]) <= Capacity[v]);

% constraint forall(i in 1..n, v in dom_veh)(visit[i] = v <-> next_after_start[v] = i);


% Objective values
% > Distance
0..10: total_distance_weigth = 10;
% > Vehicles
0..10: used_vehicles_weigth = 0;

output["next_after_start" ++ show(next_after_start)];

output ["\n"];

output["next" ++ show(next)];

output ["\n"];

output["visit" ++ show(visit)]