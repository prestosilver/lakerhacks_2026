const std = @import("std");
const ryl = @import("raylib");

const Link = @import("Link.zig");

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

    /// Checks if the resources are all 0.
    pub fn is_zero(self: StarResources) bool
    {
        if(self.population != 0) return false;
        if(self.organic != 0) return false;
        if(self.energy != 0) return false;
        if(self.mineral != 0) return false;

        return true;
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

/// Called once every tick.
pub fn tick(self: *Star, links: std.ArrayList(Link)) void
{
    for(links) |link|
    {
        var other: ?*Star = null;
        if(link.a == self)
        {
            other = link.b;
        }
        else if(link.b == self)
        {
            other = link.a;
        }

        const o = other orelse continue;
        if(!o.req_res.is_zero())
        {
            //TODO.
        }
    }
}
