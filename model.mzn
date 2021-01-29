% Vehicle Routing Problem in CSP
% ------------------------------
% Marco Ferrati, Tommaso Azzalin

include "globals.mzn";

% Parameters
% > Dataset name
string: Name; % Dataset name.

% > Customers
array[int] of int: Demand; % Demand of customer i, i in 1..n (n is defined later).
int: n = length(Demand); % Total number of customers. The n+1 customer is the depot.
array[1..n+1] of float: locX; % Coordinate X of the n locations and of the only depot.
array[1..n+1] of float: locY; % Coordinate Y of the n locations and of the only depot.

% > Vehicles
int: NumVehicles; % Total number of available vehicles.
set of int: dom_veh = 1..NumVehicles; % Domain of vehicles.
array [dom_veh] of int: Capacity; % Capacity of vehicle j, j in dom_veh.

% > Nodes
% Note: the depot is viewed (therefore exists in the array next and vehicle) not once but 2 times for each vehicle, therefore 2*NumVehicles times in total.
% 2 times for each vehicle means that a depot has always a "start-trip-exit" (node i) and "end-trip-entrance" (node i+1).
set of int: dom_nodes = 1..n+2*NumVehicles; % Customer indexes lie between 1 and n; depot entrances and exits lie between [n+1, n+2*NumVehicles].


% Variables
% > Distances (once set, they never change)
array [dom_nodes, dom_nodes] of var int: distances; % distances[i,j] = x <-> node i is distant x to node j. Only the upper triangular matrix is populated.

% > Decision variables and sets
array [dom_nodes] of var dom_nodes: next; % next[i] = n <-> node n is visited after node i.

array [dom_nodes] of var dom_veh: vehicle; % vehicle[i] = v <-> vehicle v visits node i.

array[1..n, 1..n] of var bool: visited_edges;

array[dom_veh, 1..n] of var bool: visited_customers;


% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates the Euclidean distance (rounded to nearest int and multiplied by 1000) between two points (x1,y1) and (x2,y2).


% Initialization constraints
constraint forall(c1, c2 in dom_nodes where c1 < c2)(
  if c1 <= n then
    if c2 <= n+1 then
      distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2])
    else
      distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[n+1], locY[n+1])
    endif
  else
    if c2 > n+1 then
      distances[c1, c2] = 0
    endif
  endif
); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.


% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

constraint alldifferent(next)::domain; % All nodes must be visited exactly once (note: the depot is considered as multiple nodes and with an entrance and an exit, therefore all these parts have to be visited once too).

constraint forall(i in dom_nodes)(next[i] != i); % After visiting node i the next visit cannot be to node i.

% Problem constraints
constraint forall(i in n+1..max(dom_nodes)-1)(
    % Remember the depot is viewed (therefore exists in the array next) not once but 2*NumVehicles times.
    if((n mod 2 == 0 /\ i mod 2 == 0) \/ (n mod 2 != 0 /\ i mod 2 != 0)) then
        % After a visit to the "end-trip-entrance" the following visit must be to the following "start-trip-exit". 
        next[i] = i+1
    else
        % After a visit to the "start-trip-exit" the following visit must be to the following "end-trip-entrance"
        % or to a node "customer".
        next[i] = i+1 \/ (1 <= next[i] /\ next[i] <= n)
    endif
);

constraint next[max(dom_nodes)] == n+1; % After a visit to the last "end-trip-entrance" the following visit must be to the first "start-trip-exit".

constraint circuit(next)::domain; % Ensures next represent a feasible TSP solution.

constraint let {
  set of int: customers_start_trip_exit_depot = (1..n union {j | j in n+1..max(dom_nodes) where if (n+1) mod 2 == 0 then j mod 2 == 0 else j mod 2 != 0 endif});
} in forall(i in customers_start_trip_exit_depot)(
  % The vehicle visiting node i must also visit node next[i].
  % This is true since the constraint applies only to customers and "start-trip-exit" nodes.
  vehicle[i] = vehicle[next[i]] 
);

constraint global_cardinality([vehicle[i] | i in n+1..max(dom_nodes)], dom_veh, [2 | i in dom_veh])::domain; % Each vehicle must leave once from the depot and come back once. Note: vehicles that do not move still fakely move twice (because of how depot is regarded).

constraint forall(v in dom_veh)(
  sum([Demand[i] | i in 1..n where vehicle[i] == v]) <= Capacity[v] % Each vehicle supplies only customers that do not exceed (in total) its capacity.
);


% Symmetry breaking 
constraint increasing([vehicle[i] | i in n+1..max(dom_nodes)])::domain; % Couples of depot nodes ("start-trip-exit" and "end-trip-entrance") are assigned in order (the first goes to the first vehicle, etc.).

constraint forall(i, j in 1..n)(visited_edges[i,j] <-> next[i] = j); % Channeling between next and visited_edges.

constraint lex_lesseq(array1d(visited_edges), [visited_edges[j, i] | i, j in 1..n]); % Leaving the depot for visiting some edges and then going back to the depot or leaving it for visiting the same edges in the opposite order is the same, therefore one of the two routes is discarded.

constraint forall(v in dom_veh, i in 1..n)(visited_customers[v, i] <-> vehicle[i] = v); % Channeling between vehicle and visited_customers.

constraint forall(c in array2set(Capacity))(
  let {
    array[int] of dom_veh: vehicles_with_same_capacity = [v | v in dom_veh where Capacity[v] = c]
  } in forall(v in 1..length(vehicles_with_same_capacity)-1)(
    lex_lesseq([visited_customers[v, i] | i in 1..n], [visited_customers[v+1, i] | i in 1..n])
  )
); % Since vehicle can have the same capacity and therefore serve the same nodes, a lex_lesseq is posted to avoid this possibility.

% Objective values
var int: total_distance = sum(i in dom_nodes)(
  % The matrix distances is upper triangular.
  if i < next[i] then distances[i, next[i]] else distances[next[i], i] endif  
); % Total distance travelled by the vehicles.
0..10: total_distance_weight = 10; % Total distance weight in the objective function (it should be from 0.0 to 1.0 but MiniZinc has problems with that).

var int: used_vehicles = nvalue([vehicle[i] | i in 1..n]); % Total number of vehicles that leave the depot.
0..10: used_vehicles_weight = 0; % Used vehicles weight in the objective function (it should be from 0.0 to 1.0 but MiniZinc has problems with that).

% Objective function
var int: obj_f = total_distance_weight * total_distance + used_vehicles_weight * used_vehicles;

% Solving settings and heuristics
solve minimize obj_f;

/*
% FANCY OUTPUT FOR MINIZINC IDE AND CLI
% Decomment this block and make sureto comment the next one for a fancy output of solutions in MiniZinc IDE or MiniZinc CLI.
output [
"Dataset: \(Name)\n",
"---------------------------\n",
"Total number of customers: \(n)\n",
"Depot coordinates: (\(locX[n+1]), \(locY[n+1]))\n",
"Total distance travelled by vehicles: \(total_distance)\n",
"Number of vehicles that were moved: \(used_vehicles)/\(NumVehicles)\n"
];

output [
"Vehicle \(v) has visited customers: " ++ show([i| i in 1..n where vehicle[i] = v]) ++ "\n" | v in dom_veh
];
*/


% OUTPUT FOR MiniZinc Python API
% Decomment this block and make sure FANCY OUTPUT FOR MINIZINC IDE AND CLI is commented to print solutions for the Python script (main.py).
output[show(next)++"\n"];
output[show(vehicle)++"\n"];
output["\(used_vehicles)\n"];
output["\(total_distance)\n"];
output["\(obj_f)"];