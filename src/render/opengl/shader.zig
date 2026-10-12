const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const std = @import("std");
const math = @import("../../math/math.zig");

pub const OpenGLShader = struct {
    vertex_source: [:0]const u8,
    fragment_source: [:0]const u8,
    program: c_uint,

    pub fn new(vertex_source: [:0]const u8, fragment_source: [:0]const u8) OpenGLShader {
        return OpenGLShader{ .vertex_source = vertex_source, .fragment_source = fragment_source, .program = 0 };
    }

    pub fn compile(self: *OpenGLShader) error{ VertexCompileError, FragmentCompileError, LinkError }!void {
        const vertex = gl.createShader(gl.VERTEX_SHADER);
        const fragment = gl.createShader(gl.FRAGMENT_SHADER);

        const vertex_sources = [_][*c]const u8{@ptrCast(self.vertex_source.ptr)};
        const fragment_sources = [_][*c]const u8{@ptrCast(self.fragment_source.ptr)};

        var success: c_int = undefined;
        var infoLog = [_]u8{0} ** 512;
        var length: c_int = undefined;

        gl.shaderSource(vertex, 1, &vertex_sources, null);
        gl.compileShader(vertex);

        gl.getShaderiv(vertex, gl.COMPILE_STATUS, &success);
        if (success <= 0) {
            gl.getShaderInfoLog(vertex, 512, &length, &infoLog);
            const message = infoLog[0..@intCast(@max(0, length))];
            std.debug.print("{s}", .{message});

            gl.deleteShader(vertex);

            return error.VertexCompileError;
        }

        gl.shaderSource(fragment, 1, &fragment_sources, null);
        gl.compileShader(fragment);

        gl.getShaderiv(fragment, gl.COMPILE_STATUS, &success);
        if (success <= 0) {
            gl.getShaderInfoLog(fragment, 512, &length, &infoLog);
            const message = infoLog[0..@intCast(@max(0, length))];
            std.debug.print("{s}", .{message});

            gl.deleteShader(vertex);
            gl.deleteShader(fragment);

            return error.FragmentCompileError;
        }

        const program = gl.createProgram();

        gl.attachShader(program, vertex);
        gl.attachShader(program, fragment);
        gl.linkProgram(program);

        gl.deleteShader(vertex);
        gl.deleteShader(fragment);

        gl.getProgramiv(program, gl.LINK_STATUS, &success);
        if (success <= 0) {
            gl.getProgramInfoLog(program, 512, &length, &infoLog);
            const message = infoLog[0..@intCast(@max(0, length))];
            std.debug.print("{s}", .{message});

            gl.deleteProgram(program);

            return error.LinkError;
        }

        self.program = program;
    }

    pub fn destroy(self: *OpenGLShader) void {
        gl.deleteProgram(self.program);
        self.program = 0;
    }

    pub fn use(self: *const OpenGLShader) void {
        gl.useProgram(self.program);
    }

    fn getUniformLocation(self: *const OpenGLShader, name: [:0]const u8) error{NotFound}!c_int {
        const loc = gl.getUniformLocation(self.program, name.ptr);
        if (loc < 0) return error.NotFound;
        return loc;
    }

    pub fn setVec2(self: *const OpenGLShader, name: [:0]const u8, vec: math.vector.Vec2) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        const values = vec.asArray();
        gl.uniform2fv(loc, 1, &values);
    }

    pub fn setVec3(self: *const OpenGLShader, name: [:0]const u8, vec: math.vector.Vec3) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        const values = vec.asArray();
        gl.uniform3fv(loc, 1, &values);
    }

    pub fn setVec4(self: *const OpenGLShader, name: [:0]const u8, vec: math.vector.Vec4) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        const values = vec.asArray();
        gl.uniform4fv(loc, 1, &values);
    }

    pub fn setInt(self: *const OpenGLShader, name: [:0]const u8, value: i32) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        gl.uniform1i(loc, @intCast(value));
    }

    pub fn setFloat(self: *const OpenGLShader, name: [:0]const u8, value: f32) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        gl.uniform1f(loc, value);
    }

    pub fn setMat4(self: *const OpenGLShader, name: [:0]const u8, mat: math.matrix.Mat4) error{NotFound}!void {
        const loc = try self.getUniformLocation(name);
        const rows = mat.asArray();
        // Mat4 keeps its rows contiguous, so OpenGL has to transpose on upload
        gl.uniformMatrix4fv(loc, 1, gl.TRUE, @ptrCast(&rows));
    }
};
