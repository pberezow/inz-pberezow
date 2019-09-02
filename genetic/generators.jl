

function genDemSupVectors(demandLength::Int, supplyLength::Int, sumOfVectorValues::Float64)
    demand = zeros(demandLength)
    supply = zeros(supplyLength)

    sum = 0.0
    for i = 1 : demandLength
        demand[i] = rand(1.0:10.0)
        sum += demand[i]
    end
    demand = sumOfVectorValues * demand / sum

    sum = 0.0
    for i = 1 : supplyLength
        supply[i] = rand(1.0:10.0)
        sum += supply[i]
    end
    supply = sumOfVectorValues * supply / sum

    return demand, supply
end

function genRandData(demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
    demand, supply = genDemSupVectors(demandLength, supplyLength, sumOfVectorValues)
    costMatrix = zeros(Float64, demandLength, supplyLength)

    for i = 1 : length(costMatrix)
        costMatrix[i] = rand() * costMaxVal
    end

    return demand, supply, costMatrix
end

function genRandData(demand::Vector{Float64}, supply::Vector{Float64}, costMaxVal::Float64)
    costMatrix = zeros(Float64, length(demand), length(supply))

    for i = 1 : length(costMatrix)
        costMatrix[i] = rand() * costMaxVal
    end

    return demand, supply, costMatrix
end

function genDataWthZerosCost(demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
    demand, supply = genDemSupVectors(demandLength, supplyLength, sumOfVectorValues)
    costMatrix = zeros(Float64, demandLength, supplyLength)

    # vector of supply indices - for picking 0.0 cost value in costMatrix row
    vec = Array(1:length(supply))
    shuffle!(vec)

    for i = 1 : length(demand)
        shuffle!(vec)
        
        for j = 1 : length(supply)
            if length(vec) == 0
                if j == 1
                    costMatrix[i, j] = 0.0
                else
                    costMatrix[i, j] = rand() * costMaxVal
                end

            elseif j == last(vec)
                costMatrix[i, j] = 0.0
            
            else
                costMatrix[i, j] = rand() * costMaxVal
            
            end
        end

        pop!(vec)
    end
    return demand, supply, costMatrix
end

function genDataWthZerosCost(demand::Vector{Float64}, supply::Vector{Float64}, costMaxVal::Float64)

    costMatrix = zeros(Float64, length(demand), length(supply))

    # vector of supply indices - for picking 0.0 cost value in costMatrix row
    vec = Array(1:length(supply))
    shuffle!(vec)

    for i = 1 : length(demand)
        shuffle!(vec)
        
        for j = 1 : length(supply)
            if length(vec) == 0
                if j == 1
                    costMatrix[i, j] = 0.0
                else
                    costMatrix[i, j] = rand() * costMaxVal
                end

            elseif j == last(vec)
                costMatrix[i, j] = 0.0
            
            else
                costMatrix[i, j] = rand() * costMaxVal
            
            end
        end

        pop!(vec)
    end

    return demand, supply, costMatrix
end

function genDataWthZerosDiagonal(demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
    demand, supply = genDemSupVectors(demandLength, supplyLength, sumOfVectorValues)
    costMatrix = zeros(Float64, demandLength, supplyLength)

    for i = 1 : length(demand)
        for j = 1 : length(supply)
            if i == j
                costMatrix[i, j] = 0.0
            else
                costMatrix[i, j] = rand() * costMaxVal
            end
        end
    end

    return demand, supply, costMatrix
end

function genDataWthZerosDiagonal(demand::Vector{Float64}, supply::Vector{Float64}, costMaxVal::Float64)
    costMatrix = zeros(Float64, length(demand), length(supply))

    for i = 1 : length(demand)
        for j = 1 : length(supply)
            if i == j
                costMatrix[i, j] = 0.0
            else
                costMatrix[i, j] = rand() * costMaxVal
            end
        end
    end

    return demand, supply, costMatrix
end