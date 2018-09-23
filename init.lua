plasmagun = {
    -- 2x MkII laser charge.
    max_charge = 400000,
}

-- Register plasma gun.
function plasmagun.register(name, d)
    -- Plasma projectile name.
    local p = name .. "_projectile"

    -- Register projectile.
    tigris.register_projectile(p, {
        texture = "plasmagun_projectile.png",
        size = 0.5,
        timeout = d.time,
        on_any_hit = function()
            return true
        end,
        on_entity_hit = function(self, obj)
            -- Don't hit other plasma bullets of our owner.
            if not (obj.get_luaentity and obj:get_luaentity() and self._owner == obj:get_luaentity()._owner and obj:get_luaentity()._plasmagun) then
                -- Apply heat damage.
                tigris.damage.apply(obj, {heat = d.damage}, self._owner_object)
                return true
            end
        end,
    })

    -- Calculate charge taken per shot.
    local per_shot = plasmagun.max_charge / d.shots

    -- Register gun.
    technic.register_power_tool(name, plasmagun.max_charge)
    minetest.register_tool(name, {
        description = d.description,
        inventory_image = d.image,
        range = 0,

        wear_represents = "technic_RE_charge",
        on_refill = technic.refill_RE_charge,

        on_use = function(itemstack, user)
            -- Handle charge.
            local meta = minetest.deserialize(itemstack:get_metadata())
            if not meta or not meta.charge then
                return
            end
            if meta.charge < per_shot then
                return
            end
            meta.charge = meta.charge - per_shot
            technic.set_RE_wear(itemstack, meta.charge, plasmagun.max_charge)
            itemstack:set_metadata(minetest.serialize(meta))

            -- Launch projectile for each ray.
            for i=1,d.rays do
                local dir = vector.multiply(user:get_look_dir(), d.speed)
                -- Apply spread.
                dir = vector.add(dir, vector.new(math.random() * d.spread - d.spread / 2, 0, math.random() * d.spread - d.spread / 2))
                -- Create projectile.
                tigris.create_projectile(p, {
                    -- Launch from eye height.
                    pos = vector.add(user:getpos(), vector.new(0, user:get_properties().eye_height or 1.625, 0)),
                    velocity = dir,
                    -- Small effect of gravity.
                    gravity = 0.1,
                    owner = user:get_player_name(),
                    owner_object = user,
                }):get_luaentitiy()._plasmagun = true
            end
        end,
    })
end

-- Single bullet, long range.
plasmagun.register("plasmagun:rifle", {
    description = "Plasma rifle",
    image = "plasmagun_rifle.png",
    speed = 20,
    spread = 0,
    rays = 1,
    time = 2,
    damage = 10,
    shots = 80,
})

-- Multiple bullets, short range.
plasmagun.register("plasmagun:shotgun", {
    description = "Plasma shotgun",
    image = "plasmagun_shotgun.png",
    speed = 10,
    spread = 1,
    rays = 4,
    time = 1,
    damage = 4,
    shots = 70,
})

-- Brass barrel, obsidian and diamond focus, carbon steel trigger.
minetest.register_craft({
    output = "plasmagun:rifle",
    recipe = {
        {"technic:brass_ingot", "technic:brass_ingot", "technic:brass_ingot"},
        {"default:obsidian_glass", "default:diamond", "technic:green_energy_crystal"},
        {"", "", "technic:carbon_steel_ingot"},
    },
})

-- Copper coil to split plasma into multiple projectiles.
minetest.register_craft({
    output = "plasmagun:shotgun",
    recipe = {
        {"technic:brass_ingot", "technic:brass_ingot", "technic:brass_ingot"},
        {"default:obsidian_glass", "default:diamond", "technic:green_energy_crystal"},
        {"technic:copper_coil", "", "technic:carbon_steel_ingot"},
    },
})