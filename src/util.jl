using JLD

include("instruction.jl")
include("map.jl")

function build_dict(instructions)
    d = Dict{AbstractString, Int}()

    for ins in instructions
        for w in ins.text
            for t in split(w, "-")
                get!(d, t, 1+length(d))
            end
        end
    end

    return d
end

function build_char_dict(instructions)
    d = Dict{Char, Int}()
    get!(d, ' ', 1+length(d))

    for ins in instructions
        for w in ins.text
            for t in split(w, "-")
                for c in t
                    get!(d, c, 1+length(d))
                end
            end
        end
    end

    return d
end


#converts tokens to onehots
function ins_arr(d, ins)
    arr = Any[]
    vocablength = length(d)

    for w in ins
        for t in split(w, "-")
            indx = haskey(d, t) ? d[t] : vocablength + 1
            onehot = zeros(Float32, 1, vocablength + 1)
            onehot[1, indx] = 1.0
            push!(arr, onehot)
        end
    end

    return arr
end

#converts tokens to embeddings
function ins_arr_embed(embeds, d, ins)
    arr = Any[]
    vocablength = length(d)

    for w in ins
        for t in split(w, "-")
            vec = haskey(d, t) ? transpose(embeds[t]) : transpose(embeds["unk"])
            push!(arr, vec)
        end
    end

    return arr
end

#converts chars to onehots
function ins_char_arr(d, ins)
    arr = Any[]
    vocablength = length(d)

    for i=1:length(ins)
        t = i==length(ins) ? ins[i] : "$(ins[i]) "
        for c in t
            indx = haskey(d, c) ? d[c] : vocablength + 1
            onehot = zeros(Float32, 1, vocablength + 1)
            onehot[1, indx] = 1.0
            push!(arr, onehot)
        end
    end
    return arr
end


#=
builds the agent's view
agent centric
up: front
right hand side: right of the agent
down: back
left hand side: left of the agent
(20, 20) is the agent curent location and it is a node
neighbors of a node are edges
=#
function state_agent_centric(map, loc; vdims = [39 39])
    #lfeatvec = length(Items) + length(Floors) + length(Walls) + 3
    lfeatvec = length(Items) + length(Floors) + length(Walls) + length(MapColors) + 3
    view = zeros(Float32, vdims[1], vdims[2], lfeatvec, 1)
    mid = [round(Int, vdims[1]/2) round(Int, vdims[2]/2)]

    if loc[3] == 0
        ux = 0; uy = -1;
        rx = 1; ry = 0;
        dx = 0; dy = 1;
        lx = -1; ly = 0;
    elseif loc[3] == 90
        ux = 1; uy = 0;
        rx = 0; ry = 1;
        dx = -1; dy = 0;
        lx = 0; ly = -1;
    elseif loc[3] == 180
        ux = 0; uy = 1;
        rx = -1; ry = 0;
        dx = 0; dy = -1;
        lx = 1; ly = 0;
    else
        ux = -1; uy = 0;
        rx = 0; ry = -1;
        dx = 1; dy = 0;
        lx = 0; ly = 1;
    end

    current = loc[1:2]

    i, j = mid

    view[i, j, map.nodes[(loc[1], loc[2])]] = 1.0
    view[i,j, lfeatvec-2, 1] = 1.0

    i = i - 1
    #up
    while i > 0
        next = (current[1] + ux, current[2] + uy)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[i, j, length(Items) + floor, 1] = 1.0
            view[i, j, length(Items) + length(Floors) + wall, 1] = 1.0

            for c in ColorMapping[floor]
                view[i, j, length(Items) + length(Floors) + length(Walls) + MapColors[c], 1] = 1.0
            end

            view[i,j, lfeatvec-1, 1] = 1.0
            i = i - 1
            view[i, j, map.nodes[(next[1], next[2])], 1] = 1.0
            view[i,j, lfeatvec-2, 1] = 1.0
            current = next
            i = i - 1
        else
            #view[i,j, lfeatvec-1, 1] = 1.0
            view[i, j, lfeatvec, 1] = 1.0
            break
        end
    end

    current = loc[1:2]
    i, j = mid
    j = j + 1
    #right
    while j <= vdims[2]
        next = (current[1] + rx, current[2] + ry)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[i, j, length(Items) + floor, 1] = 1.0
            view[i, j, length(Items) + length(Floors) + wall, 1] = 1.0
            view[i,j, lfeatvec-1, 1] = 1.0

            for c in ColorMapping[floor]
                view[i, j, length(Items) + length(Floors) + length(Walls) + MapColors[c], 1] = 1.0
            end

            j = j + 1
            view[i, j, map.nodes[(next[1], next[2])], 1] = 1.0
            view[i,j, lfeatvec-2, 1] = 1.0
            current = next
            j = j + 1
        else
            #view[i,j, lfeatvec-1, 1] = 1.0
            view[i, j, lfeatvec, 1] = 1.0
            break
        end
    end

    current = loc[1:2]
    i, j = mid
    i = i + 1
    #down
    while i <= vdims[1]
        next = (current[1] + dx, current[2] + dy)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[i, j, length(Items) + floor] = 1.0
            view[i, j, length(Items) + length(Floors) + wall] = 1.0
            view[i,j, lfeatvec-1, 1] = 1.0

            for c in ColorMapping[floor]
                view[i, j, length(Items) + length(Floors) + length(Walls) + MapColors[c], 1] = 1.0
            end

            i = i + 1
            view[i, j, map.nodes[(next[1], next[2])]] = 1.0
            view[i,j, lfeatvec-2, 1] = 1.0
            current = next
            i = i + 1
        else
            #view[i,j, lfeatvec-1, 1] = 1.0
            view[i, j, lfeatvec] = 1.0
            break
        end
    end

    current = loc[1:2]
    i, j = mid
    j = j - 1
    #left
    while j > 0
        next = (current[1] + lx, current[2] + ly)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[i, j, length(Items) + floor] = 1.0
            view[i, j, length(Items) + length(Floors) + wall] = 1.0
            view[i,j, lfeatvec-1, 1] = 1.0

            for c in ColorMapping[floor]
                view[i, j, length(Items) + length(Floors) + length(Walls) + MapColors[c], 1] = 1.0
            end

            j = j - 1
            view[i, j, map.nodes[(next[1], next[2])]] = 1.0
            view[i,j, lfeatvec-2, 1] = 1.0
            current = next
            j = j - 1
        else
            #view[i,j, lfeatvec-1, 1] = 1.0
            view[i, j, lfeatvec] = 1.0
            break
        end
    end

    nv = zeros(Float32, 5, 20, size(view, 3), 1)
    nv[1, :, :, 1] = view[1:20, 20, :, :]
    nv[2, :, :, 1] = view[20, 20:end, :, :]
    nv[3, :, :, 1] = view[20:end, 20, :, :]
    nv[4, :, :, 1] = view[20, 1:20, :, :]
    nv[5, :, :, 1] = view[1:20, 20, :, :]
    #return view
    return nv
