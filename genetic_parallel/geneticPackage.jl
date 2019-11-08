module GeneticNTP

    using Random
    using JSON
    # using PyPlot

    export Chromosom, getCost, init, validate, validate!, eval!, mutate, mutate!, cross, cross!, 
        Population, initPopulation, nextGeneration!, findSolution, 
        makeA,# makeB, makeC, makeD, makeE, makeF, 
        makeLinear,
        Config, initConfig, loadConfig, saveConfig
        # genRandData, genDataWthZerosCost, genDataWthZerosDiagonal

    include("config.jl")
    include("chromosom.jl")
    include("population.jl")
    include("functions.jl")
    # include("generators.jl")

end