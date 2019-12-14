using JuMP, GLPK, Ipopt
using CPLEX
GeneticNTP = include("geneticPackage.jl")

function optimize(configFile::String, solver::String, costFunction::String, param::Float64=2.0, setupCostFile::String="")

    config = GeneticNTP.loadConfig(configFile)

    cost = config.costMatrix
    supply = config.supply
    demand = config.demand
    println("Config loaded.")

    @assert abs(sum(config.demand) - sum(config.supply)) < 0.000000001

    model = nothing
    if solver == "GLPK"
        println("Using GLPK...")
        model = Model(with_optimizer(GLPK.Optimizer))
    elseif solver == "Ipopt"
        println("Using Ipopt...")
        model = Model(with_optimizer(Ipopt.Optimizer))
    elseif solver == "CPLEX"
        println("Using CPLEX...")
        model = Model(with_optimizer(CPLEX.Optimizer))
    else
        println("Please pick solver - GLPK or Ipopt.")
        error()
    end

    @variable(model, trans[1:length(demand), 1:length(supply)] >= 0)

    if costFunction == "Linear"
        
        @objective(model, Min, sum(cost[i, j] * trans[i, j] for i in 1:length(demand), j in 1:length(supply)))
    
    elseif costFunction == "A"
        
        Pa = 5.0
        @NLobjective(model, Min, sum(cost[i, j] * ( atan(Pa * (trans[i, j] - param)) / pi + 1/2 + atan(Pa * (trans[i, j] - 2*param)) / pi + 1/2 + atan(Pa * (trans[i, j] - 3 * param)) / pi + 1/2 + atan(Pa * (trans[i, j] - 4 * param)) / pi + 1/2 + atan(Pa * (trans[i, j] - 5 * param)) / pi + 1/2 ) for i in 1:length(demand), j in 1:length(supply)))
    
    elseif costFunction == "SetupCost"

        setupCost = GeneticNTP.loadSetupCostMatrix(setupCostFile)
        if size(setupCost) != size(cost)
            error("Wrong sizes of cost matrices!")
        end
        @variable(model, setC[1:size(setupCost)[1], 1:size(setupCost)[2]], Bin)
        bigNumber = sum(demand) + sum(supply)

        @constraint(model, con[i=1:size(setupCost)[1], j=1:size(setupCost)[2]], trans[i, j] <= setC[i, j] * bigNumber)
    
        @objective(model, Min, sum(cost[i, j] * trans[i, j] + setC[i, j] * setupCost[i, j] for i in 1:length(demand), j in 1:length(supply)))

    else
        println("Please pick cost function - Linear or A")
        error()
    end


    @constraint(model, [i in 1:length(demand)], sum(trans[i, j] for j in 1:length(supply)) == demand[i])
    @constraint(model, [j in 1:length(supply)], sum(trans[i, j] for i in 1:length(demand)) == supply[j])

    JuMP.optimize!(model)

    println("DONE.")
    println("Status: ", JuMP.termination_status(model))
    println("Result: ", JuMP.objective_value(model))

    # result_solution = value.(trans)
    # result_objective = objective_value(model)

    # println("VALUE:\n", result_solution)
    # println("\n\nLENGTH:\n", length(result_solution))
    # println("\n\nOBJECTIVE:\n", result_objective)

    return nothing
end

println("START")

configFile = ARGS[1]

solver = ARGS[2]

costFunction = ARGS[3]

param = 2.0

if length(ARGS) > 3
    param = tryparse(Float64, ARGS[4])
end

setupCostFile = ""
if length(ARGS) > 4
    setupCostFile = ARGS[5]
end


optimize(configFile, solver, costFunction, param, setupCostFile)