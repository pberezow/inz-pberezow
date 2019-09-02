# str 232
# module Chromosom

#     using Random

#     export Chromosom, init, validate, eval!, mutate!, crossover!

mutable struct Chromosom
    resultMatrix::Array{Float64, 2}
    cost::Float64
end

function Base.copy(c::Chromosom)
    c1 = Chromosom(copy(c.resultMatrix), copy(c.cost))
    return c1
end

function init(_demand::Vector{Float64}, _supply::Vector{Float64})
    demand = copy(_demand)
    supply = copy(_supply)
    arr = zeros(Float64, length(demand), length(supply))
    indices = collect(1 : length(demand)*length(supply))
    shuffle!(indices)
    
    for idx in indices
        d = div(idx-1, length(supply)) + 1
        s = idx % length(supply) + 1
        val = min(demand[d], supply[s])
        demand[d] -= val
        supply[s] -= val
        arr[d, s] = val
    end
    
    return Chromosom(arr, 0)
end

function validate(c::Chromosom, demand::Vector{Float64}, supply::Vector{Float64}, delta::Float64)
    """
    Check if member's result matrix is valid.
    """
    for i = 1 : length(demand)
        sum_val = 0
        for j = 1 : length(supply)
            sum_val += c.resultMatrix[i, j]
        end
        if abs(demand[i] - sum_val) > delta
            return false
        end
    end
    
    return true
end

function eval!(c::Chromosom, costFunction::Function)
    """
    Evaluate cost value of member's result matrix.
    """
    c.cost = costFunction(c.resultMatrix)
    return c
end

function mutate!(c::Chromosom, demand::Vector{Float64}, supply::Vector{Float64})
    """
    Mutation operator for nonlinear transportation problem.
    """
    num_dem = rand(2:length(demand))
    num_supp = rand(2:length(supply))
    
    supp_perm = collect(1:length(supply))
    shuffle!(supp_perm)
    dem_perm = collect(1:length(demand))
    shuffle!(dem_perm)
    
    selected_supp = supp_perm[1:num_supp]
    selected_dem = dem_perm[1:num_dem]
    
    new_demand = zeros(Float64, length(selected_dem))
    new_supply = zeros(Float64, length(selected_supp))
    
    for i = 1:length(selected_dem)
        val = 0.0
        for j in selected_supp
            val += c.resultMatrix[selected_dem[i], j]
        end
        new_demand[i] = val
    end
    
    for i = 1:length(selected_supp)
        val = 0.0
        for j in selected_dem
            val += c.resultMatrix[j, selected_supp[i]]
        end
        new_supply[i] = val
    end
    
    arr = zeros(Float64, length(new_demand), length(new_supply))
    indices = collect(1 : length(new_demand)*length(new_supply))
    shuffle!(indices)
    
    for idx in indices
        d = div(idx-1, length(new_supply)) + 1
        s = idx % length(new_supply) + 1
        val = min(new_demand[d], new_supply[s])
        new_demand[d] -= val
        new_supply[s] -= val
        arr[d, s] = val
    end
    
    for i = 1:length(selected_dem)
        for j = 1:length(selected_supp)
            c.resultMatrix[selected_dem[i], selected_supp[j]] = arr[i, j]
        end
    end

    return c
end

function crossover!(this::Chromosom, other::Chromosom)
    """
    Crossover operator for nonlinear transportation problem.
    """
    c1 = rand()
    c2 = 1.0 - c1
    X = c1 * this.resultMatrix + c2 * other.resultMatrix
    Y = c1 * other.resultMatrix + c2 * this.resultMatrix
    this.resultMatrix = X
    other.resultMatrix = Y

    return this, other
end

# end