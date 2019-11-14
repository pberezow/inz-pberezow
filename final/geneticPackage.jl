module GeneticNTP

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
        Config, initConfig, loadConfig, saveConfig

    include("config.jl")
    include("chromosom.jl")
    include("population.jl")
    include("functions.jl")
    # include("generators.jl")

end