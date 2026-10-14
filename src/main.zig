const std = @import("std");
const Init = std.process.Init;
const Window = @import("window/window.zig").Window;
const renderer = @import("render/renderer.zig");
const Shader = @import("render/shader.zig").Shader;
const Mesh = @import("render/mesh.zig").Mesh;
const math = @import("math/math.zig");

const vertices = [_]f32{ -0.5, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, 0.5, 0.0, 0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0 };
const indices = [_]u32{ 0, 1, 2, 3, 4, 5 };

const vertex_source =
    \\#version 460 core
    \\layout (location = 0) in vec3 vPos;
    \\
    \\uniform mat4 model;
    \\uniform mat4 projection;
    \\uniform mat4 view;
    \\
    \\void main() {
    \\    gl_Position = projection * view * model * vec4(vPos, 1.0);
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

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;

    var win = try Window.new("singularity demo", 1280, 720);
    defer win.destroy();

    var backend = try renderer.Renderer.new(renderer.RenderBackend.OpenGL);

    var shader = Shader.new(&backend, vertex_source, fragment_source);
    defer shader.destroy();
    var mesh = Mesh.new(&backend, &vertices, &indices, .{3});
    defer mesh.destroy();

    try shader.compile();

    const Mat4 = math.matrix.Mat4;
    const Vec3 = math.vector.Vec3;
    const Quaternion = math.quaternion.Quaternion;

    var rotation = Quaternion.identity();

    const projection = Mat4.perspective(std.math.degreesToRadians(90.0), 1280.0 / 720.0, 0.01, 100.0) orelse return error.BadProjection;
    const view = Mat4.rotate(
        Mat4.translate(Mat4.identity(), Vec3.fromAxis(0.0, 0.0, -1.0)),
        std.math.degreesToRadians(0.0),
        Vec3.fromAxis(0.0, 1.0, 0.0),
    );

    var lastTime: f32 = 0.0;
    var deltaTime: f32 = 0.0;

    // FPS is averaged over a window rather than read off a single frame, so the
    // counter stays legible instead of flickering every frame
    const fps_interval: f32 = 0.25;
    var fps_elapsed: f32 = 0.0;
    var fps_frames: u32 = 0;

    while (!win.shouldClose()) {
        Window.pollEvents();

        const time = Window.getTime();
        deltaTime = time - lastTime;
        lastTime = time;

        fps_elapsed += deltaTime;
        fps_frames += 1;

        if (fps_elapsed >= fps_interval) {
            const fps = @as(f32, @floatFromInt(fps_frames)) / fps_elapsed;

            const title = try std.fmt.allocPrintSentinel(alloc, "singularity demo | FPS: {d:.1}", .{fps}, 0);
            defer alloc.free(title);

            win.setTitle(title);

            fps_elapsed = 0.0;
            fps_frames = 0;
        }

        const spin = Quaternion.fromAngle(5.0 * deltaTime, Vec3.fromAxis(0.0, 1.0, 0.0));
        rotation = spin.mul(rotation).normalize();

        const model = rotation.asMatrix();

        backend.clearColor(1.0, 1.0, 1.0, 1.0);

        shader.use();

        try shader.setMat4("model", model);
        try shader.setMat4("projection", projection);
        try shader.setMat4("view", view);

        mesh.draw();

        win.swapBuffers();
    }
}
