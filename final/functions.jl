"""
File contains all cost functions generators.
Each function gets costMatrix + some additional parameters(optional)
    and returns new function defined as "function(resultMatrix::Array{Float64, 2})",
    which can be use as costFunction in Population struct.
"""

function getFunctions(costMatrix::Array{Float64, 2}, param::Float64=2.0) 
    dict = Dict{String, Function}()

    dict["Linear"] = makeLinear(costMatrix)
    dict["A"] = makeA(param, costMatrix)
    
    return dict
end

"""
    Returns cost function used in linear transportation problem.
"""
function makeLinear(costMatrix::Array{Float64, 2})

    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * resultMatrix[i]
        end
        return result
    end

    return f
end

function makeA(param::Float64, costMatrix::Array{Float64, 2})
    
    f = function(resultMatrix::Array{Float64, 2})
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