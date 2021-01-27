# Vehicle Routing Problem in CSP
# ------------------------------
# Marco Ferrati, Tommaso Azzalin

import minizinc
from datetime import timedelta
from sys import argv

# Time limits for running the problem and getting more interesting statistics.
if '-t' in argv:
    time_limits = [int(argv[argv.index('-t') + 1])]
else:
    time_limits = [10, 30, 60, 120, 300, 600]

# Test datasets for the model
if '-d' in argv:
    datasets = [argv[argv.index('-d') + 1]]
else:
    datasets = ["example", "mini-example", "pr01", "pr02", "pr03", "pr04", "pr05", "pr06", "pr07", "pr08", "pr09", "pr10", "pr11"]

# Search strategies
search_strategies = [
    "",
    "::int_search(next, dom_w_deg, indomain_random) :: restart_luby(10)"
]
if '-s' in argv:
    search_strategies = [search_strategies[int(argv[argv.index('-s') + 1])]]


print("----------\nVRP Script\n----------\n")

# MiniZinc parameters
gecode = minizinc.Solver.lookup("gecode")

for search_strategy in search_strategies:
    model = minizinc.Model("./model.mzn")
    model.add_string("solve {} minimize obj_f;".format(search_strategy))
    print("-------------------------------------------")
    print("Search strategy: ", search_strategy)
    print("-------------------------------------------\n")
    for time_limit in time_limits:
        print("-------------------------------------------")
        print("Time limit for executing set to {} seconds".format(time_limit))
        print("-------------------------------------------\n")
        for dataset in datasets:
            instance = minizinc.Instance(gecode, model)
            instance.add_file("./instances/{}.dzn".format(dataset))

            result = instance.solve(timeout=timedelta(seconds=time_limit))
            print("Instance: ", dataset)
            print("---------------------------")
            keys = result.statistics.keys()
            print("Solve time: ", result.statistics['time'].total_seconds() if 'time' in keys else "Not available.")
            print("Failures: ", result.statistics['failures'] if 'failures' in keys else "Not available.")
            print("Restarts: ", result.statistics['restarts'] if 'restarts' in keys else "Not available.")
            print("---------------------------")
            if result.status.has_solution():
                variables = str(result.solution).split("\n")
                print("next: ", variables[0])
                print("vehicle: ", variables[1])
                print("used_vehicles: ", variables[2])
                print("total_distance: ", variables[3])
                print("obj_f: ", variables[4], "\n")
            else:
                print("No solutions were found (", result.status, ")\n")
