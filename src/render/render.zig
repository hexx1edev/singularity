const zopengl = @import("zopengl");
const glfw = @import("zglfw");
const gl = zopengl.bindings;

fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return glfw.getProcAddress(name);
}

pub const RenderBackend = enum { OpenGL };

pub const Renderer = struct {
    backend: RenderBackend,

    pub fn new(backend: RenderBackend) error{GLError}!Renderer {
        zopengl.loadCoreProfile(getProcAddress, 4, 6) catch {
            return error.GLError;
        };

        return Renderer{ .backend = backend };
    }

    pub fn clearColor(self: *const Renderer, r: f32, g: f32, b: f32, a: f32) void {
        switch (self.backend) {
            RenderBackend.OpenGL => {
                gl.clearColor(r, g, b, a);
                gl.clear(gl.COLOR_BUFFER_BIT);
            },
        }
    }
};
