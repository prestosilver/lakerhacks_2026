const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");

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

var camera: Camera = .init();

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
    _ = blip;

    var tick_acc: f64 = 0;
    while (!rl.windowShouldClose()) {
        { // Update
            const dt = rl.getFrameTime();
            tick_acc += dt;

            if(rl.isKeyDown(.a))
            {
                camera.x -= dt;
            }
            if(rl.isKeyDown(.d))
            {
                camera.x += dt;
            }
            if(rl.isKeyDown(.w))
            {
                camera.y -= dt;
            }
            if(rl.isKeyDown(.s))
            {
                camera.y += dt;
            }

            const scroll = rl.getMouseWheelMoveV();
            if(scroll.y != 0)
            {
                camera.z += scroll.y / 10;
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            const window_size: rl.Vector2 = .{
                .x = @floatFromInt(SCREEN_WIDTH),
                .y = @floatFromInt(SCREEN_HEIGHT)
            };

            rl.clearBackground(.{.r = 0, .g = 0, .b = 0, .a = 255});

            for (links.items) |*link| {
                link.draw();
            }

            std.debug.print("{d}, {d}, {d}\n", .{camera.x, camera.y, camera.z});

            const rect_size = camera.size_to_screen(1);
            const rect_pos = camera.vector2_world_to_screen(.{ .x = 0, .y = 0 }, window_size);

            std.debug.print("{d}, {d}, {d}\n", .{rect_pos.x, rect_pos.y, rect_size});

            rl.drawRectangleV(rect_pos, .{ .x = rect_size, .y = rect_size }, .red);
        }
    }
}
