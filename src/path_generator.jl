function generate_path(maze, available; distance=4)
    h,w,_ = size(maze)
    rp = shuffle(collect(available))

    x1,y1 = rp[1]
    z1 = rand(0:3) * 90
    x2 = 0
    y2 = 0
    dist = -1
    i=2

    while dist < distance
        x2,y2 = rp[i]
        i += 1
        dist = abs(x1-x2)+abs(y1-y2)
    end

    path = astar_solver(maze, available, Int[x1, y1], Int[x2, y2])

    start = (y1, x1, z1)
    goal = (y2, x2, -1)

    nodes = Any[]

    current = start
    next = 2

    while !(current[1] == goal[1] && current[2] == goal[2])
        y2, x2 = path[next]
        nb = (x2, y2)
        ns = getnodes(current, nb)
        current = ns[end]
        if length(nodes) == 0
            append!(nodes, ns)
        else
            append!(nodes, ns[2:end])
        end
        next += 1
    end

    return nodes, path
end

function getnodes(n1, n2)
    n1 = map(x->round(Int, x), n1)
    n2 = map(x->round(Int, x), n2)
    nodes = Any[]
    if n1[1] == n2[1]
        if n1[2] > n2[2]
            if n1[3] != 270
                c = n1[3]
                while c != 0
                    push!(nodes, (n1[1], n1[2], c))
                    c -= 90
                end
            else
                push!(nodes, n1)
            end
            push!(nodes, (n1[1], n1[2], 0))
            push!(nodes, (n2[1], n2[2], 0))
        else
            if n1[3] != 270
                c = n1[3]
                while c != 180
                    push!(nodes, (n1[1], n1[2], c))
                    c += 90
                end
            else
                push!(nodes, n1)

            end
            push!(nodes, (n1[1], n1[2], 180))
            push!(nodes, (n2[1], n2[2], 180))

        end
    else
        if n1[1] > n2[1]
            if n1[3] != 0
                c = n1[3]
                while c != 270
                    push!(nodes, (n1[1], n1[2], c))
                    c += 90
                end
            else
                push!(nodes, n1)
            end
            push!(nodes, (n1[1], n1[2], 270))
            push!(nodes, (n2[1], n2[2], 270))
        else
            if n1[3] != 0
                c = n1[3]
                while c != 90
                    push!(nodes, (n1[1], n1[2], c))
                    c -= 90
                end
            else
                push!(nodes, n1)

            end
            push!(nodes, (n1[1], n1[2], 90))
            push!(nodes, (n2[1], n2[2], 90))
        end
    end
    return nodes
end

function segment_path(path)
    """
    Segment the path into forward movements and turns
    """
    segments = Any[]

    c = 1
    curr = Any[]
    move = path[1][3] == path[2][3]

    while c < length(path)
        if path[c][3] == path[c+1][3]
            if move
                push!(curr, path[c])
                c += 1
            else
                push!(curr, path[c])
                push!(segments, ("turn", curr))
                curr = Any[]
                move = true
            end
        else
            if !move
                push!(curr, path[c])
                c += 1
            else
                push!(curr, path[c])
                push!(segments, ("move", curr))
                curr = Any[]
                move = false
            end
        end
    end
    push!(curr, path[end])
    move ? push!(segments, ("move", curr)) : push!(segments, ("turn", curr))
    return segments
end
