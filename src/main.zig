const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");
const Faction = @import("Faction.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 800;

const TPS = 20.0;

const GRID_SIZE = 512;
const GRID_MEDIAN = GRID_SIZE / 2;
const MAX_LINK_COUNT = 256;
const MAX_FACTION_COUNT = 1024;

const FILL_RATIO = 0.25;
const STAR_COUNT: usize = (GRID_SIZE * GRID_SIZE) * FILL_RATIO;

const TICK_RATE = 1.0 / TPS;
const CAMERA_SPEED = 5.0;

const SCREEN_SIZE: rl.Vector2 = .{
    .x = SCREEN_WIDTH,
    .y = SCREEN_HEIGHT,
};

// zig+emscripten only works with c malloc/free
const allocator = std.heap.c_allocator;

var stars: [GRID_SIZE][GRID_SIZE]?Star = .{[1]?Star{null} ** GRID_SIZE} ** GRID_SIZE;
var link_buffer: [MAX_LINK_COUNT]Link = undefined;

var stars_aux_buffer: [STAR_COUNT]*Star = undefined;

var factions_aux_buffer: [MAX_FACTION_COUNT]*Faction = undefined;

var camera: Camera = .init(SCREEN_WIDTH, SCREEN_HEIGHT);

fn get_mouse_position() rl.Vector2 {
    const mouse_pos_x = rl.getMouseX();
    const mouse_pos_y = rl.getMouseY();

    return .{ .x = @floatFromInt(mouse_pos_x), .y = @floatFromInt(mouse_pos_y) };
}

fn get_mouse_world_position() rl.Vector2 {
    return camera.vector2_screen_to_world(get_mouse_position());
}

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Lakerhacks 2026");
    defer rl.closeWindow();

    const links: std.ArrayList(Link) = .initBuffer(&link_buffer);

    var stars_aux: std.ArrayList(*Star) = .initBuffer(&stars_aux_buffer);
    var factions_aux: std.ArrayList(*Faction) = .initBuffer(&factions_aux_buffer);

    // Clear the screen once to avoid a black flash
    {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
    }
    rl.setTargetFPS(60);
    rl.setExitKey(.null);

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    const blip: rl.Sound = try rl.loadSound("cont/blip_1.ogg");
    defer blip.unload();

    const star_texture = try rl.loadTexture("cont/star.png");
    defer star_texture.unload();

    camera.x = (GRID_SIZE / 2);
    camera.y = (GRID_SIZE / 2);

    const base_star_chance = 0.1;

    { // WORLD GEN NERDS
        for (0..GRID_SIZE) |i| for (0..GRID_SIZE) |j| {
            // TODO: Stretch goal: make the galaxy spiral out. (might take an hour or two).

            const is: isize = @intCast(i);
            const js: isize = @intCast(j);

            const distance = std.math.sqrt(@as(f32, @floatFromInt(std.math.pow(isize, is - GRID_MEDIAN, 2) + std.math.pow(isize, js - GRID_MEDIAN, 2))));

            const inner_density_factor = 1 - @min(1, distance / 30 - 1);
            const outer_density_factor = 1 - distance / GRID_MEDIAN;

            const density_factor = outer_density_factor - inner_density_factor;

            const chance = base_star_chance * density_factor;

            const r = rl.getRandomValue(0, 999);
            if (r < @as(i32, @intFromFloat(chance * 1000))) {
                stars[i][j] = .init(&star_texture, @truncate(i), @truncate(j));
            }
        };

        for (&stars) |*row| for (row) |*cell| {
            const star = &(cell.* orelse continue);
            stars_aux.appendAssumeCapacity(star);
        };

        var num_factions = rl.getRandomValue(6, 25);
        var cur_faction: usize = 1;
        while(num_factions > 0) : (num_factions -= 1)
        {
            var host_star = rl.getRandomValue(0, stars.len - 1);
            while(stars_aux.items[host_star].owner != 0)
            {
                // Make sure the star isn't already owned by another faction.
                host_star = rl.getRandomValue(0, stars.len - 1);
            }

            stars_aux.items[host_star].owner = cur_faction;

            factions_aux.appendAssumeCapacity(host_star);

            cur_faction += 1;
        }

        std.debug.print("Total stars: {d}.\n", .{stars_aux.items.len});
    }

    var tick_acc: f64 = 0;
    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            tick_acc += dt;

            var ticks: u32 = 0;
            while (tick_acc > TICK_RATE) {
                ticks += 1;
                tick_acc -= TICK_RATE;

                for (stars_aux.items) |star|
                    star.tick(links);
            }

            const camera_move = dt * CAMERA_SPEED / camera.z;

            if (rl.isKeyDown(.a)) {
                camera.x -= camera_move;
            }
            if (rl.isKeyDown(.d)) {
                camera.x += camera_move;
            }
            if (rl.isKeyDown(.w)) {
                camera.y -= camera_move;
            }
            if (rl.isKeyDown(.s)) {
                camera.y += camera_move;
            }

            const scroll = rl.getMouseWheelMoveV();
            if (scroll.y != 0) {
                camera.zoom_target += @intFromFloat(scroll.y);
                camera.zoom_target = @min(camera.zoom_target, 6);
                camera.zoom_target = @max(camera.zoom_target, -13);
            }

            camera.tick();
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(.{ .r = 0, .g = 0, .b = 0, .a = 255 });

            for (links.items) |link| {
                link.draw();
            }

            const screen_bounds = camera.get_screen_space_rect();

            for (stars_aux.items) |star| {
                if (rl.checkCollisionRecs(star.getRectangle(), screen_bounds))
                    star.draw(camera);
            }

            // const mouse_world_pos = get_mouse_world_position();

        }
    }
}
