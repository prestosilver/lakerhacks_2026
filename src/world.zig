const std = @import("std");
const rl = @import("raylib");

const assets = @import("assets.zig");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");
const Faction = @import("Faction.zig");

const GRID_SIZE = 512;
const GRID_MEDIAN = GRID_SIZE / 2;
const MAX_LINK_COUNT = 256;
const MAX_FACTION_COUNT = 1024;

const FILL_RATIO = 0.25;
const STAR_COUNT: usize = (GRID_SIZE * GRID_SIZE) * FILL_RATIO;
const BASE_STAR_CHANCE = 0.1;

var stars: [GRID_SIZE][GRID_SIZE]?Star = .{[1]?Star{null} ** GRID_SIZE} ** GRID_SIZE;
var link_buffer: [MAX_LINK_COUNT]Link = undefined;

var stars_aux_buffer: [STAR_COUNT]*Star = undefined;
var stars_aux: std.ArrayList(*Star) = undefined;

var star_selection: isize = undefined;
var focused_star: isize = undefined;

var factions_aux_buffer: [MAX_FACTION_COUNT]Faction = undefined;
var factions_aux: std.ArrayList(Faction) = undefined;

var links: std.ArrayList(Link) = undefined;

pub const UserInput = struct { mouse_world_pos: rl.Vector2, lmb: bool, rmb: bool };

pub const UIMode = enum { Game, Linking };

pub var ui_mode: UIMode = undefined;

fn generate_world(camera: *Camera) void {
    for (0..GRID_SIZE) |i| for (0..GRID_SIZE) |j| {
        // TODO: Stretch goal: make the galaxy spiral out. (might take an hour or two).

        const is: isize = @intCast(i);
        const js: isize = @intCast(j);

        const distance = std.math.sqrt(@as(f32, @floatFromInt(std.math.pow(isize, is - GRID_MEDIAN, 2) + std.math.pow(isize, js - GRID_MEDIAN, 2))));

        const inner_density_factor = 1 - @min(1, distance / 30 - 1);
        const outer_density_factor = 1 - distance / GRID_MEDIAN;

        const density_factor = outer_density_factor - inner_density_factor;

        const chance = BASE_STAR_CHANCE * density_factor;

        const r = rl.getRandomValue(0, 999);
        if (r < @as(i32, @intFromFloat(chance * 1000))) {
            stars[i][j] = .init(&assets.texture_star, @truncate(i), @truncate(j));
        }
    };

    for (&stars) |*row| for (row) |*cell| {
        const star = &(cell.* orelse continue);
        stars_aux.appendAssumeCapacity(star);
    };

    var num_factions = rl.getRandomValue(6, 25);
    var cur_faction: usize = 1;
    while (num_factions > 0) : (num_factions -= 1) {
        var host_star = @as(usize, @intCast(rl.getRandomValue(0, @intCast(stars_aux.items.len - 1))));
        while (stars_aux.items[host_star].owner != 0) {
            // Make sure the star isn't already owned by another faction.
            host_star = @as(usize, @intCast(rl.getRandomValue(0, @intCast(stars_aux.items.len - 1))));
        }

        stars_aux.items[host_star].setOwner(host_star);

        const faction: Faction = .init(stars_aux.items[host_star]);
        factions_aux.appendAssumeCapacity(faction);

        if (cur_faction == 1) {
            const star_pos = stars_aux.items[host_star].getStarWorldPos(true);
            camera.x = star_pos.x;
            camera.y = star_pos.y;

            std.debug.print("{d}, {d}\n", .{ camera.x, camera.y });
        }

        cur_faction += 1;
    }

    if (@import("builtin").mode == .Debug) {
        std.debug.print("Total stars: {d}.\n", .{stars_aux.items.len});
        std.debug.print("Total factions: {d}.\n", .{factions_aux.items.len});
    }
}

pub fn draw(camera: Camera) void {
    rl.clearBackground(.{ .r = 0, .g = 0, .b = 0, .a = 255 });

    for (links.items) |link| {
        link.draw(camera);
    }

    const screen_bounds = camera.get_screen_space_rect();

    for (stars_aux.items, 0..) |star, i| {
        if (rl.checkCollisionRecs(star.getGridRectangle(), screen_bounds))
            star.draw(camera, star_selection == i);
    }
}

pub fn init(camera: *Camera) void {
    links = .initBuffer(&link_buffer);

    stars_aux = .initBuffer(&stars_aux_buffer);
    factions_aux = .initBuffer(&factions_aux_buffer);

    star_selection = -1;
    focused_star = -1;

    ui_mode = .Game;

    generate_world(camera);
}

fn linkStars(index_a: usize, index_b: usize) void {
    const link: Link = .init(stars_aux.items[index_a], stars_aux.items[index_b]);
    links.appendAssumeCapacity(link);

    star_selection = @intCast(index_a);
    ui_mode = .Game;
}

fn selectStar(index: usize) void {
    star_selection = @intCast(index);
}

pub fn selectedStar() ?*Star {
    return if (star_selection >= 0)
        stars_aux.items[@intCast(star_selection)]
    else
        null;
}

pub fn tick() void {
    for (stars_aux.items) |star|
        star.tick();

    for (links.items) |*link|
        link.tick();
}

pub fn updateInput(input: UserInput) void {
    if (input.rmb) {
        star_selection = -1;
        focused_star = -1;

        ui_mode = .Game;
    }

    for (stars_aux.items, 0..) |star, i| {
        star.mouse_hovering = false;
        if (rl.checkCollisionPointRec(input.mouse_world_pos, star.getStarRectangle())) {
            star.mouse_hovering = true;
            if (input.lmb) {
                switch (ui_mode) {
                    .Game => selectStar(i),
                    .Linking => {
                        std.debug.assert(star_selection != -1);
                        linkStars(i, @intCast(star_selection));
                    },
                }
            }
        }
    }

    if (star_selection != -1 and rl.isKeyPressed(.kp_1)) {
        ui_mode = .Linking;
    }
}
