const std = @import("std");
const c = @cImport({@cInclude("uiohook.h");});

extern fn logger_proc(level: c_uint, format: [*c]const u8, ...) callconv(.C) bool;

fn dispatch_proc(event: [*c]const c.uiohook_event) callconv(.C) void {
    std.log.info("Got event: {}", .{event.*});
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