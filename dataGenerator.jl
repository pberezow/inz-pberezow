module Generators

    using Random
    using JSON

    export genDataWthZerosDiagonal

    include("final/config.jl")

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
