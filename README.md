# ZigSignal
这是一个 `Zig` 信号槽库。

## 使用要求
- `Zig 0.14.0` 及以上

## 使用方式
在你的项目的 `build.zig.zon` 文件的 `dependencies` 字段中添加内容：
```zig
.dependencies = .{
	// 其它...
	
	.ZigSignal = .{
		.url = "https://github.com/TongVan520/ZigSignal/archive/refs/heads/main.zip",
		// .hash = "注释本行，然后通过zig build获取即可",
		.lazy = false,
	},
	
	// 其它...
},
```

然后在 `bulid.zig` 中添加内容：
```zig
// 其它...
const your_mod = ...;

const zig_signal = b.dependency("ZigSignal", .{});
your_mod.addImport("signal", zig_signal.module("zig-signal"));

// 其它...
```

最后 `zig build` 即可。

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
