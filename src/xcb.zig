const std = @import("std");
const c = @cImport({
    @cInclude("xcb/xcb.h");
    @cInclude("xcb/xcb_keysyms.h");
    @cInclude("xcb/xinput.h");
});
pub usingnamespace @import("xcb_generated.zig");

// zig test src/xcb.zig -lxcb -lc
fn matches(comptime A: type, comptime B: type) void {
    comptime {
        if(A == B) return;
        const ti_a = @typeInfo(A);
        const ti_b = @typeInfo(B);
        if(ti_a == .Opaque and ti_b == .Opaque) return;
        if(@sizeOf(A) == @sizeOf(B)) return;
        @compileError("Incorrect struct");
    }
}

test "struct" {matches(Window, c.xcb_window_t);}
const Window = enum(u32) {_};

test "struct" {matches(Colormap, c.xcb_colormap_t);}
const Colormap = enum(u32) {_};

test "struct" {matches(Colormap, c.xcb_visualid_t);}
const VisualID = enum(u32) {_};

test "struct" {matches(Keycode, c.xcb_keycode_t);}
const Keycode = enum(u8) {_};

test "struct" {matches(Atom, c.xcb_atom_t);}
const Atom = enum(u32) {_};

test "struct" {matches(Screen, c.xcb_screen_t);}
pub const Screen = extern struct {
    root: Window,
    default_colormap: Colormap,
    white_pixel: u32,
    black_pixel: u32,
    current_input_masks: u32,
    width_in_pixels: u16,
    height_in_pixels: u16,
    width_in_millimeters: u16,
    height_in_millimeters: u16,
    min_installed_maps: u16,
    max_installed_maps: u16,
    root_visual: VisualID,
    backing_stores: u8,
    save_unders: u8,
    root_depth: u8,
    allowed_depths_len: u8,
};

test "struct" {matches(ScreenIterator, c.xcb_screen_iterator_t);}
pub const ScreenIterator = extern struct {
    data: *Screen,
    rem: c_int,
    index: c_int,
};

test "struct" {matches(Setup, c.xcb_setup_t);}
pub const Setup = extern struct {
    status: u8,
    pad0: u8,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    length: u16,
    release_number: u32,
    resource_id_base: u32,
    resource_id_mask: u32,
    motion_buffer_size: u32,
    vendor_len: u16,
    maximum_request_length: u16,
    roots_len: u8,
    pixmap_formats_len: u8,
    image_byte_order: u8,
    bitmap_format_bit_order: u8,
    bitmap_format_scanline_unit: u8,
    bitmap_format_scanline_pad: u8,
    min_keycode: Keycode,
    max_keycode: Keycode,
    pad1: [4]u8,
    
    extern fn xcb_setup_roots_iterator(R: *const Setup) ScreenIterator;
    const rootsIterator = xcb_setup_roots_iterator;
};

test "struct" {matches(Connection, c.xcb_connection_t);}
pub const Connection = opaque {
    extern fn xcb_connect(displayname: ?[*:0]const u8, screenp: ?[*:0]const u8) *Connection;
    pub const connect = xcb_connect;
    
    extern fn xcb_disconnect(c: *Connection) void;
    pub const disconnect = xcb_disconnect;
    
    extern fn xcb_get_setup(c: *Connection) *const Setup;
    pub const setup = xcb_get_setup;
    
    extern fn xcb_get_input_focus(c: *Connection) InputFocus;
    extern fn xcb_get_input_focus_reply(c: *Connection, cookie: InputFocus, e: ?*?*GenericError) *InputFocus.Reply;
    const InputFocus = AutoCookie(InputFocusReply, struct{const method = xcb_get_input_focus_reply;}, .cannot_error);
    pub const getInputFocus = xcb_get_input_focus;
    
    extern fn xcb_input_list_input_devices(c: *Connection) ListInputDevices;
    extern fn xcb_input_list_input_devices_reply(c: *Connection, cookie: ListInputDevices, e: ?*?*GenericError) *ListInputDevices.Reply;
    const ListInputDevices = AutoCookie(ListInputDevicesReply, struct{const method = xcb_input_list_input_devices_reply;}, .cannot_error);
    pub const listInputDevices = xcb_input_list_input_devices;
    
    extern fn xcb_change_window_attributes_checked(c: *Connection, window: Window, value_mask: u32, value_list: [*]const u32) VoidCookie;
    pub fn changeWindowAttribute(conn: *Connection, window: Window, value: WindowAttribute) VoidCookie {
        var value_mask: u32 = 0;
        var buf = [_]u32{undefined} ** @typeInfo(WindowAttribute).Struct.fields.len;
        var bufidx: usize = 0;
        inline for(@typeInfo(WindowAttribute).Struct.fields) |field, i| {
            if(@field(value, field.name)) |attr| {
                value_mask |= 1 << i;
                defer bufidx += 1;
                if(@TypeOf(attr) == u32) {
                    buf[bufidx] = attr;
                }else{
                    buf[bufidx] = attr.toU32();
                }
            } 
        }
        std.log.info("buf: {} {b} {} {}", .{window, buf[0], bufidx, value_mask});
        return conn.xcb_change_window_attributes_checked(window, value_mask, &buf);
    }
    
    extern fn xcb_wait_for_event(c: *Connection) ?*GenericEvent;
    pub fn waitForEvent(conn: *Connection) ?GenericEvent {
        const event = conn.xcb_wait_for_event() orelse return null;
        defer free(event);
        return event.*;
    }
    extern fn xcb_poll_for_event(c: *Connection) ?*GenericEvent;
    pub fn pollForEvent(conn: *Connection) ?GenericEvent {
        const event = conn.xcb_poll_for_event() orelse return null;
        defer free(event);
        return event.*;
    }
};

