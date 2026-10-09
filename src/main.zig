const std = @import("std");
const Init = std.process.Init;
const Window = @import("window/window.zig").Window;
const render = @import("render/render.zig");

pub fn main() !void {
    var win = try Window.new("Singularity demo", 1280, 720);
    defer win.destroy();

    const backend = try render.Renderer.new(render.RenderBackend.OpenGL);

    while (!win.shouldClose()) {
        Window.pollEvents();

        backend.clearColor(1.0, 1.0, 1.0, 1.0);

        win.swapBuffers();
    }
}
