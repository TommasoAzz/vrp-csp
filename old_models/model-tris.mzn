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

array [1..n+1, dom_veh] of var 0..n+1: next; % next[i, j] = n <-> n is the next visit of vehicle j after visiting node i 
array [1..n, dom_veh] of var 0..2: visited;

constraint forall(v in dom_veh, i in 1..n)(
  if next[i, v] != 0 /\ visited[i, v] == 0 /\ visited[next[i,v], v] == 0 then
    visited[i, v] = 1
  else if visited[next[i, v], v] == 1 then
    visited[i, v] = 2
    endif
  endif
);

% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).

% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.

% Objective values
% > Distance
0..10: total_distance_weigth = 10;
var int: total_distance = sum(v in dom_veh, i in 1..n+1 where next[i,v] != 0)(distances[i,next[i,v]]); % Total distance travelled by the vehicles.
% > Vehicles
0..10: used_vehicles_weigth = 0;
var int: used_vehicles = NumVehicles - count([next[n+1, v] | v in dom_veh], n+1); % Total number of vehicles that leave the depot.
% > Function to minimize
var int: obj_f = total_distance_weigth * total_distance + used_vehicles_weigth * used_vehicles;

% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.

% Problem constraints

% Every vehicles must either leave the depot or stay in it
constraint alldifferent_except([next[n+1, v] | v in dom_veh], {n+1})::domain; % From the depot every vehicles leaves for one node (can go to the end-depot)
constraint among(0, [next[n+1, v] | v in dom_veh], {0})::domain; % 0 is not allowed in this row since every vehicle must do something

% A node must be visited exactly from one vehicle
constraint forall(i in 1..n)(
  among(NumVehicles-1, [next[i, v] | v in dom_veh], {0})::domain
);

% A node can be visited only once
constraint global_cardinality(array1d(next), set2array(1..n), [1 | i in 1..n])::domain;  
%constraint forall(v in dom_veh)(
%  alldifferent_except_0([next[i, v] | i in 1..n+1])
%);

% The matrix can't have repeated elements except for 0 and for n+1 (the depot)
%constraint alldifferent_except(array1d(next), {0, n+1});

% In the matrix there must be exactly NumVehicles visits to the depot
constraint among(NumVehicles, array1d(next), {n+1})::domain;
/*
constraint forall(i in 1..n+1, v in dom_veh)(
  (next[i, v] > 0 <-> next[next[i, v], v] > 0) /\ %if vehicle v vists node i then the same vehicle must visit next[i, v]
  (next[next[i, v], v] = i -> count([next[j, v] | j in 1..n+1], 0) == n-1) /\
  next[i, v] != i % After visiting a node, next[i, v] can't be the same node
);
*/
constraint forall(i in 1..n+1, v in dom_veh)(
  (next[i, v] > 0 <-> next[next[i, v], v] > 0) 
); %if vehicle v visits node i then the same vehicle must visit next[i, v]
/*
constraint forall(i in 1..n+1, v in dom_veh)(
  next[next[i, v], v] = i -> among(n-1, [next[j, v] | j in 1..n+1], {0})::domain 
); % if vehicle v visits just one node and then come back then number of 0 must be n-1
*/
constraint forall(v in dom_veh)((next[next[n+1, v], v] = n+1 /\ next[n+1, v] != n+1) <-> among(n-1, [next[j, v] | j in 1..n], {0})::domain);

constraint forall(v in dom_veh)(next[n+1, v] = n+1 <-> among(n, [next[j, v] | j in 1..n], {0})::domain);

constraint forall(i in 1..n/*+1*/, v in dom_veh)(
  next[i, v] != i
); % After visiting a node, next[i, v] can't be the same node

%constraint next[n+1, 2] = n+1;

% TODO: constraint to allow vehicles not to leave the depot.

% TODO: constraint to deny inner loops in nodes between [1,n].

constraint among(0, array1d(visited), {2})::domain;

constraint forall(v in dom_veh)(sum(i in 1..n where next[i,v] > 0)(Demand[i]) <= Capacity[v]); % Each vehicle can visit only nodes that do not exceed its capacity.

int: num_edges = round(((num_nodes * n) / 2)); % Total numbers of possible edges in a complete graph.

array[int] of int: starting_points = [i | i in 1..n, j in 1..n where i <= j]; % Edges' starting points.
array[int] of int: ending_points = [j | i in 1..n, j in 2..n+1 where i < j]; % Edges' finishing points.

array[dom_veh, 1..num_nodes] of var bool: visited_nodes; % visited_nodes[i,j] <-> vehicle i visites customer j
array[dom_veh, 1..num_edges] of var bool: visited_edges; % visited_edges[i,l] <-> vehicle i pass through edge l

constraint forall(i in 1..n, v in dom_veh)(
  next[i,v] > 0 <-> (visited_nodes[v,i] /\ visited_nodes[v, next[i,v]] /\ visited_edges[v, i * (next[i,v] - 1)])
);

constraint forall(v in dom_veh)(
  let {
    array[1..num_nodes] of var bool: v_nodes = [visited_nodes[v, j] | j in 1..num_nodes];
    array[1..num_edges] of var bool: v_edges = [visited_edges[v, j] | j in 1..num_edges];
  } in 
  forall(i in 1..n+1 where next[i,v] > 0)(
    path(starting_points, ending_points, i, n+1, v_nodes, v_edges)::domain
  )
);

output ["\(starting_points[i]) " | i in 1..num_edges];
output ["\n"];
output ["\(ending_points[i]) " | i in 1..num_edges];
output ["\n"];



% Solving configuration
% solve minimize obj_f;

output ["  1:"];
output [
  if (v mod NumVehicles == 0) then 
    show_int(3, next[i, v]) ++ "\n" ++ (if(i <= n) then show_int(3, i+1) ++ ":" else "" endif)
  else
    show_int(3, next[i, v]) ++" "
  endif | i in 1..n+1, v in dom_veh
];