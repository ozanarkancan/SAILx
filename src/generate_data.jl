include("data_generator.jl")

function main(args=ARGS)
    defaults = ["turn_to_x", "move_to_x", "combined_12", "turn_and_move_to_x",
        "lang_only", "combined_1245", "move_until", "any_combination", "all_classes"]
    s = ArgParseSettings()
    s.description = "Generate navigational instructions and corresponding worlds"
    s.exc_handler=ArgParse.debug_handler
    @add_arg_table s begin
        ("--num"; nargs='+'; arg_type=Int; default=[10]; help="number of instances")
        ("--tasks"; nargs='+'; default=defaults; help="tasks")
        ("--folder"; default="../data/"; help="the parent folder to save the data")
        ("--ofolder"; default="../dataset/"; help="the parent folder to save the data")
        ("--seed"; default=170523; arg_type=Int; help="random seed")
        ("--unique"; help = "generate unique instances"; action = :store_true)
        ("--ratio"; help = "split data into training, development and test dataset"; default=[0.0]; arg_type=Float64; nargs='+')
    end

    isa(args, AbstractString) && (args=split(args))
    o = parse_args(args, s)
    o["seed"] > 0 && srand(o["seed"])

    if o["ratio"] != [0.0]
        splitdataset(o["folder"], o["ofolder"], o["ratio"])
    else
        !ispath(o["folder"]) && mkdir(o["folder"])

        tasks = map(t->eval(parse(t)), o["tasks"])
        gdata = o["unique"] ? generate_unique_data : generatedata
        if length(o["num"]) != length(o["tasks"])
            o["num"] = map(x->o["num"][1], o["tasks"])
        end

        for (t,n) in zip(tasks, o["num"])
            folder = string(o["folder"], t)
            !ispath(folder) && mkdir(folder)
            instructions, maps = gdata(t; numins=n)
            insdicts = map(ins2dict, instructions)

            file = open(string(folder, "/instructions.json"), "w")
            JSON.print(file, insdicts)
            close(file)
            file = open(string(folder, "/maps.json"), "w")
            JSON.print(file, maps)
            close(file)
        end
    end
end

function ins2dict(ins)
    d = Dict()
    d["fname"] = ins.fname
    d["text"] = ins.text
    pathtext = string(ins.path)
    ind1 = findfirst(pathtext, '[')
    ind2 = findfirst(pathtext, ']')
    d["path"] = pathtext[ind1:ind2]
    d["map"] = ins.map
    d["id"] = ins.id
    return d
end

function splitdataset(folder, ofolder, ratio=[0.8, 0.1, 0.1])
    trainmaps = Dict()
    trainins = []
    devmaps = Dict()
    devins = []
    testmaps = Dict()
    testins = []

    for task in readdir(folder)
        instructions = JSON.parsefile(folder*"/"*task*"/instructions.json")
        maps = JSON.parsefile(folder*"/"*task*"/maps.json")

        l = length(instructions)
        tend = Int(l * ratio[1])
        dend = Int(l * ratio[2] + tend)

        append!(trainins, instructions[1:tend])
        append!(devins, instructions[tend+1:dend])
        append!(testins, instructions[dend+1:end])

        for i=1:l
            key = instructions[i]["map"]
            if i <= tend
                trainmaps[key] = maps[key]
            elseif i <= dend
                devmaps[key] = maps[key]
            else
                testmaps[key] = maps[key]
            end
        end
    end
    
    !ispath(ofolder) && mkdir(ofolder)
    
    for (fname, ins, ms) in [("train", trainins, trainmaps), ("dev", devins, devmaps),
               ("test", testins, testmaps)]
        nfolder = ofolder * "/" * fname
        mkdir(nfolder)
        file = open(nfolder*"/instructions.json", "w")
        JSON.print(file, ins)
        close(file)
        file = open(nfolder * "/maps.json", "w")
        JSON.print(file, ms)
        close(file)
    end
end

if VERSION >= v"0.5.0-dev+7720"
    PROGRAM_FILE=="generate_data.jl" && main(ARGS)
else
    !isinteractive() && !isdefined(Core.Main,:load_only) && main(ARGS)
end
