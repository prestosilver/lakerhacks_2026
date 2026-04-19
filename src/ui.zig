const rl = @import("raylib");

pub const UIElement = struct {
    const VTable = struct {
        draw: *const fn (*const anyopaque, rl.Vector2) void,
        update: *const fn (*anyopaque, f32) void,

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

            fn updateImpl(data: *anyopaque, dt: f32) void {
                const self: *T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.update, .{ self, dt });
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

    pub fn update(self: *const UIElement, dt: f32) void {
        return self.vtable.update(self.data, dt);
    }

    pub fn size(self: *const UIElement) rl.Vector2 {
        return self.vtable.size(self.data);
    }
};

pub const Panel = struct {
    children: []const UIElement,
    padding: f32,

    pub fn update(self: *Panel, dt: f32) void {
        for (self.children) |*child|
            child.update(dt);
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

            elem_offset.y += child_size.y;
        }
    }

    pub fn size(self: *const Panel) rl.Vector2 {
        var self_size: rl.Vector2 = .{ .x = self.padding * 2, .y = self.padding };
        for (self.children) |child| {
            const child_size = child.size();
            self_size.y += child_size.y;
            self_size.x = @max(self_size.x, self.padding * 2 + child_size.x);
        }

        self_size.y += self.padding;

        return self_size;
    }
};

pub const Label = struct {
    text: [:0]const u8,
    height: i32,

    pub fn update(self: *Label, dt: f32) void {
        _ = self;
        _ = dt;
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
