module GeneticNTP
    using Random
    using JSON
    using PyPlot
    using Distributions

    export 
        # chromosom.jl
        Chromosom, init, getCost, validate, validate!, eval!, mutate!, mutate2!, cross!, getSizeForMutation,
        # population.jl
        Population, initPopulation, drawResults, runEA, nextGeneration!, islandNextGeneration!, findSolution,
        # functions.jl
        getFunctions,
        # config.jl
        Config, initConfig, loadConfig, saveConfig, REGULAR_MODE, ISLAND_MODE

    include("config.jl")
    include("chromosom.jl")
    include("population.jl")
    include("functions.jl")

end
