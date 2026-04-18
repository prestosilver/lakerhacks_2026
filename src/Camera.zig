const rl = @import("raylib");

const ZOOM_FACTOR: f32 = 100;

const Camera = @This();

x: f32,
y: f32,
z: f32,

pub fn init() Camera
{
    return .{
        .x = 0,
        .y = 0,
        .z = 1
    };
}

pub fn size_to_screen(self: Camera, size: f32) f32
{
    return size * self.z * ZOOM_FACTOR;
}

pub fn vector2_screen_to_world(self: Camera, point: rl.Vector2, window_size: rl.Vector2) rl.Vector2
{
    return .{
        .x = (point.x - window_size.x / 2) / (self.z * ZOOM_FACTOR) + self.x,
        .y = (point.y - window_size.y / 2) / (self.z * ZOOM_FACTOR) + self.y,
    };
}

pub fn vector2_world_to_screen(self: Camera, point: rl.Vector2, window_size: rl.Vector2) rl.Vector2
{
    return .{
        .x = (point.x - self.x) * self.z * ZOOM_FACTOR + window_size.x / 2,
        .y = (point.y - self.y) * self.z * ZOOM_FACTOR + window_size.y / 2
    };
}