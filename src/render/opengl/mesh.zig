const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const std = @import("std");

pub const OpenGLMesh = struct {
    vao: c_uint,
    vbo: c_uint,
    ebo: c_uint,
    index_count: u64,

    pub fn new(vertices: []const f32, indices: []const u32, comptime attributes: anytype) OpenGLMesh {
        var vao: c_uint = undefined;
        var vbo: c_uint = undefined;
        var ebo: c_uint = undefined;

        gl.genVertexArrays(1, &vao);
        gl.genBuffers(1, &vbo);
        gl.genBuffers(1, &ebo);

        gl.bindVertexArray(vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, gl.STATIC_DRAW);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, gl.STATIC_DRAW);

        comptime var total_components: usize = 0;
        inline for (attributes) |size| {
            total_components += size;
        }

        var offset: usize = 0;

        inline for (attributes, 0..) |size, index| {
            gl.vertexAttribPointer(
                index,
                size,
                gl.FLOAT,
                gl.FALSE,
                @intCast(total_components * @sizeOf(f32)),
                @ptrFromInt(offset * @sizeOf(f32)),
            );

            gl.enableVertexAttribArray(index);

            offset += size;
        }

        gl.bindVertexArray(0);

        return OpenGLMesh{ .vao = vao, .vbo = vbo, .ebo = ebo, .index_count = indices.len };
    }

    pub fn draw(self: *const OpenGLMesh) void {
        gl.bindVertexArray(self.vao);

        gl.drawElements(gl.TRIANGLES, @intCast(self.index_count), gl.UNSIGNED_INT, null);

        gl.bindVertexArray(0);
    }

    pub fn destroy(self: *OpenGLMesh) void {
        const buffers = [_]c_uint{ self.vbo, self.ebo };
        gl.deleteBuffers(2, @ptrCast(&buffers));
        gl.deleteVertexArrays(1, &self.vao);
    }
};
