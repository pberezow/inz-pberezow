module Generators

    using Random
    using JSON
    using Distributions

    export genDataWthZerosDiagonal, genMatrix, genVector

    include("final/config.jl")
# type::Type, populationSize::Int, eliteProc::Float64, mutationProb::Float64, mutationRate::Float64, crossoverProb::Float64, mode::Int, numberOfSeparateGenerations::Int
    function genMatrix(meanVal::Float64, stdVal::Float64, maxVal::Float64, size::Tuple{Int,Int})
        r = Normal(meanVal, stdVal)
        tr = Truncated(r, 0.0, maxVal)
        matrix = rand(tr, size[1], size[2])
        # matrix32 = Float32.(matrix)

        return matrix
    end

    function genMatrix(minVal::Float64, maxVal::Float64, size::Tuple{Int, Int})
        matrix = rand(minVal:0.001:maxVal, size...)
        return matrix
    end

    function genVector(vecLength::Int, vecSum::Int, step::Int=10, minVal::Int=1)
        vec = ones(Int, vecLength)
        
        while(sum(vec) < vecSum)
            idx = rand(1:vecLength)
            vec[idx] += rand(1:step)
        end
        while(sum(vec) != vecSum)
            idx = rand(1:vecLength)
            if vec[idx] > minVal
                vec[idx] -= 1
            end
        end

        return vec
    end

    function genVector(sumVal::Float64, stdVal::Float64, vecLength::Int)
        # vec = Vector{Float64}(undef, vecLength)

        r = Normal(sumVal/vecLength, stdVal)
        tr = Truncated(r, 0.0, 100.0)
        rArr = rand(tr, vecLength)
        s = sum(rArr)

        # for i = 1 : vecLength
        vec = sumVal * rArr / s
        # end
        return vec
    end

    function genDataWthZerosDiagonal(filename::String, mutationProb::Float64, crossoverProb::Float64, populationSize::Int, eliteProc::Float64, demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
        demand, supply, costMatrix = genDataWthZerosDiagonal(demandLength, supplyLength, costMaxVal, sumOfVectorValues)

        config = Config(mutationProb, 0.05, crossoverProb, populationSize, eliteProc, costMatrix, demand, supply, false)
        validate!(config)
        saveConfig(config, filename)
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

    function genRandData(filename::String, mutationProb::Float64, crossoverProb::Float64, populationSize::Int, eliteProc::Float64, demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
        demand, supply, costMatrix = genRandData(demandLength, supplyLength, costMaxVal, sumOfVectorValues)

        config = Config(mutationProb, 0.05, crossoverProb, populationSize, eliteProc, costMatrix, demand, supply, false)
        validate!(config)
        saveConfig(config, filename)
    end

    function genRandData(demandLength::Int, supplyLength::Int, costMaxVal::Float64, sumOfVectorValues::Float64)
        demand, supply = genDemSupVectors(demandLength, supplyLength, sumOfVectorValues)
        costMatrix = zeros(Float64, demandLength, supplyLength)
    
        for i = 1 : length(demand)
            for j = 1 : length(supply)
                costMatrix[i, j] = rand() * costMaxVal
            end
        end
    
        return demand, supply, costMatrix
    end

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
    

end
