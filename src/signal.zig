const std = @import("std");

/// 用于确保 **所有** ***空参数结构体*** **完全相同**
pub const EmptyArgs = struct {};

/// 任意数量参数信号
pub fn Signal(comptime ArgsTuple: type) type {
    return struct {
        const Self = @This();
        const Args = ArgsTuple;

        slots: std.ArrayList(Slot(Args)),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .slots = std.ArrayList(Slot(Args)).init(allocator),
            };
        }

        pub fn deinit(self: Self) void {
            self.slots.deinit();
        }

        pub fn emit(self: Self, args: Self.Args) !void {
            for (self.slots.items) |slot| {
                try slot.invoke(args);
            }
        }
    };
}

/// 无参数信号
pub const SignalZero = Signal(EmptyArgs);

/// 单参数信号
pub fn SignalOne(comptime Arg: type) type {
    return Signal(Arg);
}

/// 任意数量参数槽
pub fn Slot(comptime ArgsTuple: type) type {
    return struct {
        const Self = @This();
        const Args = ArgsTuple;

        userdata: ?*anyopaque = null,
        function: *const fn (userdata: ?*anyopaque, args: Self.Args) anyerror!void,

        pub fn invoke(self: Self, args: Self.Args) !void {
            try self.function(self.userdata, args);
        }
    };
}

/// 无参数槽
pub const SlotZero = Slot(EmptyArgs);

/// 单参数槽
pub fn SlotOne(comptime Arg: type) type {
    return Slot(Arg);
}

test "slot-zero" {
    var number: usize = 114514;
    const slot = SlotZero{
        .userdata = &number,
        .function = struct {
            fn f(userdata: ?*anyopaque, _: SlotZero.Args) !void {
                const n: *usize = @ptrCast(@alignCast(userdata));
                n.* = 1919810;
            }
        }.f,
    };
    try std.testing.expect(number == 114514);

    try slot.invoke(.{});
    try std.testing.expect(number == 1919810);
}

test "slot-one" {
    var number: usize = 114514;
    const slot = SlotOne(usize){
        .userdata = &number,
        .function = struct {
            fn f(userdata: ?*anyopaque, new_number: usize) !void {
                const n: *usize = @ptrCast(@alignCast(userdata));
                n.* = new_number;
            }
        }.f,
    };
    try std.testing.expect(number == 114514);

    try slot.invoke(1919810);
    try std.testing.expect(number == 1919810);
}

test "slot" {
    var number: usize = 114514;
    const MySlot = Slot(struct { a: usize, b: usize });
    const slot = MySlot{
        .userdata = &number,
        .function = struct {
            fn f(userdata: ?*anyopaque, args: MySlot.Args) !void {
                const n: *usize = @ptrCast(@alignCast(userdata));
                n.* = @min(args.a, args.b);
            }
        }.f,
    };
    try std.testing.expect(number == 114514);

    try slot.invoke(MySlot.Args{ .a = 1919, .b = 810 });
    try std.testing.expect(number == 810);
}

test "signal-zero" {
    const Button = struct {
        const Self = @This();

        clicked: SignalZero,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .clicked = SignalZero.init(allocator),
            };
        }

        pub fn deinit(self: Self) void {
            self.clicked.deinit();
        }

        pub fn click(self: Self) void {
            self.clicked.emit(.{}) catch unreachable;
        }
    };

    var button = Button.init(std.testing.allocator);
    defer button.deinit();

    var click_count: usize = 0;
    button.click();
    try std.testing.expect(click_count == 0);

    try button.clicked.slots.append(SlotZero{
        .userdata = &click_count,
        .function = struct {
            fn f(userdata: ?*anyopaque, _: SlotZero.Args) !void {
                const count: *usize = @ptrCast(@alignCast(userdata));
                count.* += 1;
            }
        }.f,
    });

    button.click();
    try std.testing.expect(click_count == 1);

    button.click();
    try std.testing.expect(click_count == 2);

    button.click();
    try std.testing.expect(click_count == 3);
}

test "signal-one" {
    const TextBox = struct {
        const Self = @This();

        text: []const u8,
        text_changed: SignalOne([]const u8),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .text = "",
                .text_changed = SignalOne([]const u8).init(allocator),
            };
        }

        pub fn deinit(self: Self) void {
            self.text_changed.deinit();
        }

        /// 设置文本，并触发信号
        pub fn setText(self: *Self, text: []const u8) void {
            self.text = text;
            self.text_changed.emit(self.text) catch unreachable;
        }
    };

    var text_box = TextBox.init(std.testing.allocator);
    defer text_box.deinit();

    text_box.text = "114";
    try std.testing.expect(std.mem.eql(u8, text_box.text, "114"));

    text_box.setText("514");
    try std.testing.expect(std.mem.eql(u8, text_box.text, "514"));

    try text_box.text_changed.slots.append(SlotOne([]const u8){
        .function = struct {
            fn f(_: ?*anyopaque, new_text: []const u8) !void {
                try std.testing.expect(std.mem.eql(u8, new_text, "810"));
            }
        }.f,
    });

    text_box.text = "1919";
    try std.testing.expect(std.mem.eql(u8, text_box.text, "1919"));

    text_box.setText("810");
    try std.testing.expect(std.mem.eql(u8, text_box.text, "810"));
}

test "signal" {
    // TODO 添加 任意数量参数信号 测试用例
}
