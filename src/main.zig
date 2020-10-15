const std = @import("std");
const xcb = @import("xcb.zig");

pub fn main() !void {
    const conn = xcb.Connection.connect(null, null);
    defer conn.disconnect();
    
    std.log.info("Connected", .{});
    defer std.log.info("Exiting", .{});
    
    const screen = conn.setup().rootsIterator().data;
    
    const root = screen.root;
    
    const focus = conn.getInputFocus().wait(conn);
    
    std.log.info("Got focused window: {}", .{focus});
    
    // XListInputDevices();
    // for(devices) {
    //     if(devices[i].use == IsXExtensionKeyboard) {
    //         XOpenDevice(display, devices[i].id);
    //         DeviceKeyPress(device, KEY_PRESS_TYPE, event_class)
    //         XSelectExtensionEvent(display, root, &event_class, 1)
    //     }
    // }
    
    // there is an xcb xinput extension
    
    const input_devices = conn.listInputDevices().wait(conn).devices();
    for(input_devices) |device| {
        std.log.info("Got input device: {}", .{device});
        // if(@enumToInt(device.device_type) == 0) continue;
        if(conn.getAtomName(device.device_type).wait(conn)) |atom| {
            const text = atom.text();
            for(text) |char| std.log.info("Char: `{}`", .{char});
            std.log.info("Type: `{}`", .{atom.text()});
        }else |err| std.log.err("Err: {}", .{err});
    }
    
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
    //
    // maybe try this? https://github.com/cyrus-and/xkeylogger/blob/master/xkeylogger.c
    // but with xcb
    //
    // ok the other option is taking over the keyboard and trying to fake events
    
    // try conn.changeWindowAttribute(focus.window, .{.event_mask = .{.key_press = true, .key_release = true, .focus_change = true}}).wait(conn);
    
    while(conn.waitForEvent()) |event| {
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
