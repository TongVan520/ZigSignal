const std = @import("std");
const signal = @import("signal.zig");

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var said = signal.Signal([]const u8).init(allocator);
    defer said.deinit();

    try said.slots.append(&comptime struct {
        fn f(message: []const u8) !void {
            say(message);
        }
    }.f);

    try said.emit("Hello World!\n");
}

pub fn say(message: []const u8) void {
    std.debug.print("{s}", .{message});
}
