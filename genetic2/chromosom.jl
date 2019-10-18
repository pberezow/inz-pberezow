"""
File contains Chromosom struct which represents single result of transportation problem.
Functions:
    Base.copy(c::Chromosom) -> Chromosom
    getCost(self::Chromosom, costFunc::Function) -> Float
    init(_demand::Vector{Float64}, _supply::Vector{Float64}) -> Chromosom
    initArray(demand::Vector{Float64}, supply::Vector{Float64}) -> Array{Float64, 2}
    eval!(self::Chromosom, costFunc::Function)
    mutate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    mutate!(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    cross(self::Chromosom, other::Chromosom)
    cross!(self::Chromosom, other::Chromosom)
    validate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, delta::Float64=0.0000000000001)
"""

# using Random

mutable struct Chromosom
    """
    Struct to represent single chromosom for genetic algorithm.
    """
    result::Array{Float64, 2}
    cost::Float64
    isCalculated::Bool
end

function getCost(self::Chromosom, costFunc::Function)
    if self.isCalculated
        return self.cost
    else
        eval!(self, costFunc)
        return self.cost
    end
end

function Base.copy(c::Chromosom)
    c1 = Chromosom(copy(c.result), copy(c.cost), copy(c.isCalculated))
    return c1
end

function Base.isless(self::Chromosom, other::Chromosom)
    return isless(self.cost, other.cost)
end

function init(_demand::Vector{Float64}, _supply::Vector{Float64})
    """
    Initialization of new chromosom for given demand and supply vectors
    """
    demand = copy(_demand)
    supply = copy(_supply)

    result = initArray(demand, supply)

    return Chromosom(result, 0.0, false)
end

function initArray(demand::Vector{Float64}, supply::Vector{Float64})
    result = zeros(Float64, length(demand), length(supply))

    indices = collect(1 : length(demand)*length(supply))
    shuffle!(indices)
    for idx in indices
        d = div((idx-1), length(supply)) + 1
        s = (idx-1) % length(supply) + 1
        val = min(demand[d], supply[s])
        result[d, s] = val
        demand[d] -= val
        supply[s] -= val
    end
    
    return result
end 

function eval!(self::Chromosom, costFunc::Function)
    self.cost = costFunc(self.result)
    self.isCalculated = true
    return self
end

function mutate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    chromosomCopy = copy(self)
    mutate!(chromosomCopy, demand, supply, nDemand, nSupply)
    return chromosomCopy
end

function mutate!(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, nDemand::Int=2, nSupply::Int=2)
    """
    Perform mutation operator on Chromosom.
    nDemand and nSupply tells about size of newly initialized array(default 2x2).
    """
    self.isCalculated = false

    demandPerm = collect(1:length(demand))
    shuffle!(demandPerm)
    demandPerm = demandPerm[1:nDemand]

    supplyPerm = collect(1:length(supply))
    shuffle!(supplyPerm)
    supplyPerm = supplyPerm[1:nSupply]

    partialDemand = zeros(Float64, nDemand)
    partialSupply = zeros(Float64, nSupply)

    for i = 1 : nDemand
        val = 0.0
        for j in supplyPerm
            val += self.result[demandPerm[i], j]
        end
        partialDemand[i] = val
    end
    
    for i = 1 : nSupply
        val = 0.0
        for j in demandPerm
            val += self.result[j, supplyPerm[i]]
        end
        partialSupply[i] = val
    end

    partialResult = initArray(partialDemand, partialSupply)

    for i = 1 : nDemand
        for j = 1 : nSupply
            self.result[demandPerm[i], supplyPerm[j]] = partialResult[i, j]
        end
    end

    # to drop later
    if !validate(self, demand, supply)
        println("Result array after mutation:")
        println(self.result)
        error("Error while performing mutation.")
    end

    return self
end

function cross(self::Chromosom, other::Chromosom)
    selfCopy = copy(self)
    otherCopy = copy(other)
    cross!(selfCopy, otherCopy)
    return selfCopy, otherCopy
end

function cross!(self::Chromosom, other::Chromosom)
    self.isCalculated = false
    other.isCalculated = false

    c1 = rand()
    c2 = 1.0 - c1
    X = c1 * self.result + c2 * other.result
    Y = c1 * other.result + c2 * self.result
    self.result = X
    other.result = Y

    return self, other
    
end

function validate(self::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, delta::Float64=0.0000000000001)
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