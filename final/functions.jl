"""
File contains all cost functions generators.
Each function gets costMatrix + some additional parameters(optional)
    and returns new function defined as "function(resultMatrix::Array{Float64, 2})",
    which can be use as costFunction in Population struct.
"""

function getFunctions(costMatrix::Array{Float64, 2}, setupCostFile::String="", param::Float64=2.0) 
    dict = Dict{String, Function}()

    dict["Linear"] = makeLinear(costMatrix)
    dict["A"] = makeA(param, costMatrix)
    dict["B"] = makeB(5.0, costMatrix)
    dict["C"] = makeC(costMatrix)
    dict["D"] = makeD(costMatrix)
    dict["E"] = makeE(5.0, costMatrix)
    dict["F"] = makeF(5.0, costMatrix)

    if setupCostFile != ""
        dict["SetupCost"] = makeSetupCost(costMatrix, setupCostFile)
    end

    return dict
end

"""
    Returns cost function used in linear transportation problem.
"""
function makeLinear(costMatrix::Array{Float64, 2})

    f = function(resultMatrix::Array{Float64, 2})
        return sum(resultMatrix[i, j] * costMatrix[i, j] for i in 1:size(costMatrix)[1], j in 1:size(costMatrix)[2])
        # result = 0.0
        # for i = 1:length(costMatrix)
        #     result += costMatrix[i] * resultMatrix[i]
        # end
        # return result
    end

    return f
end

function makeA(param::Float64, costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        # return sum(costMatrix[d,s] * (atan(1000*(resultMatrix[d,s]-2))/pi + 0.5 + atan(1000*(resultMatrix[d,s]-4))/pi + 0.5 + atan(1000*(resultMatrix[d,s]-6))/pi + 0.5 + atan(1000*(resultMatrix[d,s]-8))/pi + 0.5 + atan(1000*(resultMatrix[d,s]-10))/pi + 0.5) for d in 1:size(costMatrix)[1], s in 1:size(costMatrix)[2])
        result = 0.0
        for i = 1:length(costMatrix)
            if resultMatrix[i] <= param
                # + 0 
            elseif resultMatrix[i] <= 2*param
                result += costMatrix[i]
            elseif resultMatrix[i] <= 3*param
                result += 2 * costMatrix[i]
            elseif resultMatrix[i] <= 4*param
                result += 3 * costMatrix[i]
            elseif resultMatrix[i] <= 5*param
                result += 4 * costMatrix[i]
            else
                result += 5 * costMatrix[i]
            end
        end
        return result
    end
    
    return f
end

function makeB(param::Float64, costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            if resultMatrix[i] <= param
                result += costMatrix[i] * resultMatrix[i] / param 
            elseif resultMatrix[i] <= 2*param
                result += costMatrix[i]
            else
                result += costMatrix[i] * (1 + (resultMatrix[i] - 2 * param)/param)
            end
        end
        return result
    end
    
    return f
end

function makeC(costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * resultMatrix[i]^2 
        end
        return result
    end
    
    return f
end

function makeD(costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * sqrt(resultMatrix[i])
        end
        return result
    end
    
    return f
end

function makeE(param::Float64, costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * (1.0/(1.0 + (resultMatrix[i] - 2*param)^2) + 1.0/(1.0 + (resultMatrix[i] - 9.0/4.0*param)^2) + 1.0/(1.0 + (resultMatrix[i] - 7.0/4.0*param)^2))
        end
        return result
    end
    
    return f
end

function makeF(param::Float64, costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * resultMatrix[i] * (sin(resultMatrix[i]*5*pi/4/param) + 1)
        end
        return result
    end
    
    return f
end

function makeSetupCost(costMatrix::Array{Float64, 2}, setupCostMatrix::Array{Float64, 2}, delta::Float64=0.0000000001)

    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(resultMatrix)
            if resultMatrix[i] > delta
                result += resultMatrix[i] * costMatrix[i] + setupCostMatrix[i]
            else
                # nothing
            end
        end
        return result
    end

    return f
end

function makeSetupCost(costMatrix::Array{Float64, 2}, setupCostFile::String, delta::Float64=0.0000000001)

    setupCostMatrix = loadSetupCostMatrix(setupCostFile)
    if size(setupCostMatrix) != size(costMatrix)
        error("Wrong size of setupCostMatrix or costMatrix!")
        nothing
    end

    return makeSetupCost(costMatrix, setupCostMatrix, delta)
end