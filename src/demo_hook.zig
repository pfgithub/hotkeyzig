const std = @import("std");
const c = @cImport({@cInclude("uiohook.h");});

extern fn logger_proc(level: c_uint, format: [*c]const u8, ...) callconv(.C) bool;

fn dispatch_proc(c_event: [*c]const c.uiohook_event) callconv(.C) void {
    const event: *const c.uiohook_event = c_event;
    std.debug.warn("\r", .{});
    switch(event.@"type") {
        .EVENT_KEY_PRESSED => std.debug.warn("↓Key", .{}),
        .EVENT_KEY_RELEASED => std.debug.warn("↑Key", .{}),
        .EVENT_KEY_TYPED => blk: {
            // {u} please
            var buf = [_]u8{undefined} ** 4;
            const len = std.unicode.utf8Encode(event.data.keyboard.keychar, &buf) catch |e| switch(e) {
                else => {std.log.err("{}", .{e}); break :blk;},
            };
            std.debug.warn("{}| Key", .{buf[0..len]});
        },
        .EVENT_MOUSE_PRESSED => std.debug.warn("↓m", .{}),
        .EVENT_MOUSE_RELEASED => std.debug.warn("↑m", .{}),
        .EVENT_MOUSE_CLICKED => std.debug.warn("· m", .{}),
        .EVENT_MOUSE_WHEEL => std.debug.warn("w", .{}),
        .EVENT_MOUSE_MOVED => return,
        .EVENT_MOUSE_DRAGGED => return,
        else => std.debug.warn("Unknown: {}", .{event.@"type"}),
    }
    std.debug.warn("\x1b[K\n", .{});
}

pub fn main() !void {
    // Set the logger callback for library output.
    c.hook_set_logger_proc(logger_proc);
    
    // Set the event callback for uiohook events.
    c.hook_set_dispatch_proc(dispatch_proc);
    
    // Start the hook and block.
    // NOTE If EVENT_HOOK_ENABLED was delivered, the status will always succeed.
    const status = c.hook_run();
    switch (status) {
        c.UIOHOOK_SUCCESS => {},
        else => std.log.err("Error code {}", .{status}),
    }
}