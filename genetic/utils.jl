function saveData(supply::Array{Float64, 1}, demand::Array{Float64, 1}, costMatrix::Array{Float64, 2}, filename::String)
    open(filename, "w") do file
        # supply set
        write(file, "set I :=")
        for i = 1:length(supply)
            write(file, " $i")
        end
        write(file, ";\n")

        # demand set
        write(file, "set J :=")
        for i = 1:length(demand)
            write(file, " $i")
        end
        write(file, ";\n")

        # supply values
        write(file, "param a :=")
        for i = 1:length(supply)
            write(file, "\n $i  $(supply[i])")
        end
        write(file, ";\n")

        # demand values
        write(file, "param b :=")
        for i = 1:length(demand)
            write(file, "\n $i  $(demand[i])")
        end
        write(file, ";\n")

        # costMatrix values
        write(file, "param c :")
        for i = 1:length(demand)
            write(file, " $i")
        end
        write(file, " :=")
        for i = 1:length(supply)
            write(file, "\n $i")
            for j = 1:length(demand)
                write(file, " $(costMatrix[i, j])")
            end
        end
        write(file, ";\n")
    end

    return true, filename
end

function readData(filename::String)
    f = open(filename)

    data = read(f, String)

    # drop /* ... */ comments
    while true
        rng1 = findfirst("/*", data)
        if rng1 == nothing || rng1.stop == 0
            rng2 = findfirst("*/", data)
            if rng2 == nothing || rng2.stop == 0
                break
            end
            error("readData - error, line 12")
        end
        rng2 = findfirst("*/", data)
        if rng2 == nothing || rng2.stop == 0
            error("readData - error, line 16")
        end

        len = length(data)
        if rng2.stop != len
            data = data[1:rng1.start-1] * data[rng2.stop+1:end]
        else
            data = data[1:rng1.start-1]
        end
    end

    # drop # comments
    rng1 = findfirst("#", data)
    while true
        if rng1 == nothing
            break
        end
        rng2 = findnext("\n", data, rng1.start)
        if rng2 == nothing
            data = data[1:rng1.start-1]
        else
            data = data[1:rng1.start-1] * data[rng2.stop+1:end]
        end
    end

    data = split(data, ";")

    setI = nothing
    setJ = nothing
    paramA = nothing
    paramB = nothing
    paramC = nothing

    for arg in data
        splitedData = split(arg, ":=")
        if length(splitedData) != 2
            error("readData - error, line 47")
        end
        type, value = handleArgument(arg)
        if type == "set I"
            setI = value
        elseif type == "set J"
            setJ = value
        elseif type == "param a"
            paramA = value
        elseif type == "param b"
            paramB = value
        elseif type == "param c"
            paramC = value
        else
            error("Undefined type of argument")
        end
    end

    # check all parameters 
    if nothing in [setI, setJ, paramA, paramB, paramC]
        error("Some parameters are undefined")
    end
    if length(setI) != length(paramA)
        error()
    end
    if length(setJ) != length(paramB)
        error()
    end
    if size(paramC) != (length(setI), length(setJ))
        error()
    end
    close(f)

    return paramA, paramB, paramC
end

function handleArgument(splitedData::Array{String,2})
    if occursin("set I", splitedData[1])
        return "set I", split(splitedData[2])
    elseif occursin("set J", splitedData[1])
        return "set J", split(splitedData[2])
    elseif occursin("param a", splitedData[1])
        params = split(splitedData[2], "\n")
        result = Array{Float64, 1}()
        for param in params
            append!(result, parse(Float64, param[2]))
        end
        return "param a", result
    elseif occursin("param b", splitedData[1])
        params = split(splitedData[2], "\n")
        result = Array{Float64, 1}()
        for param in params
            append!(result, parse(Float64, param[2]))
        end
        return "param b", result
    elseif occursin("param c", splitedData[1])
        params = split(splitedData[2], "\n")
        result = Array{Float64, 2}()
        for param in params
            append!(result, [parse(Float64, x) for x in split(param)])
        end
        return "param c", result
    else
        # undefined type - wrong data format
        return "Undef", nothing
    end
end