module GeneticNTP
    using Random
    using JSON
    using PyPlot
    using Distributions

    export 
        # chromosom.jl
        Chromosom, getCost, validate, validate!, eval!, mutate, mutate!, cross, cross!, 
        # population.jl
        Population, initPopulation, drawResults, runEA,
        # functions.jl
        getFunctions,
        # config.jl
        Config, initConfig, loadConfig, saveConfig

    include("config.jl")
    include("chromosom.jl")
    include("population.jl")
    include("functions.jl")

end
