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

pub fn draw(self: *const Link, camera: Camera) void {
    const a_pos = self.a.getStarWorldPos(true);
    const b_pos = self.b.getStarWorldPos(true);

    const a_pos_screen = camera.vector2_world_to_screen(a_pos);
    const b_pos_screen = camera.vector2_world_to_screen(b_pos);

    rl.drawLineEx(
        a_pos_screen,
        b_pos_screen,
        if (self.link_toggle) 5 else 3,
        if (self.link_toggle) .white else .gray,
    );
}

pub fn init(a: *Star, b: *Star) Link {
    return .{ .a = a, .b = b, .toggle = a.cycle_timer < b.cycle_timer, .link_toggle = false, .sound_id = @intCast(rl.getRandomValue(0, 4)), .sound_pitch = @intCast(rl.getRandomValue(0, 6)) };
}

pub fn tick(self: *Link) void {
    self.link_toggle = false;

    const a = self.a;
    const b = self.b;

    var linked: bool = false;

    const diff = @abs(a.cycle_timer - b.cycle_timer);

    if (diff < 3) {
        if (a.cycle_timer >= b.cycle_timer and !self.toggle) {
            linked = true;
            self.toggle = true;
        } else if (a.cycle_timer < b.cycle_timer and self.toggle) {
            linked = true;
            self.toggle = false;
        }
    }

    if (linked and a.total_res.energy >= 1 and b.total_res.energy >= 1 and a.total_res.population >= 1) {
        self.link_toggle = true;
        // std.debug.print("{s} ({d}:{d})\n", .{"Link!", a.cycle_timer, b.cycle_timer});

        a.total_res.energy -= 1;
        b.total_res.energy -= 1;

        const pop_diff = a.req_res.population - b.req_res.population;
        const org_diff = a.req_res.organic - b.req_res.organic;
        const min_diff = a.req_res.mineral - b.req_res.mineral;

        if(pop_diff > 0)
        {
            // B donating to A.
            if(b.total_res.population > pop_diff)
            {
                b.total_res.population -= pop_diff;
                a.total_res.population += pop_diff;
            }
        }
        else if(pop_diff < 0)
        {
            // A donating to B.
            if(a.total_res.population > @abs(pop_diff))
            {
                b.total_res.population -= pop_diff;
                a.total_res.population += pop_diff;
            }
        }

        if(org_diff > 0)
        {
            // B donating to A.
            if(b.total_res.organic > org_diff)
            {
                b.total_res.organic -= org_diff;
                a.total_res.organic += org_diff;
            }
        }
        else if(org_diff < 0)
        {
            // A donating to B.
            if(a.total_res.organic > @abs(org_diff))
            {
                b.total_res.organic -= org_diff;
                a.total_res.organic += org_diff;
            }
        }

        if(min_diff > 0)
        {
            // B donating to A.
            if(b.total_res.mineral > min_diff)
            {
                b.total_res.mineral -= min_diff;
                a.total_res.mineral += min_diff;
            }
        }
        else if(min_diff < 0)
        {
            // A donating to B.
            if(a.total_res.mineral > @abs(min_diff))
            {
                b.total_res.mineral -= min_diff;
                a.total_res.mineral += min_diff;
            }
        }

        if (a.owner == 1 or b.owner == 1) {
            const pitch: f32 = switch (self.sound_pitch) {
                0 => 1, // C
                1 => 1.122, // D
                2 => 1.26, // E
                3 => 1.335, // F
                4 => 1.498, // G
                5 => 1.682, // A
                6 => 1.888, // B
                else => 2, // C (octave)
            };

            rl.setSoundPitch(assets.audio_blips[self.sound_id], pitch);
            rl.playSound(assets.audio_blips[self.sound_id]);
        }
    }
}
