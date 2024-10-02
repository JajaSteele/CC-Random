local me = peripheral.find("meBridge")

local storage = peripheral.find("minecraft:chest")

local ingredient_list = {
    "minecraft:iron_ingot",
    "minecraft:copper_ingot",
    "minecraft:redstone",

    "minecraft:white_dye",
    "minecraft:orange_dye",
    "minecraft:magenta_dye",
    "minecraft:light_blue_dye",
    "minecraft:yellow_dye",
    "minecraft:lime_dye",
    "minecraft:pink_dye",
    "minecraft:gray_dye",
    "minecraft:light_gray_dye",
    "minecraft:cyan_dye",
    "minecraft:purple_dye",
    "minecraft:blue_dye",
    "minecraft:brown_dye",
    "minecraft:green_dye",
    "minecraft:red_dye",
    "minecraft:black_dye",

    "minecraft:oak_planks",
    "minecraft:spruce_planks",
    "minecraft:birch_planks",
    "minecraft:jungle_planks",
    "minecraft:acacia_planks",
    "minecraft:cherry_planks",
    "minecraft:dark_oak_planks",
    "minecraft:mangrove_planks",
    "minecraft:bamboo_planks",
    "minecraft:crimson_planks",
    "minecraft:warped_planks",

    "minecraft:quartz_block",
    "minecraft:glass",
    "minecraft:leather",
    "minecraft:piston",
    "minecraft:string",
    "minecraft:slime_ball",
    "minecraft:stone",
    "minecraft:granite",
    "minecraft:diorite",
    "minecraft:andesite",
    "minecraft:deepslate",
    "minecraft:stick",
    "minecraft:white_wool",
    "minecraft:wheat",
    "minecraft:glowstone_dust",
    "minecraft:amethyst_shard",
    "minecraft:gold_ingot",

    "minecraft:oak_leaves",
	--"minecraft:spruce_leaves",
	"minecraft:birch_leaves",
	"minecraft:jungle_leaves",
	--"minecraft:acacia_leaves",
	"minecraft:cherry_leaves",
	"minecraft:dark_oak_leaves",
	"minecraft:mangrove_leaves",
	"minecraft:azalea_leaves",
}

local function getItemCount(list, name)
    local count = 0
    for k,v in pairs(list) do
        if v.name == name then
            count = count+v.count
        end
    end
    return count 
end
print("Total amount of ingredients: "..#ingredient_list)

local function isIngredient(name)
	for k,v in pairs(ingredient_list) do
		if name == v then
			return true
		end
	end
end

while true do
    local current_list = storage.list()

	for k, item in pairs(current_list) do
		if not isIngredient(item.name) then
			me.importItem({name=item.name}, "front")
			print("Removed item: "..item.name:match(".+:(.+)"))
		end
	end

    for k, ingredient in pairs(ingredient_list) do
        local current_count = getItemCount(current_list, ingredient)
        if current_count < 64 then
            local ingredient_short = ingredient:match(".+:(.+)")
            local required_amount = 64-current_count
            local me_item = me.getItem({name=ingredient})
            if me_item and me_item.amount and me_item.amount > 0 then
                me.exportItem({name=ingredient, count=required_amount}, "front")
                print("Exported "..ingredient_short.." x"..required_amount)
            elseif me.isItemCraftable({name=ingredient, count=required_amount}) and not me.isItemCrafting({name=ingredient}) then
                me.craftItem({name=ingredient, count=required_amount})
                print("Crafting "..ingredient_short.." x"..required_amount)
            end
        end
    end
    sleep(1)
end