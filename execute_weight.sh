#! /usr/local/bin/zsh
killall minizinc

instances=("pr05.dzn")

distance_weights=(10 7 5 3 0)
vehicles_weights=(0 3 5 7 10)

for instance in $instances
do
    for i in {1..5}
    do
        echo "0..10: total_distance_weight = ${distance_weights[i]};" | tee -a model.mzn > /dev/null
        echo "0..10: used_vehicles_weight = ${vehicles_weights[i]};" | tee -a model.mzn > /dev/null
        echo "--INSTANCE: ${instance}--\n--DISTANCE WEIGHT: ${distance_weights[i]}--\n--VEHICLES WEIGHT: ${vehicles_weights[i]}--\n"

        echo "--INSTANCE: ${instance}--\n--DISTANCE WEIGHT: ${distance_weights[i]}--\n--VEHICLES WEIGHT: ${vehicles_weights[i]}--\n$(timeout -s SIGINT 300s minizinc -a -s model.mzn instances/${instance})\n\n" >> checks/${instance}.txt
        sed -i '' -e '$ d' model.mzn
        sed -i '' -e '$ d' model.mzn
    done
done
