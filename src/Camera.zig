const std = @import("std");
const rl = @import("raylib");

const ZOOM_FACTOR: f32 = 100;

const ZOOM_EXPONENT: f32 = 1.4;
const ZOOM_SMOOTH: f32 = 2;

const Camera = @This();

x: f32,
y: f32,
z: f32,

zoom_target: i32,

screen_width: f32,
screen_height: f32,

pub fn init(screen_width: f32, screen_height: f32) Camera
{
    return .{
        .x = 0,
        .y = 0,
        .z = 1,
        .zoom_target = 0,
        .screen_width = screen_width,
        .screen_height = screen_height
    };
}

pub fn get_screen_space_rect(self: Camera) rl.Rectangle
{
    const top_left = self.vector2_screen_to_world(.{ .x = 0, .y = 0 });
    const bottom_right = self.vector2_screen_to_world(get_window_size(self));

    return .{
        .x = top_left.x,
        .y = top_left.y,
        .width = bottom_right.x - top_left.x,
        .height = bottom_right.y - top_left.y
    };
}

pub fn get_window_size(self: Camera) rl.Vector2
{
    return .{
        .x = self.screen_width,
        .y = self.screen_height
    };
}

pub fn get_target_zoom(self: Camera) f32
{
    return std.math.pow(f32, ZOOM_EXPONENT, @floatFromInt(self.zoom_target));
}

pub fn size_to_screen(self: Camera, size: f32) f32
{
    return size * self.z * ZOOM_FACTOR;
}

pub fn tick(self: *Camera) void
{
    const target = self.get_target_zoom();
    if(self.z != target)
    {
        const diff = target - self.z;
        self.z += diff / ZOOM_SMOOTH;
    }
}

pub fn vector2_screen_to_world(self: Camera, point: rl.Vector2) rl.Vector2
{
    return .{
        .x = (point.x - self.screen_width / 2) / (self.z * ZOOM_FACTOR) + self.x,
        .y = (point.y - self.screen_height / 2) / (self.z * ZOOM_FACTOR) + self.y,
    };
}

pub fn vector2_world_to_screen(self: Camera, point: rl.Vector2) rl.Vector2
{
    return .{
        .x = (point.x - self.x) * self.z * ZOOM_FACTOR + self.screen_width / 2,
        .y = (point.y - self.y) * self.z * ZOOM_FACTOR + self.screen_height / 2
    };
}