"""
File contains Population struct, which represents population of chromosoms.
Functions:
    - initPopulation(config::Config, maxGeneration::Int, costFunction::Function)
    - selection(self::Population)
    - nextGeneration!(self::Population)
    - findSolution(population::Population)
"""


"""
    Structure used to represent population of Chromosoms.
"""
mutable struct Population
    config::Config
    currGeneration::Int
    maxGeneration::Int
    chromosomSet::Vector{Chromosom}
    bestChromosom::Chromosom
    costFunction::Function
    bestsVector::Vector{Float64} # to plot results
    isTestRun::Bool
    nDemand::Int
    nSupply::Int
    partialPopulationsData::Vector{Tuple{Int, Int, Int, Int}} # (firstIdx, lastIdx, parentsToPick, eliteCount)
    fittness::Vector{Float64}
    parents::Vector{Chromosom}
    tmpChromosomeSet::Vector{Chromosom}
end

function runGA(configFile::String, maxGeneration::Int, costFunctionName::String, isTestRun::Bool=false, setupCostFile::String="") 
    config = loadConfig(configFile)

    println("==================== CONFIG ====================")
    println("Population Size: ", config.populationSize, " Crossover: ", config.crossoverProb, " Mutation: ", config.mutationProb, " Elite: ", config.eliteProc, " Iterations: ", maxGeneration)
    println("Cost Func: ", costFunctionName)
    println("Test Run: ", isTestRun)
    println()


    functionsDict = getFunctions(config.costMatrix, setupCostFile)
    costFunc = functionsDict[costFunctionName]

    population = nothing
    if config.mode == REGULAR_MODE
        population = initPopulation(config, maxGeneration, costFunc, isTestRun, 1)
    elseif config.mode == ISLAND_MODE
        population = initPopulation(config, maxGeneration, costFunc, isTestRun, Threads.nthreads())
    else
        error()
    end
    println("Best result in first generation: ", population.bestChromosom.cost)

    result = findSolution(population)
    
    if isTestRun
        # open("res.txt", "w") do f
        #     write(f, "y = [")
        #     for res in population.bestsVector
        #         write(f, "$res, ")
        #     end
        #     write(f, "]\n")
        # end
        drawResults(population, "resultPlot.png")
    end
    
    if !validate(result, config.demand, config.supply)
        error("Error while performing mutation.")
    end
    return result
end

"""
    initPopulation(config, maxGeneration, costFunction)

Initializes new population.

# Arguments
- `config::Config`: Config struct including all population's parameters.
- `maxGeneration::Integer`: number of iterations before algorithm stops.
- `costFunction::Function`: function used to calculate cost of single solution, should have signature func(resultMatrix::Array{Float64, 2}).
"""
function initPopulation(config::Config, maxGeneration::Int, costFunction::Function, isTestRun::Bool=false, numberOfSeparatePopulations::Int=1)
    validate!(config)

    chromosomSet = Vector{Chromosom}(undef, config.populationSize)
    Threads.@threads for i = 1 : config.populationSize
        chromosomSet[i] = init(config.demand, config.supply)
        eval!(chromosomSet[i], costFunction)
    end

    sort!(chromosomSet)
    bestChromosom = copy(chromosomSet[1])

    # to draw plots
    vec = Vector{Float64}()
    if isTestRun
        # getCost() removed
        push!(vec, bestChromosom.cost)
    end

    nDemand, nSupply = getSizeForMutation(bestChromosom, config.mutationRate)

    partialPopulationsData = getPartialPopulationsData(config, numberOfSeparatePopulations)

    fittness = Vector{Float64}(undef, length(chromosomSet))

    parentsToPick = sum(partialPopulationsData[i][3] for i in 1 : length(partialPopulationsData))
    parents = Vector{Chromosom}(undef, parentsToPick)

    tmpChromosomSet = Vector{Chromosom}(undef, length(chromosomSet))

    return Population(config, 1, maxGeneration, chromosomSet, bestChromosom, costFunction, vec, isTestRun, nDemand, nSupply, partialPopulationsData, fittness, parents, tmpChromosomSet)
end

