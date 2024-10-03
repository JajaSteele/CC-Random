local d = peripheral.find("statue_workbench")

d.setCubes(
    {
        {
            x1=0,
            x2=16,
            y1=0,
            y2=1,
            z1=0,
            z2=2,
            tint = 0xFFFFFF,
            texture="minecraft:block/stone"
        },
        {
            x1=0,
            x2=16,
            y1=0,
            y2=1,
            z1=14,
            z2=16,
            tint = 0xFFFFFF,
            texture="minecraft:block/stone"
        },
        {
            x1=0,
            x2=2,
            y1=0,
            y2=1,
            z1=2,
            z2=14,
            tint = 0xFFFFFF,
            texture="minecraft:block/stone"
        },
        {
            x1=14,
            x2=16,
            y1=0,
            y2=1,
            z1=2,
            z2=14,
            tint = 0xFFFFFF,
            texture="minecraft:block/stone"
        }
    }
)

d.setCubes(
    {
        {
            x1=0,
            x2=16,
            y1=0,
            y2=16,
            z1=0,
            z2=16,
            tint = 0xFFFFFF,
            texture="minecraft:block/red_nether_bricks",
            opacity=0.5,
        }
    }
)