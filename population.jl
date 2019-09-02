struct Population
    size::Int
    members::Vector{Member}
    best_member::Member
    mutation_prob::Float
    crossover_prob::Float
    inversion_prob::Float
    # generator
end

function get_best_member(population::Population)
    return population.best_member
end

function next_generation!(population::Population)
end

