# vrp-csp
Solution to the Constraint Satisfaction Problem "Vehicle Routing Problem".

## What main.py does
Executes the model written in `model.mzn` with gecode solver for all the instances available in `instances/`. Every instance is executed for 10s, 30s, 1m, 2m, 5m and 10m.

## Install MiniZinc-python
1. [Optional] Create a virtual environment with virtualenv and activate it;
2. Install the requirements with `pip install -r requirements.txt`

## Execute the Python script
```bash
python main.py [-d dataset name] [-t time-limit in seconds] [-s index of the heuristic]
```

### Optional arguments
1. Dataset name choose between:
    - example
    - mini-example
    - pr01
    - pr02
    - pr03
    - pr04
    - pr05
    - pr06
    - pr07
    - pr08
    - pr09
    - pr10
    - pr11
2. Time limit in seconds
3. Index of the search strategy:
    - 0 - Default search

