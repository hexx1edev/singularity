const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const std = @import("std");

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
};
