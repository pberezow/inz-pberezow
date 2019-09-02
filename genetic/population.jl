# using Chromosom, costFunctions, Random

mutable struct Population
    size::Int

    chromosoms::Vector{Chromosom}
    bestChromosom::Chromosom
    
    mutationProb::Float64
    crossoverProb::Float64
    
    costMatrix::Array{Float64, 2}
    costFunction::Function

    demand::Vector{Float64}
    supply::Vector{Float64}
    generation::Int
end

function initPopulation(size::Int, mutationProb::Float64, crossoverProb::Float64, costMatrix::Array{Float64, 2}, costFunction::Function, demand::Vector{Float64}, supply::Vector{Float64})
    # if length(demand) != size(costMatrix)[1] || length(supply) != size(costMatrix)[2]
    #     error("Wrong arguments!")
    # end
    
    chromosoms = Vector{Chromosom}()

    
    bestChromosomIdx = 1
    for i = 1:size
        c = init(demand, supply)
        eval!(c, costFunction)
        push!(chromosoms, c)
        if c.cost < chromosoms[bestChromosomIdx].cost
            bestChromosomIdx = i
        end
    end

    bestChromosom = copy(chromosoms[bestChromosomIdx]) # Chromosom(copy(chromosoms[bestChromosomIdx].resultMatrix), 0)
    # eval!(bestChromosom, costFunction)

    population = Population(size, chromosoms, bestChromosom, mutationProb, crossoverProb, costMatrix, costFunction, demand, supply, 0)
    return population
end

function nextGeneration!(population::Population)

    # for statistic purpose
    mutations = 0
    crossovers = 0

    for i = 1:population.size
        if rand() <= population.mutationProb
            mutate!(population.chromosoms[i], population.demand, population.supply)
            mutations += 1
        end
    end

    for i = 1:population.size
        if rand() <= population.crossoverProb
            other = i
            while other == i
                other = rand(1:population.size)
            end
            crossover!(population.chromosoms[i], population.chromosoms[other])
            crossovers += 1
        end
    end

    for i = 1:population.size
        eval!(population.chromosoms[i], population.costFunction)
        if population.chromosoms[i].cost < population.bestChromosom.cost
            # possible need of deep copy
            population.bestChromosom = population.chromosoms[i]
        end
    end

    # deep copy of best chromosm
    population.bestChromosom = copy(population.bestChromosom) # Chromosom(copy(population.bestChromosom.resultMatrix), population.bestChromosom.cost)

    population.generation += 1

    println("Generation: $(population.generation)   Mutations: $(mutations) Crossovers: $(crossovers)   Best Solution: $(population.bestChromosom.cost)")
end

function findSolution(size::Int, mutationProb::Float64, crossoverProb::Float64, costMatrix::Array{Float64, 2}, costFunction::Function, demand::Vector{Float64}, supply::Vector{Float64}, maxGenerations::Int)
    population = initPopulation(size, mutationProb, crossoverProb, costMatrix, costFunction, demand, supply)

    while population.generation < maxGenerations
        nextGeneration!(population)
    end

    return population.bestChromosom
end

function findSolution(size::Int, mutationProb::Float64, crossoverProb::Float64, costMatrix::Array{Float64, 2}, costFunction::Function, demand::Vector{Float64}, supply::Vector{Float64}, maxGenerations::Int, enougthCost::Float64)
    population = initPopulation(size, mutationProb, crossoverProb, costMatrix, costFunction, demand, supply)

    while population.generation < maxGenerations || population.bestChromosom.cost <= enougthCost
        nextGeneration!(population)
    end

    return population.bestChromosom
end