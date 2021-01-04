% Vehicle Routing Problem in CSP
% Marco Ferrati, Tommaso Azzalin

% Parameters
% > Dataset name
string: Name; % Dataset name.
% > Customers
array[int] of int: Demand; % Demand of customer i, i in 1..n (n is defined later).
array[int] of float: locX; % Coordinate X of the locations.
array[int] of float: locY; % Coordinate Y of the locations.

var int: n = length(Demand); % Total number of customers. The n+1 customer is the depot.

% > Vehicles
int: NumVehicles; % Total number of available vehicles.
array [1..NumVehicles] of int: Capacity; % Capacity of vehicle j, j in 1..NumVehicles.

% Variables
array [int, int] of var int: distances; % Distances between locations.

% Functions
% function int: calculate_distance(float: x1, float: y1, float: x2, float: y2) =
%   round(sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2)) * 1000);

% Initialization constraints
% constraint forall(c1, c2 in 1..n where c1 < c2)(distances[c1, c2] = calculate_distance(locX[c1], locY[c1], locX[c2], locY[c2]));

output [
"Dataset: \(Name)\n",
"Total number of customers: \(n)\n"
];