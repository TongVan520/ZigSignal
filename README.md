# ZigSignal
这是一个 `Zig` 信号槽库。

## 使用要求
- `Zig 0.14.0` 及以上

## 使用方式


## 使用示例
此示例展示了 *信号槽* 最基本的用法。
```zig
const std = @import("std");
const signal = @import("signal.zig");

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var said = signal.SignalOne([]const u8).init(allocator);
    defer said.deinit();

    try said.slots.append(signal.SlotOne([]const u8){
        .function = struct {
            fn f(_: ?*anyopaque, message: []const u8) !void {
                say(message);
            }
        }.f,
    });

    try said.emit("Hello Signal Slot!\n");
}

pub fn say(message: []const u8) void {
    std.debug.print("{s}", .{message});
}
```

输出：
```shell
Hello World!
Hello Signal Slot!
```

更多示例请参考 [源码](./src/signal.zig) 的 `test` 单元测试。
