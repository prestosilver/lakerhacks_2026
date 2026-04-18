const Star = @import("Star.zig");

const Faction = @This();

home: *Star,

pub fn init(home: *Star) Faction
{
    return .{
        .home = home
    };
}

