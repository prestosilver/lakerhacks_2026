const rl = @import("raylib");

pub const UIElement = struct {
    const VTable = struct {
        draw: *const fn (*const anyopaque) void,
        update: *const fn (*anyopaque, f32) void,
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
            fn drawImpl(data: *const anyopaque) void {
                const self: *const T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.draw, .{self});
            }

            fn updateImpl(data: *anyopaque, dt: f32) void {
                const self: *T = @ptrCast(@alignCast(data));

                return @call(.always_inline, T.update, .{ self, dt });
            }

            const vtable: VTable = .{
                .draw = &drawImpl,
                .update = &updateImpl,
            };
        };

        return .{
            .vtable = Gen.vtable,
            .data = ptr,
        };
    }

    pub fn draw(self: *const UIElement) void {
        return self.vtable.draw(self.data);
    }

    pub fn update(self: *UIElement, dt: f32) void {
        return self.vtable.update(self.data, dt);
    }
};

pub const Panel = struct {
    children: []UIElement,
    bounds: rl.Rectangle,

    pub fn update(self: *Panel, dt: f32) void {
        _ = dt;
        _ = self;
    }

    pub fn draw(self: *const Panel) void {
        rl.drawRectangleRec(self.bounds, .gray);
    }
};