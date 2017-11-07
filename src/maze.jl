using DataStructures

include("util.jl")

#recursive backtracking algorithm
function generate_maze(h = 4, w = 4; numdel=0)
    maze = zeros(h, w, 4)
    unvisited = zeros(h, w)

    available = Set(map(ind->ind2sub((h,w), ind), randperm(h*w)[(numdel+1):end]))

    for (r, c) in available; unvisited[r, c] = 1; end

    function neighbours(r,c)
        ns = Array{Tuple{Int, Int, Int}, 1}()
        for i=1:4
            if i == 1 && (r - 1) >= 1 && in((r-1, c), available) && unvisited[r-1, c] == 1
                push!(ns, (r-1, c, 1))
            elseif i == 2 && (c + 1) <= w && in((r, c+1), available) && unvisited[r, c+1] == 1
                push!(ns, (r, c+1, 2))
            elseif i == 3 && (r+1) <= h && in((r+1, c), available) && unvisited[r+1, c] == 1
                push!(ns, (r+1, c, 3))
            elseif i == 4 && (c-1) >= 1 && in((r, c-1), available) && unvisited[r, c-1] == 1
                push!(ns, (r, c-1, 4))
            end
        end
        return shuffle(ns)
    end

    stack = Array{Tuple{Int, Int}, 1}()
    curr = rand(collect(available))

    r, c = curr
    unvisited[r,c] = 0
    while countnz(unvisited) != 0
        ns = neighbours(curr[1], curr[2])
        if length(ns) > 0
            r,c = curr
            rn, cn, d = ns[1]
            push!(stack, (r,c))
            maze[r, c, d] = 1
            dn = d - 2 <= 0 ? d + 2 : d - 2
            maze[rn, cn, dn] = 1
            curr = (rn, cn)
            unvisited[rn, cn] = 0
        elseif length(stack) != 0
            curr = pop!(stack)
        end

    end

    #delete some walls
    ratio = 0.2
    lim = round(Int, h*w*4*ratio)
    for ind=1:lim
        r = rand(1:h)
        c = rand(1:w)
        if !in((r, c), available); continue; end;

        d = rand(1:4)
        if d==1 && r != 1 && in((r-1, c), available)
            maze[r,c,d] = 1
            maze[r-1,c,3] = 1
        elseif d==2 && c !=w && in((r, c+1), available)  
            maze[r,c,d] = 1
            maze[r,c+1,4] = 1
        elseif d==3 && r !=h && in((r+1, c), available)
            maze[r,c,d] = 1
            maze[r+1,c,1] = 1
        elseif d==4 && c != 1 && in((r, c-1), available)
            maze[r,c,d] = 1
            maze[r,c-1,2] = 1
        end
    end

    return maze, available
end

function print_maze(maze, available)
    h,w,_ = size(maze)
    rows = 2*h + 1
    cols = 2*w + 1

    for i=1:rows
        println("")
        for j=1:cols
            if i == 1 || i == rows || j == 1 || j == cols
                print("#")
            elseif i % 2 == 1 && j % 2 == 1
                print("#")
            elseif i % 2 == 1 && j % 2 == 0
                r = div(i - 1, 2)
                c = div(j, 2)
                if maze[r, c, 3] == 1
                    print(" ")
                else
                    print("#")
                end
            elseif i % 2 == 0 && j % 2 == 1
                r = div(i, 2)
                c = div(j - 1, 2)
                if maze[r,c,2] == 1
                    print(" ")
                else
                    print("#")
                end
            else
                r = div(i, 2)
                c = div(j, 2)

                if in((r, c), available)
                    print(" ")
                else
                    print(".")
                end
            end

        end
    end
    print("\n")
end

