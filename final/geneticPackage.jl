module GeneticNTP
    __precompile__()
    using Random
    using JSON
    using PyPlot

    export 
        # chromosom.jl
        Chromosom, getCost, init, validate, validate!, eval!, mutate, mutate!, cross, cross!, 
        # population.jl
        Population, initPopulation, nextGeneration!, findSolution, drawResults, runGA,
        # functions.jl
        makeLinear, makeA, getFunctions,
        # config.jl
        Config, initConfig, loadConfig, saveConfig, genCFunctionAndData

    include("config.jl")
    include("chromosom.jl")
    include("population.jl")
    include("functions.jl")
    # include("generators.jl")

    # precompile(getCost, (Chromosom,))
    # precompile(copy, (Chromosom,))
    # precompile(isless, (Chromosom, Chromosom))
    # precompile(init, (Vector{Float64}, Vector{Float64}))
    # precompile(initArray, (Vector{Float64}, Vector{Float64}))
    # precompile(initArray2, (Vector{Float64}, Vector{Float64}))
    # precompile(eval!, (Chromosom, Function))
    # precompile(mutate!, (Chromosom, Vector{Float64}, Vector{Float64}, Int64, Int64))
    # precompile(mutate2!, (Chromosom, Vector{Float64}, Vector{Float64}, Int64, Int64))
    # precompile(cross!, (Chromosom, Chromosom))
    # precompile(getSizeForMutation, (Chromosom, Float64))
    # precompile(validate, (Chromosom, Vector{Float64}, Vector{Float64}, Float64))

    # precompile(runGA, (String, Int, String, Bool))
    # precompile(initPopulation, (Config, Int64, Function, Bool, Int64))
    # precompile(getPartialPopulationsData, (Config, Int64))
    # precompile(selection, (Population, Int64))
    # precompile(islandSelection, (Population, Int64, Int64, Int64))
    # precompile(nextGeneration!, (Population, Int64, Int64))
    # precompile(islandNextGeneration!, (Population, Int64, Int64, Int64, Int64, Vector{Chromosom}))
    # precompile(nextGenerationTest!, (Population, Int64, Int64))
    # precompile(findSolution, (Population,))

    # precompile(validate!, (Config,))
    # precompile(loadConfig, (String,))
    # precompile(saveConfig, (Config, String))

end