include("geneticPackage.jl")

if length(ARGS) < 3 || length(ARGS) > 4
    error("Wrong arguments!")
end

configFile = ARGS[1]

maxGeneration = tryparse(Int, ARGS[2])
if isnothing(maxGeneration)
    error("Wrong value of 2nd (maxGeneration) argument!")
end

costFuncName = ARGS[3]

isTestRun = false
if length(ARGS) == 4
    isTestRun = true
end

println("Path: ", configFile)

println("Running on ", Threads.nthreads(), " threads")

result = GeneticNTP.runGA(configFile, maxGeneration, costFuncName, isTestRun)
println("Best result: ", result.cost)