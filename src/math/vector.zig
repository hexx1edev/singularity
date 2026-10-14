const std = @import("std");
const sm = @import("scalar.zig");
const qm = @import("quaternion.zig");

pub const Vec2 = struct {
    Simd: @Vector(2, f32),

    /// Constructs 2D vector from axis
    pub fn fromAxis(vx: f32, vy: f32) Vec2 {
        return .{ .Simd = .{ vx, vy } };
    }

    /// Constructs 2D vector from scalar
    pub fn fromScalar(scalar: f32) Vec2 {
        return .{ .Simd = .{ scalar, scalar } };
    }

    /// Constructs 2D vector from array
    pub fn fromArray(array: [2]f32) Vec2 {
        return .{ .Simd = array };
    }

    /// Constructs 2D vector with all axis set to 0
    pub fn zero() Vec2 {
        return .{ .Simd = @splat(0.0) };
    }

    /// Constructs 2D vector with all axis set to 1
    pub fn one() Vec2 {
        return .{ .Simd = @splat(1.0) };
    }

    /// Returns vector X axis
    pub fn x(self: *const Vec2) f32 {
        return self.Simd[0];
    }

    /// Returns vector Y axis
    pub fn y(self: *const Vec2) f32 {
        return self.Simd[1];
    }

    /// Sets vector X axis
    pub fn setX(self: *Vec2, value: f32) void {
        self.Simd[0] = value;
    }

    /// Sets vector Y axis
    pub fn setY(self: *Vec2, value: f32) void {
        self.Simd[1] = value;
    }

    /// Returns vector as an array
    pub fn asArray(self: *const Vec2) [2]f32 {
        return self.Simd;
    }

    /// Returns vector absolute value
    pub fn abs(vec: Vec2) Vec2 {
        return fromArray(@abs(vec.Simd));
    }

    /// Returns the smaller value of each axis
    pub fn min(a: Vec2, b: Vec2) Vec2 {
        return fromArray(@min(a.Simd, b.Simd));
    }

    /// Returns the bigger value of each axis
    pub fn max(a: Vec2, b: Vec2) Vec2 {
        return fromArray(@max(a.Simd, b.Simd));
    }

    /// Adds two vectors
    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return fromArray(a.Simd + b.Simd);
    }

    /// Subtracts two vectors
    pub fn sub(a: Vec2, b: Vec2) Vec2 {
        return fromArray(a.Simd - b.Simd);
    }

    /// Multiplies vector by a number
    pub fn mul(a: Vec2, b: f32) Vec2 {
        return fromArray(a.Simd * @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Divides vector by a number
    pub fn div(a: Vec2, b: f32) Vec2 {
        return fromArray(a.Simd / @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Compares two vectors
    pub fn equals(a: Vec2, b: Vec2) bool {
        return @reduce(.And, a.Simd == b.Simd);
    }

    /// Calculates dot production of two vectors
    pub fn dot(a: Vec2, b: Vec2) f32 {
        return @reduce(.Add, a.Simd * b.Simd);
    }

    /// Calculates square length of vector
    pub fn lengthSq(vec: Vec2) f32 {
        return @reduce(.Add, vec.Simd * vec.Simd);
    }

    /// Calculates length of vector
    pub fn length(vec: Vec2) f32 {
        return @sqrt(lengthSq(vec));
    }

    /// Scales vector to length 1, returning a zero vector when it has no length
    pub fn normalize(vec: Vec2) Vec2 {
        const len = length(vec);
        if (len == 0.0) return zero();

        return div(vec, len);
    }

    /// Calculates angle between two vectors
    pub fn angle(a: Vec2, b: Vec2) f32 {
        const denominator = length(a) * length(b);
        if (denominator == 0.0) return 0.0;

        return std.math.acos(std.math.clamp(dot(a, b) / denominator, -1.0, 1.0));
    }

    /// Calculates distance between two vectors
    pub fn distance(a: Vec2, b: Vec2) f32 {
        const diff = a.Simd - b.Simd;
        return @sqrt(@reduce(.Add, diff * diff));
    }

    /// Linear interpolation
    pub fn lerp(a: Vec2, b: Vec2, t: f32) Vec2 {
        return fromAxis(std.math.lerp(a.x(), b.x(), t), std.math.lerp(a.y(), b.y(), t));
    }

    /// Linear interpolation with `t` clamped to [0, 1], so it never extrapolates
    pub fn lerpClamped(a: Vec2, b: Vec2, t: f32) Vec2 {
        return lerp(a, b, sm.saturate(t));
    }

    /// Linear interpolation eased by `smoothstep`, so it leaves `a` and reaches
    /// `b` with zero speed
    pub fn smoothstep(a: Vec2, b: Vec2, t: f32) Vec2 {
        return lerp(a, b, sm.smoothstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by `smootherstep`, which also has zero
    /// acceleration at both ends
    pub fn smootherstep(a: Vec2, b: Vec2, t: f32) Vec2 {
        return lerp(a, b, sm.smootherstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by a CSS style cubic bezier curve, where
    /// `x0, y0, x1, y1` are its two shape points
    pub fn cubicBezier(a: Vec2, b: Vec2, x0: f32, y0: f32, x1: f32, y1: f32, t: f32) Vec2 {
        return lerp(a, b, sm.cubicBezier(t, x0, y0, x1, y1));
    }

    /// Steps `current` toward `target` by at most `max_delta`, keeping direction
    pub fn moveTowards(current: Vec2, target: Vec2, max_delta: f32) Vec2 {
        const delta = sub(target, current);
        const dist = length(delta);
        if (dist <= max_delta or dist == 0.0) return target;
        return add(current, mul(delta, max_delta / dist));
    }

    /// Bilinear interpolation over a unit quad. Corners are named `c{x}{y}`
    pub fn bilinear(c00: Vec2, c10: Vec2, c01: Vec2, c11: Vec2, tx: f32, ty: f32) Vec2 {
        return lerp(lerp(c00, c10, tx), lerp(c01, c11, tx), ty);
    }

    /// Trilinear interpolation over a unit cube. Corners are named `c{x}{y}{z}`
    pub fn trilinear(
        c000: Vec2,
        c100: Vec2,
        c010: Vec2,
        c110: Vec2,
        c001: Vec2,
        c101: Vec2,
        c011: Vec2,
        c111: Vec2,
        tx: f32,
        ty: f32,
        tz: f32,
    ) Vec2 {
        const near = bilinear(c000, c100, c010, c110, tx, ty);
        const far = bilinear(c001, c101, c011, c111, tx, ty);
        return lerp(near, far, tz);
    }

    /// Cubic hermite spline segment from `p0` with tangent `m0` to `p1` with
    /// tangent `m1`
    pub fn cubicHermite(p0: Vec2, m0: Vec2, p1: Vec2, m1: Vec2, t: f32) Vec2 {
        const t2 = t * t;
        const t3 = t2 * t;

        const h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
        const h10 = t3 - 2.0 * t2 + t;
        const h01 = -2.0 * t3 + 3.0 * t2;
        const h11 = t3 - t2;

        return add(
            add(mul(p0, h00), mul(m0, h10)),
            add(mul(p1, h01), mul(m1, h11)),
        );
    }

    /// Catmull-Rom spline segment: passes through `p1` at t = 0 and `p2` at
    /// t = 1, using `p0` and `p3` only to derive the tangents
    pub fn catmullRom(p0: Vec2, p1: Vec2, p2: Vec2, p3: Vec2, t: f32) Vec2 {
        const t2 = t * t;
        const t3 = t2 * t;

        const w0 = 0.5 * (-t3 + 2.0 * t2 - t);
        const w1 = 0.5 * (3.0 * t3 - 5.0 * t2 + 2.0);
        const w2 = 0.5 * (-3.0 * t3 + 4.0 * t2 + t);
        const w3 = 0.5 * (t3 - t2);

        return add(
            add(mul(p0, w0), mul(p1, w1)),
            add(mul(p2, w2), mul(p3, w3)),
        );
    }

    /// Quadratic bezier curve over 3 control points
    pub fn quadBezier(p0: Vec2, p1: Vec2, p2: Vec2, t: f32) Vec2 {
        return lerp(lerp(p0, p1, t), lerp(p1, p2, t), t);
    }

    /// Cubic bezier curve over 4 control points, the 2D curve rather than the
    /// easing function. Use `cubicBezier` to ease between two vectors instead
    pub fn bezier(p0: Vec2, p1: Vec2, p2: Vec2, p3: Vec2, t: f32) Vec2 {
        return lerp(quadBezier(p0, p1, p2, t), quadBezier(p1, p2, p3, t), t);
    }
};

pub const Vec3 = struct {
    Simd: @Vector(3, f32),

    /// Constructs 3D vector from axis
    pub fn fromAxis(vx: f32, vy: f32, vz: f32) Vec3 {
        return .{ .Simd = .{ vx, vy, vz } };
    }

    /// Constructs 3D vector from scalar
    pub fn fromScalar(scalar: f32) Vec3 {
        return .{ .Simd = .{ scalar, scalar, scalar } };
    }

    /// Constructs 3D vector from array
    pub fn fromArray(array: [3]f32) Vec3 {
        return .{ .Simd = array };
    }

    /// Constructs 3D vector with all axis set to 0
    pub fn zero() Vec3 {
        return .{ .Simd = @splat(0.0) };
    }

    /// Constructs 3D vector with all axis set to 1
    pub fn one() Vec3 {
        return .{ .Simd = @splat(1.0) };
    }

    /// Returns vector X axis
    pub fn x(self: *const Vec3) f32 {
        return self.Simd[0];
    }

    /// Returns vector Y axis
    pub fn y(self: *const Vec3) f32 {
        return self.Simd[1];
    }

    /// Returns vector Z axis
    pub fn z(self: *const Vec3) f32 {
        return self.Simd[2];
    }

    /// Sets vector X axis
    pub fn setX(self: *Vec3, value: f32) void {
        self.Simd[0] = value;
    }

    /// Sets vector Y axis
    pub fn setY(self: *Vec3, value: f32) void {
        self.Simd[1] = value;
    }

    /// Sets vector Z axis
    pub fn setZ(self: *Vec3, value: f32) void {
        self.Simd[2] = value;
    }

    /// Returns vector as an array
    pub fn asArray(self: *const Vec3) [3]f32 {
        return self.Simd;
    }

    /// Returns vector absolute value
    pub fn abs(vec: Vec3) Vec3 {
        return fromArray(@abs(vec.Simd));
    }

    /// Returns the smaller value of each axis
    pub fn min(a: Vec3, b: Vec3) Vec3 {
        return fromArray(@min(a.Simd, b.Simd));
    }

    /// Returns the bigger value of each axis
    pub fn max(a: Vec3, b: Vec3) Vec3 {
        return fromArray(@max(a.Simd, b.Simd));
    }

    /// Adds two vectors
    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return fromArray(a.Simd + b.Simd);
    }

    /// Subtracts two vectors
    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return fromArray(a.Simd - b.Simd);
    }

    /// Multiplies vector by a number
    pub fn mul(a: Vec3, b: f32) Vec3 {
        return fromArray(a.Simd * @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Divides vector by a number
    pub fn div(a: Vec3, b: f32) Vec3 {
        return fromArray(a.Simd / @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Compares two vectors
    pub fn equals(a: Vec3, b: Vec3) bool {
        return @reduce(.And, a.Simd == b.Simd);
    }

    /// Calculates dot production of two vectors
    pub fn dot(a: Vec3, b: Vec3) f32 {
        return @reduce(.Add, a.Simd * b.Simd);
    }

    /// Calculates square length of vector
    pub fn lengthSq(vec: Vec3) f32 {
        return @reduce(.Add, vec.Simd * vec.Simd);
    }

    /// Calculates length of vector
    pub fn length(vec: Vec3) f32 {
        return @sqrt(lengthSq(vec));
    }

    /// Scales vector to length 1, returning a zero vector when it has no length
    pub fn normalize(vec: Vec3) Vec3 {
        const len = length(vec);
        if (len == 0.0) return zero();

        return div(vec, len);
    }

    /// Calculates angle between two vectors
    pub fn angle(a: Vec3, b: Vec3) f32 {
        const denominator = length(a) * length(b);
        if (denominator == 0.0) return 0.0;

        return std.math.acos(std.math.clamp(dot(a, b) / denominator, -1.0, 1.0));
    }

    /// Calculates distance between two vectors
    pub fn distance(a: Vec3, b: Vec3) f32 {
        const diff = a.Simd - b.Simd;
        return @sqrt(@reduce(.Add, diff * diff));
    }

    /// Rotates vector by quaternion, the `q * v * q'` sandwich product. The
    /// quaternion is normalized first, so a non-unit one still rotates without scaling
    pub fn rotate(vec: Vec3, quat: qm.Quaternion) Vec3 {
        const q = quat.normalize();

        const ux = q.x();
        const uy = q.y();
        const uz = q.z();
        const uw = q.w();

        const vx = vec.x();
        const vy = vec.y();
        const vz = vec.z();

        // t = (u X v) + w * v
        const tx = uy * vz - uz * vy + uw * vx;
        const ty = uz * vx - ux * vz + uw * vy;
        const tz = ux * vy - uy * vx + uw * vz;

        // v' = v + 2 * (u X t)
        return fromAxis(
            vx + 2.0 * (uy * tz - uz * ty),
            vy + 2.0 * (uz * tx - ux * tz),
            vz + 2.0 * (ux * ty - uy * tx),
        );
    }

    /// Linear interpolation
    pub fn lerp(a: Vec3, b: Vec3, t: f32) Vec3 {
        return fromAxis(
            std.math.lerp(a.x(), b.x(), t),
            std.math.lerp(a.y(), b.y(), t),
            std.math.lerp(a.z(), b.z(), t),
        );
    }

    /// Linear interpolation with `t` clamped to [0, 1], so it never extrapolates
    pub fn lerpClamped(a: Vec3, b: Vec3, t: f32) Vec3 {
        return lerp(a, b, sm.saturate(t));
    }

    /// Linear interpolation eased by `smoothstep`, so it leaves `a` and reaches
    /// `b` with zero speed
    pub fn smoothstep(a: Vec3, b: Vec3, t: f32) Vec3 {
        return lerp(a, b, sm.smoothstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by `smootherstep`, which also has zero
    /// acceleration at both ends
    pub fn smootherstep(a: Vec3, b: Vec3, t: f32) Vec3 {
        return lerp(a, b, sm.smootherstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by a CSS style cubic bezier curve, where
    /// `x0, y0, x1, y1` are its two shape points
    pub fn cubicBezier(a: Vec3, b: Vec3, x0: f32, y0: f32, x1: f32, y1: f32, t: f32) Vec3 {
        return lerp(a, b, sm.cubicBezier(t, x0, y0, x1, y1));
    }

    /// Steps `current` toward `target` by at most `max_delta`, keeping direction
    pub fn moveTowards(current: Vec3, target: Vec3, max_delta: f32) Vec3 {
        const delta = sub(target, current);
        const dist = length(delta);
        if (dist <= max_delta or dist == 0.0) return target;
        return add(current, mul(delta, max_delta / dist));
    }

    /// Bilinear interpolation over a unit quad. Corners are named `c{x}{y}`
    pub fn bilinear(c00: Vec3, c10: Vec3, c01: Vec3, c11: Vec3, tx: f32, ty: f32) Vec3 {
        return lerp(lerp(c00, c10, tx), lerp(c01, c11, tx), ty);
    }

    /// Trilinear interpolation over a unit cube. Corners are named `c{x}{y}{z}`
    pub fn trilinear(
        c000: Vec3,
        c100: Vec3,
        c010: Vec3,
        c110: Vec3,
        c001: Vec3,
        c101: Vec3,
        c011: Vec3,
        c111: Vec3,
        tx: f32,
        ty: f32,
        tz: f32,
    ) Vec3 {
        const near = bilinear(c000, c100, c010, c110, tx, ty);
        const far = bilinear(c001, c101, c011, c111, tx, ty);
        return lerp(near, far, tz);
    }

    /// Cubic hermite spline segment from `p0` with tangent `m0` to `p1` with
    /// tangent `m1`
    pub fn cubicHermite(p0: Vec3, m0: Vec3, p1: Vec3, m1: Vec3, t: f32) Vec3 {
        const t2 = t * t;
        const t3 = t2 * t;

        const h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
        const h10 = t3 - 2.0 * t2 + t;
        const h01 = -2.0 * t3 + 3.0 * t2;
        const h11 = t3 - t2;

        return add(
            add(mul(p0, h00), mul(m0, h10)),
            add(mul(p1, h01), mul(m1, h11)),
        );
    }

    /// Catmull-Rom spline segment: passes through `p1` at t = 0 and `p2` at
    /// t = 1, using `p0` and `p3` only to derive the tangents
    pub fn catmullRom(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, t: f32) Vec3 {
        const t2 = t * t;
        const t3 = t2 * t;

        const w0 = 0.5 * (-t3 + 2.0 * t2 - t);
        const w1 = 0.5 * (3.0 * t3 - 5.0 * t2 + 2.0);
        const w2 = 0.5 * (-3.0 * t3 + 4.0 * t2 + t);
        const w3 = 0.5 * (t3 - t2);

        return add(
            add(mul(p0, w0), mul(p1, w1)),
            add(mul(p2, w2), mul(p3, w3)),
        );
    }

    /// Quadratic bezier curve over 3 control points
    pub fn quadBezier(p0: Vec3, p1: Vec3, p2: Vec3, t: f32) Vec3 {
        return lerp(lerp(p0, p1, t), lerp(p1, p2, t), t);
    }

    /// Cubic bezier curve over 4 control points, the 2D curve rather than the
    /// easing function. Use `cubicBezier` to ease between two vectors instead
    pub fn bezier(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, t: f32) Vec3 {
        return lerp(quadBezier(p0, p1, p2, t), quadBezier(p1, p2, p3, t), t);
    }
};

pub const Vec4 = struct {
    Simd: @Vector(4, f32),

    /// Constructs 4D vector from axis
    pub fn fromAxis(vx: f32, vy: f32, vz: f32, vw: f32) Vec4 {
        return .{ .Simd = .{ vx, vy, vz, vw } };
    }

    /// Constructs 4D vector from scalar
    pub fn fromScalar(scalar: f32) Vec4 {
        return .{ .Simd = .{ scalar, scalar, scalar, scalar } };
    }

    /// Constructs 4D vector from array
    pub fn fromArray(array: [4]f32) Vec4 {
        return .{ .Simd = array };
    }

    /// Constructs 4D vector with all axis set to 0
    pub fn zero() Vec4 {
        return .{ .Simd = @splat(0.0) };
    }

    /// Constructs 4D vector with all axis set to 1
    pub fn one() Vec4 {
        return .{ .Simd = @splat(1.0) };
    }

    /// Returns vector X axis
    pub fn x(self: *const Vec4) f32 {
        return self.Simd[0];
    }

    /// Returns vector Y axis
    pub fn y(self: *const Vec4) f32 {
        return self.Simd[1];
    }

    /// Returns vector Z axis
    pub fn z(self: *const Vec4) f32 {
        return self.Simd[2];
    }

    /// Returns vector W axis
    pub fn w(self: *const Vec4) f32 {
        return self.Simd[3];
    }

    /// Sets vector X axis
    pub fn setX(self: *Vec4, value: f32) void {
        self.Simd[0] = value;
    }

    /// Sets vector Y axis
    pub fn setY(self: *Vec4, value: f32) void {
        self.Simd[1] = value;
    }

    /// Sets vector Z axis
    pub fn setZ(self: *Vec4, value: f32) void {
        self.Simd[2] = value;
    }

    /// Sets vector W axis
    pub fn setW(self: *Vec4, value: f32) void {
        self.Simd[3] = value;
    }

    /// Returns vector as an array
    pub fn asArray(self: *const Vec4) [4]f32 {
        return self.Simd;
    }

    /// Returns vector absolute value
    pub fn abs(vec: Vec4) Vec4 {
        return fromArray(@abs(vec.Simd));
    }

    /// Returns the smaller value of each axis
    pub fn min(a: Vec4, b: Vec4) Vec4 {
        return fromArray(@min(a.Simd, b.Simd));
    }

    /// Returns the bigger value of each axis
    pub fn max(a: Vec4, b: Vec4) Vec4 {
        return fromArray(@max(a.Simd, b.Simd));
    }

    /// Adds two vectors
    pub fn add(a: Vec4, b: Vec4) Vec4 {
        return fromArray(a.Simd + b.Simd);
    }

    /// Subtracts two vectors
    pub fn sub(a: Vec4, b: Vec4) Vec4 {
        return fromArray(a.Simd - b.Simd);
    }

    /// Multiplies vector by a number
    pub fn mul(a: Vec4, b: f32) Vec4 {
        return fromArray(a.Simd * @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Divides vector by a number
    pub fn div(a: Vec4, b: f32) Vec4 {
        return fromArray(a.Simd / @as(@TypeOf(a.Simd), @splat(b)));
    }

    /// Compares two vectors
    pub fn equals(a: Vec4, b: Vec4) bool {
        return @reduce(.And, a.Simd == b.Simd);
    }

    /// Calculates dot production of two vectors
    pub fn dot(a: Vec4, b: Vec4) f32 {
        return @reduce(.Add, a.Simd * b.Simd);
    }

    /// Calculates square length of vector
    pub fn lengthSq(vec: Vec4) f32 {
        return @reduce(.Add, vec.Simd * vec.Simd);
    }

    /// Calculates length of vector
    pub fn length(vec: Vec4) f32 {
        return @sqrt(lengthSq(vec));
    }

    /// Scales vector to length 1, returning a zero vector when it has no length
    pub fn normalize(vec: Vec4) Vec4 {
        const len = length(vec);
        if (len == 0.0) return zero();

        return div(vec, len);
    }

    /// Calculates angle between two vectors
    pub fn angle(a: Vec4, b: Vec4) f32 {
        const denominator = length(a) * length(b);
        if (denominator == 0.0) return 0.0;

        return std.math.acos(std.math.clamp(dot(a, b) / denominator, -1.0, 1.0));
    }

    /// Calculates distance between two vectors
    pub fn distance(a: Vec4, b: Vec4) f32 {
        const diff = a.Simd - b.Simd;
        return @sqrt(@reduce(.Add, diff * diff));
    }

    /// Rotates the XYZ part of the vector by quaternion, leaving W untouched
    pub fn rotate(vec: Vec4, quat: qm.Quaternion) Vec4 {
        const rotated = Vec3.rotate(Vec3.fromAxis(vec.x(), vec.y(), vec.z()), quat);

        return fromAxis(rotated.x(), rotated.y(), rotated.z(), vec.w());
    }

    /// Linear interpolation
    pub fn lerp(a: Vec4, b: Vec4, t: f32) Vec4 {
        return fromAxis(
            std.math.lerp(a.x(), b.x(), t),
            std.math.lerp(a.y(), b.y(), t),
            std.math.lerp(a.z(), b.z(), t),
            std.math.lerp(a.w(), b.w(), t),
        );
    }

    /// Linear interpolation with `t` clamped to [0, 1], so it never extrapolates
    pub fn lerpClamped(a: Vec4, b: Vec4, t: f32) Vec4 {
        return lerp(a, b, sm.saturate(t));
    }

    /// Linear interpolation eased by `smoothstep`, so it leaves `a` and reaches
    /// `b` with zero speed
    pub fn smoothstep(a: Vec4, b: Vec4, t: f32) Vec4 {
        return lerp(a, b, sm.smoothstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by `smootherstep`, which also has zero
    /// acceleration at both ends
    pub fn smootherstep(a: Vec4, b: Vec4, t: f32) Vec4 {
        return lerp(a, b, sm.smootherstep(0.0, 1.0, t));
    }

    /// Linear interpolation eased by a CSS style cubic bezier curve, where
    /// `x0, y0, x1, y1` are its two shape points
    pub fn cubicBezier(a: Vec4, b: Vec4, x0: f32, y0: f32, x1: f32, y1: f32, t: f32) Vec4 {
        return lerp(a, b, sm.cubicBezier(t, x0, y0, x1, y1));
    }

    /// Steps `current` toward `target` by at most `max_delta`, keeping direction
    pub fn moveTowards(current: Vec4, target: Vec4, max_delta: f32) Vec4 {
        const delta = sub(target, current);
        const dist = length(delta);
        if (dist <= max_delta or dist == 0.0) return target;
        return add(current, mul(delta, max_delta / dist));
    }

    /// Bilinear interpolation over a unit quad. Corners are named `c{x}{y}`
    pub fn bilinear(c00: Vec4, c10: Vec4, c01: Vec4, c11: Vec4, tx: f32, ty: f32) Vec4 {
        return lerp(lerp(c00, c10, tx), lerp(c01, c11, tx), ty);
    }

    /// Trilinear interpolation over a unit cube. Corners are named `c{x}{y}{z}`
    pub fn trilinear(
        c000: Vec4,
        c100: Vec4,
        c010: Vec4,
        c110: Vec4,
        c001: Vec4,
        c101: Vec4,
        c011: Vec4,
        c111: Vec4,
        tx: f32,
        ty: f32,
        tz: f32,
    ) Vec4 {
        const near = bilinear(c000, c100, c010, c110, tx, ty);
        const far = bilinear(c001, c101, c011, c111, tx, ty);
        return lerp(near, far, tz);
    }

    /// Cubic hermite spline segment from `p0` with tangent `m0` to `p1` with
    /// tangent `m1`
    pub fn cubicHermite(p0: Vec4, m0: Vec4, p1: Vec4, m1: Vec4, t: f32) Vec4 {
        const t2 = t * t;
        const t3 = t2 * t;

        const h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
        const h10 = t3 - 2.0 * t2 + t;
        const h01 = -2.0 * t3 + 3.0 * t2;
        const h11 = t3 - t2;

        return add(
            add(mul(p0, h00), mul(m0, h10)),
            add(mul(p1, h01), mul(m1, h11)),
        );
    }

    /// Catmull-Rom spline segment: passes through `p1` at t = 0 and `p2` at
    /// t = 1, using `p0` and `p3` only to derive the tangents
    pub fn catmullRom(p0: Vec4, p1: Vec4, p2: Vec4, p3: Vec4, t: f32) Vec4 {
        const t2 = t * t;
        const t3 = t2 * t;

        const w0 = 0.5 * (-t3 + 2.0 * t2 - t);
        const w1 = 0.5 * (3.0 * t3 - 5.0 * t2 + 2.0);
        const w2 = 0.5 * (-3.0 * t3 + 4.0 * t2 + t);
        const w3 = 0.5 * (t3 - t2);

        return add(
            add(mul(p0, w0), mul(p1, w1)),
            add(mul(p2, w2), mul(p3, w3)),
        );
    }

    /// Quadratic bezier curve over 3 control points
    pub fn quadBezier(p0: Vec4, p1: Vec4, p2: Vec4, t: f32) Vec4 {
        return lerp(lerp(p0, p1, t), lerp(p1, p2, t), t);
    }

    /// Cubic bezier curve over 4 control points, the 2D curve rather than the
    /// easing function. Use `cubicBezier` to ease between two vectors instead
    pub fn bezier(p0: Vec4, p1: Vec4, p2: Vec4, p3: Vec4, t: f32) Vec4 {
        return lerp(quadBezier(p0, p1, p2, t), quadBezier(p1, p2, p3, t), t);
    }
};
