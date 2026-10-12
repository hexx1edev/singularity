const gl = @import("opengl/shader.zig");
const Renderer = @import("renderer.zig").Renderer;
const math = @import("../math/math.zig");

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

    pub fn setVec2(self: *const Shader, name: [:0]const u8, vec: math.vector.Vec2) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setVec2(name, vec);
            },
        }
    }

    pub fn setVec3(self: *const Shader, name: [:0]const u8, vec: math.vector.Vec3) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setVec3(name, vec);
            },
        }
    }

    pub fn setVec4(self: *const Shader, name: [:0]const u8, vec: math.vector.Vec4) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setVec4(name, vec);
            },
        }
    }

    pub fn setInt(self: *const Shader, name: [:0]const u8, value: i32) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setInt(name, value);
            },
        }
    }

    pub fn setFloat(self: *const Shader, name: [:0]const u8, value: f32) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setFloat(name, value);
            },
        }
    }

    pub fn setMat4(self: *const Shader, name: [:0]const u8, mat: math.matrix.Mat4) !void {
        switch (self.impl) {
            .opengl => |*impl| {
                try impl.setMat4(name, mat);
            },
        }
    }
};
