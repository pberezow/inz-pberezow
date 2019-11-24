"""
File contains definition of Config struct used in Population struct to set parameters of population.
    Config can be saved/loaded from file.
    config file struct: (json)
        {
            "mutationProb": <float>,
            "crossoverProb": <float>,
            "populationSize": <int>,
            "eliteProc": <float>,
            "costMatrix": [
                {
                    "d": <int>,
                    "s": <int>,
                    "val": <float>
                }, [...]
            ],
            "demand": [
                {
                    "i": <int>,
                    "val": <float> 
                }, [...]
            ],
            "supply": [
                {
                    "i": <int>,
                    "val": <float>
                }, [...]
            ]
        }
"""


"""
    Structure used to store all population parameters.
"""
mutable struct Config
    mutationProb::Float64 # [0,1]
    mutationRate::Float64 # [0,1]
    crossoverProb::Float64 # [0,1]
    populationSize::Int # > 1
    eliteProc::Float64 # % of best chromosoms which will be coppied to next generation
    costMatrix::Array{Float64, 2}
    demand::Vector{Float64}
    supply::Vector{Float64}
    validated::Bool
end

function genCFunctionAndData(config::Config, outFile::String, maxGeneration::Int)

    open("cost_function.c", "w") do f
        write(f, "#include \"genocop.h\"\n\n")
        write(f, "float cost_function(X)\nVECTOR X;\n{\n")
        write(f, "return( X[1] * $(config.costMatrix[1]) ")
        for idx = 2 : length(config.costMatrix)
            write(f, "+ X[$idx] * $(config.costMatrix[idx]) ")
        end
        write(f, ");\n}")
    end

    open(outFile, "w") do f
        write(f, "$(length(config.costMatrix))\t$(length(config.demand) + length(config.supply))\t0\t$(length(config.costMatrix))\n")
        # equations
        for i = 1 : length(config.demand)
            for s = 1 : length(config.supply)
                for d = 1 : length(config.demand)
                    if d == i
                        write(f, "1.0 ")
                    else
                        write(f, "0.0 ")
                    end
                end
            end
            write(f, "$(config.demand[i])\n")
        end

        for i = 1 : length(config.supply)
            for s = 1 : length(config.supply)
                for d = 1 : length(config.demand)
                    if s == i
                        write(f, "1.0 ")
                    else
                        write(f, "0.0 ")
                    end
                end
            end
            write(f, "$(config.supply[i])\n")
        end

        # inequalities
        # none
        # domain for variables
        idx = 1
        for s = 1 : length(config.supply)
            for d = 1 : length(config.demand)
                write(f, "0.0\t$idx\t$(min(config.supply[s], config.demand[d]))\n")
                idx += 1
            end
        end

        # population size and number of generations
        write(f, "$(config.populationSize)\t$maxGeneration\n")

        # frequencies of 7 operators (default = 4 each)
        write(f, "4\t4\t4\t4\t4\t4\t4\n")

        # (the coeficient q for cumulative probability distribution;
        # higher q values provide stronger selective pressure;
        # standard value 0.1 is very reasonable for a population
        # size 70). 
        write(f, "0.1\n")

        # (1 is for maximization problem, 0 for minimization).
        write(f, "0\n")

        # (0 for a start from a random pupulation, 1 for a start
        # from a single point, i.e., all individuals in the 
        # initial population are identical). If the system has
        # difficulties in finding feasible points, it will
        # prompt you for these (see note below, for parameter TRIES).
        write(f, "0\n")

        # (a parameter for non-uniform mutation; should stay as 6).
        write(f, "6\n")

        # (a parameter for simple crossover, leave it as it is).
        write(f, "10\n")

        # the number of your test-case; any integer would do. It is
        # convenient if your eval.c file contains several test cases:
        # then you can run the system (without recompiling) and any
        # of the test problems present in eval.c.
        # 100 for generated cost_function
        write(f, "100\n")
    end

    return nothing
end

"""
    Validates config struct. (returns true if is valid, otherwise returns false)
"""
function validate!(self::Config)
    if self.validated
        return true
    end

    if self.mutationProb < 0.0 || self.mutationProb > 1.0
        error("Wrong mutationProb value ($(self.mutationProb)). It must be between 0 and 1.")
        return false
    end

    if self.mutationRate < 0.0 || self.mutationRate > 1.0
        error("Wrong mutationRate value ($(self.mutationRate)). It must be between 0 and 1.")
        return false
    end

    if self.crossoverProb < 0.0 || self.crossoverProb > 1.0
        error("Wrong crossoverProb value ($(self.crossoverProb)). It must be between 0 and 1.")
        return false
    end

    if self.populationSize <= 1
        error("Wrong populationSize value ($(self.populationSize)). It must be greater than 1.")
        return false
    end

    if self.eliteProc < 0.0 || self.eliteProc > 1.0
        error("Wrong eliteProc value.")
        return false
    end

    if self.eliteProc + self.crossoverProb > 1.0
        error("eliteProc + crossoverProb must be between 0 and 1.")
        return false
    end

    if size(self.costMatrix) != (length(self.demand), length(self.supply))
        error("Wrong costMatrix size - $(size(self.costMatrix)). It must be length(demand) x length(supply) ($((length(self.demand), length(self.supply)))).")
        return false
    end

    self.validated = true
    return true
