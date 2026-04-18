const std = @import("std");
const rl = @import("raylib");

const Star = @import("Star.zig");
const Link = @import("Link.zig");
const Camera = @import("Camera.zig");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const TPS = 20.0;

const GRID_SIZE = 1024;
const MAX_LINK_COUNT = 2048;

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

var camera: Camera = .init(SCREEN_WIDTH, SCREEN_HEIGHT);

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

    camera.x = (GRID_SIZE / 2);
    camera.y = (GRID_SIZE / 2);

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

            var ticks: u32 = 0;
            while(tick_acc > TICK_RATE)
            {
                ticks += 1;
                tick_acc -= TICK_RATE;
            }

            if(rl.isKeyDown(.a))
            {
                camera.x -= CAMERA_SPEED * dt / camera.z;
            }
            if(rl.isKeyDown(.d))
            {
                camera.x += CAMERA_SPEED * dt / camera.z;
            }
            if(rl.isKeyDown(.w))
            {
                camera.y -= CAMERA_SPEED * dt / camera.z;
            }
            if(rl.isKeyDown(.s))
            {
                camera.y += CAMERA_SPEED * dt / camera.z;
            }

            const scroll = rl.getMouseWheelMoveV();
            if(scroll.y != 0)
            {
                camera.zoom_target += @intFromFloat(scroll.y);
            }

            for(0..ticks) |_|
            {
                camera.tick();
            }
        }

        { // Draw
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(.{.r = 0, .g = 0, .b = 0, .a = 255});

            for (links.items) |link| {
                link.draw();
            }

            const screen_bounds = camera.get_screen_space_rect();

            for (stars_aux.items) |star| 
            {
                if(rl.checkCollisionRecs(star.getRectangle(), screen_bounds))
                    star.draw(camera);
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
        }
    }
}
