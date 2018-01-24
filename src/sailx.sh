#!/bin/bash

echo "Unique data generation"
julia generate_data.jl --num 15000 --folder ../unique_sailx/ --unique --tasks turn_to_x --seed 123789
julia generate_data.jl --num 15000 --folder ../unique_sailx/ --unique --tasks move_to_x --seed 124986
julia generate_data.jl --num 10000 --folder ../unique_sailx/ --unique --tasks turn_and_move_to_x --seed 125985
julia generate_data.jl --num 15000 --folder ../unique_sailx/ --unique --tasks lang_only --seed 126984
julia generate_data.jl --num 10000 --folder ../unique_sailx/ --unique --tasks move_until --seed 127983
julia generate_data.jl --num 40000 --folder ../unique_sailx/ --unique --tasks any_combination --seed 128982
julia generate_data.jl --folder ../unique_sailx/ --unique --ofolder  ../sailxdataset/ --ratio 0.7 0.15 0.15
