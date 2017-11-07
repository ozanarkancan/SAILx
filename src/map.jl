import Base.copy

using JSON
using DataStructures

type Map
    name
    nodes
    edges
end

copy(m::Map) = Map(m.name, copy(m.nodes), copy(m.edges))

Items = Dict("stool" => 1, "chair" => 2, "easel" => 3,
    "hatrack" => 4, "lamp" => 5, "sofa" => 6, "" => 7)

Walls = Dict("butterfly" => 1, "fish" => 2, "tower" => 3)

Floors = Dict("blue" => 1, "brick" => 2, "concrete" => 3, "flower" => 4, 
    "grass" => 5, "gravel" => 6, "wood" => 7, "yellow" => 8)

MapColors = Dict("black" => 1, "blue" => 2, "brown" => 3,
    "green" => 4, "grey" => 5, "pink" => 6, "red" => 7, "yellow" => 8)

ColorMapping = Dict(1 => ["blue"], 2 => ["red", "brown"], 3 => ["grey"],
    4 => ["pink"], 5 => ["green"], 6 => ["black", "grey"],
    7 => ["brown"], 8 => ["yellow", "green"])

function getmap(fname)
    j = JSON.parsefile(fname; dicttype=DataStructures.OrderedDict, use_mmap=true)
    gridmap = j["map"]
    #println(keys(gridmap))
    #println(typeof(gridmap["nodes"]["node"]))

    name = gridmap["_name"]
    nodes = Dict()
    edges = Dict()
    for n in gridmap["nodes"]["node"]
        x = parse(Int, n["_x"])
        y = parse(Int, n["_y"])
        item = Items[n["_item"]]
        get!(nodes, (x,y), item)
    end

    for e in gridmap["edges"]["edge"]
        arr = map(a -> parse(Int, a), split(e["_node1"], ","))
        n1 = (arr[1], arr[2])
        arr = map(a -> parse(Int, a), split(e["_node2"], ","))
        n2 = (arr[1], arr[2])
        wall = Walls[e["_wall"]]
        flr = Floors[e["_floor"]]
        d = get!(edges, n1, Dict(n2 => (wall, flr)))
        get!(d, n2, (wall, flr))
        d = get!(edges, n2, Dict(n1 => (wall, flr)))
        get!(d, n1, (wall, flr))
    end
    return Map(name, nodes, edges)
end

function getlocation(map::Map, current, action)
    if action == 1#move
        if current[3] == 0
            next = (current[1], current[2] - 1, current[3])
        elseif current[3] == 90
            next = (current[1] + 1, current[2], current[3])
        elseif current[3] == 180
            next = (current[1], current[2] + 1, current[3])
        elseif current[3] == 270
            next = (current[1] - 1, current[2] , current[3])
        end
    elseif action == 2#right
        next = (current[1], current[2], (current[3] + 90) % 360)
    elseif action == 3#left
        next = (current[1], current[2], (current[3] - 90 + 360) % 360)
    else#stop
        next = current
    end
    return next
end
