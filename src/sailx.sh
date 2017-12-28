#!/bin/bash

echo "Unique data generation"
julia generate_data.jl --num 70000 25000 80000 35000 25000 70000 32000 115000 115000 --folder ../unique/ --unique --tasks turn_to_x move_to_x combined_12 turn_and_move_to_x lang_only combined_1245 move_until any_combination all_classes