function getPartialPopulationsData(config::Config, numberOfSeparatePopulations::Int)
    size = floor(Int, config.populationSize / numberOfSeparatePopulations)
    
    firstIdx = Vector{Int}(undef, numberOfSeparatePopulations)
    firstIdx[1] = 1
    for i = 2 : length(firstIdx)
        firstIdx[i] = size + firstIdx[i-1]
    end

    idx = 2
    while firstIdx[numberOfSeparatePopulations] + size - 1 < config.populationSize
        for i = idx : numberOfSeparatePopulations
            firstIdx[i] += 1
        end
        idx += 1
    end

    lastIdx = Vector{Int}(undef, numberOfSeparatePopulations)
    lastIdx[numberOfSeparatePopulations] = config.populationSize
    for i = numberOfSeparatePopulations-1 : -1 : 1
        lastIdx[i] = firstIdx[i+1] - 1
    end

    parentsToPick = Vector{Int}(undef, numberOfSeparatePopulations)
    elites = Vector{Int}(undef, numberOfSeparatePopulations)

    allElites = floor(Int, config.populationSize * config.eliteProc)
    allParents = floor(Int, config.populationSize * config.crossoverProb)
    if allParents % 2 == 1
        allParents += 1
    end
    if allParents + allElites > config.populationSize
        allElites -= 1
    end

    parentsEach = floor(Int, allParents / numberOfSeparatePopulations)
    elitesEach = floor(Int, allElites / numberOfSeparatePopulations)
    for i = 1 : numberOfSeparatePopulations
        parentsToPick[i] = parentsEach
        elites[i] = elitesEach
    end

    idx = 1
    while sum(elites) != allElites
        elites[idx] += 1
        idx += 1
    end
    idx = 1
    while sum(parentsToPick) != allParents
        parentsToPick[idx] += 1
        idx += 1
    end

    for i = 1 : numberOfSeparatePopulations
        if parentsToPick[i] % 2 == 1
            if lastIdx[i] - firstIdx[i] + 1 - elites[i] > parentsToPick[i]
                parentsToPick[i] += 1
            else
                parentsToPick[i] -= 1
            end
        end
    end

    partialPopulationsData = Vector{Tuple{Int, Int, Int, Int}}()
    for i = 1 : numberOfSeparatePopulations
        push!(partialPopulationsData, (firstIdx[i], lastIdx[i], parentsToPick[i], elites[i]))
    end

    return partialPopulationsData
end

function _calcFittness!(self::Population)
    # getCost() removed
    self.fittness[length(self.chromosomSet)] = 1.0 / self.chromosomSet[length(self.chromosomSet)].cost
    for i = length(self.chromosomSet)-1 : -1 : 1
        self.fittness[i] = 1.0 / self.chromosomSet[i].cost + self.fittness[i+1]
    end

    #2
    self.fittness ./= self.fittness[1]
    return nothing
end

"""
    Select chromosoms to reproduction.
"""
function selection!(self::Population, parentsToPick::Int)
    
    _calcFittness!(self)

    for i = 1 : parentsToPick
        pick = rand()
        idx = findfirst(x -> x <= pick, self.fittness)
        if idx === nothing
            idx = length(self.chromosomSet)
        end
        self.parents[i] = copy(self.chromosomSet[idx])
    end

    return nothing
end

function _calcPartialFittness!(self::Population, firstIdx::Int, lastIdx::Int)
    self.fittness[lastIdx] = 1.0 / self.chromosomSet[lastIdx].cost
    for i = lastIdx-1 : -1 : firstIdx
        self.fittness[i] = 1.0 / self.chromosomSet[i].cost + self.fittness[i+1]
    end

    #2
    for i = lastIdx : -1 : firstIdx
        self.fittness[i] /= self.fittness[firstIdx]
    end
    return nothing
end

function islandSelection!(self::Population, firstIdx::Int, lastIdx::Int, parentsToPick::Int, partialDataIdx::Int)
    _calcPartialFittness!(self, firstIdx, lastIdx)

    parentsIdx = 1
    for i = 1 : partialDataIdx-1
        parentsIdx += self.partialPopulationsData[i][3]
    end

    for i = parentsIdx : parentsIdx + parentsToPick - 1
        pick = rand()

        selectedIdx = lastIdx
        for idx = firstIdx : lastIdx
            if self.fittness[idx] <= pick
                selectedIdx = idx
                break
            end
        end
            
        self.parents[i] = copy(self.chromosomSet[selectedIdx])
    end

    return nothing
end

