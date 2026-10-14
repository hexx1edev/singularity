const gl = @import("opengl/opengl.zig");

pub const RenderBackend = enum { OpenGL };

pub const Renderer = struct {
    impl: union(enum) { opengl: gl.OpenGL },

    pub fn new(backend: RenderBackend) error{InitError}!Renderer {
        switch (backend) {
            RenderBackend.OpenGL => {
                const impl = gl.OpenGL.new() catch {
                    return error.InitError;
                };
                return Renderer{ .impl = .{ .opengl = impl } };
            },
        }
    }

    pub fn clearColor(self: *const Renderer, r: f32, g: f32, b: f32, a: f32) void {
        switch (self.impl) {
            .opengl => gl.OpenGL.clearColor(r, g, b, a),
        }
    }

    pub fn enableCulling(self: *const Renderer) void {
        switch (self.impl) {
            .opengl => gl.OpenGL.enableCulling(),
        }
    }

    pub fn disableCulling(self: *const Renderer) void {
        switch (self.impl) {
            .opengl => gl.OpenGL.disableCulling(),
        }
    }
};
