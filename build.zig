const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("hotkeyzig", "src/demo_hook.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    
    
    // zig build-exe lib/uiohook/demo/demo_hook.c -I lib/uiohook/include/ lib/uiohook/src/logger.c lib/uiohook/src/x11/*.c --name demo -lc -lX11 -I lib/uiohook/src/ -lXtst
    exe.linkLibC();
    exe.linkSystemLibrary("Xtst");
    exe.linkSystemLibrary("X11");
    
    exe.addIncludeDir("lib/uiohook/include");
    exe.addIncludeDir("lib/uiohook/src");
    exe.addCSourceFile("lib/uiohook/src/logger.c", &[_][]const u8{});
    inline for(.{"input_helper.c", "input_hook.c", "post_event.c", "system_properties.c"}) |csrc| {
        switch(target.getOsTag()) {
            .linux => exe.addCSourceFile("lib/uiohook/src/x11/"++csrc, &[_][]const u8{}),
            .macos => exe.addCSourceFile("lib/uiohook/src/darwin/"++csrc, &[_][]const u8{}),
            .windows => exe.addCSourceFile("lib/uiohook/src/windows/"++csrc, &[_][]const u8{}),
            else => @import("std").debug.warn("Unsupported OS\n", .{}), // I know this isn't right but I'm not sure what is right
        }
    }
    
    exe.addCSourceFile("src/demo_hook_logger.c", &[_][]const u8{});
    
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
