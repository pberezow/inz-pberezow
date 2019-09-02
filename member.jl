# https://www.researchgate.net/publication/278037485_Rafal_Pronko_ZASTOSOWANIE_KLASYCZNEGO_ALGORYTMU_GENETYCZNEGO_DO_ROZWIAZANIA_ZBILANSOWANEGO_ZAGADNIENIA_TRANSPORTOWEGO
# http://file.scirp.org/Html/15-7400665_16769.htm

# https://docplayer.pl/8154284-Zagadnienie-transportowe-w-wersji-liniowej-i-nieliniowej.html
# Chromosome
struct Member
    # dim - (demand, supply)
    result_matrix::Array{Integer, 2}
    cost::Integer
end

function eval!(member::Member, cost_matrix::Array{Integer, 2})
    """
    Evaluate cost value of member's result matrix.
    """
    member.cost = 0
    for i = 1 : size(cost_matrix)[1]
        for j = 1 : size(cost_matrix)[2]
            member.cost += cost_matrix[i, j] * member.result_matrix[i, j]
        end
    end
end

function check_result(member::Member, demand::Vector, supply::Vector)
    """
    Check if member's result matrix is valid.
    """
    for i = 1 : length(demand)
        sum_val = 0
        for j = 1 : length(supply)
            sum_val += member.result_matrix[i, j]
        end
        if demand[i] != sum_val
            return false
        end
    end

    for i = 1 : length(supply)
        sum_val = 0
        for j = 1 : length(demand)
            sum_val += member.result_matrix[j, i]
        end
        if supply[i] != sum_val
            return false
        end
    end
    return true
end

function mutate!(member::Member)
end

function crossover!(this::Member, other::Member)
end

function invert!(member::Member)
end

function init(_demand::Vector, _supply::Vector)
    demand = copy(_demand)
    supply = copy(_supply)
    arr = zeros(Int, length(demand), length(supply))
    indices = collect(1 : length(demand)*length(supply))
    shuffle!(indices)

    for idx in indices
        d = div(idx-1, length(supply))+1
        s = idx % length(supply) + 1
        val = min(demand[d], supply[s])
        demand[d] -= val
        supply[s] -= val
        arr[d, s] = val
    end

    return Member(arr, 0)
end

