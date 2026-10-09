const std = @import("std");
const Init = std.process.Init;
const Window = @import("window/window.zig").Window;
const renderer = @import("render/renderer.zig");
const Shader = @import("render/shader.zig").Shader;
const Mesh = @import("render/mesh.zig").Mesh;

const vertices = [_]f32{ 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 };
const indices = [_]u32{ 0, 1, 2 };

const vertex_source =
    \\#version 460 core
    \\layout (location = 0) in vec3 vPos;
    \\
    \\void main() {
    \\    gl_Position = vec4(vPos, 1.0);
    \\}
;

const fragment_source =
    \\#version 460 core
    \\
    \\out vec4 fragColor;
    \\
    \\void main() {
    \\    fragColor = vec4(1.0, 0.5, 0.3, 1.0);
    \\}
;

pub fn main() !void {
    var win = try Window.new("singularity demo", 1280, 720);
    defer win.destroy();

    var backend = try renderer.Renderer.new(renderer.RenderBackend.OpenGL);

    var shader = Shader.new(&backend, vertex_source, fragment_source);
    var mesh = Mesh.new(&backend, &vertices, &indices, .{3});
    defer mesh.destroy();

    try shader.compile();
    defer shader.destroy();

    while (!win.shouldClose()) {
        Window.pollEvents();

        backend.clearColor(1.0, 1.0, 1.0, 1.0);

        shader.use();
        mesh.draw();

        win.swapBuffers();
    }
}
