module GeneticTransProblem

    using Random

    export Chromosom, init, validate, eval!, mutate!, crossover!, 
        Population, initPopulation, nextGeneration!, findSolution, 
        makeA, makeB, makeC, makeD, makeE, makeF, makeLinear,
        genRandData, genDataWthZerosCost, genDataWthZerosDiagonal

    include("chromosom.jl")
    include("population.jl")
    include("costFunctions.jl")
    include("generators.jl")

end



# function makeData(size::Int)
#     demand = zeros(Float64, size)
#     supply = zeros(Float64, size)
#     costMatrix = zeros(Float64, size, size)
    
#     for i = 1 : size
#         supply[i] = 20.0 * i
#         demand[i] = 20.0 * i
#     end
    
#     for i = 1 : size
#         for j = 1 : size
#             if i == j
#                 costMatrix[i, j] = 0.0
#             else
#                 costMatrix[i, j] = rand(100.0:0.01:1000.0)
#             end
#         end
#     end
    
#     return demand, supply, costMatrix
# end