end

function state_agent_centric_multihot(map, loc)
    lfeatvec = length(Items) + length(Floors) + length(Walls) + 1
    view = zeros(Float32, 1, length(Items) + 4 * lfeatvec)

    if loc[3] == 0
        ux = 0; uy = -1;
        rx = 1; ry = 0;
        dx = 0; dy = 1;
        lx = -1; ly = 0;
    elseif loc[3] == 90
        ux = 1; uy = 0;
        rx = 0; ry = 1;
        dx = -1; dy = 0;
        lx = 0; ly = -1;
    elseif loc[3] == 180
        ux = 0; uy = 1;
        rx = -1; ry = 0;
        dx = 0; dy = -1;
        lx = 1; ly = 0;
    else
        ux = -1; uy = 0;
        rx = 0; ry = -1;
        dx = 1; dy = 0;
        lx = 0; ly = 1;
    end

    current = loc[1:2]

    view[1, map.nodes[(loc[1], loc[2])]] = 1.0
    walkable = false

    #up
    while true
        next = (current[1] + ux, current[2] + uy)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[1, length(Items) + length(Items) + floor] = 1.0
            view[1, length(Items) + length(Items) + length(Floors) + wall] = 1.0

            view[1, length(Items) + map.nodes[(next[1], next[2])]] = 1.0
            current = next
            walkable = true
        else
            if !walkable
                view[1, length(Items) + lfeatvec] = 1.0
            end
            break
        end
    end

    current = loc[1:2]
    walkable = false

    #right
    while true
        next = (current[1] + rx, current[2] + ry)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[1, length(Items) + lfeatvec + length(Items) + floor] = 1.0
            view[1, length(Items) + lfeatvec + length(Items) + length(Floors) + wall] = 1.0

            view[1, length(Items) + lfeatvec + map.nodes[(next[1], next[2])]] = 1.0
            current = next
            walkable = true
        else
            if !walkable
                view[1, length(Items) + 2*lfeatvec] = 1.0
            end
            break
        end
    end

    current = loc[1:2]
    walkable = false

    #down
    while true
        next = (current[1] + dx, current[2] + dy)
        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[1, length(Items) + 2*lfeatvec + length(Items) + floor] = 1.0
            view[1, length(Items) + 2*lfeatvec + length(Items) + length(Floors) + wall] = 1.0

            view[1, length(Items) + 2*lfeatvec + map.nodes[(next[1], next[2])]] = 1.0
            current = next
            walkable = true
        else
            if !walkable
                view[1, length(Items) + 3*lfeatvec] = 1.0
            end
            break
        end
    end

    current = loc[1:2]
    walkable = false

    #left
    while true
        next = (current[1] + lx, current[2] + ly)

        if haskey(map.edges[(current[1], current[2])], (next[1], next[2]))#check the wall existence
            wall, floor = map.edges[(current[1], current[2])][(next[1], next[2])]
            view[1, length(Items) + 3*lfeatvec + length(Items) + floor] = 1.0
            view[1, length(Items) + 3*lfeatvec + length(Items) + length(Floors) + wall] = 1.0

            view[1, length(Items) + 3*lfeatvec + map.nodes[(next[1], next[2])]] = 1.0
            current = next
            walkable = true
        else
            if !walkable
                view[1, length(Items) + 4*lfeatvec] = 1.0
            end
            break
        end
    end

    return view
