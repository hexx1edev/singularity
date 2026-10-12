const vm = @import("vector.zig");
const Vec3 = vm.Vec3;

/// 4x4 matrix stored as 4 row vectors, so `Simd[row][column]`. Transforms are
/// applied to column vectors, `M * v`, the same convention GLSL uses
pub const Mat4 = struct {
    Simd: [4]@Vector(4, f32),

    /// Constructs an identity matrix
    pub fn identity() Mat4 {
        return .{ .Simd = .{ .{ 1.0, 0.0, 0.0, 0.0 }, .{ 0.0, 1.0, 0.0, 0.0 }, .{ 0.0, 0.0, 1.0, 0.0 }, .{ 0.0, 0.0, 0.0, 1.0 } } };
    }

    /// Constructs matrix from scalar
    pub fn fromScalar(scalar: f32) Mat4 {
        return .{ .Simd = .{ .{ scalar, 0.0, 0.0, 0.0 }, .{ 0.0, scalar, 0.0, 0.0 }, .{ 0.0, 0.0, scalar, 0.0 }, .{ 0.0, 0.0, 0.0, scalar } } };
    }

    /// Constructs matrix from 4x4 array
    pub fn fromArray(array: [4][4]f32) Mat4 {
        return .{ .Simd = .{ array[0], array[1], array[2], array[3] } };
    }

    /// Constructs a perspective projection matrix with FOV in radians, aspect ratio and near-far planes
    pub fn perspective(fov: f32, aspectRatio: f32, near: f32, far: f32) ?Mat4 {
        if (near == 0.0 or aspectRatio == 0.0 or far == near) return null;

        const half_tan = @tan(fov * 0.5);
        if (half_tan == 0.0) return null;

        const first = 1.0 / (aspectRatio * half_tan);
        const second = 1.0 / half_tan;
        const third = -((far + near) / (far - near));
        const fourth = -(((2 * far) * near) / (far - near));

        return .{ .Simd = .{ .{ first, 0.0, 0.0, 0.0 }, .{ 0.0, second, 0.0, 0.0 }, .{ 0.0, 0.0, third, fourth }, .{ 0.0, 0.0, -1.0, 0.0 } } };
    }

    /// Returns matrix as array
    pub fn asArray(self: *const Mat4) [4][4]f32 {
        return .{ self.Simd[0], self.Simd[1], self.Simd[2], self.Simd[3] };
    }

    /// Returns matrix determinant
    pub fn determinant(matrix: Mat4) f32 {
        const m = matrix.Simd;

        const a = m[0][0];
        const b = m[0][1];
        const c = m[0][2];
        const d = m[0][3];

        const minor0 =
            m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2]) -
            m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1]) +
            m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1]);

        const minor1 =
            m[1][0] * (m[2][2] * m[3][3] - m[2][3] * m[3][2]) -
            m[1][2] * (m[2][0] * m[3][3] - m[2][3] * m[3][0]) +
            m[1][3] * (m[2][0] * m[3][2] - m[2][2] * m[3][0]);

        const minor2 =
            m[1][0] * (m[2][1] * m[3][3] - m[2][3] * m[3][1]) -
            m[1][1] * (m[2][0] * m[3][3] - m[2][3] * m[3][0]) +
            m[1][3] * (m[2][0] * m[3][1] - m[2][1] * m[3][0]);

        const minor3 =
            m[1][0] * (m[2][1] * m[3][2] - m[2][2] * m[3][1]) -
            m[1][1] * (m[2][0] * m[3][2] - m[2][2] * m[3][0]) +
            m[1][2] * (m[2][0] * m[3][1] - m[2][1] * m[3][0]);

        return a * minor0 - b * minor1 + c * minor2 - d * minor3;
    }

    /// Calculates an inverse matrix, returning null when the matrix is singular
    pub fn inverse(matrix: Mat4) ?Mat4 {
        // Extended matrix
        var aug: [4][8]f32 = undefined;

        for (0..4) |r| {
            const row: [4]f32 = matrix.Simd[r];

            for (0..8) |c| {
                aug[r][c] = if (c < 4)
                    row[c]
                else if (c - 4 == r)
                    1.0
                else
                    0.0;
            }
        }

        for (0..4) |col| {
            // Select row with max main element modulo
            var pivot_row = col;
            var max_abs = @abs(aug[col][col]);

            for (col + 1..4) |r| {
                const value = @abs(aug[r][col]);

                if (value > max_abs) {
                    max_abs = value;
                    pivot_row = r;
                }
            }

            // Can we continue calculation?
            if (max_abs < 1e-8) return null;

            // Swap rows if needed
            if (pivot_row != col) {
                const temp = aug[col];
                aug[col] = aug[pivot_row];
                aug[pivot_row] = temp;
            }

            // Set main element to 1
            const pivot = aug[col][col];

            for (0..8) |c| {
                aug[col][c] /= pivot;
            }

            // Zero all other elements
            for (0..4) |r| {
                if (r == col) continue;

                const factor = aug[r][col];

                for (0..8) |c| {
                    aug[r][c] -= factor * aug[col][c];
                }
            }
        }

        // Right half
        var result: Mat4 = undefined;

        for (0..4) |r| {
            result.Simd[r] = .{
                aug[r][4],
                aug[r][5],
                aug[r][6],
                aug[r][7],
            };
        }

        return result;
    }

    /// Adds two matrices
    pub fn add(a: Mat4, b: Mat4) Mat4 {
        return .{ .Simd = .{ a.Simd[0] + b.Simd[0], a.Simd[1] + b.Simd[1], a.Simd[2] + b.Simd[2], a.Simd[3] + b.Simd[3] } };
    }

    /// Subtracts two matrices
    pub fn sub(a: Mat4, b: Mat4) Mat4 {
        return .{ .Simd = .{ a.Simd[0] - b.Simd[0], a.Simd[1] - b.Simd[1], a.Simd[2] - b.Simd[2], a.Simd[3] - b.Simd[3] } };
    }

    /// Multiplies two matrices
    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var result: Mat4 = undefined;

        for (0..4) |i| {
            var row: @Vector(4, f32) = @splat(0.0);

            inline for (0..4) |k| {
                row += b.Simd[k] * @as(@Vector(4, f32), @splat(a.Simd[i][k]));
            }

            result.Simd[i] = row;
        }

        return result;
    }

    /// Multiplies matrix by scalar
    pub fn mulScalar(a: Mat4, b: f32) Mat4 {
        return .{ .Simd = .{
            a.Simd[0] * @as(@Vector(4, f32), @splat(b)),
            a.Simd[1] * @as(@Vector(4, f32), @splat(b)),
            a.Simd[2] * @as(@Vector(4, f32), @splat(b)),
            a.Simd[3] * @as(@Vector(4, f32), @splat(b)),
        } };
    }

    /// Returns transposed matrix
    pub fn transpose(matrix: Mat4) Mat4 {
        var result: Mat4 = undefined;

        inline for (0..4) |i| {
            inline for (0..4) |j| {
                result.Simd[i][j] = matrix.Simd[j][i];
            }
        }

        return result;
    }

    /// Compares two matrices
    pub fn equals(a: Mat4, b: Mat4) bool {
        for (0..4) |i| {
            if (!@reduce(.And, a.Simd[i] == b.Simd[i])) {
                return false;
            }
        }

        return true;
    }

    /// Translates matrix by vector
    pub fn translate(matrix: Mat4, vec: Vec3) Mat4 {
        const translation: Mat4 = .{ .Simd = .{ .{ 1.0, 0.0, 0.0, vec.x() }, .{ 0.0, 1.0, 0.0, vec.y() }, .{ 0.0, 0.0, 1.0, vec.z() }, .{ 0.0, 0.0, 0.0, 1.0 } } };

        return mul(matrix, translation);
    }

    /// Rotates matrix by angle in radians over axis, leaving it untouched when the axis has no length
    pub fn rotate(matrix: Mat4, angle: f32, axis: Vec3) Mat4 {
        const axis_len = Vec3.length(axis);
        if (axis_len == 0.0) return matrix;

        const n = Vec3.div(axis, axis_len);

        const x = n.x();
        const y = n.y();
        const z = n.z();

        const c = @cos(angle);
        const s = @sin(angle);
        const t = 1.0 - c;

        const r: Mat4 = .{ .Simd = .{ .{ t * x * x + c, t * x * y - s * z, t * x * z + s * y, 0 }, .{ t * x * y + s * z, t * y * y + c, t * y * z - s * x, 0 }, .{ t * x * z - s * y, t * y * z + s * x, t * z * z + c, 0 }, .{ 0, 0, 0, 1 } } };

        return mul(matrix, r);
    }

    /// Scales matrix by vector
    pub fn scale(matrix: Mat4, vec: Vec3) Mat4 {
        const scaling: Mat4 = .{ .Simd = .{ .{ vec.x(), 0.0, 0.0, 0.0 }, .{ 0.0, vec.y(), 0.0, 0.0 }, .{ 0.0, 0.0, vec.z(), 0.0 }, .{ 0.0, 0.0, 0.0, 1.0 } } };

        return mul(matrix, scaling);
    }
};
