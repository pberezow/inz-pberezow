"""
File contains Chromosom struct which represents single result of transportation problem.
Functions:
    - Base.copy(c::Chromosom) -> Chromosom
    - Base.isless(self::Chromosom, other::Chromosom)
    
    - getCost(self::Chromosom, costFunc::Function) -> Float
    - init(_demand::Vector{Float64}, _supply::Vector{Float64}) -> Chromosom
    - initArray(demand::Vector{Float64}, supply::Vector{Float64}) -> Array{Float64, 2}
    - eval!(self::Chromosom, costFunc::Function)
    - mutate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    - mutate!(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    - cross(self::Chromosom, other::Chromosom)
    - cross!(self::Chromosom, other::Chromosom)
    - validate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, delta::Float64=0.0000000001)
"""


"""
    Struct to represent single chromosom for genetic algorithm.
"""
mutable struct Chromosom
    result::Array{Float64, 2}
    cost::Float64
    isCalculated::Bool
end


"""
    Calculates cost of chromosom.
"""
function getCost(self::Chromosom, costFunc::Function)
    if self.isCalculated
        return self.cost
    else
        eval!(self, costFunc)
        return self.cost
    end
end

"""
    Returns a copy of Chromosom c.
"""
function Base.copy(c::Chromosom)
    c1 = Chromosom(copy(c.result), copy(c.cost), copy(c.isCalculated))
    return c1
end

"""
    Returns true if cost of Chromosom self is smaller than cost of other.
Used to sort vector of Chromosoms.
"""
function Base.isless(self::Chromosom, other::Chromosom)
    return isless(self.cost, other.cost)
end

"""
    Initialization of new chromosom for given demand and supply vectors
"""
function init(_demand::Vector{Float64}, _supply::Vector{Float64})
    demand = copy(_demand)
    supply = copy(_supply)

    result = initArray(demand, supply)

    return Chromosom(result, 0.0, false)
end

"""
    Initialization of chromosom's result Array. (it is also useed is mutation operator)
"""
function initArray(demand::Vector{Float64}, supply::Vector{Float64})
    result = Array{Float64, 2}(undef, length(demand), length(supply))

    indices = vec([(i,j) for i in 1 : length(demand), j in 1 : length(supply)])
    shuffle!(indices)
    for idx in indices
        val = min(demand[idx[1]], supply[idx[2]])
        result[idx[1], idx[2]] = val
        demand[idx[1]] -= val
        supply[idx[2]] -= val
    end

    return result
end

function initArray2(demand::Vector{Float64}, supply::Vector{Float64})
    result = Array{Float64, 2}(undef, length(demand), length(supply))

    indices = vec([(i,j) for i in 1 : length(demand), j in 1 : length(supply)])
    shuffle!(indices)
    for idx in indices
        val = min(demand[idx[1]], supply[idx[2]]) * rand()
        result[idx[1], idx[2]] = val
        demand[idx[1]] -= val
        supply[idx[2]] -= val
    end

    for idx in reverse(indices)
        val = min(demand[idx[1]], supply[idx[2]])
        result[idx[1], idx[2]] += val
        demand[idx[1]] -= val
        supply[idx[2]] -= val
    end

    return result
end

"""
    Evaluates chromosom's cost.
"""
function eval!(self::Chromosom, costFunc::Function)
    if !self.isCalculated
        self.cost = costFunc(self.result)
        self.isCalculated = true
    end
    return nothing
end

"""
    Mutation operator - creates copy of a self::Chromosom.
"""
function mutate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    chromosomCopy = copy(self)
    mutate!(chromosomCopy, demand, supply, nDemand, nSupply)
    return chromosomCopy
end

"""
    In-place mutation operator.
nDemand and nSupply tells about size of newly initialized array(default 2x2).
"""
function mutate!(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    self.isCalculated = false

    demandPerm = collect(1:length(demand))
    shuffle!(demandPerm)
    demandPerm = demandPerm[1:nDemand]

    supplyPerm = collect(1:length(supply))
    shuffle!(supplyPerm)
    supplyPerm = supplyPerm[1:nSupply]

    partialDemand = Vector{Float64}(undef, nDemand)
    partialSupply = Vector{Float64}(undef, nSupply)

    for i = 1 : nDemand
        partialDemand[i] = sum(self.result[demandPerm[i], j] for j in supplyPerm)
    end
    
    for i = 1 : nSupply
        partialSupply[i] = sum(self.result[j, supplyPerm[i]] for j in demandPerm)
    end

    partialResult = initArray(partialDemand, partialSupply)

    for i = 1 : nDemand
        for j = 1 : nSupply
            self.result[demandPerm[i], supplyPerm[j]] = partialResult[i, j]
        end
    end

    return nothing
end

function mutate2!(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    self.isCalculated = false

    demandPerm = collect(1:length(demand))
    shuffle!(demandPerm)
    demandPerm = demandPerm[1:nDemand]

    supplyPerm = collect(1:length(supply))
    shuffle!(supplyPerm)
    supplyPerm = supplyPerm[1:nSupply]

    partialDemand = Vector{Float64}(undef, nDemand)
    partialSupply = Vector{Float64}(undef, nSupply)

    for i = 1 : nDemand
        partialDemand[i] = sum(self.result[demandPerm[i], j] for j in supplyPerm)
    end
    
    for i = 1 : nSupply
        partialSupply[i] = sum(self.result[j, supplyPerm[i]] for j in demandPerm)
    end

    partialResult = initArray2(partialDemand, partialSupply)

    for i = 1 : nDemand
        for j = 1 : nSupply
            self.result[demandPerm[i], supplyPerm[j]] = partialResult[i, j]
        end
    end

    return nothing
end

"""
    Crossover operator - doesn't change parents, creates 2 children.
"""
function cross(self::Chromosom, other::Chromosom)
    selfCopy = copy(self)
    otherCopy = copy(other)
    cross!(selfCopy, otherCopy)
    return selfCopy, otherCopy
end

"""
    In-place crossover operator on 2 Chromosoms(creates 2 children and swaps them with parents).
"""
function cross!(self::Chromosom, other::Chromosom)
    self.isCalculated = false
    other.isCalculated = false

    c1 = rand()
    c2 = 1.0 - c1

    for i in 1: length(self.result)
        self.result[i], other.result[i] = c1 * self.result[i] + c2 * other.result[i], c1 * other.result[i] + c2 * self.result[i]
    end

    return nothing
end

"""
    Calculates size of matrix initialized during mutation, based on param - mutationRate.
"""
function getSizeForMutation(self::Chromosom, param::Float64)
    nDemand = round(Int, size(self.result)[1] * param)
    nSupply = round(Int, size(self.result)[2] * param)
    
    if nDemand < 2
        nDemand = 2
    end
    if nSupply < 2
        nSupply = 2
    end

    return nDemand, nSupply
end

"""
    Check if chromosom fits as solution.
"""
function validate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, delta::Float64=0.0000001)
    for i = 1 : length(demand)
        sumVal = 0.0
        for j = 1 : length(supply)
            sumVal += self.result[i, j]
        end
        if abs(demand[i] - sumVal) > delta
            println("Delta = $(abs(demand[i] - sumVal)).")
            return false
        end
    end

    for j = 1 : length(supply)
        sumVal = 0.0
        for i = 1 : length(demand)
            sumVal += self.result[i, j]
        end
        if abs(supply[j] - sumVal) > delta
            println("Delta = $(abs(supply[j] - sumVal)).")
            return false
        end
    end
    
    return true
end