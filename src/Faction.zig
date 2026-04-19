const std = @import("std");

const Star = @import("Star.zig");
const world = @import("world.zig");

const Faction = @This();

home: *Star,
star_buffer: [1024]*Star = undefined,
stars: std.ArrayList(*Star) = undefined,
tick_acc: u32 = 0,

pub fn tick(self: *Faction, stars: *std.ArrayList(*Star)) void {
    self.tick_acc +%= 1;

    if (self.tick_acc % 25 != 0) return;

    var min_d: f32 = 0;
    var min_s: ?usize = null;
    var min_t: ?usize = null;
    for (stars.items, 0..) |cell, cell_id| {
        if (cell.owner != 0) continue;

        for (self.stars.items, 0..) |my_star, my_star_id| {
            if (my_star == cell) continue;

            const xd = @as(f32, @floatFromInt(my_star.x)) - @as(f32, @floatFromInt(cell.x));
            const yd = @as(f32, @floatFromInt(my_star.y)) - @as(f32, @floatFromInt(cell.y));
            const dist = xd * xd + yd * yd;
            if (min_s == null or min_d > dist) {
                min_d = dist;
                min_t = cell_id;
                min_s = my_star_id;
            }
        }
    }

    if (min_t) |t| {
        for (stars.items, 0..) |cell, cell_id| {
            if (cell == self.stars.items[min_s.?]) {
                world.linkStars(cell_id, t);
                break;
            }
        }
    }
}
