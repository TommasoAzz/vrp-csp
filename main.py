# Vehicle Routing Problem in CSP
# ------------------------------
# Marco Ferrati, Tommaso Azzalin

import minizinc
from datetime import timedelta

# Time limits for running the problem and getting more interesting statistics.
time_limits = [10, 30, 60, 120, 300, 600]

# Test datasets for the model
datasets = ["example", "mini-example", "pr01", "pr02", "pr03", "pr04", "pr05", "pr06", "pr07", "pr08", "pr09", "pr10", "pr11"]

print("----------\nVRP Script\n----------\n")

# MiniZinc parameters
model = minizinc.Model("./model.mzn")
gecode = minizinc.Solver.lookup("gecode")

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
            print("total_distance: ", variables[3], "\n")
        else:
            print("No solutions were found (", result.status, ")\n")
