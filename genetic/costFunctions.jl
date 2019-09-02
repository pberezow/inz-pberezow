# module costFunctions

#     export makeA, makeB, makeC, makeD, makeE, makeF, makeLinear

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

function makeB(param::Float64, costMatrix::Array{Float64, 2})

    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            if resultMatrix[i] <= param
                result += costMatrix[i] * resultMatrix[i] / param
            elseif resultMatrix[i] <= 2*param
                result += costMatrix[i]
            else
                result += costMatrix[i] * (1 + (resultMatrix[i] - 2*param)/param)
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
            result += costMatrix[i] * (1 / (1 + (resultMatrix[i] - 2*param)^2) + 1 / (1 + (resultMatrix[i] - 9/4*param)^2) + 1 / (1 + (resultMatrix[i] - 7/4*param)^2))
        end
        return result
    end

    return f
end

function makeF(param::Float64, costMatrix::Array{Float64, 2})

    f = function(resultMatrix::Array{Float64, 2})
        result = 0.0
        for i = 1:length(costMatrix)
            result += costMatrix[i] * resultMatrix[i] * (sin(resultMatrix[i] * 5 * pi / 4 / param) + 1)
        end
        return result
    end

    return f
end

# end