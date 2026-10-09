const gl = @import("opengl/shader.zig");
const Renderer = @import("renderer.zig").Renderer;

pub const Shader = struct {
    impl: union(enum) { opengl: gl.OpenGLShader },

    pub fn new(renderer: *const Renderer, vertex_source: [:0]const u8, fragment_source: [:0]const u8) Shader {
        switch (renderer.impl) {
            .opengl => {
                const shader = gl.OpenGLShader.new(vertex_source, fragment_source);
                return Shader{ .impl = .{ .opengl = shader } };
            },
        }
    }

    pub fn compile(self: *Shader) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.compile();
            },
        }
    }

    pub fn destroy(self: *Shader) void {
        switch (self.impl) {
            .opengl => |*impl| {
                impl.destroy();
            },
        }
    }

    pub fn use(self: *const Shader) void {
        switch (self.impl) {
            .opengl => |*impl| {
                impl.use();
            },
        }
    }
};
