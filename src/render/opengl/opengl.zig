const zopengl = @import("zopengl");
const glfw = @import("zglfw");
const gl = zopengl.bindings;

fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return glfw.getProcAddress(name);
}

pub const OpenGL = struct {
    pub fn new() error{GLError}!OpenGL {
        zopengl.loadCoreProfile(getProcAddress, 4, 6) catch {
            return error.GLError;
        };

        return OpenGL{};
    }

    pub fn clearColor(r: f32, g: f32, b: f32, a: f32) void {
        gl.clearColor(r, g, b, a);
        gl.clear(gl.COLOR_BUFFER_BIT);
    }

    pub fn enableCulling() void {
        gl.enable(gl.CULL_FACE);
    }

    pub fn disableCulling() void {
        gl.disable(gl.CULL_FACE);
    }
};