#start & goal must be an array with 2 elements
function astar_solver(maze, available, start, goal)
    function neighbours(r,c)
        ns = Any[]
        for i=1:4
            if i == 1 && maze[r, c, 1] == 1 && in((r-1, c), available)
                push!(ns, Float64[r-1, c])
            elseif i == 2 && maze[r, c, 2] == 1 && in((r, c+1), available)
                push!(ns, Float64[r, c+1])
            elseif i == 3 && maze[r, c, 3] == 1 && in((r+1, c), available)
                push!(ns, Float64[r+1, c])
            elseif i == 4 && maze[r, c, 4] == 1 && in((r, c-1), available)
                push!(ns, Float64[r, c-1])
            end
        end
        return ns
    end

    closed = Set()
    open = PriorityQueue{Array{Float64, 1}, Float64}()

    parent = Dict()
    path_cost = Dict()
    heuristic = Dict()

    path_cost[start] = 0.0
    heuristic[start] = norm(start - goal)
    parent[start] = [0.0, 0.0]

    enqueue!(open, start, path_cost[start] + heuristic[start])

    current = nothing

    while length(open) != 0
        current = dequeue!(open)

        if current == goal; break; end

        push!(closed, current)

        ns = neighbours(convert(Int, current[1]), convert(Int, current[2]))
        for n in ns
            if n in closed; continue; end
            if n in keys(open)
                if path_cost[n] > path_cost[current] + 1
                    path_cost[n] = path_cost[current] + 1
                    heuristic[n] = norm(n - goal)
                    open[n] = path_cost[n] + heuristic[n]
                    parent[n] = current
                end
            else
                path_cost[n] = path_cost[current] + 1
                heuristic[n] = norm(n- goal)
                enqueue!(open, n, path_cost[n] + heuristic[n])
                parent[n] = current
            end
        end
    end

    path = Any[]

    while current != [0.0, 0.0]
        push!(path, current)
        current = parent[current]
    end

    return reverse(path)
end

function sample(probs)
    c_probs = cumsum(probs, 2)
    return indmax(c_probs .> rand())
end

"""
Decorates the given maze with items & hall patterns
"""
function generate_navi_map(maze, name; itemcountprobs=[0.05 0.5 0.45], iprob=0.2, emptyfloor=false, emptywall=false)
    h,w,_ = size(maze)
    nodes = Dict()
    edges = Dict()

    #wall pattern boundaries
    b1 = rand(2:w-1)
    b2 = rand(2:h) 
    b3 = rand(2:h)

    items = Any[]
    for k in keys(Items)
        if k != ""
            c = sample(itemcountprobs)-1
            for i=1:c; push!(items, k); end;
        end
    end
    shuffle!(items)

    walls = shuffle(collect(values(Walls)))
    floor = rand(collect(values(Floors)))

    #set nodes and horizontal edges
    for i=1:h
        for j=1:w
            n1 = (j, i)
            n2 = (j+1, i)
            item = ""

            if rand() < iprob && length(items) > 0
                item = pop!(items)
            end

            get!(nodes, n1, Items[item])
            wall = 0

            if j+1 <= b1 && i <= b2
                wall = walls[1]
            elseif j+1 > b1 && i <= b3
                wall = walls[2]
            else
                wall = walls[3]
            end

            if emptyfloor
                floor = -1
            elseif emptywall
                wall = -1
            end

            if maze[i, j, 2] == 1
                d = get!(edges, n1, Dict(n2 => (wall, floor)))
                get!(d, n2, (wall, floor))
                d = get!(edges, n2, Dict(n1 => (wall, floor)))
                get!(d, n1, (wall, floor))
            else
                floor = rand(collect(values(Floors)))
            end
        end
    end

    floor = rand(collect(values(Floors)))

    #set vertical edges
    for j=1:w
        for i=1:h
            n1 = (j, i)
            n2 = (j, i+1)

            wall = 0

            if j <= b1 && i+1 <= b2
                wall = walls[1]
            elseif j > b1 && i+1 <= b3
                wall = walls[2]
            else
                wall = walls[3]
            end
            
            if emptyfloor
                floor = -1
            elseif emptywall
                wall = -1
            end
            
            if maze[i, j, 3] == 1
                d = get!(edges, n1, Dict(n2 => (wall, floor)))
                get!(d, n2, (wall, floor))
                d = get!(edges, n2, Dict(n1 => (wall, floor)))
                get!(d, n1, (wall, floor))
            else
                floor = rand(collect(values(Floors)))
            end
        end
    end

    return Map(name, nodes, edges)
end

function testmazepath()
    h,w=(8, 8)
    maze, available = generate_maze(h, w; numdel=8)
    print_maze(maze, available)
    
    #=
    start = [1.0, 1.0]
    goal = [4.0, 6.0]

    path = astar_solver(maze, start, goal)

    for i=1:length(path)-1
        print(path[i])
        print(" => ")
    end

    println(path[end])
    =#
end

#testmazepath()
