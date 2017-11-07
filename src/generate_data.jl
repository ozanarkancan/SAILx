include("data_generator.jl")

function main(args=ARGS)
    defaults = ["turn_to_x", "move_to_x", "combined_12", "turn_and_move_to_x",
        "lang_only", "combined_1245", "move_until", "any_combination", "all_classes"]
    s = ArgParseSettings()
    s.description = "Generate navigational instructions and corresponding worlds"
    s.exc_handler=ArgParse.debug_handler
    @add_arg_table s begin
        ("--num"; arg_type=Int; default=10; help="number of instances")
        ("--tasks"; nargs='+'; default=defaults; help="tasks")
        ("--folder"; default="../data/"; help="the parent folder to save the data")
        ("--seed"; default=170523; arg_type=Int; help="random seed")
    end

    isa(args, AbstractString) && (args=split(args))
    o = parse_args(args, s)
    o["seed"] > 0 && srand(o["seed"])

    tasks = map(t->eval(parse(t)), o["tasks"])

    for t in tasks
        folder = string(o["folder"], t)
        !ispath(folder) && mkdir(folder)
        instructions, maps = generatedata(t; numins=o["num"])
        insdicts = map(ins2dict, instructions)

        file = open(string(folder, "/instructions.json"), "w")
        JSON.print(file, insdicts)
        close(file)
        file = open(string(folder, "/maps.json"), "w")
        JSON.print(file, maps)
        close(file)
    end
end

function ins2dict(ins)
    d = Dict()
    d["fname"] = ins.fname
    d["text"] = ins.text
    d["path"] = string(ins.path)[4:end]
    d["map"] = ins.map
    d["id"] = ins.id
    return d
end

if VERSION >= v"0.5.0-dev+7720"
    PROGRAM_FILE=="generate_data.jl" && main(ARGS)
else
    !isinteractive() && !isdefined(Core.Main,:load_only) && main(ARGS)
end
