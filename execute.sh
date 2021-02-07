#! /usr/local/bin/zsh

killall minizinc

#search_strategies=(" " "::int_search(next++vehicle, dom_w_deg, indomain_random)"  "::int_search(next++vehicle, dom_w_deg, indomain_random) ::restart_luby(250)" "::int_search(next++vehicle, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next++vehicle, 85)" "::int_search(next++vehicle, dom_w_deg, indomain_random) ::restart_luby(250) ::relax_and_reconstruct(next++vehicle, 15)" "::int_search(vehicle ++ next, first_fail, indomain_min)")

search_strategies=(" ")

instances=("instances/pr01.dzn" "instances/pr02.dzn" "instances/pr03.dzn" "instances/pr04.dzn" "instances/pr05.dzn" "instances/pr06.dzn" "instances/pr07.dzn" "instances/pr08.dzn" "instances/pr09.dzn")

times=(30 60 120 300)

for instance in $instances
do
    for search_strategy in $search_strategies
    do
        echo "solve $search_strategy minimize obj_f;" | tee -a model.mzn > /dev/null
        for time in $times
        do
            echo "--INSTANCE: ${instance}--\n--SEARCH STRATEGY: ${search_strategy}--\n--TIME: ${time}--\n"

            echo "--INSTANCE: ${instance}--\n--SEARCH STRATEGY: ${search_strategy}--\n--TIME: ${time}--\n
            $(timeout -s SIGINT ${time}s minizinc -a -s model.mzn $instance)\n\n" >> result7.txt
        done
        sed -i '' -e '$ d' model.mzn
    done
done
