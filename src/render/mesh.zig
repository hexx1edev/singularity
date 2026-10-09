const gl = @import("opengl/mesh.zig");
const Renderer = @import("renderer.zig").Renderer;

pub const Mesh = struct {
    impl: union(enum) { opengl: gl.OpenGLMesh },

    pub fn new(renderer: *Renderer, vertices: []const f32, indices: []const u32, comptime attributes: anytype) Mesh {
        switch (renderer.impl) {
            .opengl => {
                const mesh = gl.OpenGLMesh.new(vertices, indices, attributes);
                return Mesh{ .impl = .{ .opengl = mesh } };
            },
        }
    }

    pub fn draw(self: *const Mesh) void {
        switch (self.impl) {
            .opengl => |*impl| {
                impl.draw();
            },
        }
    }

    pub fn destroy(self: *Mesh) void {
        switch (self.impl) {
            .opengl => |*impl| {
                impl.destroy();
            },
        }
    }
};
