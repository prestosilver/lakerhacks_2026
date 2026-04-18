const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");

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

var camera: Camera = .init(SCREEN_WIDTH, SCREEN_HEIGHT);

fn get_window_size() rl.Vector2
{
    return .{
        .x = @floatFromInt(SCREEN_WIDTH),
        .y = @floatFromInt(SCREEN_HEIGHT)
    };
}

fn get_mouse_position() rl.Vector2
{
    const mouse_pos_x = rl.getMouseX();
    const mouse_pos_y = rl.getMouseY();

    return .{
        .x = @floatFromInt(mouse_pos_x),
        .y = @floatFromInt(mouse_pos_y)
    };
}

fn get_mouse_world_position() rl.Vector2
{
    return camera.vector2_screen_to_world(get_mouse_position());
}

fn get_screen_space_rect() rl.Rectangle
{
    const top_left = camera.vector2_screen_to_world(.{ .x = 0, .y = 0 });
    const bottom_right = camera.vector2_screen_to_world(get_window_size());

    return .{
        .x = top_left.x,
        .y = top_left.y,
        .width = bottom_right.x - top_left.x,
        .height = bottom_right.y - top_left.y
    };
}

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
    _ = blip;

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

            rl.clearBackground(.{.r = 0, .g = 0, .b = 0, .a = 255});

            for (links.items) |link| {
                link.draw();
            }

            const rect_size = camera.size_to_screen(1);
            const rect_pos = camera.vector2_world_to_screen(.{ .x = 0, .y = 0 });

            const mouse_world_pos = get_mouse_world_position();

            var color: rl.Color = undefined;

            if(rl.checkCollisionPointRec(mouse_world_pos, .{ .x = 0, .y = 0, .width = 1, .height = 1}))
            {
                color = .pink;
            }
            else
            {
                color = .red;
            }

            rl.drawRectangleV(rect_pos, .{ .x = rect_size, .y = rect_size }, color);

            std.debug.print("{d}, {d}\n", .{mouse_world_pos.x, mouse_world_pos.y});
        }
    }
}
