#!/bin/bash
N=50000
N2=10000

echo "Unique data generation"
julia generate_data.jl --num $N $N $N $N $N $N $N2 $N2 --folder ../unique/ --unique --tasks turn_to_x move_to_x turn_and_move_to_x lang_only move_until any_combination orient describe

echo "Splitting the generated data into train, dev, test"
julia generate_data.jl --folder ../unique/ --ratio 0.8 0.1 0.1 --ofolder dataset

echo "Zipping"
tar -cvzf ../dataset ../sailx.tar.gz
