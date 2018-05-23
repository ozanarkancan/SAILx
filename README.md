# SAILx

This repo contains code to generate artificial data described in: *A new dataset
and model for learning to understand navigational instructions*

https://arxiv.org/abs/1805.07952

To generate the fixed dataset:

```bash
sh sailx.sh
```

To generate the data used in the efficiency experiments:
```bash
sh tasks.sh
```
You can generate data for specific tasks by using the generatedata.jl. It will create a folder for each subtask and generate instructions.json and corresponding maps.json.

```julia
Example: julia generate_data.jl --num 15000 --folder ../unique_sailx/ --unique --tasks turn_to_x --seed 123789

--num : number of instances
--tasks: list of the tasks
--folder: parent folder to save the data
--seed: random seed
--unique: the combination of the instruction and corresponding path (including the configuration of visual properties) is unique for each instance
--ratio: default is [0.0]. If you want to split data into train, dev and test splits, give the ratio (e.g 0.7 0.15 0.15)
--ofolder: If the ratio is given, then --folder argument is used to input folder. ofolder argument is used as the parent folder to save the data
```
List of possible tasks:
* turn_to_x
* move_to_x
* combined_12 (sample from [turn_to_x, move_to_x])
* turn_and_move_to_x
* lang_only
* combined_1245 (sample from [turn_to_x, move_to_x, turn_and_move_to_x, lang_only])
* move_until
* orient
* describe
* move_vis_turn_lang
* turn_vis_move_lang
* move_lang_turn_vis
* turn_lang_move_vis
* move_vis_turn_vis
* turn_vis_move_vis
* any_combination (sample from [move_vis_turn_lang, turn_vis_move_lang, move_lang_turn_vis, turn_lang_move_vis, move_vis_turn_vis, turn_vis_move_vis])
* norestriction

### Instruction:
```json
id : id
fname : the file name
text : tokenized version of the instruction
map : the name of the map
path : a list of (x,y,orientation) tuples
```

### Map:
```julia
name : randomly generated name
nodes : A dictionary where keys are the locations as (x,y) tuples and values are ids of items
edges : A dictionary as (x1,y1) => (x2, y2) => [wall id, floor id],
    where (x1, y1) and (x2, y2) are nodes and [wall id, floor id] represents the wall paintings and flooring. 
```

Ids of attributes:
```julia
Items = Dict("stool" => 1, "chair" => 2, "easel" => 3,
    "hatrack" => 4, "lamp" => 5, "sofa" => 6, "" => 7)

Walls = Dict("butterfly" => 1, "fish" => 2, "tower" => 3)

Floors = Dict("blue" => 1, "brick" => 2, "concrete" => 3, "flower" => 4,
    "grass" => 5, "gravel" => 6, "wood" => 7, "yellow" => 8)
```

### Dependencies (Julia Packages):
```
Logging
ArgParse
JLD
JSON
DataStructures
```
