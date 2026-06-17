local scale = 1000000

return {
    id = "burden",
    name = "Burden",
    min_value = 0,
    max_value = scale,
    calculate_base = function(ch)
        local room = ch:room_get()
        local gravity = 1
        if room ~= nil then gravity = room:gravity_get() end
        if gravity < 1 then gravity = 1 end

        local capacity = ch:der_total("weight_carry_capacity")
        if capacity <= 0 then return scale end

        local weighted = ch:der_total("weight_total") * gravity
        local burden = (weighted * scale) // capacity
        if burden > scale then return scale end
        if burden < 0 then return 0 end
        return burden
    end,
}
