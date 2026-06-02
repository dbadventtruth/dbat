local transform = require("lua.transform_condition")

local RACE_HUMAN = 0
local RACE_ICER = 2
local RACE_KONATSU = 3
local RACE_NAMEK = 4
local RACE_MUTANT = 5
local RACE_HALFBREED = 7
local RACE_BIO = 8
local RACE_ANDROID = 9
local RACE_MAJIN = 11
local RACE_KAI = 12
local RACE_TRUFFLE = 13

local family_defaults = {
    super_human = { races = { RACE_HUMAN }, sort_base = 200 },
    icer_transform = { races = { RACE_ICER }, sort_base = 300 },
    super_namek = { races = { RACE_NAMEK }, sort_base = 400 },
    shadow = { races = { RACE_KONATSU }, sort_base = 500 },
    mutation = { races = { RACE_MUTANT }, sort_base = 600 },
    bio_android = { races = { RACE_BIO }, sort_base = 700 },
    android_upgrade = { races = { RACE_ANDROID }, sort_base = 800 },
    majin_morph = { races = { RACE_MAJIN }, sort_base = 900 },
    mystic = { races = { RACE_KAI }, sort_base = 1000 },
    ascend = { races = { RACE_TRUFFLE }, sort_base = 1100 },
}

local forms = {
    super_human_1 = { alias = { "sh1", "superhuman1" }, family = "super_human", tier = 1, name = "@YSuper @CHuman @WFirst@n", bonus = 1000000, mult = 2.0, drain = 0.1, requires_pl = 1800000 },
    super_human_2 = { alias = { "sh2", "superhuman2" }, family = "super_human", tier = 2, name = "@YSuper @CHuman @WSecond@n", bonus = 12000000, mult = 3.0, drain = 0.2, requires_pl = 35000000 },
    super_human_3 = { alias = { "sh3", "superhuman3" }, family = "super_human", tier = 3, name = "@YSuper @CHuman @WThird@n", bonus = 50000000, mult = 4.0, drain = 0.2, requires_pl = 190000000 },
    super_human_4 = { alias = { "sh4", "superhuman4" }, family = "super_human", tier = 4, name = "@YSuper @CHuman @WFourth@n", bonus = 270000000, mult = 4.5, drain = 0.2, requires_pl = 1200000000 },
    icer_transform_1 = { alias = { "icer1", "transform1" }, family = "icer_transform", tier = 1, name = "@YTransform @WFirst@n", bonus = 400000, mult = 2.0, drain = 0.1, requires_pl = 500000 },
    icer_transform_2 = { alias = { "icer2", "transform2" }, family = "icer_transform", tier = 2, name = "@YTransform @WSecond@n", bonus = 7000000, mult = 3.0, drain = 0.2, requires_pl = 17500000 },
    icer_transform_3 = { alias = { "icer3", "transform3" }, family = "icer_transform", tier = 3, name = "@YTransform @WThird@n", bonus = 45000000, mult = 4.0, drain = 0.2, requires_pl = 150000000 },
    icer_transform_4 = { alias = { "icer4", "transform4" }, family = "icer_transform", tier = 4, name = "@YTransform @WFourth@n", bonus = 200000000, mult = 5.0, drain = 0.2, requires_pl = 850000000 },
    super_namek_1 = { alias = { "sn1", "supernamek1" }, family = "super_namek", tier = 1, name = "@YSuper @CNamek @WFirst@n", bonus = 200000, mult = 2.0, drain = 0.1, requires_pl = 360000 },
    super_namek_2 = { alias = { "sn2", "supernamek2" }, family = "super_namek", tier = 2, name = "@YSuper @CNamek @WSecond@n", bonus = 4000000, mult = 3.0, drain = 0.2, requires_pl = 9500000 },
    super_namek_3 = { alias = { "sn3", "supernamek3" }, family = "super_namek", tier = 3, name = "@YSuper @CNamek @WThird@n", bonus = 65000000, mult = 4.0, drain = 0.2, requires_pl = 220000000 },
    super_namek_4 = { alias = { "sn4", "supernamek4" }, family = "super_namek", tier = 4, name = "@YSuper @CNamek @WFourth@n", bonus = 230000000, mult = 4.5, drain = 0.2, requires_pl = 900000000 },
    shadow_1 = { alias = { "shadow1" }, family = "shadow", tier = 1, name = "@YShadow @WFirst@n", bonus = 1000000, mult = 2.0, drain = 0.1, requires_pl = 1800000 },
    shadow_2 = { alias = { "shadow2" }, family = "shadow", tier = 2, name = "@YShadow @WSecond@n", bonus = 56000000, mult = 4.0, drain = 0.2, requires_pl = 225000000 },
    shadow_3 = { alias = { "shadow3" }, family = "shadow", tier = 3, name = "@YShadow @WThird@n", bonus = 290000000, mult = 5.0, drain = 0.2, requires_pl = 1400000000 },
    mutation_1 = { alias = { "mutate1", "mutation1" }, family = "mutation", tier = 1, name = "@YMutate @WFirst@n", bonus = 100000, mult = 2.0, drain = 0.1, requires_pl = 180000 },
    mutation_2 = { alias = { "mutate2", "mutation2" }, family = "mutation", tier = 2, name = "@YMutate @WSecond@n", bonus = 8500000, mult = 3.0, drain = 0.2, requires_pl = 27500000 },
    mutation_3 = { alias = { "mutate3", "mutation3" }, family = "mutation", tier = 3, name = "@YMutate @WThird@n", bonus = 80000000, mult = 5.0, drain = 0.2, requires_pl = 700000000 },
    potential_unleashed = { alias = { "potential", "pu", "ssj3", "super saiyan 3", "super saiyan third" }, races = { RACE_HALFBREED }, sort_order = 103, family = "super_saiyan", tier = 3, name = "@cPotential @CUnleashed@n", bonus = 240000000, mult = 5.0, drain = 0.2, requires_pl = 1050000000 },
    mature = { alias = { "mature" }, family = "bio_android", tier = 1, name = "@YMature@n", bonus = 1000000, mult = 2.0, drain = 0.0, requires_pl = 1800000 },
    semi_perfect = { alias = { "semi", "semiperfect" }, family = "bio_android", tier = 2, name = "@YSemi@D-@GPerfect@n", bonus = 8000000, mult = 3.0, drain = 0.0, requires_pl = 25000000 },
    perfect = { alias = { "perfect" }, family = "bio_android", tier = 3, name = "@YPerfect@n", bonus = 70000000, mult = 3.5, drain = 0.0, requires_pl = 220000000 },
    super_perfect = { alias = { "superperfect" }, family = "bio_android", tier = 4, name = "@YSuper @GPerfect@n", bonus = 400000000, mult = 4.0, drain = 0.0, requires_pl = 300000000 },
    android_upgrade_1 = { alias = { "upgrade1", "android1", "1.0" }, family = "android_upgrade", tier = 1, name = "@Y1.0@n", bonus = 5000000, mult = 1.0, drain = 0.0, requires_pl = 1000000 },
    android_upgrade_2 = { alias = { "upgrade2", "android2", "2.0" }, family = "android_upgrade", tier = 2, name = "@Y2.0@n", bonus = 20000000, mult = 1.0, drain = 0.0, requires_pl = 8000000 },
    android_upgrade_3 = { alias = { "upgrade3", "android3", "3.0" }, family = "android_upgrade", tier = 3, name = "@Y3.0@n", bonus = 125000000, mult = 1.0, drain = 0.0, requires_pl = 50000000 },
    android_upgrade_4 = { alias = { "upgrade4", "android4", "4.0" }, family = "android_upgrade", tier = 4, name = "@Y4.0@n", bonus = 1000000000, mult = 1.0, drain = 0.0, requires_pl = 300000000 },
    android_upgrade_5 = { alias = { "upgrade5", "android5", "5.0" }, family = "android_upgrade", tier = 5, name = "@Y5.0@n", bonus = 2500000000, mult = 1.0, drain = 0.0, requires_pl = 800000000 },
    android_upgrade_6 = { alias = { "upgrade6", "android6", "6.0" }, family = "android_upgrade", tier = 6, name = "@Y6.0@n", bonus = 5000000000, mult = 1.0, drain = 0.0, requires_pl = 1200000000 },
    morph_affinity = { alias = { "affinity", "morph1" }, family = "majin_morph", tier = 1, name = "@YMorph @WAffinity@n", bonus = 1250000, mult = 2.0, drain = 0.0, requires_pl = 2200000 },
    morph_super = { alias = { "morph2", "morphsuper" }, family = "majin_morph", tier = 2, name = "@YMorph @WSuper@n", bonus = 15000000, mult = 3.0, drain = 0.0, requires_pl = 45000000 },
    morph_true = { alias = { "morph3", "true" }, family = "majin_morph", tier = 3, name = "@YMorph @WTrue@n", bonus = 340000000, mult = 4.5, drain = 0.0, requires_pl = 1550000000 },
    mystic_1 = { alias = { "mystic1" }, family = "mystic", tier = 1, name = "@YMystic @WFirst@n", bonus = 1100000, mult = 3.0, drain = 0.1, requires_pl = 3000000 },
    mystic_2 = { alias = { "mystic2" }, family = "mystic", tier = 2, name = "@YMystic @WSecond@n", bonus = 115000000, mult = 4.0, drain = 0.2, requires_pl = 650000000 },
    mystic_3 = { alias = { "mystic3" }, family = "mystic", tier = 3, name = "@YMystic @WThird@n", bonus = 270000000, mult = 5.0, drain = 0.2, requires_pl = 1300000000 },
    ascend_1 = { alias = { "ascend1" }, family = "ascend", tier = 1, name = "@YAscend @WFirst@n", bonus = 1300000, mult = 3.0, drain = 0.1, requires_pl = 3600000 },
    ascend_2 = { alias = { "ascend2" }, family = "ascend", tier = 2, name = "@YAscend @WSecond@n", bonus = 80000000, mult = 4.0, drain = 0.2, requires_pl = 300000000 },
    ascend_3 = { alias = { "ascend3" }, family = "ascend", tier = 3, name = "@YAscend @WThird@n", bonus = 300000000, mult = 5.0, drain = 0.2, requires_pl = 1450000000 },
}

local M = {}

function M.form(slug)
    local form = forms[slug]
    if form == nil then error("unknown legacy transform: " .. slug) end
    form.id = form.id or slug
    local defaults = family_defaults[form.family]
    if defaults ~= nil then
        form.races = form.races or defaults.races
        form.sort_order = form.sort_order or defaults.sort_base + (form.tier or 0)
    end
    return form
end

function M.condition(slug)
    return transform.condition(M.form(slug))
end

function M.transformation(slug)
    return transform.transformation(M.form(slug))
end

return M
