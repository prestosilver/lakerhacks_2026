const Star = @import("Star.zig");

const Link = @This();

a: *Star,
b: *Star,

/// Toggle used to keep track of whether the cycle timer in a is [less than] (false) or [greater than or equal to] (true) than b.
toggle: bool,

pub fn init(a: *Star, b: *Star) Link
{
    return .{
        .a = a,
        .b = b,
        .toggle = false
    };
}