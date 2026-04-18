const Star = @import("Star.zig");

const Link = @This();

a: *Star,
b: *Star,

pub fn init(a: *Star, b: *Star) Link
{
    return .{
        .a = a,
        .b = b
    };
}