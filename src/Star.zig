const ryl = @import("raylib");

/// Contains quantities of all resources used.
const StarResources = struct
{
    population: f32,
    organic: f32,
    energy: f32,
    mineral: f32,

    pub fn init_zero() StarResources
    {
        return .{
            .population = 0,
            .organic = 0,
            .energy = 0,
            .mineral = 0
        };
    }
};

pub const Star = @This();

/// Total resources that the star system could have/produce.
total_res: StarResources,
/// Resources generated every tick.
gen_res: StarResources,
/// Resources that the star is requesting from other stars.
req_res: StarResources,

pub fn init() Star
{
    const star: Star = .{
        .total_res = .{
            .population = 0,
            .organic = ryl.getRandomValue(0, 1000),
            .energy = 0,
            .mineral = ryl.getRandomValue(0, 60)
        },
        .gen_res = .init_zero(),
        .req_res = .init_zero()
    };

    return star;
}

pub fn tick() void
{
    
}
