#!/bin/bash

echo "Unique data generation"
julia generate_data.jl --num 55000 --folder ../unique/ --unique --tasks turn_to_x
julia generate_data.jl --num 100000 --folder ../unique/ --unique --tasks move_to_x
julia generate_data.jl --num 35000 --folder ../unique/ --unique --tasks turn_and_move_to_x
julia generate_data.jl --num 30000 --folder ../unique/ --unique --tasks lang_only
julia generate_data.jl --num 45000 --folder ../unique/ --unique --tasks move_until
julia generate_data.jl --num 200000 --folder ../unique/ --unique --tasks any_combination
