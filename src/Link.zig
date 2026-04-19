const std = @import("std");
const rl = @import("raylib");

const assets = @import("assets.zig");

const Star = @import("Star.zig");
const Camera = @import("Camera.zig");

const Link = @This();

a: *Star,
b: *Star,

/// Toggle used to keep track of whether the cycle timer in a is [less than] (false) or [greater than or equal to] (true) than b.
toggle: bool,

/// Toggle set when a link occurs. Used for drawing.
link_toggle: bool,

sound_id: u8,
sound_pitch: u8,

pub fn draw(self: *const Link, camera: Camera) void
{
    const a_pos = self.a.getStarWorldPos(true);
    const b_pos = self.b.getStarWorldPos(true);

    const a_pos_screen = camera.vector2_world_to_screen(a_pos);
    const b_pos_screen = camera.vector2_world_to_screen(b_pos);

    const color: rl.Color = if(self.link_toggle) .white else .gray;

    rl.drawLineV(a_pos_screen, b_pos_screen, color);
}

pub fn init(a: *Star, b: *Star) Link {
    return .{
        .a = a,
        .b = b,
        .toggle = a.cycle_timer < b.cycle_timer,
        .link_toggle = false,
        .sound_id = @intCast(rl.getRandomValue(0, 4)),
        .sound_pitch = @intCast(rl.getRandomValue(0, 6))
    };
}

pub fn tick(self: *Link) void
{
    self.link_toggle = false;

    const a = self.a;
    const b = self.b;

    var linked: bool = false;

    const diff = @abs(a.cycle_timer - b.cycle_timer);

    if(diff < 3)
    {
        if(a.cycle_timer >= b.cycle_timer and !self.toggle)
        {
            linked = true;
            self.toggle = true;
        }
        else if(a.cycle_timer < b.cycle_timer and self.toggle)
        {
            linked = true;
            self.toggle = false;
        }
    }

    if(linked)
    {
        self.link_toggle = true;
        // std.debug.print("{s} ({d}:{d})\n", .{"Link!", a.cycle_timer, b.cycle_timer});

        const pitch: f32 = switch(self.sound_pitch)
        {
            0 => 1,       // C
            1 => 1.122,   // D
            2 => 1.26,    // E
            3 => 1.335,   // F
            4 => 1.498,   // G
            5 => 1.682,   // A
            6 => 1.888,   // B
            else => 2     // C (octave)
        };

        rl.setSoundPitch(assets.audio_blips[self.sound_id], pitch);
        rl.playSound(assets.audio_blips[self.sound_id]);
    }
}