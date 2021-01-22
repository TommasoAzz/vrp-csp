% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin

include "alldifferent_except.mzn";
include "globals.mzn";

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
% > Distances between nodes
array [1..n+1, 1..n+1] of var int: distances; % Distances between locations.

% > Decision variables and sets
set of int: dom_nodes = 1..n+2*NumVehicles; % Customers indexes lie between 1..n; depot entrances and exits lie between [n+1, n+2*NumVehicles].
array [dom_nodes] of var dom_nodes: next; % For all i in dom_nodes (visit indexes), next[i] corresponds to the node that is visited after node i, that is next[i].
% Note that the depot assumes multiple values.
array [dom_nodes] of var dom_veh: vehicle; % For all i in dom_nodes (visit indexes), vehicle[i] corresponds to the vehicle that performs the i-th visit to node visit[i].


% Functions
function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
  round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000); % Calculates Euclidean distance between two points (x1,y1) and (x2,y2).


% Initialization constraints
constraint forall(c1, c2 in 1..n+1 where c1 <= c2)(if(c1 < c2) then distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]) else distances[c1, c2] = 0 endif); % Computes the distances between customers (and of course customers and depot). Only the lower triangular matrix is sufficient to compute.


% Implied constraints
constraint sum([d | d in Demand]) <= sum([c | c in Capacity]); % The sum of the customers' demands must be lesser or equal than the available capacity of the vehicles otherwise the problem is unsatisfiable.


% Problem constraints
constraint alldifferent(next)::domain; % All nodes must be different, note that depot has multiple values

constraint forall(i in n+1..max(dom_nodes)-1)(
  if(n mod 2 == 0) then % se il numero di customer è pari allora le partenze dei veicoli avvengono da depot di index dispari e gli arrivi da depot di index pari
    if(i mod 2 == 0) then
      next[i] = i+1
    else
      next[i] = i+1 \/ (1 <= next[i] /\ next[i] <= n)
    endif
  else
    if(i mod 2 != 0) then
      next[i] = i+1
    else
      next[i] = i+1 \/ (1 <= next[i] /\ next[i] <= n)
    endif
  endif
);

constraint forall(i in dom_nodes)(next[i] != i);

constraint next[max(dom_nodes)] == n+1;

output [show(next)];