test "struct" {matches(ListInputDevicesReply, c.xcb_input_list_input_devices_reply_t);}
pub const ListInputDevicesReply = extern struct {
    response_type: u8,
    xi_reply_type: u8,
    sequence: u16,
    length: u32,
    devices_len: u8,
    pad0: [23]u8,
    pub fn devices(R: *const ListInputDevicesReply) []DeviceInfo {
        return R.devicesPtr()[0..@intCast(usize, R.devicesLen())];
    }
    extern fn xcb_input_list_input_devices_devices(R: *const ListInputDevicesReply) [*]DeviceInfo;
    pub const devicesPtr = xcb_input_list_input_devices_devices;
    extern fn xcb_input_list_input_devices_devices_length(R: *const ListInputDevicesReply) c_int;
    pub const devicesLen = xcb_input_list_input_devices_devices_length;
    
    extern fn xcb_input_list_input_devices_devices_iterator(R: *const ListInputDevicesReply) xcb_input_device_info_iterator_t;
    extern fn xcb_input_list_input_devices_infos_length(R: *const ListInputDevicesReply) c_int;
    extern fn xcb_input_list_input_devices_infos_iterator(R: *const ListInputDevicesReply) xcb_input_input_info_iterator_t;
    extern fn xcb_input_list_input_devices_names_length(R: *const ListInputDevicesReply) c_int;
    extern fn xcb_input_list_input_devices_names_iterator(R: *const ListInputDevicesReply) xcb_str_iterator_t;
};

test "struct" {matches(DeviceInfo, c.xcb_input_device_info_t);}
pub const DeviceInfo = extern struct {
    device_type: Atom,
    device_id: u8,
    num_class_info: u8,
    device_use: u8,
    pad0: u8,
};

pub const GenericEvent = extern struct {
    response_type: u8,
    pad0: u8,
    sequence: u16,
    pad: [7]u32,
    full_sequence: u32,
    
    pub fn tag(event: GenericEvent) EventTag {
        return @intToEnum(EventTag, event.response_type);
    }
};

