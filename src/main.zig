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

pub fn main() anyerror!void {
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

    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            _ = dt;
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(.white);
            rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        }
    }
}
