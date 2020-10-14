const std = @import("std");
const xcb = @import("xcb.zig");

pub fn main() !void {
    const connection = xcb.Connection.connect(null, null);
    defer connection.disconnect();
    
    std.log.info("Connected", .{});
    
    const screen = connection.setup().rootsIterator().data;
    
    const root = screen.root;
    
    const focus = connection.getInputFocus().wait(connection);
    defer xcb.free(focus); // why do I have to free it? why can't I just copy it onto the stack?
    // maybe I will make .wait() do that because freeing pointers from every function is dumb
    
    std.log.info("Got focused window: {}", .{focus});
    
    try connection.changeWindowAttribute(focus.window, .{.event_mask = .{.key_press = true, .key_release = true, .focus_change = true}}).wait(connection);
    
    std.log.info("Changed window attribute", .{});
}
