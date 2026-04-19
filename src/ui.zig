const std = @import("std");
const rl = @import("raylib");
const Star = @import("Star.zig");

pub const UIElement = struct {
    const VTable = struct {
        draw: *const fn (*const anyopaque, rl.Vector2) void,
        update: *const fn (*anyopaque, f32, rl.Vector2) void,

        size: *const fn (*const anyopaque) rl.Vector2,
    };

    vtable: VTable,
    data: *anyopaque,

    pub fn init(ptr: anytype) UIElement {
        const Ptr = @TypeOf(ptr);
        const ptr_info = @typeInfo(Ptr);

        if (ptr_info != .pointer) @compileError("bruh that is not a pointer to a ui element");
        if (ptr_info.pointer.size != .one) @compileError("Bruh that is a slice of ui elements dumbass");

        const T = ptr_info.pointer.child;

        const Gen = struct {
            fn drawImpl(data: *const anyopaque, offset: rl.Vector2) void {
                const self: *const T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.draw, .{ self, offset });
            }

            fn updateImpl(data: *anyopaque, dt: f32, mouse: rl.Vector2) void {
                const self: *T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.update, .{ self, dt, mouse });
            }

            fn sizeImpl(data: *const anyopaque) rl.Vector2 {
                const self: *const T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.size, .{self});
            }

            const vtable: VTable = .{
                .draw = &drawImpl,
                .update = &updateImpl,
                .size = &sizeImpl,
            };
        };

        return .{
            .vtable = Gen.vtable,
            .data = ptr,
        };
    }

    pub fn draw(self: *const UIElement, offset: rl.Vector2) void {
        return self.vtable.draw(self.data, offset);
    }

    pub fn update(self: *const UIElement, dt: f32, mouse: rl.Vector2) void {
        return self.vtable.update(self.data, dt, mouse);
    }

    pub fn size(self: *const UIElement) rl.Vector2 {
        return self.vtable.size(self.data);
    }
};

pub const Panel = struct {
    vertical: bool = true,
    children: []const UIElement,
    spacing: f32 = 0,
    padding: f32,

    pub fn update(self: *Panel, dt: f32, mouse: rl.Vector2) void {
        var elem_offset: rl.Vector2 = .{ .x = self.padding, .y = self.padding };

        for (self.children) |*child| {
            const child_size = child.size();

            child.update(dt, mouse.subtract(elem_offset));

            if (self.vertical) {
                elem_offset.y += child_size.y;
                elem_offset.y += self.spacing;
            } else {
                elem_offset.x += child_size.x;
                elem_offset.x += self.spacing;
            }
        }
    }

    pub fn draw(self: *const Panel, offset: rl.Vector2) void {
        const self_size = self.size();

        rl.drawRectangleRec(.{
            .x = offset.x,
            .y = offset.y,
            .width = self_size.x,
            .height = self_size.y,
        }, .gray);

        var elem_offset = offset;
        elem_offset.x += self.padding;
        elem_offset.y += self.padding;
        for (self.children) |child| {
            const child_size = child.size();

            child.draw(elem_offset);

            if (self.vertical) {
                elem_offset.y += child_size.y;
                elem_offset.y += self.spacing;
            } else {
                elem_offset.x += child_size.x;
                elem_offset.x += self.spacing;
            }
        }
    }

    pub fn size(self: *const Panel) rl.Vector2 {
        var self_size: rl.Vector2 = .{ .x = self.padding, .y = self.padding };
        for (self.children) |child| {
            const child_size = child.size();

            if (self.vertical) {
                self_size.y += child_size.y + self.spacing;
                self_size.x = @max(self_size.x, self.padding * 2 + child_size.x);
            } else {
                self_size.x += child_size.x + self.spacing;
                self_size.y = @max(self_size.y, self.padding * 2 + child_size.y);
            }
        }

        self_size.x -= self.spacing;
        self_size.y -= self.spacing;
        self_size.x += self.padding;
        self_size.y += self.padding;

        return self_size;
    }
};

pub const Label = struct {
    text: [:0]const u8,
    height: i32,

    pub fn update(self: *Label, dt: f32, mouse: rl.Vector2) void {
        _ = self;
        _ = dt;
        _ = mouse;
    }

    pub fn draw(self: *const Label, offset: rl.Vector2) void {
        rl.drawText(
            self.text,
            @intFromFloat(offset.x),
            @intFromFloat(offset.y),
            self.height,
            .white,
        );
    }

    pub fn size(self: *const Label) rl.Vector2 {
        const width = rl.measureText(self.text, self.height);

        return .{
            .x = @floatFromInt(width),
            .y = @floatFromInt(self.height),
        };
    }
};

pub const ResourceLabel = struct {
    line_buf: [512:0]u8 = undefined,

    desc: []const u8 = "",

    resources: ?*Star.StarResources = null,
    text: [:0]const u8 = "",

    height: i32,

    pub fn update(self: *ResourceLabel, dt: f32, mouse: rl.Vector2) void {
        _ = dt;
        _ = mouse;

        if (self.resources) |resources| {
            self.text = std.fmt.bufPrintZ(
                &self.line_buf,
                "{s}  - P:{d}  O:{d}  E:{d}  M:{d}",
                .{ self.desc, resources.population, resources.organic, resources.energy, resources.mineral },
            ) catch unreachable;
        }
    }

    pub fn draw(self: *const ResourceLabel, offset: rl.Vector2) void {
        rl.drawText(
            self.text,
            @intFromFloat(offset.x),
            @intFromFloat(offset.y),
            self.height,
            .white,
        );
    }

    pub fn size(self: *const ResourceLabel) rl.Vector2 {
        const width = rl.measureText(self.text, self.height);

        return .{
            .x = @floatFromInt(width),
            .y = @floatFromInt(self.height),
        };
    }
};

pub const Button = struct {
    focused: bool = false,
    on_click: ?*const fn () void = null,
    text: [:0]const u8,
    height: i32,
    padding: i32,

    pub fn update(self: *Button, dt: f32, mouse_offset: rl.Vector2) void {
        const self_size = self.size();

        self.focused = mouse_offset.x > 0 and mouse_offset.x < self_size.x and
            mouse_offset.y > 0 and mouse_offset.y < self_size.y;

        if (self.focused and rl.isMouseButtonPressed(.left)) {
            if (self.on_click) |click| click();
        }

        _ = dt;
    }

    pub fn draw(self: *const Button, offset: rl.Vector2) void {
        const self_size = self.size();

        rl.drawRectangleRec(.{
            .x = offset.x,
            .y = offset.y,
            .width = self_size.x,
            .height = self_size.y,
        }, if (self.focused) .light_gray else .dark_gray);

        rl.drawText(
            self.text,
            @as(i32, @intFromFloat(offset.x)) + self.padding,
            @as(i32, @intFromFloat(offset.y)) + self.padding,
            self.height,
            .white,
        );
    }

    pub fn size(self: *const Button) rl.Vector2 {
        const width = rl.measureText(self.text, self.height);

        return .{
            .x = @floatFromInt(width + self.padding * 2),
            .y = @floatFromInt(self.height + self.padding * 2),
        };
    }
};
