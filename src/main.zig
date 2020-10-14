const std = @import("std");
const xcb = @import("xcb.zig");

pub fn main() !void {
    const connection = xcb.Connection.connect(null, null);
    defer connection.disconnect();
    
    std.log.info("Connected", .{});
    
    const screen = connection.setup().rootsIterator().data;
    
    const root = screen.root;
    
    const focus = connection.getInputFocus().wait();
    defer xcb.free(focus); // why do I have to free it? why can't I just copy it onto the stack?
    // maybe I will make .wait() do that because freeing pointers from every function is dumb
    
    std.debug.warn("Got focused window: {}\n", .{focused_window});
    
    // https://www.x.org/releases/current/doc/man/man3/xcb_change_window_attributes.3.xhtml
    // xcb_change_window_attributes
    // XCB_CW_EVENT_MASK
    // XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_KEY_RELEASE | XCB_EVENT_MASK_FOCUS_CHANGE
    
    // focus.window.changeAttribute(.event_mask, .{.key_press = true, .key_release = true, .focus_change = true});
}
