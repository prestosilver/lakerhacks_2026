const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const TPS = 20;

const TICK_RATE = 1 / TPS;

const SCREEN_SIZE: rl.Vector2 = .{
    .x = SCREEN_WIDTH,
    .y = SCREEN_HEIGHT,
};

// zig+emscripten only works with c malloc/free
const allocator = std.heap.c_allocator;

var stars: [1024][1024]?Star = .{[1]?Star{null} ** 1024} ** 1024;

var link_buffer: [2048]Link = undefined;

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Lakerhacks 2026");
    defer rl.closeWindow();

    const links: std.ArrayList(Link) = .fromOwnedSlice(&link_buffer);

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

    var tick_acc: f64 = 0;
    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            tick_acc += dt;

            for (&stars) |*row|
                for (row) |*star| {
                    if (star.* != null) star.*.?.draw();
                };

            if (rl.isKeyPressed(.w)) {
                rl.playSound(blip);
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            for (links.items) |link| {
                link.draw();
            }
        }
    }
}
