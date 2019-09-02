# metoda bruteforce
# cost_matrix - macierz kosztu
# demand - wektor popyt
# supply - wektor podaż 
# http://kmp.wm.tu.koszalin.pl/cms/dydaktyka/atomkowska/atomkowska_22.pdf
function calc_bruteforce(cost_matrix, demand, supply) {
    if size(cost_matrix)[1] != size(supply)[1]
        error("Wrong supply dim!")
    end
    if size(cost_matrix)[2] != size(demand)[1]
        error("Wrong demand dim!")
    end

    
}

function calc_cost(cost_matrix, result_matrix)
    result = 0
    for i = 1 : size(cost_matrix)[1]
        for j = 1 : size(cost_matrix)[2]
            result += cost_matrix[i, j] * result_matrix[i, j]
        end
    end
    return result
end

function check_arguments(cost_matrix, demand, supply)
    # check parameters
    if size(cost_matrix)[1] != size(demand)[1]
        error("Nieprawidłowa długość wektora popytu!")
    end
    if size(cost_matrix)[2] != size(supply)[1]
        error("Nieprawidłowa długość wektora podaży!")
    end
    if sum(demand) != sum(supply)
        error("Zadanie niezbilansowane.")
    end
end

# metoda gornego-lewego rogu
function calc_transport1(cost_matrix, _demand, _supply)
    check_arguments(cost_matrix, _demand, _supply)
    supply = copy(_supply)
    demand = copy(_demand)

    # (demand_dim, supply_dim)
    arr = zeros(Int, length(demand)*length(supply))
    arr = reshape(arr, length(demand), length(supply))

    s_idx = 1
    d_idx = 1
    while s_idx <= length(supply) && d_idx <= length(demand)
        if supply[s_idx] > demand[d_idx]
            arr[d_idx, s_idx] = demand[d_idx]
            
            supply[s_idx] = supply[s_idx] - demand[d_idx]
            demand[d_idx] = 0

            d_idx += 1
        elseif supply[s_idx] < demand[d_idx]
            arr[d_idx, s_idx] = supply[s_idx]

            demand[d_idx] = demand[d_idx] - supply[s_idx]
            supply[s_idx] = 0

            s_idx += 1
        else
            arr[d_idx, s_idx] = supply[s_idx]
            
            supply[s_idx] = 0
            demand[d_idx] = 0

            s_idx += 1
            d_idx += 1
        end
    end
    return arr
end

# metoda najmniejszego elementu
function calc_transport2(_cost_matrix, _demand, _supply)
    check_arguments(_cost_matrix, _demand, _supply)

    demand = copy(_demand)
    supply = copy(_supply)
    cost_matrix = copy(_cost_matrix)

    arr = zeros(Int, length(demand)*length(supply))
    arr = reshape(arr, length(demand), length(supply))

    sum_all = 0
    all = sum(_demand)

    while sum_all < all
        d_idx, s_idx = find_first_lowest_cost(cost_matrix, demand, supply)

        if supply[s_idx] > demand[d_idx]
            arr[d_idx, s_idx] = demand[d_idx]
            
            supply[s_idx] -= demand[d_idx]
            demand[d_idx] = 0
        elseif supply[s_idx] < demand[d_idx]
            arr[d_idx, s_idx] = supply[s_idx]
            
            demand[d_idx] -= supply[s_idx]
            supply[s_idx] = 0
        else
            arr[d_idx, s_idx] = supply[s_idx]

            supply[s_idx] = 0
            demand[d_idx] = 0
        end

        sum_all += arr[d_idx, s_idx]
    end
    return arr
end

function find_first_lowest_cost(cost_matrix, demand, supply)
    d_idx = -1
    s_idx = -1
    min_cost = typemax(typeof(cost_matrix[1]))
    for i = 1 : length(supply)
        if supply[i] == 0
            continue
        end
        for j = 1 : length(demand)
            if demand[j] == 0
                continue
            end
            if cost_matrix[j, i] < min_cost
                d_idx = j
                s_idx = i
                min_cost = cost_matrix[j, i]
            end
        end
    end
    return d_idx, s_idx
end

function loc_min_element(arr, ret_idx::Bool, bigger_than::Number)
    min_val = typemax(typeof(arr[1]))
    idx = -1
    for i = 1 : length(arr)
        if arr[i] < min_val && arr[i] > bigger_than
            min_val = arr[i]
            idx = i
        end
    end
    if ret_idx
        return idx
    else
        return min_val
    end
end

function loc_max_element(arr, ret_idx::Bool, lower_than::Number)
    max_val = typemin(typeof(arr[1]))
    idx = -1
    for i = 1 : length(arr)
        if arr[i] > max_val && arr[i] < lower_than
            max_val = arr[i]
            idx = i
        end
    end
    if ret_idx
        return idx
    else
        return max_val
    end
end

# metoda VAM
function calc_transport3(_cost_matrix, _demand, _supply)
    check_arguments(_cost_matrix, _demand, _supply)

    demand = copy(_demand)
    supply = copy(_supply)
    cost_matrix = copy(_cost_matrix)

    arr = zeros(Int, length(demand)*length(supply))
    arr = reshape(arr, length(demand), length(supply))

    minus_demand = zeros(Int, length(demand))
    minus_supply = zeros(Int, length(supply))

    for i = 1 : length(supply)
        min1 = typemax(Int)
        min2 = typemax(Int)
        for j = 1 : length(demand)
            if cost_matrix[j, i] < min2
                if cost_matrix[j, i] < min1
                    min2 = min1
                    min1 = cost_matrix[j, i]
                else
                    min2 = cost_matrix[j, i]
                end
            end
        end
        minus_supply[i] = min2 - min1
    end

    for i = 1 : length(demand)
        min1 = typemax(Int)
        min2 = typemax(Int)
        for j = 1 : length(supply)
            if cost_matrix[i, j] < min2
                if cost_matrix[i, j] < min1
                    min2 = min1
                    min1 = cost_matrix[i, j]
                else
                    min2 = cost_matrix[i, j]
                end
            end
        end
        minus_demand[i] = min2 - min1
    end

    sum_all = 0
    all = sum(demand)

    while sum_all < all
        s_idx = -1
        d_idx = -1

        if maximum(minus_demand) > maximum(minus_supply)
            max_idx = loc_max_element(minus_demand, true, typemax(Int))
            min_val = typemax(Int)
            min_idx = loc_min_element(minus_supply, true, -1)
            d_idx = max_idx
            s_idx = min_idx
        else
            max_idx = loc_max_element(minus_supply, true, typemax(Int))
            min_val = typemax(Int)
            min_idx = loc_min_element(minus_demand, true, -1)
            d_idx = min_idx
            s_idx = max_idx
        end

        if supply[s_idx] > demand[d_idx]
            arr[d_idx, s_idx] = demand[d_idx]
            supply[s_idx] -= demand[d_idx]
            demand[d_idx] = 0
            minus_demand[d_idx] = -1
        elseif supply[s_idx] < demand[d_idx]
            arr[d_idx, s_idx] = supply[s_idx]
            demand[d_idx] -= supply[s_idx]
            supply[s_idx] = 0
            minus_supply[s_idx] = -1
        else
            arr[d_idx, s_idx] = supply[s_idx]
            supply[s_idx] = 0
            demand[d_idx] = 0
            minus_supply[s_idx] = -1
            minus_demand[d_idx] = -1
        end

        sum_all += arr[d_idx, s_idx]
    end
    return arr
end

# supply = [20,30,10,40]
# demand = [10,15,30,10,35]