end

function action(curr, next)
    a = 0
    if curr[1] != next[1] || curr[2] != next[2]#move
        a = 1
    elseif !(next[3] == 270 && curr[3] == 0) && (next[3] > curr[3] || (next[3] == 0 && curr[3] == 270))#right
        a = 2
    elseif !(next[3] == 0 && curr[3] == 270) && (next[3] < curr[3] || (next[3] == 270 && curr[3] == 0))#left
        a = 3
    else
        a = 4
    end
    return a
end

function getactions(path)
    actions = Any[]
    for i=1:length(path)
        curr = path[i]
        next = i == length(path) ? curr : path[i+1]
        push!(actions, action(curr, next))
    end
    return actions
end

function build_instance(instance, map, vocab; vdims=[39, 39], emb=nothing, encoding="grid")
    words = emb == nothing ? ins_arr(vocab, instance.text) : ins_arr_embed(emb, vocab, instance.text)

    states = Any[]
    Y = zeros(Float32, length(instance.path), 4)

    for i=1:length(instance.path)
        curr = instance.path[i]
        next = i == length(instance.path) ? curr : instance.path[i+1]
        Y[i, action(curr, next)] = 1.0
        push!(states, encoding == "grid" ? state_agent_centric(map, curr) : state_agent_centric_multihot(map, curr))
    end

    return (words, states, Y)
end

function minibatch(data; bs=100)
    sort!(data; by=t->length(t[1]))
    batches = []

    vocab = size(data[1][1][1], 2)
    vdims = size(data[1][2][1])

    for i=1:bs:length(data)
        l = i + bs - 1
        l = l > length(data) ? length(data) : l
        words = Any[]
        views = Any[]
        ys = Any[]
        maskouts = Any[]

        maxe = maximum(map(ind->length(data[ind][1]), i:l))
        maxd = maximum(map(ind->length(data[ind][2]), i:l))

        for enc=1:maxe
            word = zeros(Float32, (l-i+1), vocab)

            for j=i:l
                t = j-i+1

                if length(data[j][1]) >= enc
                    word[t, :] = data[j][1][enc]
                end
            end
            push!(words, word)
        end

        multihot = length(vdims) == 2

        for dec=1:maxd
            view = multihot ? zeros(Float32, (l-i+1), vdims[2]) : zeros(Float32, vdims[1], vdims[2], vdims[3], (l-i+1))
            y = zeros(Float32, (l-i+1), 4)
            maskout = ones(Float32, (l-i+1), 1)

            for j=i:l
                t = j-i+1
                if length(data[j][2]) >= dec
                    if !multihot
                        view[:, :, :, t] = data[j][2][dec]
                    else
                        view[t, :] = data[j][2][dec]
                    end

                    y[t, :] = data[j][3][dec, :]
                else
                    maskout[t, 1] = 0.0
                end
            end

            push!(views, view)
            push!(ys, y)
            push!(maskouts, maskout)
        end

        push!(batches, (words, views, ys, maskouts))
    end

    return batches
end

function build_data(trn_ins, tst_ins, outfile; charenc=false, encoding="grid")
    fname = "data/maps/map-grid.json"
    grid = getmap(fname)

    fname = "data/maps/map-jelly.json"
    jelly = getmap(fname)

    fname = "data/maps/map-l.json"
    l = getmap(fname)

    maps = Dict("Grid" => grid, "Jelly" => jelly, "L" => l)

    voc_ins = copy(trn_ins)
    append!(voc_ins, tst_ins)

    println("Building the vocab...")
    vocab = !charenc ? build_dict(voc_ins) : build_char_dict(voc_ins)

    println("Converting data...")
    trn_data = map(x -> build_instance(x, maps[x.map], vocab; encoding=encoding), trn_ins)

    println("Saving...")

    save(outfile, "vocab", vocab, "maps", maps, "data", trn_data)
    println("Done!")
end
