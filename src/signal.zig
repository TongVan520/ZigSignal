const std = @import("std");

pub fn Signal(comptime ArgType: type) type {
    return struct {
        const Self = @This();
        const Args = ArgType;
        const Slot = *const fn (args: Self.Args) anyerror!void;

        slots: std.ArrayList(Slot),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .slots = std.ArrayList(Slot).init(allocator),
            };
        }

        pub fn deinit(self: Self) void {
            self.slots.deinit();
        }

        pub fn emit(self: Self, args: Self.Args) !void {
            for (self.slots.items) |slot| {
                try slot(args);
            }
        }
    };
}
