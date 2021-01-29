# Vehicle Routing Problem in CSP
# ------------------------------
# Marco Ferrati, Tommaso Azzalin

import minizinc
from datetime import timedelta
from sys import argv

file = open('output.txt', mode="w+")
def print_both(*lines):
    global file
    for l in lines:
        print(l, end="")
        file.write(str(l))
    print("\n")

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
    "::int_search(next, dom_w_deg, indomain_random)",
    "::int_search(next, smallest, indomain_random)",
    "::int_search(next, first_fail, indomain_min)",
    "::int_search(next, dom_w_deg, indomain_random) ::restart_luby(250)",
    "::int_search(next, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next, 85)",
    "::int_search(next, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next, 15)",
    "::int_search(next, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next, 75)",
    "::int_search(next, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next, 25)",
]
if '-s' in argv:
    search_strategies = [search_strategies[int(argv[argv.index('-s') + 1])]]

print_both("----------\nVRP Script\n----------\n")

# MiniZinc parameters
gecode = minizinc.Solver.lookup("gecode")

for search_strategy in search_strategies:
    model = minizinc.Model("./model.mzn")
    model.add_string("solve {} minimize obj_f;".format(search_strategy))
    print_both("-------------------------------------------")
    print_both("Search strategy: ", search_strategy if search_strategy != "" else "default")
    print_both("-------------------------------------------\n")
    for time_limit in time_limits:
        print_both("-------------------------------------------")
        print_both("Time limit for executing set to {} seconds".format(time_limit))
        print_both("-------------------------------------------\n")
        for dataset in datasets:
            instance = minizinc.Instance(gecode, model)
            instance.add_file("./instances/{}.dzn".format(dataset))

            result = instance.solve(timeout=timedelta(seconds=time_limit))
            print_both("Instance: ", dataset)
            print_both("---------------------------")
            keys = result.statistics.keys()
            print_both("Solve time: ", result.statistics['time'].total_seconds() if 'time' in keys else "Not available.")
            print_both("Failures: ", result.statistics['failures'] if 'failures' in keys else "Not available.")
            print_both("Restarts: ", result.statistics['restarts'] if 'restarts' in keys else "Not available.")
            print_both("---------------------------")
            if result.status.has_solution():
                variables = str(result.solution).split("\n")
                print_both("next: ", variables[0])
                print_both("vehicle: ", variables[1])
                print_both("used_vehicles: ", variables[2])
                print_both("total_distance: ", variables[3])
                print_both("obj_f: ", variables[4], "\n")
            else:
                print_both("No solutions were found (", result.status, ")\n")

file.close()