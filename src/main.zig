const std = @import("std");
const Init = std.process.Init;
const Window = @import("window/window.zig").Window;
const renderer = @import("render/renderer.zig");
const Shader = @import("render/shader.zig").Shader;
const Mesh = @import("render/mesh.zig").Mesh;
const math = @import("math/math.zig");

const vertices = [_]f32{ 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 };
const indices = [_]u32{ 0, 1, 2 };

const vertex_source =
    \\#version 460 core
    \\layout (location = 0) in vec3 vPos;
    \\
    \\uniform mat4 model;
    \\uniform mat4 projection;
    \\uniform mat4 view;
    \\
    \\void main() {
    \\    gl_Position = model * projection * view * vec4(vPos, 1.0);
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

    const model = math.matrix.identity();

    const projection = math.matrix.perspective(std.math.degreesToRadians(90.0), 1280.0 / 720.0, 0.01, 100.0);
    const view = math.matrix.mul(math.matrix.mul(math.matrix.fromTranslation(math.vector.vec3(0.0, 0.0, -1.0)), math.matrix.fromAxisAngle(math.vector.vec3(0.0, 1.0, 0.0), std.math.degreesToRadians(0.0))), math.matrix.identity());

    while (!win.shouldClose()) {
        Window.pollEvents();

        backend.clearColor(1.0, 1.0, 1.0, 1.0);

        shader.use();

        try shader.setMat4("model", model);
        try shader.setMat4("projection", projection);
        try shader.setMat4("view", view);

        mesh.draw();

        win.swapBuffers();
    }
}
