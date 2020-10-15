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
    
    // ok new plan
    // https://github.com/cyrus-and/xkeylogger/blob/master/xkeylogger.c#L176
    // xlistinputdevices, xopendevice, devicekeypress, xselectextensionevent I guess idk
    // this doesn't work at all and the c version ignores keys pressed in terminals for some reason
    //
    // even better https://stackoverflow.com/questions/6560553/linux-x11-global-keyboard-hook
    // that's exactly what I need
    // and there doesn't seem to be any good answer
    //
    // ok here
    // https://github.com/wilix-team/iohook/tree/master/libuiohook
    // read from that and figure out how it works
    // f it uses X11 instead of xcb, I'll have to translate it
    // https://github.com/kwhat/libuiohook
    // oh neat there's an option for xcb
    // https://github.com/kwhat/libuiohook/blob/1.2/src/x11/input_hook.c
    // ok or instead of this I can just use libuiohook
    // and then I need to figure out how to fake events
    
    try connection.changeWindowAttribute(focus.window, .{.event_mask = .{.key_press = true, .key_release = true, .focus_change = true}}).wait(connection);
    
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
