const std = @import("std");
const xcb = @import("xcb.zig");

pub fn main() !void {
    const connection = xcb.Connection.connect(null, null);
    defer connection.disconnect();
    
    std.log.info("Connected", .{});
    defer std.log.info("Exiting", .{});
    
    const screen = connection.setup().rootsIterator().data;
    
    const root = screen.root;
    
    const focus = connection.getInputFocus().wait(connection);
    
    std.log.info("Got focused window: {}", .{focus});
    
    try connection.changeWindowAttribute(focus.window, .{.event_mask = .{.key_press = true, .key_release = true, .focus_change = true, .button_press = true}}).wait(connection);
    
    while(connection.waitForEvent()) |event| {
        // why does one example say to do (event->response_type & ~0x80)?
        std.log.info("Got event {}", .{event.tag()});
        switch(event.tag()) {
            .x11_error => {
                const err = @bitCast(xcb.GenericError, event);
                std.log.err("Got error! {}", .{err.errorString()});
            },
            else =>{},
        }
    }
}
