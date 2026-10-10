const std = @import("std");
const Init = std.process.Init;
const Window = @import("window/window.zig").Window;
const renderer = @import("render/renderer.zig");
const Shader = @import("render/shader.zig").Shader;
const Mesh = @import("render/mesh.zig").Mesh;
const vector = @import("math/math.zig").vector;

const vertices = [_]f32{ 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 };
const indices = [_]u32{ 0, 1, 2 };

const vertex_source =
    \\#version 460 core
    \\layout (location = 0) in vec3 vPos;
    \\
    \\uniform vec3 offset;
    \\
    \\void main() {
    \\    gl_Position = vec4(offset + vPos, 1.0);
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
    defer shader.destroy();
    var mesh = Mesh.new(&backend, &vertices, &indices, .{3});
    defer mesh.destroy();

    try shader.compile();

    const offset = vector.vec3(0.25, 0.25, 0.0);

    while (!win.shouldClose()) {
        Window.pollEvents();

        backend.clearColor(1.0, 1.0, 1.0, 1.0);

        shader.use();

        try shader.setVec3("offset", offset);

        mesh.draw();

        win.swapBuffers();
    }
}
