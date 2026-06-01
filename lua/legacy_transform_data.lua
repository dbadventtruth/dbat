local transform = require("lua.transform_condition")

local forms = {
    super_human_1 = { family = "super_human", tier = 1, name = "@YSuper @CHuman @WFirst@n", bonus = 1000000, mult = 2.0, drain = 0.1, requires_pl = 1800000 },
    super_human_2 = { family = "super_human", tier = 2, name = "@YSuper @CHuman @WSecond@n", bonus = 12000000, mult = 3.0, drain = 0.2, requires_pl = 35000000 },
    super_human_3 = { family = "super_human", tier = 3, name = "@YSuper @CHuman @WThird@n", bonus = 50000000, mult = 4.0, drain = 0.2, requires_pl = 190000000 },
    super_human_4 = { family = "super_human", tier = 4, name = "@YSuper @CHuman @WFourth@n", bonus = 270000000, mult = 4.5, drain = 0.2, requires_pl = 1200000000 },
    icer_transform_1 = { family = "icer_transform", tier = 1, name = "@YTransform @WFirst@n", bonus = 400000, mult = 2.0, drain = 0.1, requires_pl = 500000 },
    icer_transform_2 = { family = "icer_transform", tier = 2, name = "@YTransform @WSecond@n", bonus = 7000000, mult = 3.0, drain = 0.2, requires_pl = 17500000 },
    icer_transform_3 = { family = "icer_transform", tier = 3, name = "@YTransform @WThird@n", bonus = 45000000, mult = 4.0, drain = 0.2, requires_pl = 150000000 },
    icer_transform_4 = { family = "icer_transform", tier = 4, name = "@YTransform @WFourth@n", bonus = 200000000, mult = 5.0, drain = 0.2, requires_pl = 850000000 },
    super_namek_1 = { family = "super_namek", tier = 1, name = "@YSuper @CNamek @WFirst@n", bonus = 200000, mult = 2.0, drain = 0.1, requires_pl = 360000 },
    super_namek_2 = { family = "super_namek", tier = 2, name = "@YSuper @CNamek @WSecond@n", bonus = 4000000, mult = 3.0, drain = 0.2, requires_pl = 9500000 },
    super_namek_3 = { family = "super_namek", tier = 3, name = "@YSuper @CNamek @WThird@n", bonus = 65000000, mult = 4.0, drain = 0.2, requires_pl = 220000000 },
    super_namek_4 = { family = "super_namek", tier = 4, name = "@YSuper @CNamek @WFourth@n", bonus = 230000000, mult = 4.5, drain = 0.2, requires_pl = 900000000 },
    shadow_1 = { family = "shadow", tier = 1, name = "@YShadow @WFirst@n", bonus = 1000000, mult = 2.0, drain = 0.1, requires_pl = 1800000 },
    shadow_2 = { family = "shadow", tier = 2, name = "@YShadow @WSecond@n", bonus = 56000000, mult = 4.0, drain = 0.2, requires_pl = 225000000 },
    shadow_3 = { family = "shadow", tier = 3, name = "@YShadow @WThird@n", bonus = 290000000, mult = 5.0, drain = 0.2, requires_pl = 1400000000 },
    mutation_1 = { family = "mutation", tier = 1, name = "@YMutate @WFirst@n", bonus = 100000, mult = 2.0, drain = 0.1, requires_pl = 180000 },
    mutation_2 = { family = "mutation", tier = 2, name = "@YMutate @WSecond@n", bonus = 8500000, mult = 3.0, drain = 0.2, requires_pl = 27500000 },
    mutation_3 = { family = "mutation", tier = 3, name = "@YMutate @WThird@n", bonus = 80000000, mult = 5.0, drain = 0.2, requires_pl = 700000000 },
    potential_unleashed = { family = "super_saiyan", tier = 3, name = "@cPotential @CUnleashed@n", bonus = 240000000, mult = 5.0, drain = 0.2, requires_pl = 1050000000 },
    mature = { family = "bio_android", tier = 1, name = "@YMature@n", bonus = 1000000, mult = 2.0, drain = 0.0, requires_pl = 1800000 },
    semi_perfect = { family = "bio_android", tier = 2, name = "@YSemi@D-@GPerfect@n", bonus = 8000000, mult = 3.0, drain = 0.0, requires_pl = 25000000 },
    perfect = { family = "bio_android", tier = 3, name = "@YPerfect@n", bonus = 70000000, mult = 3.5, drain = 0.0, requires_pl = 220000000 },
    super_perfect = { family = "bio_android", tier = 4, name = "@YSuper @GPerfect@n", bonus = 400000000, mult = 4.0, drain = 0.0, requires_pl = 300000000 },
    android_upgrade_1 = { family = "android_upgrade", tier = 1, name = "@Y1.0@n", bonus = 5000000, mult = 1.0, drain = 0.0, requires_pl = 1000000 },
    android_upgrade_2 = { family = "android_upgrade", tier = 2, name = "@Y2.0@n", bonus = 20000000, mult = 1.0, drain = 0.0, requires_pl = 8000000 },
    android_upgrade_3 = { family = "android_upgrade", tier = 3, name = "@Y3.0@n", bonus = 125000000, mult = 1.0, drain = 0.0, requires_pl = 50000000 },
    android_upgrade_4 = { family = "android_upgrade", tier = 4, name = "@Y4.0@n", bonus = 1000000000, mult = 1.0, drain = 0.0, requires_pl = 300000000 },
    android_upgrade_5 = { family = "android_upgrade", tier = 5, name = "@Y5.0@n", bonus = 2500000000, mult = 1.0, drain = 0.0, requires_pl = 800000000 },
    android_upgrade_6 = { family = "android_upgrade", tier = 6, name = "@Y6.0@n", bonus = 5000000000, mult = 1.0, drain = 0.0, requires_pl = 1200000000 },
    morph_affinity = { family = "majin_morph", tier = 1, name = "@YMorph @WAffinity@n", bonus = 1250000, mult = 2.0, drain = 0.0, requires_pl = 2200000 },
    morph_super = { family = "majin_morph", tier = 2, name = "@YMorph @WSuper@n", bonus = 15000000, mult = 3.0, drain = 0.0, requires_pl = 45000000 },
    morph_true = { family = "majin_morph", tier = 3, name = "@YMorph @WTrue@n", bonus = 340000000, mult = 4.5, drain = 0.0, requires_pl = 1550000000 },
    mystic_1 = { family = "mystic", tier = 1, name = "@YMystic @WFirst@n", bonus = 1100000, mult = 3.0, drain = 0.1, requires_pl = 3000000 },
    mystic_2 = { family = "mystic", tier = 2, name = "@YMystic @WSecond@n", bonus = 115000000, mult = 4.0, drain = 0.2, requires_pl = 650000000 },
    mystic_3 = { family = "mystic", tier = 3, name = "@YMystic @WThird@n", bonus = 270000000, mult = 5.0, drain = 0.2, requires_pl = 1300000000 },
    ascend_1 = { family = "ascend", tier = 1, name = "@YAscend @WFirst@n", bonus = 1300000, mult = 3.0, drain = 0.1, requires_pl = 3600000 },
    ascend_2 = { family = "ascend", tier = 2, name = "@YAscend @WSecond@n", bonus = 80000000, mult = 4.0, drain = 0.2, requires_pl = 300000000 },
    ascend_3 = { family = "ascend", tier = 3, name = "@YAscend @WThird@n", bonus = 300000000, mult = 5.0, drain = 0.2, requires_pl = 1450000000 },
}

local M = {}

function M.form(slug)
    local form = forms[slug]
    if form == nil then error("unknown legacy transform: " .. slug) end
    form.id = form.id or slug
    return form
end

function M.condition(slug)
    return transform.condition(M.form(slug))
end

function M.transformation(slug)
    return transform.transformation(M.form(slug))
end

return M
