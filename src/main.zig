const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const SCREEN_SIZE: rl.Vector2 = .{
    .x = SCREEN_WIDTH,
    .y = SCREEN_HEIGHT,
};

// zig+emscripten only works with c malloc/free
const allocator = std.heap.c_allocator;

var stars: [1024][1024]?Star = .{[1]?Star{null} ** 1024} ** 1024;

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Lakerhacks 2026");
    defer rl.closeWindow();

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

    while (!rl.isAudioDeviceReady()) {}

    const blip: rl.Sound = try rl.loadSound("cont/blip_1.ogg");

    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            _ = dt;

            if (rl.isKeyPressed(.w)) {
                rl.playSound(blip);
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(.white);
            rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        }
    }
}
