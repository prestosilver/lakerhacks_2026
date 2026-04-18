const std = @import("std");
const rl = @import("raylib");

const Link = @import("Link.zig");
const Camera = @import("Camera.zig");

const GRID_UNIT = 1;
const RADIUS = 0.4;

/// Contains quantities of all resources used.
const StarResources = struct {
    population: f32,
    organic: f32,
    energy: f32,
    mineral: f32,

    /// Initializes the struct by setting all resource values to 0.
    pub fn init_zero() StarResources {
        return .{ .population = 0, .organic = 0, .energy = 0, .mineral = 0 };
    }

    /// Checks if the resources are all 0.
    pub fn is_zero(self: StarResources) bool {
        if (self.population != 0) return false;
        if (self.organic != 0) return false;
        if (self.energy != 0) return false;
        if (self.mineral != 0) return false;

        return true;
    }

    /// Adds the quantities of another resource struct to this one.
    pub fn add(self: *StarResources, other: StarResources) void {
        self.population += other.population;
        self.organic += other.organic;
        self.energy += other.energy;
        self.mineral += other.mineral;
    }

    /// Adds the quantities of another resource struct to this one, subtracting from the other resource struct.
    pub fn exchange(self: *StarResources, other: *StarResources, amount: StarResources) void {
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

x: u16,
y: u16,

/// Total resources that the star system could have/produce.
total_res: StarResources,
/// Resources generated every tick.
gen_res: StarResources,
/// Resources that the star is requesting from other stars.
req_res: StarResources,

/// Cycle length.
cycle_length: f32,
/// Increase (per tick) in cycle.
cycle_speed: f32,
/// Cycle timer.
cycle_timer: f32,

pub fn draw(self: *const Star, camera: Camera) void {
    const world_pos: rl.Vector2 = .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y),
    };

    const to_screen = camera.vector2_world_to_screen(world_pos);
    const screen_size = camera.size_to_screen(RADIUS * GRID_UNIT * 2);

    rl.drawRectangleLinesEx(
        .{
            .x = to_screen.x,
            .y = to_screen.y,
            .width = screen_size,
            .height = screen_size
        },
        2,
        .white,
    );
}

pub fn init(x: u16, y: u16) Star {
    const star: Star = .{
        .x = x,
        .y = y,
        .total_res = .{
            .population = 0,
            .organic = @floatFromInt(rl.getRandomValue(0, 1000)),
            .energy = 0,
            .mineral = @floatFromInt(rl.getRandomValue(0, 60)),
        },
        .gen_res = .init_zero(),
        .req_res = .init_zero(),

        .cycle_length = @floatFromInt(rl.getRandomValue(10000, 30000)),
        .cycle_timer = @floatFromInt(rl.getRandomValue(0, 30000)),
        .cycle_speed = @as(f32, @floatFromInt(rl.getRandomValue(1, 100))) / 10,
    };

    return star;
}

pub fn getRectangle(self: Star) rl.Rectangle
{
    return .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y),
        .width = GRID_UNIT * RADIUS * 2,
        .height = GRID_UNIT * RADIUS * 2
    };
}

/// Called once every tick.
pub fn tick(self: *Star, links: std.ArrayList(Link)) void {
    for (links) |link| {
        var other: ?*Star = null;
        if (link.a == self) {
            other = link.b;
        } else if (link.b == self) {
            other = link.a;
        }

        const o = other orelse continue;

        var linked: bool = false;
        if (self.cycle_timer >= o.cycle_timer and !link.toggle) {
            linked = true;
            link.toggle = true;
        } else if (self.cycle_timer < o.cycle_timer and link.toggle) {
            linked = true;
            link.toggle = false;
        }

        if (!linked) continue;

        if (!o.req_res.is_zero()) {
            //TODO: Swap resources & other stuff.
        }
    }

    self.cycle_timer += 1;
    if (self.cycle_timer >= self.cycle_length) {
        self.cycle_timer -= self.cycle_length;
    }
}
