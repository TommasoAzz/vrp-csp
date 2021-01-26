import minizinc
from datetime import timedelta

datasets = ["example", "mini-example", "pr01", "pr02", "pr03", "pr04", "pr05", "pr06", "pr07", "pr08", "pr09", "pr10", "pr11"]

model = minizinc.Model("./model.mzn")

gecode = minizinc.Solver.lookup("gecode")

instance = minizinc.Instance(gecode, model)
for dataset in datasets:
    instance = minizinc.Instance(gecode, model)
    instance.add_file("./instances/{}.dzn".format(dataset))

    result = instance.solve(timeout=timedelta(seconds=3))
    print("Instance: ", dataset)
    print("***")
    print("Solve time: ", result.statistics['time'].total_seconds())
    print("Failures: ", result.statistics['failures'])
    print("Restarts: ", result.statistics['restarts'])
    print("---")
    if result.status.has_solution():
        print("Next: ", str(result.solution).split("\n")[0])
        print("Vehicle: ", str(result.solution).split("\n")[1])
        print("Used vehicles: ", str(result.solution).split("\n")[2])
        print("Total distance: ", str(result.solution).split("\n")[3])
    else:
        print("No solutions were found: ", result.status)
    print("+++")
