const std = @import("std");
const rl = @import("raylib");

const assets = @import("assets.zig");
const world = @import("world.zig");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");
const Faction = @import("Faction.zig");

const ui = @import("ui.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 800;

const TPS = 20.0;

const TICK_RATE = 1.0 / TPS;
const CAMERA_SPEED = 5.0;

const SCREEN_SIZE: rl.Vector2 = .{
    .x = SCREEN_WIDTH,
    .y = SCREEN_HEIGHT,
};

// zig+emscripten only works with c malloc/free
const allocator = std.heap.c_allocator;

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

    try assets.init();
    defer assets.deinit();

    world.init(&camera);

    var test_panel = ui.Panel{
        .children = &.{},
        .bounds = .{
            .x = 10,
            .y = 10,
            .width = 300,
            .height = SCREEN_HEIGHT - 20,
        },
    };

    const ui_elements = [_]ui.UIElement{
        .init(&test_panel),
    };

    var tick_acc: f64 = 0;
    while (!rl.windowShouldClose()) {
        { // Update + Tick.
            const dt = rl.getFrameTime();
            tick_acc += dt;

            var ticks: u32 = 0;
            while (tick_acc > TICK_RATE) {
                ticks += 1;
                tick_acc -= TICK_RATE;

                world.tick();
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

            camera.update();
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            world.draw(camera);

            for (ui_elements) |element| {
                element.draw();
            }

            // const mouse_world_pos = get_mouse_world_position();
        }
    }
}
