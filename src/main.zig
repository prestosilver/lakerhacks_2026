const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const TPS = 20;

const GRID_SIZE = 1024;
const MAX_LINK_COUNT = 2048;

const FILL_RATIO = 0.25;
const STAR_COUNT: usize = (GRID_SIZE * GRID_SIZE) * FILL_RATIO;

const TICK_RATE = 1 / TPS;

const SCREEN_SIZE: rl.Vector2 = .{
    .x = SCREEN_WIDTH,
    .y = SCREEN_HEIGHT,
};

// zig+emscripten only works with c malloc/free
const allocator = std.heap.c_allocator;

var stars: [GRID_SIZE][GRID_SIZE]?Star = .{[1]?Star{null} ** GRID_SIZE} ** GRID_SIZE;
var link_buffer: [MAX_LINK_COUNT]Link = undefined;

var stars_aux_buffer: [STAR_COUNT]*Star = undefined;

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Lakerhacks 2026");
    defer rl.closeWindow();

    const links: std.ArrayList(Link) = .initBuffer(&link_buffer);
    var stars_aux: std.ArrayList(*Star) = .initBuffer(&stars_aux_buffer);

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

    { // WORLD GEN NERDS
        for (0..STAR_COUNT) |_| {
            const x: u16 = @intCast(rl.getRandomValue(0, GRID_SIZE - 1));
            const y: u16 = @intCast(rl.getRandomValue(0, GRID_SIZE - 1));

            stars[x][y] = .init(x, y);
        }

        for (&stars) |*row| for (row) |*cell| {
            const star = &(cell.* orelse continue);
            stars_aux.appendAssumeCapacity(star);
        };
    }

    var tick_acc: f64 = 0;
    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            tick_acc += dt;

            for (stars_aux.items) |star| {
                star.draw();
            }

            if (rl.isKeyPressed(.w)) {
                rl.playSound(blip);
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(.{ .r = 0, .g = 0, .b = 0, .a = 255 });

            for (links.items) |link| {
                link.draw();
            }

            rl.drawRectangleV(.{ .x = 10, .y = 10 }, .{ .x = 100, .y = 100 }, .{ .r = 255, .g = 0, .b = 0, .a = 255 });
        }
    }
}
