return {
    id = "weight_equipment",
    name = "Equipment Weight",
    min_value = 0,
    calculate_base = function(ch)
        local weight = 0
        for _, obj in ch:equipment() do
            weight = weight + obj:weight_total_get()
        end
        return weight
    end,
}
