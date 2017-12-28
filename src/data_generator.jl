using Logging, ArgParse

include("maze.jl")
include("path_generator.jl")
include("lang_generator.jl")

CHARS = collect("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
items = filter(x->x!="", collect(keys(Items)))
floors = collect(keys(Floors))
walls = collect(keys(Walls))

function turn_to_x(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        gen = generate_lang(navimap, maze, segments; combine=0.0, cons=[visual_t])

        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]
            if length(cats) == 1 && cats[1] == visual_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_to_x(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        gen = generate_lang(navimap, maze, segments; combine=0.0, cons=[visual_m])
        acts = rand(1:4)
        if rand() <= 0.3
            reverse!(gen)
        end
        for (s, inst) in gen
            cats = inst[2:end]
            if length(cats) == 1 && cats[1] == visual_m && length(s) >= acts
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end

    return inslist, navimap
end

combined_12(name, id) = rand([turn_to_x, move_to_x])(name, id)

function turn_and_move_to_x(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_tm])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]
            if length(cats) == 1 && cats[1] == visual_tm
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function lang_only(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)

        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.3], iprob=0.8)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)

        l = rand(1:3)
        l = l > 1 ? 2 : 1
        acts = rand(1:5)
        gen = generate_lang(navimap, maze, segments; combine=(l == 2 ? 1.0 : 0.0), cons=[langonly_t, langonly_m, langonly_s])
        if rand() <= 0.4
            shuffle!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]
            langvalid = true
            for c in cats
                if !(c == langonly_t || c == langonly_m || c == langonly_s)
                    langvalid = false
                end
            end

            if langvalid && length(cats) == l && length(s) >= acts
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end 
    end
    return inslist, navimap
end

combined_1245(name, id) = rand([turn_to_x, move_to_x, turn_and_move_to_x, lang_only])(name, id)

function turn_to_x_and_move(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)

        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)

        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, langonly_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == visual_t && cats[2] == langonly_m
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end 
    end
    return inslist, navimap
end

function turn_move_to_x(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)

        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)

        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_m, langonly_t])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == langonly_t && cats[2] == visual_m
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end 
    end
    return inslist, navimap
end

