return {
    id = "weight_inventory",
    name = "Inventory Weight",
    min_value = 0,
    calculate_base = function(ch)
        local weight = 0
        for obj in ch:inventory() do
            weight = weight + obj:weight_total_get()
        end
        return weight
    end,
}