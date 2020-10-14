const std = @import("std");
const c = @cImport({
    @cInclude("xcb/xcb.h");
    @cInclude("xcb/xcb_keysyms.h");
});

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
    
    extern fn xcb_get_input_focus(c: *Connection) InputFocus.Cookie;
    extern fn xcb_get_input_focus_reply(c: *Connection, cookie: InputFocus.Cookie, e: ?**GenericError) InputFocus.Reply;
    const InputFocus = AutoCookie(*InputFocusReply, struct{const method = xcb_get_input_focus_reply;});
    pub fn getInputFocus(conn: *Connection) InputFocus {
        return InputFocus.wrap(conn, xcb_get_input_focus(conn));
    }
};

pub fn free(ptr: anytype) void {
    std.heap.c_allocator.destroy(ptr);
}

fn AutoCookie(comptime ReplyType: type, comptime ReplyMethod: type) type {
    return struct {
        cookie: Cookie,
        connection: *Connection,
        const Cookie = extern struct {sequence: c_uint};
        const Reply = ReplyType;
        pub fn wrap(conn: *Connection, cookie: Cookie) @This() {
            return .{.connection = conn, .cookie = cookie};
        } 
        pub fn wait(cookie: @This()) ReplyType {
            return ReplyMethod.method(cookie.connection, cookie.cookie, null);
        }
    };
}

test "struct" {matches(InputFocusReply, c.xcb_get_input_focus_reply_t);}
const InputFocusReply = extern struct {
    response_type: u8,
    revert_to: u8,
    sequence: u16,
    length: u32,
    focus: Window,
};
test "struct" {matches(GenericError, c.xcb_generic_error_t);}
const GenericError = extern struct {
    response_type: u8,
    error_code: u8,
    sequence: u16,
    resource_id: u32,
    minor_code: u16,
    major_code: u8,
    pad0: u8,
    pad: [5]u32,
    full_sequence: u32,
};

// apparently there is XCB_CW_WIN_GRAVITY
// i3 should probably set this to bottom right when resizing up left, but it doesn't
// should I pr i3?
//   Defines which region of the window should be retained if the window is resized