end

"""
    Initializes new config struct with values passed in arguments.
"""
function initConfig(mutationProb::Float64, mutationRate::Float64, crossoverProb::Float64, populationSize::Int, eliteProc::Float64, costMatrix::Array{Float64, 2}, demand::Vector{Float64}, supply::Vector{Float64})
    config = Config(mutationProb, mutationRate, crossoverProb, populationSize, eliteProc, costMatrix, demand, supply)
    validate!(config)
    return config
end

"""
    Loads config struct from file.
"""
function loadConfig(filename::String)
    txt = ""
    open(filename, "r") do f
        txt = read(f, String)
    end
    configDict = JSON.parse(txt)

    if length(configDict["demand"]) * length(configDict["supply"]) != length(configDict["costMatrix"])
        error("Wrong size of demand($(length(configDict["demand"]))), supply($(length(configDict["supply"]))) or costMatrix($(length(configDict["costMatrix"]))).")
        return nothing
    end

    demand = Vector{Float64}(undef, length(configDict["demand"]))
    for d in configDict["demand"]
        demand[d["i"]] = d["val"]
    end

    supply = Vector{Float64}(undef, length(configDict["supply"]))
    for d in configDict["supply"]
        supply[d["i"]] = d["val"]
    end

    costMatrix = Array{Float64, 2}(undef, length(demand), length(supply))
    for d in configDict["costMatrix"]
        costMatrix[d["d"], d["s"]] = d["val"]
    end

    config = Config(configDict["mutationProb"],
                    configDict["mutationRate"],
                    configDict["crossoverProb"],
                    configDict["populationSize"],
                    configDict["eliteProc"],
                    costMatrix,
                    demand,
                    supply,
                    false)
    validate!(config)

    return config
end

"""
    Saves config struct.
"""
function saveConfig(config::Config, filename::String)
    if !config.validated
        validate!(config)
    end

    configDict = Dict()
    configDict["mutationProb"] = config.mutationProb
    configDict["mutationRate"] = config.mutationRate
    configDict["crossoverProb"] = config.crossoverProb
    configDict["populationSize"] = config.populationSize
    configDict["eliteProc"] = config.eliteProc

    costMatrixList = Vector{Dict{String, Any}}(undef, length(config.costMatrix))
    idx = 1
    for i = 1 : size(config.costMatrix)[1]
        for j = 1 : size(config.costMatrix)[2]
            costMatrixList[idx] = Dict("d" => i, "s" => j, "val" => config.costMatrix[i, j])
            idx += 1
        end
    end
    configDict["costMatrix"] = costMatrixList
    
    demandList = Vector{Dict{String, Any}}(undef, length(config.demand))
    idx = 1
    for i = 1 : length(config.demand)
        demandList[idx] = Dict("i" => i, "val" => config.demand[i])
        idx += 1
    end
    configDict["demand"] = demandList
    
    supplyList = Vector{Dict{String, Any}}(undef, length(config.supply))
    idx = 1
    for i = 1 : length(config.supply)
        supplyList[idx] = Dict("i" => i, "val" => config.supply[i])
        idx += 1
    end
    configDict["supply"] = supplyList

    open(filename, "w") do f
        JSON.print(f, configDict, 4)
    end

    return true
end

# TEST
function testSaveLoad()
    demand = [1.0, 10.0]
    supply = [1.0, 5.0, 5.0]
    costMatrix = [1.0 2.0 3.0; 10.0 20.0 30.0]
    mutationProb = 0.1
    mutationRate = 0.05
    crossoverProb = 0.2
    populationSize = 100
    eliteProc = 0.3

    config = Config(mutationProb,
                    mutationRate, 
                    crossoverProb, 
                    populationSize,
                    eliteProc,
                    costMatrix,
                    demand,
                    supply,
                    false)
    validate!(config)
    saveConfig(config, "test.json")
    
    config2 = loadConfig("test.json")
    validate!(config2)

    if config.mutationProb != config2.mutationProb
        error()
    end
    if config.mutationRate != config2.mutationRate
        error()
    end
    if config.crossoverProb != config2.crossoverProb
        error()
    end
    if config.populationSize != config2.populationSize
        error()
    end
    if config.eliteProc != config2.eliteProc
        error()
    end
    if config.costMatrix != config2.costMatrix
        error()
    end
    if config.demand != config2.demand
        error()
    end
    if config.supply != config2.supply
        error()
    end
    if config.validated != config2.validated
        error()
    end

    return true
end