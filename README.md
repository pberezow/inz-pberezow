# Genetic Algorithm for Nonlinear Transportation Problem
This project contains genetic algorithm used to solve Nonlinear Transportation Problem.
Algorithm is a part of bachelor's thesis.
Project is written in Julia v1.1

### Author - Piotr Berezowski

## Short description of files

+ geneticPackage.jl - module definition (GeneticNTP)
+ chromosom.jl - all functions related to Chromosom (initialization, genetic operators, etc.)
+ population.jl - all functions related to population of chromosomes and algorithm (population init, selection, etc.)
+ config.jl - defines structure to store configuration of population, and functions to write/read configuration files
+ functions - definitions of cost functions used in nonlinear transportation problem to calculate cost of solution

## TODO:
- [x] Chromosom's representation
- [x] Genetic operators
- [x] First version of algorithm
- [x] Handling configuration files
- [x] Functions to draw visualizations
- [x] Parallel version of algorithm
- [x] Optimization
- [ ] Final version of algorithm
- [X] Comparsion with other algorithms


## TODO2:
- [x] Add mutation rate
- [x] Think about other ways of creating next generation of chromosoms (selection)
- [x] Think about other crossover operators
- [x] Implement second mutation operator from book

- [ ] Swap to Float32