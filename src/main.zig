const std = @import("std");
const rl = @import("raylib");

const assets = @import("assets.zig");
const world = @import("world.zig");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");
const Faction = @import("Faction.zig");

const ui = @import("ui.zig");

const SCREEN_WIDTH = 1200;
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

    var star_has_text = ui.ResourceLabel{
        .height = 24,
        .desc = "Has",
    };
    var star_makes_text = ui.ResourceLabel{
        .height = 24,
        .desc = "Makes",
    };
    var star_uses_text = ui.ResourceLabel{
        .height = 24,
        .desc = "Uses",
    };
    var link_button = ui.Button{
        .height = 24,
        .text = "Link",
        .padding = 10,
        .on_click = &world.beginLink,
    };
    var cancel_button = ui.Button{
        .height = 24,
        .text = "Stop Link",
        .padding = 10,
        .on_click = &world.cancelLink,
    };

    var star_panel = ui.Panel{
        .children = &.{
            .init(&star_has_text),
            .init(&star_makes_text),
            .init(&star_uses_text),
            .init(&link_button),
            .init(&cancel_button),
        },
        .padding = 20,
    };

    const ui_elements = [_]ui.UIElement{
        .init(&star_panel),
    };

    var ui_positions = [_]?rl.Vector2{null} ** ui_elements.len;

    var previous_selection: ?*Star = null;
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
                previous_selection = null;
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

            const selected_star = world.selectedStar();
            defer previous_selection = selected_star;

            if (selected_star) |star| {
                if (selected_star != previous_selection) {
                    star_has_text.resources = &star.total_res;
                    star_makes_text.resources = &star.gen_res;
                    star_uses_text.resources = &star.req_res;
                }

                const ui_location_world: rl.Vector2 = .{
                    .x = @as(f32, @floatFromInt(Star.GRID_UNIT * star.x)) + star.center_x - Star.SELECTION_OUTLINE_BORDER,
                    .y = @as(f32, @floatFromInt(Star.GRID_UNIT * star.y)) + star.center_y + Star.RADIUS * 2 + Star.SELECTION_OUTLINE_BORDER,
                };

                const ui_location_screen = camera.vector2_world_to_screen(ui_location_world);

                ui_positions[0] = ui_location_screen;
            } else {
                ui_positions[0] = null;
            }

            camera.update();

            const mouse_world_pos = get_mouse_world_position();

            const input: world.UserInput = .{ .mouse_world_pos = mouse_world_pos, .lmb = rl.isMouseButtonDown(.left), .rmb = rl.isMouseButtonDown(.right) };

            world.updateInput(input);

            const mouse_pos = rl.getMousePosition();

            for (ui_elements, ui_positions) |element, position| {
                if (position) |pos|
                    element.update(dt, mouse_pos.subtract(pos));
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            world.draw(camera);
            world.drawUI(camera);

            for (ui_elements, ui_positions) |element, position| {
                if (position) |pos|
                    element.draw(pos);
            }
        }
    }
}