pub const WindowAttribute = struct {
    const EventMask = struct {
        no_event: bool = false,
        key_press: bool = false,
        key_release: bool = false,
        button_press: bool = false,
        button_release: bool = false,
        
        enter_window: bool = false,
        leave_window: bool = false,
        pointer_motion: bool = false,
        pointer_motion_hint: bool = false,
        button_1_motion: bool = false,
        button_2_motion: bool = false,
        button_3_motion: bool = false,
        button_4_motion: bool = false,
        button_5_motion: bool = false,
        keymap_state: bool = false,
        visibility_change: bool = false,
        structure_notify: bool = false,
        resize_redirect: bool = false,
        substructure_notify: bool = false,
        substructure_redirect: bool = false,
        focus_change: bool = false,
        property_change: bool = false,
        color_change: bool = false,
        owner_grab_button: bool = false,
        
        fn toU32(self: EventMask) u32 {
            var result_type: std.meta.Int(false, @typeInfo(EventMask).Struct.fields.len) = 0;
            inline for(@typeInfo(EventMask).Struct.fields) |field, i| {
                if(@field(self, field.name)) {
                    result_type |= 1 << i;
                }
            }
            return result_type;
        }
    };
    back_pixmap: ?u32 = null,
    back_pixel: ?u32 = null,
    border_pixmap: ?u32 = null,
    border_pixel: ?u32 = null,
    bit_gravity: ?u32 = null,
    win_gravity: ?u32 = null,
    backing_store: ?u32 = null,
    backing_planes: ?u32 = null,
    backing_pixel: ?u32 = null,
    override_redirect: ?u32 = null,
    save_under: ?u32 = null,
    event_mask: ?EventMask = null,
    dont_propagate: ?u32 = null,
    colormap: ?u32 = null,
    cursor: ?u32 = null,
};

const VoidCookie = extern struct {
    sequence: c_uint,
    extern fn xcb_request_check(c: *Connection, cookie: VoidCookie) ?*GenericError;
    pub fn wait(cookie: @This(), conn: *Connection) !void {
        if(xcb_request_check(conn, cookie)) |err| {
            defer free(err);
            std.log.err("Got error: {}", .{err.errorString()});
            return error.XcbError;
        }
    }
};

pub fn free(ptr: anytype) void {
    std.heap.c_allocator.destroy(ptr);
}

fn AutoCookie(comptime ReplyType: type, comptime ReplyMethod: type, comptime can_error: enum{can_error, cannot_error}) type {
    switch(can_error) {
        .cannot_error => return extern struct {
            sequence: c_uint,
            const Reply = ReplyType;
            pub fn wait(cookie: @This(), conn: *Connection) ReplyType {
                var err: ?*GenericError = null;
                const result = ReplyMethod.method(conn, cookie, &err);
                if(err) |er| unreachable; // .cannot_error
                defer free(result);
                return result.*;
            }
        },
        .can_error => return extern struct {
            sequence: c_uint,
            const Reply = ReplyType;
            pub fn wait(cookie: @This(), conn: *Connection) !ReplyType {
                var err: ?*GenericError = null;
                const result = ReplyMethod.method(conn, cookie, &err);
                std.log.info("Waited!", .{});
                if(err) |er| {
                    defer free(er);
                    return error.XcbError;
                }
                defer free(result);
                return result.*;
            }
        },
    }
}

test "struct" {matches(InputFocusReply, c.xcb_get_input_focus_reply_t);}
const InputFocusReply = extern struct {
    response_type: u8,
    revert_to: u8,
    sequence: u16,
    length: u32,
    window: Window,
};
test "struct" {matches(GenericError, c.xcb_generic_error_t);}
pub const GenericError = extern struct {
    response_type: u8,
    error_code: u8,
    sequence: u16,
    resource_id: u32,
    minor_code: u16,
    major_code: u8,
    pad0: u8,
    pad: [5]u32,
    full_sequence: u32,
    pub fn errorString(err: GenericError) []const u8 {
        return switch(err.error_code) {
            0 => "Success : success",
            1 => "BadRequest : bad request code",
            2 => "BadValue : int parameter out of range",
            3 => "BadWindow : parameter not a Window",
            4 => "BadPixmap : parameter not a Pixmap",
            5 => "BadAtom : parameter not an Atom",
            6 => "BadCursor : parameter not a Cursor",
            7 => "BadFont : parameter not a Font",
            8 => "BadMatch : parameter mismatch",
            9 => "BadDrawable : parameter not a Pixmap or Window",
            10 => "BadAccess : key/button already grabbed | attempt to free illegal cmap entry | attempt to store into a read-only colormap entry | attempt to modify access control list from other host",
            11 => "BadAlloc : insufficient resources",
            12 => "BadColor : no such colormap",
            13 => "BadGC : parameter not a GC",
            14 => "BadIDChoice : choice not in range or already used",
            15 => "BadName : font or color name does not exist",
            16 => "BadLength : request length incorrect",
            17 => "BadImplementation : server is defective",
            else => "?? : unknown error",
        };
    }
};

// apparently there is XCB_CW_WIN_GRAVITY
// i3 should probably set this to bottom right when resizing up left, but it doesn't
// should I pr i3?
//   Defines which region of the window should be retained if the window is resized