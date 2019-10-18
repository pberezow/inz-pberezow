# all functions used to create config object
# config object is used by Population class to set up parameters
# like mutationProb, crossoverProb etc.

mutable struct Config
    size::Int64
    
    mutationProb::Float64
    crossoverProb::Float64
    
    isCostMatrixSet::Bool
    costMatrix::Array{Float64, 2}
    
    isDemandSet::Bool
    demand::Vector{Float64}
    
    isSupplySet::Bool
    supply::Vector{Float64}
end

function saveConfig(config::Config, filename::String)
    status, msg = verifyConfig(config)
    if !status
        error(msg)
    end

    open(filename, "w") do file
        


end

function verifyConfig(config::Config)
    # check if Config object is complete
    # return (status::Bool, msg::String)

    if config.size < 1
        return false, "size must be greater than 0!"
    end

    if 0.0 > config.mutationProb || 1.0 < config.mutationProb
        return false, "value of mutationProb must be float between 0 and 1!"
    end

    if 0.0 > config.crossoverProb || 1.0 < config.crossoverProb
        return false, "value of crossoverProb must be float between 0 and 1!"
    end

    if !config.isDemandSet
        return false, "demand vector must be set!"
    end

    if !config.isSupplySet
        return false, "supply vector must be set!"
    end

    if !config.isCostMatrixSet
        return false, "costMatrix must be set!"
    end

    if size(config.costMatrix) != (length(config.demand), length(config.supply))
        return false, "invalid costMatrix, demand or supply size!"
    end

    return true, "it's fine"

end