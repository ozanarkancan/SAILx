facing_wall(maze, p) = maze[p[1], p[2], p[3]] == 0
is_intersection(maze, p) = sum(maze[p[1], p[2], :]) >= 3
is_deadend(maze, p) = sum(maze[p[1], p[2], :]) == 1
rightof(d) = ((d+1) % 4) == 0 ? 4 : ((d+1) % 4)
leftof(d) = (((d-1)+4) % 4) == 0 ? 4 : (((d-1)+4) % 4)
backof(d) = ((d+2) % 4) == 0 ? 4 : ((d+2) % 4)

function nodes_visible(navimap, curr)
    nbs = Any[]
    for nb in keys(navimap.edges[curr])
        dir = Any[]
        x = nb[1] - curr[1]
        y = nb[2] - curr[2]

        prev = nb
        next = map(Int, (nb[1] + x, nb[2] + y))

        while haskey(navimap.edges, prev) && haskey(navimap.edges[prev], next)
            push!(dir, prev)
            prev = next
            next = map(Int, (prev[1] + x, prev[2] + y))
        end
        push!(dir, prev)
        push!(nbs, dir)
    end
    return nbs
end

function is_corner(maze, p)
    if sum(maze[p[1], p[2], :]) == 2
        conds = false
        for i=1:4
            if i == 4
                conds = conds || (maze[p[1], p[2], 4] == 1 && maze[p[1], p[2], 1] == 1)
            else
                conds = conds || (maze[p[1], p[2], i] == 1 && maze[p[1], p[2], i+1] == 1)
            end
        end
        return conds
    else
        return false
    end
end

function around_different_walls_floor(navimap, node)
    ws = Set()
    fs = Set()
    for n2 in keys(navimap.edges[node])
        w, f = navimap.edges[node][n2]
        push!(ws, w)
        push!(fs, f)
    end
    return (length(ws) == length(keys(navimap.edges[node])), length(fs) == length(keys(navimap.edges[node])))
end

function count_alleys(maze, segment)
    count = 0
    for i=2:length(segment)
        p = (segment[i][2], segment[i][1], -1)
        count += is_intersection(maze, p) ? 1 : 0
    end

    return count
end

function item_single_on_this_segment(navimap, segment)
    cnt = 0
    item = navimap.nodes[(segment[end][1], segment[end][2])]
    for s in segment
        it = navimap.nodes[(s[1], s[2])]
        cnt += it == item ? 1 : 0
    end

    return cnt == 1
end

function item_single_in_visible(navimap, item, node)
    cnt = 0

    nbs = nodes_visible(navimap, node)
    for ns in nbs
        for n in ns
            if item == navimap.nodes[n]
                cnt += 1
            end
        end
    end
    return cnt
end

function find_single_item_in_visible(navimap, node, nextloc)
    item = 7#empty

    curr = node[1:2]

    while haskey(navimap.edges, curr) && haskey(navimap.edges[curr], nextloc[1:2])
        item = navimap.nodes[nextloc[1:2]]
        if item != 7 && item_single_in_visible(navimap, item, node) == 1
            break
        end
        item = 7
        curr = nextloc[1:2]
        nextloc = getlocation(navimap, nextloc, 1)
    end
    return item
end

function is_floor_unique(navimap, maze, segment, target)
    """
    0: not unique
    1: right
    2: left
    3: right&left
    """

    res = 3
    wall, floor = navimap.edges[segment[end][1:2]][target[1:2]]
    wp, fp = navimap.edges[segment[end-1][1:2]][segment[end][1:2]]
    if fp == floor
        return 0,0
    end

    for i=2:length(segment)-1
        p1 = (segment[i][2], segment[i][1], round(Int, 1+segment[i][3]/90))
        r = rightof(p1[3])
        l = leftof(p1[3])

        if maze[p1[1], p1[2], r] == 1
            p2 = nothing

            if r == 1
                p2 = (p1[1]-1, p1[2])
            elseif r == 2
                p2 = (p1[1], p1[2]+1)
            elseif r == 3
                p2 = (p1[1]+1, p1[2])
            else
                p2 = (p1[1], p1[2]-1)
            end

            wc, fc = navimap.edges[(p1[2], p1[1])][(p2[2], p2[1])]
            if fc == floor
                res = 0
                break
            end
        end

        if maze[p1[1], p1[2], l] == 1
            p2 = nothing

            if l == 1
                p2 = (p1[1]-1, p1[2])
            elseif l == 2
                p2 = (p1[1], p1[2]+1)
            elseif l == 3
                p2 = (p1[1]+1, p1[2])
            else
                p2 = (p1[1], p1[2]-1)
            end

            wc, fc = navimap.edges[(p1[2], p1[1])][(p2[2], p2[1])]
            if fc == floor
                res = 0
                break
            end

        end
    end

    if res != 0
        p = (segment[end][2], segment[end][1], round(Int, 1+segment[end][3]/90))
        r = rightof(p[3])
        l = leftof(p[3])

        if maze[p[1], p[2], r] == 1 && maze[p[1], p[2], l] == 1
            return 3, floor
        elseif maze[p[1], p[2], r] == 1
            return 1, floor
        else
            return 2, floor
        end
    else
        return 0,0
    end
end

function hall_front(navimap, curr)
    dir = Any[]

    prev = curr
    next = getlocation(navimap, curr, 1)

    while haskey(navimap.edges, prev[1:2]) && haskey(navimap.edges[prev[1:2]], next[1:2])
        push!(dir, next)
        prev = next
        next = getlocation(navimap, next, 1)
    end
    return dir
end

#edge patterns in the order of front, right, back, left
function edge_around(navimap, curr)
    flrs = [-1, -1, -1, -1]
    wlls = [-1, -1, -1, -1]
    next = getlocation(navimap, curr, 1)

    if haskey(navimap.edges[curr[1:2]], next[1:2])
        wc, fc = navimap.edges[curr[1:2]][next[1:2]]
        flrs[1] = fc
        wlls[1] = wc
    end

    tr = getlocation(navimap, curr, 2)
    next = getlocation(navimap, tr, 1)

    if haskey(navimap.edges[curr[1:2]], next[1:2])
        wc, fc = navimap.edges[curr[1:2]][next[1:2]]
        flrs[2] = fc
        wlls[2] = wc
    end
    
    tr = getlocation(navimap, tr, 2)
    next = getlocation(navimap, tr, 1)

    if haskey(navimap.edges[curr[1:2]], next[1:2])
        wc, fc = navimap.edges[curr[1:2]][next[1:2]]
        flrs[3] = fc
        wlls[3] = wc
    end
    
    tr = getlocation(navimap, tr, 2)
    next = getlocation(navimap, tr, 1)

    if haskey(navimap.edges[curr[1:2]], next[1:2])
        wc, fc = navimap.edges[curr[1:2]][next[1:2]]
        flrs[4] = fc
        wlls[4] = wc
    end
    return flrs, wlls
end