"""
    nextGeneration!(self)

Performs single iteration of genetic algorithm.

# Arguments
- `self::Population`: evolving population.
"""
function nextGeneration!(self::Population, parentsToPick::Int, eliteCount::Int)
    selection!(self, parentsToPick)
    
    Threads.@threads for i = 1 : 2 : length(self.parents)
        cross!(self.parents[i], self.parents[i+1])
        self.tmpChromosomeSet[i] = self.parents[i]
        self.tmpChromosomeSet[i+1] = self.parents[i+1]
        for j = 0 : 1
            if rand() <= self.config.mutationProb
                # if rand() <= 0.5
                #     mutate2!(self.tmpChromosomeSet[i+j], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
                # else
                    mutate!(self.tmpChromosomeSet[i+j], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
                # end
            end
            eval!(self.tmpChromosomeSet[i+j], self.costFunction)
        end
    end

    Threads.@threads for i = length(self.parents) + 1 : self.config.populationSize
        if i - length(self.parents) <= eliteCount
            self.tmpChromosomeSet[i] = self.chromosomSet[i - length(self.parents)]
        else
            selected_idx = rand(eliteCount+1 : self.config.populationSize)
            self.tmpChromosomeSet[i] = copy(self.chromosomSet[selected_idx])
        end

        if rand() <= self.config.mutationProb
            # if rand() <= 0.5
            #     mutate2!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            # else
                mutate!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            # end
        end
        eval!(self.tmpChromosomeSet[i], self.costFunction)
    end

    sort!(self.tmpChromosomeSet)

    tmp = self.chromosomSet
    self.chromosomSet = self.tmpChromosomeSet
    self.tmpChromosomeSet = tmp
    
    # getCost() removed
    if self.bestChromosom.cost > self.chromosomSet[1].cost
        self.bestChromosom = copy(self.chromosomSet[1])
    end

    self.currGeneration += 1
    return nothing
end

# function nextGeneration!(self::Population, parentsToPick::Int, eliteCount::Int)
#     selection!(self, parentsToPick)
    
#     currIdx = 1
#     for i = 1 : eliteCount
#         self.tmpChromosomeSet[currIdx] = self.chromosomSet[currIdx]
#         currIdx += 1
#     end

#     Threads.@threads for i = 1 : 2 : parentsToPick
#         cross!(self.parents[i], self.parents[i+1])
#         self.tmpChromosomeSet[currIdx+i-1] = self.parents[i]
#         self.tmpChromosomeSet[currIdx+i] = self.parents[i+1]
#     end
#     currIdx += parentsToPick

#     for i = currIdx : length(self.tmpChromosomeSet)
#         selected_idx = rand(1 : length(self.tmpChromosomeSet))
#         self.tmpChromosomeSet[i] = copy(self.chromosomSet[selected_idx])
#     end

#     Threads.@threads for i = 1 : length(self.tmpChromosomeSet)
#         if rand() <= self.config.mutationProb
#             # if rand() <= 0.5
#             #     mutate2!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
#             # else
#                 mutate!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
#             # end
#         end
#         eval!(self.tmpChromosomeSet[i], self.costFunction)
#     end

#     sort!(self.tmpChromosomeSet)
#     # sort!(self.tmpChromosomeSet, 1, length(self.tmpChromosomeSet), QuickSort, Base.Order.Forward)

#     tmp = self.chromosomSet
#     self.chromosomSet = self.tmpChromosomeSet
#     self.tmpChromosomeSet = tmp
    
#     # getCost() removed
#     if self.bestChromosom.cost > self.chromosomSet[1].cost
#         self.bestChromosom = copy(self.chromosomSet[1])
#     end

#     self.currGeneration += 1
#     return nothing
# end

function islandNextGeneration!(self::Population, firstIdx::Int, lastIdx::Int, parentsToPick::Int, eliteCount::Int, partialDataIdx::Int, mutex::Threads.SpinLock)
    islandSelection!(self, firstIdx, lastIdx, parentsToPick, partialDataIdx)
    
    currIdx = firstIdx
    for i = 1 : eliteCount
        self.tmpChromosomeSet[currIdx] = self.chromosomSet[currIdx]
        currIdx += 1
    end

    parentsIdx = 1
    for i = 1 : partialDataIdx-1
        parentsIdx += self.partialPopulationsData[i][3]
    end

    for i = parentsIdx : 2 : parentsIdx + parentsToPick - 1
        cross!(self.parents[i], self.parents[i+1])
        self.tmpChromosomeSet[currIdx] = self.parents[i]
        self.tmpChromosomeSet[currIdx+1] = self.parents[i+1]
        currIdx += 2
    end

    for i = currIdx : lastIdx
        selected_idx = rand(firstIdx : lastIdx)
        self.tmpChromosomeSet[i] = copy(self.chromosomSet[selected_idx])
    end

    for i = firstIdx : lastIdx
        if rand() <= self.config.mutationProb
            # if rand() <= 0.5
            #     mutate2!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            # else
                mutate!(self.tmpChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            # end
        end
        eval!(self.tmpChromosomeSet[i], self.costFunction)
    end

    sort!(self.tmpChromosomeSet, firstIdx, lastIdx, QuickSort, Base.Order.Forward)
    
    for i = firstIdx : lastIdx
        self.chromosomSet[i], self.tmpChromosomeSet[i] = self.tmpChromosomeSet[i], self.chromosomSet[i]
    end

    if self.bestChromosom.cost > self.chromosomSet[firstIdx].cost
        lock(mutex)
        self.bestChromosom = copy(self.chromosomSet[firstIdx])
        unlock(mutex)
    end

    return nothing
end

function nextGenerationTest!(self::Population, parentsToPick::Int, eliteCount::Int)
    nextGeneration!(self, parentsToPick, eliteCount)
    # getCost() removed
    push!(self.bestsVector, self.chromosomSet[1].cost)
    if self.currGeneration % 1000 == 0
        meanVal = 0.0
        for i = 1 : length(self.chromosomSet)
            meanVal += self.chromosomSet[i].cost
        end
        meanVal /= length(self.chromosomSet)
        println("Generation: ", self.currGeneration, "  Best: ", self.chromosomSet[1].cost, "  Mean: ", meanVal, "  Worse: ", self.chromosomSet[length(self.chromosomSet)].cost)
    end

    return nothing
end

"""
    Run's genetic algorithm on population.
"""
function findSolution(population::Population)
    if population.isTestRun
        if population.config.mode == REGULAR_MODE
            # TEST - REGULAR MODE
            while population.currGeneration < population.maxGeneration
                nextGenerationTest!(population, population.partialPopulationsData[1][3], population.partialPopulationsData[1][4])
            end
        elseif population.config.mode == ISLAND_MODE
            # TEST - ISLAND MODE
            mutex = Threads.SpinLock()
            while population.currGeneration < population.maxGeneration
                shuffle!(population.chromosomSet)
                
                Threads.@threads for i = 1 : length(population.partialPopulationsData)
                    sort!(population.chromosomSet, population.partialPopulationsData[i][1], population.partialPopulationsData[i][2], QuickSort, Base.Order.Forward)
                    for j = 1 : population.config.numberOfSeparateGenerations
                        islandNextGeneration!(population, population.partialPopulationsData[i]..., i, mutex)
                    end
                end
                population.currGeneration += population.config.numberOfSeparateGenerations

                sort!(population.chromosomSet)
                if population.bestChromosom.cost > population.chromosomSet[1].cost
                    population.bestChromosom = copy(population.chromosomSet[1])
                end
                # getCost() removed
                push!(population.bestsVector, population.chromosomSet[1].cost)
            end
        end
    else
        if population.config.mode == REGULAR_MODE
            # REGULAR MODE
            while population.currGeneration < population.maxGeneration
                nextGeneration!(population, population.partialPopulationsData[1][3], population.partialPopulationsData[1][4])
            end
        elseif population.config.mode == ISLAND_MODE
            # ISLAND MODE
            mutex = Threads.SpinLock()
            while population.currGeneration < population.maxGeneration
                shuffle!(population.chromosomSet)
                
                Threads.@threads for i = 1 : length(population.partialPopulationsData)
                    sort!(population.chromosomSet, population.partialPopulationsData[i][1], population.partialPopulationsData[i][2], QuickSort, Base.Order.Forward)
                    for j = 1 : population.config.numberOfSeparateGenerations
                        islandNextGeneration!(population, population.partialPopulationsData[i]..., i, mutex)
                    end
                end
                population.currGeneration += population.config.numberOfSeparateGenerations

                sort!(population.chromosomSet)
                if population.bestChromosom.cost > population.chromosomSet[1].cost
                    population.bestChromosom = copy(population.chromosomSet[1])
                end
            end
        end
    end

    return population.bestChromosom
end

function drawResults(self::Population, filename::String, runNumber::Int=-1)
    if self.currGeneration < self.maxGeneration
        println("You have to evolve population first!")
        return false
    end

    # if !self.isTestRun || length(self.bestsVector) != self.maxGeneration
    #     println("You have to set isTestRun = true during population initialization!")
    #     return false
    # end

    title = "mutProb: $(self.config.mutationProb), crossProb: $(self.config.crossoverProb), elite: $(self.config.eliteProc), popSize: $(self.config.populationSize), maxGen: $(self.maxGeneration)"
    if runNumber > 0
        title = "($runNumber)  " * title
    end
    xlabel = "Generation"
    ylabel = "Cost of best chromosom"

    ioff()
    fig = PyPlot.figure(title, figsize=(12, 12))
    ax = PyPlot.axes()
    plt = plot(1 : self.config.numberOfSeparateGenerations : self.currGeneration, self.bestsVector)
    grid(true)
    PyPlot.xlabel(xlabel)
    PyPlot.ylabel(ylabel)
    PyPlot.title(title)

    fig.savefig(filename)
    clf()
    close(fig)
    
    return true
end