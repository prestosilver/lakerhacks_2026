const ryl = @import("raylib");

/// Contains quantities of all resources used.
const StarResources = struct
{
    population: f32,
    organic: f32,
    energy: f32,
    mineral: f32,

    /// Initializes the struct by setting all resource values to 0.
    pub fn init_zero() StarResources
    {
        return .{
            .population = 0,
            .organic = 0,
            .energy = 0,
            .mineral = 0
        };
    }

    /// Adds the quantities of another resource struct to this one.
    pub fn add(self: *StarResources, other: StarResources) void
    {
        self.population += other.population;
        self.organic += other.organic;
        self.energy += other.energy;
        self.mineral += other.mineral;
    }

    /// Adds the quantities of another resource struct to this one, subtracting from the other resource struct.
    pub fn exchange(self: *StarResources, other: *StarResources, amount: StarResources) void
    {
        self.population += amount.population;
        self.organic += amount.organic;
        self.energy += amount.energy;
        self.mineral += amount.mineral;

        other.population += amount.population;
        other.organic += amount.organic;
        other.energy += amount.energy;
        other.mineral += amount.mineral;
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
