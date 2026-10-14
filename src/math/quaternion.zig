const vm = @import("vector.zig");
const mm = @import("matrix.zig");
const math = @import("std").math;

pub const Quaternion = struct {
    Simd: @Vector(4, f32),

    /// Constructs quaternion from W and XYZ axis
    pub fn new(qw: f32, qx: f32, qy: f32, qz: f32) Quaternion {
        return .{ .Simd = .{ qw, qx, qy, qz } };
    }

    /// Constructs an identity quaternion(no rotation)
    pub fn identity() Quaternion {
        return .{ .Simd = .{ 1.0, 0.0, 0.0, 0.0 } };
    }

    /// Constructs quaternion, rotated by angle on axis
    pub fn fromAngle(angle: f32, axis: vm.Vec3) Quaternion {
        const h = angle / 2.0;
        const a = axis.normalize();
        const s = @sin(h);

        return .{ .Simd = .{
            @cos(h),
            a.x() * s,
            a.y() * s,
            a.z() * s,
        } };
    }

    /// Constructs quaternion from array
    pub fn fromArray(array: [4]f32) Quaternion {
        return .{ .Simd = array };
    }

    /// Returns W scalar
    pub fn w(self: *const Quaternion) f32 {
        return self.Simd[0];
    }

    /// Returns X axis
    pub fn x(self: *const Quaternion) f32 {
        return self.Simd[1];
    }

    /// Returns Y axis
    pub fn y(self: *const Quaternion) f32 {
        return self.Simd[2];
    }

    /// Returns Z axis
    pub fn z(self: *const Quaternion) f32 {
        return self.Simd[3];
    }

    /// Constructs 4x4 rotation matrix from quaternion
    pub fn asMatrix(self: *const Quaternion) mm.Mat4 {
        const q = self.normalize();

        const qw = q.w();
        const qx = q.x();
        const qy = q.y();
        const qz = q.z();

        return .{
            .Simd = .{
                .{ 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qw * qz), 2 * (qx * qz + qw * qy), 0 },
                .{ 2 * (qx * qy + qw * qz), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qw * qx), 0 },
                .{ 2 * (qx * qz - qw * qy), 2 * (qy * qz + qw * qx), 1 - 2 * (qx * qx + qy * qy), 0 },
                .{ 0, 0, 0, 1 },
            },
        };
    }

    /// Calculates square of length of quaternion
    pub fn lengthSq(quat: Quaternion) f32 {
        return @reduce(.Add, quat.Simd * quat.Simd);
    }

    /// Calculates length of quaternion
    pub fn length(quat: Quaternion) f32 {
        return @sqrt(lengthSq(quat));
    }

    /// Returns normalized quaternion
    pub fn normalize(quat: Quaternion) Quaternion {
        const len = length(quat);

        if (len == 0.0) return identity();

        return .{ .Simd = quat.Simd / @as(@Vector(4, f32), @splat(len)) };
    }

    /// Conjugates quaternion(invers XYZ values)
    pub fn conjugate(quat: Quaternion) Quaternion {
        // SIMD-optimized :)
        const signs: @Vector(4, f32) = .{
            1.0, -1.0, -1.0, -1.0,
        };

        return .{
            .Simd = quat.Simd * signs,
        };
    }

    /// Inverts quaternion
    pub fn inverse(quat: Quaternion) Quaternion {
        const sq = lengthSq(quat);

        if (sq == 0.0) return identity();

        const inv_sq = 1.0 / sq;

        return .{ .Simd = conjugate(quat).Simd * @as(@Vector(4, f32), @splat(inv_sq)) };
    }

    /// Multiplies quaternions
    pub fn mul(a: Quaternion, b: Quaternion) Quaternion {
        const aw = a.Simd[0];
        const ax = a.Simd[1];
        const ay = a.Simd[2];
        const az = a.Simd[3];

        const bw = b.Simd[0];
        const bx = b.Simd[1];
        const by = b.Simd[2];
        const bz = b.Simd[3];

        return new(
            aw * bw - ax * bx - ay * by - az * bz,
            aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
        );
    }

    /// Spherical linear interpolation
    pub fn slerp(a: Quaternion, b: Quaternion, t: f32) Quaternion {
        const qa = a.normalize();
        var qb = b.normalize();

        var dot = @reduce(.Add, qa.Simd * qb.Simd);

        // Closest path
        if (dot < 0.0) {
            qb.Simd = -qb.Simd;
            dot = -dot;
        }

        // Round error protection
        dot = @min(dot, 1.0);

        // Use lerp for close rotations
        if (dot > 0.9995) {
            const tv: @Vector(4, f32) = @splat(t);

            return .{
                .Simd = (qa.Simd * (@as(@Vector(4, f32), @splat(1.0)) - tv) + qb.Simd * tv),
            }.normalize();
        }

        const theta = math.acos(dot);
        const sin_theta = @sin(theta);

        const wa = @sin((1.0 - t) * theta) / sin_theta;
        const wb = @sin(t * theta) / sin_theta;

        return .{
            .Simd = qa.Simd * @as(@Vector(4, f32), @splat(wa)) + qb.Simd * @as(@Vector(4, f32), @splat(wb)),
        }.normalize();
    }
};
