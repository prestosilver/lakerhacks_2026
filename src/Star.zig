const std = @import("std");
const rl = @import("raylib");

const Link = @import("Link.zig");
const Camera = @import("Camera.zig");

const GRID_UNIT = 1;
const RADIUS = 0.2;

const SELECTION_OUTLINE_BORDER = 0.1;

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

texture: *const rl.Texture,

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

/// ID of the faction owner. 0 if unclaimed.
owner: usize,

/// Color of the background cell, determined by the owning faction.
faction_color: rl.Color = .blank,

mouse_hovering: bool,

pub fn draw(self: *const Star, camera: Camera, is_selected: bool) void {
    const world_pos: rl.Vector2 = .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y),
    };

    const to_screen = camera.vector2_world_to_screen(world_pos);
    const screen_size = camera.size_to_screen(RADIUS * GRID_UNIT * 2);

    const screen_pos: rl.Rectangle = .{
        .x = to_screen.x,
        .y = to_screen.y,
        .width = screen_size,
        .height = screen_size,
    };

    const ol_to_screen = camera.vector2_world_to_screen(.{
        .x = world_pos.x - SELECTION_OUTLINE_BORDER,
        .y = world_pos.y - SELECTION_OUTLINE_BORDER
    });

    const ol_screen_size = camera.size_to_screen(RADIUS * GRID_UNIT * 2 + SELECTION_OUTLINE_BORDER * 2);

    const outline_screen_pos: rl.Rectangle = .{
        .x = ol_to_screen.x,
        .y = ol_to_screen.y,
        .width = ol_screen_size,
        .height = ol_screen_size,
    };

    if(self.mouse_hovering)
    {
        rl.drawRectangleRec(outline_screen_pos, .{ .r = 255, .g = 255, .b = 255, .a = 200 });
    }

    if(is_selected)
    {
        rl.drawRectangleLinesEx(outline_screen_pos, 3, .white);
    }

    const grid_rectangle_world = self.getGridRectangle();

    const grid_pos_screen = camera.vector2_world_to_screen(.{.x = grid_rectangle_world.x, .y = grid_rectangle_world.y});
    const grid_size_screen = camera.size_to_screen(GRID_UNIT);

    rl.drawRectangleV(grid_pos_screen, .{ .x = grid_size_screen, .y = grid_size_screen}, self.faction_color);

    self.texture.drawPro(
        .{
            .x = 0,
            .y = 0,
            .width = 19,
            .height = 19,
        },
        .{
            .x = to_screen.x + screen_size / 2,
            .y = to_screen.y + screen_size / 2,
            .width = screen_size,
            .height = screen_size,
        },
        .{ .x = screen_pos.width / 2, .y = screen_pos.height / 2 },
        (self.cycle_timer / self.cycle_length) * 360,
        .white,
    );

    //if (@import("builtin").mode == .Debug)
        //rl.drawRectangleLinesEx(screen_pos, 2, .blue);
}

pub fn init(texture: *const rl.Texture, x: u16, y: u16) Star {
    const star: Star = .{
        .texture = texture,
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

        .cycle_length = @floatFromInt(rl.getRandomValue(100, 300)),
        .cycle_timer = @floatFromInt(rl.getRandomValue(0, 300)),
        .cycle_speed = @as(f32, @floatFromInt(rl.getRandomValue(1, 100))) / 10,

        .owner = 0,

        .mouse_hovering = false
    };

    return star;
}

pub fn getFactionColor(self: Star) rl.Color
{
    if(self.owner == 0)
    {
        return .blank;
    }
    else
    {
        const r: usize = (45 + (1771 * self.owner) % 855) & 127;
        const g: usize = (113 + (8121 * self.owner) % 1059) & 127;
        const b: usize = (201 + (6599 * self.owner) % 653) & 127;

        return .{
            .r = @truncate(r + 128),
            .g = @truncate(g + 128),
            .b = @truncate(b + 128),
            .a = 102
        };
    }
}

pub fn getGridRectangle(self: Star) rl.Rectangle {
    return .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y),
        .width = GRID_UNIT,
        .height = GRID_UNIT
    };
}

pub fn getStarRectangle(self: Star) rl.Rectangle {
    return .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y),
        .width = GRID_UNIT * RADIUS * 2,
        .height = GRID_UNIT * RADIUS * 2,
    };
}

pub fn getStarWorldPos(self: Star, centered: bool) rl.Vector2
{
    if(centered)
    {
        const x: f32 = @floatFromInt(GRID_UNIT * self.x);
        const y: f32 = @floatFromInt(GRID_UNIT * self.y);

        return .{
            .x = x + RADIUS,
            .y = y + RADIUS
        };
    }
    else return .{
        .x = @floatFromInt(GRID_UNIT * self.x),
        .y = @floatFromInt(GRID_UNIT * self.y)
    };
}

pub fn setOwner(self: *Star, owner: usize) void
{
    self.owner = owner;
    self.faction_color = self.getFactionColor();
}

/// Called once every tick.
pub fn tick(self: *Star, links: std.ArrayList(Link)) void {
    for (links.items) |*link| {
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