function move_to_x_and_turn(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_m, langonly_t])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == visual_m && cats[2] == langonly_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_turn_to_x(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, langonly_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == langonly_m && cats[2] == visual_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function turn_to_x_move_to_y(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0 
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, visual_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == visual_t && cats[2] == visual_m
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_to_x_turn_to_y(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, visual_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && cats[1] == visual_m && cats[2] == visual_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_until(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.7)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[condition_m])
        acts = rand(2:4)
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 1 && cats[1] == condition_m && length(s) > acts
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
            end
        end
    end
    return inslist, navimap
end

function orient(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        gen = generate_lang(navimap, maze, segments; combine=0.0, cons=[orient_t])

        for (s, inst) in gen
            cats = inst[2:end]
            if length(cats) == 1 && cats[1] == orient_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
            end
        end
    end
    return inslist, navimap
end

function describe(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        mname = join(rand(CHARS, 40))
        navimap.name = mname
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        gen = generate_lang(navimap, maze, segments; combine=0.0, cons=[description])
        reverse!(gen)

        for (s, inst) in gen
            cats = inst[2:end]
            if length(cats) == 1 && cats[1] == description
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_vis_turn_lang(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_m, condition_m, langonly_t])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && (cats[1] == condition_m || cats[1] == visual_m) && cats[2] == langonly_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

move_lang_turn_vis = move_turn_to_x

function turn_vis_move_lang(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, orient_t, langonly_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && (cats[1] == visual_t || cats[1] == orient_t) && cats[2] == langonly_m
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function turn_lang_move_vis(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[langonly_t, visual_m, condition_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && (cats[1] == langonly_t && (cats[2] == visual_m || cats[2] == condition_m))
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
                id += 1
            end
        end
    end
    return inslist, navimap
end

function move_vis_turn_vis(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_m, condition_m, visual_t])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && (cats[1] == condition_m || cats[1] == visual_m) && cats[2] == visual_t
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
            end
        end
    end
    return inslist, navimap
end

function turn_vis_move_vis(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    while length(inslist) == 0
        maze, available = generate_maze(h, w; numdel=1)
        navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
        nodes, path = generate_path(maze, available)
        segments = segment_path(nodes)
        mname = join(rand(CHARS, 40))
        navimap.name = mname

        gen = generate_lang(navimap, maze, segments; combine=1.0, cons=[visual_t, orient_t, visual_m, condition_m])
        if rand() <= 0.3
            reverse!(gen)
        end

        for (s, inst) in gen
            cats = inst[2:end]

            if length(cats) == 2 && (cats[1] == visual_t || cats[1] == orient_t) && (cats[2] == visual_m || cats[2] == condition_m)
                ins = Instruction(name, split(inst[1]), s, mname, id)
                push!(inslist, ins)
            end
        end
    end
    return inslist, navimap
end

any_combination(name, id) = rand([move_vis_turn_lang, turn_vis_move_lang, move_lang_turn_vis, turn_lang_move_vis, move_vis_turn_vis, turn_vis_move_vis])(name, id)

function all_classes(name, id)
    h,w = (8,8)
    inslist = Any[]
    navimap = nothing

    maze, available = generate_maze(h, w; numdel=1)
    navimap = generate_navi_map(maze, ""; itemcountprobs=[0.0 0.0 0.05 0.05 0.1 0.1 0.1 0.1 0.1 0.2 0.2], iprob=0.6)
    nodes, path = generate_path(maze, available)
    segments = segment_path(nodes)
    mname = join(rand(CHARS, 40))
    navimap.name = mname

    gen = generate_lang(navimap, maze, segments; combine=0.4)

    for (s, inst) in gen
        ins = Instruction(name, split(inst[1]), s, mname, id)
        push!(inslist, ins)
        id += 1
    end
    return inslist, navimap
end

"""
Available task functions:

turn_to_x : turn to an object, floor or wall pattern
move_to_x : move to an object
combined_12 : generate data using turn_to_x and move_to_x
turn_and_move_to_x : turn and move to a specific object
lang_only : the instruction does not depend on the perceptual information
combined_1245 : generate data using turn_to_x, move_to_x, turn_and_move_to_x, lang_only
move_until : move until the specified condition is satisfied (the condition occurs after movement start)
orient : orient the agent by conditioned to perceptual information
describe : describes the final position

Following tasks contain two parts

move_vis_turn_lang : the perceptual information is required for the movement part, the turning part can be solved using language
move_lang_turn_vis : the perceptual information is required for the turning part, the movement part can be solved using language
move_vis_turn_vis : both parts require the perceptual information
turn_lang_move_vis : the perceptual information is required for the movement part, the turning part can be solved using language
turn_vis_move_lang : the perceptual information is required for the turning part, the movement part can be solved using language
turn_vis_move_vis : both parts require the perceptual information

any_combination : one of the visual task that contains two segment

all_classes : random task
"""

function generatedata(taskf; numins=100)
    data = Any[]
    mps = Dict()

    inscount = 0
    while inscount < numins
        inscount += 1
        name = string(taskf, "_", inscount)

        inslist, mp = taskf(name, inscount)
        l = inscount-1 + length(inslist) > numins ? numins - (inscount-1): length(inslist)
        append!(data, inslist[1:l])
        mps[mp.name] = mp
        inscount += length(inslist)
    end

    return data, mps
end

"""
Collection::Dict{Instruction, Dict{Length, Set{String representation of a path}}}
"""
function generate_unique_data(taskf; numins=100)
    collection = Dict{String, Dict{Int, Set{String}}}()
    
    #check whether new instance in the collection or not
    #add the new instance to the collection if it is not in the collection
    function is_in_collection!(map, instance)
        #generates string representation of the path
        function get_path_rep()
            rep = ""
            for curr in instance.path
                view = state_agent_centric(map, curr)
                rep = rep * string(view)
            end
            return rep
        end

        in_collection = true
        text = join(instance.text, " ")
        rep = get_path_rep()

        if haskey(collection, text)
            if length(collection[text]) < 5
                if !haskey(collection[text], length(instance.path))
                    passed = true
                    for k in keys(collection[text])
                        set = collection[text][k]
                        if rep in set
                            passed = false
                            break
                        end
                    end
                    if passed
                        collection[text][length(instance.path)] = Set{String}([rep])
                        in_collection = false
                    end
                end
            end
        else
            collection[text] = Dict{Int, Set{String}}(length(instance.path) => Set{String}([rep]))
            in_collection = false
        end
        return in_collection
    end

    data = Any[]
    mps = Dict()

    inscount = 0
    while inscount < numins
        name = string(taskf, "_", inscount)

        inslist, mp = taskf(name, inscount)
        for instance in inslist
            if !(is_in_collection!(mp, instance))
                push!(data, instance)
                mps[mp.name] = mp
                inscount += 1
            else
                println("$taskf - $inscount ** In the collection")
            end

            if inscount == numins
                break
            end
        end
    end

    return data, mps
end
