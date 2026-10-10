//! Matrices, backed by zmath. zmath only has one 4x4 matrix type, so `Mat3` is
//! an alias of it and the name only says that just the upper left 3x3 block is
//! meant to be used; `asArray3` repacks that block for the GPU.
//!
//! The convention here is ours, not zmath's: a matrix transforms a column
//! vector, written `M * v`, and `mul(a, b)` applies `b` first. zmath stores its
//! matrices as rows, which is the transpose of that, so these two cancel out
//! exactly: the raw zmath layout is already the column-major layout OpenGL
//! wants, and `asArray3`/`asArray4` upload with `transpose` set to false. In a
//! shader the usual `uMvp * vec4(vPos, 1.0)` is correct.

const zm = @import("zmath");
const vec = @import("vec.zig");

const Vec3 = vec.Vec3;
const Vec4 = vec.Vec4;

pub const Mat3 = zm.Mat;
pub const Mat4 = zm.Mat;

/// Returns identity matrix
pub const identity = zm.identity;

/// Returns zero matrix
pub inline fn zero() Mat4 {
    const z = zm.f32x4s(0);
    return .{ z, z, z, z };
}

/// Constructs a matrix that moves by `offset`
pub inline fn fromTranslation(offset: Vec3) Mat4 {
    return zm.translationV(offset);
}

/// Constructs a matrix that scales by `factors`
pub inline fn fromScale(factors: Vec3) Mat4 {
    return zm.scalingV(factors);
}

/// Constructs a matrix that rotates counter-clockwise around +x by `radians`
pub inline fn fromRotationX(radians: f32) Mat4 {
    return zm.rotationX(radians);
}

/// Constructs a matrix that rotates counter-clockwise around +y by `radians`
pub inline fn fromRotationY(radians: f32) Mat4 {
    return zm.rotationY(radians);
}

/// Constructs a matrix that rotates counter-clockwise around +z by `radians`
pub inline fn fromRotationZ(radians: f32) Mat4 {
    return zm.rotationZ(radians);
}

/// Constructs a matrix that rotates counter-clockwise around `axis`
pub inline fn fromAxisAngle(axis: Vec3, radians: f32) Mat4 {
    return zm.matFromAxisAngle(axis, radians);
}

/// Constructs a matrix from a quaternion
pub inline fn fromQuat(quat: zm.Quat) Mat4 {
    return zm.matFromQuat(quat);
}

/// Constructs a matrix from roll, pitch and yaw, applied in that order
pub inline fn fromRollPitchYaw(roll: f32, pitch: f32, yaw: f32) Mat4 {
    return zm.matFromRollPitchYaw(pitch, yaw, roll);
}

/// Returns a right-handed perspective projection mapping depth to [-1, 1],
/// looking down -z. `fov_y` is the vertical field of view in radians
pub inline fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Mat4 {
    return zm.perspectiveFovRhGl(fov_y, aspect, near, far);
}

/// Returns a right-handed orthographic projection mapping depth to [-1, 1],
/// looking down -z
pub inline fn orthographic(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Mat4 {
    return zm.orthographicOffCenterRhGl(left, right, top, bottom, near, far);
}

/// Returns a right-handed view matrix placing `eye` at the origin looking at
/// `target`, with `up` deciding which way is up
pub inline fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
    return zm.lookAtRh(eye, target, up);
}

/// Returns the element in row `r`, column `c`
pub inline fn at(m: Mat4, r: usize, c: usize) f32 {
    return m[c][r];
}

/// Returns column `index`
pub inline fn col(m: Mat4, index: usize) Vec4 {
    return m[index];
}

/// Returns row `index`
pub inline fn row(m: Mat4, index: usize) Vec4 {
    return zm.f32x4(m[0][index], m[1][index], m[2][index], m[3][index]);
}

/// Returns the upper left 3x3 block as a column-major array, ready to upload to
/// a `mat3` uniform
pub inline fn asArray3(m: Mat3) [9]f32 {
    return .{
        m[0][0], m[0][1], m[0][2],
        m[1][0], m[1][1], m[1][2],
        m[2][0], m[2][1], m[2][2],
    };
}

/// Returns a matrix as a column-major array, ready to upload to a `mat4` uniform
pub inline fn asArray4(m: Mat4) [16]f32 {
    return .{
        m[0][0], m[0][1], m[0][2], m[0][3],
        m[1][0], m[1][1], m[1][2], m[1][3],
        m[2][0], m[2][1], m[2][2], m[2][3],
        m[3][0], m[3][1], m[3][2], m[3][3],
    };
}

/// Adds 2 matrices
pub inline fn add(a: Mat4, b: Mat4) Mat4 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3] };
}

/// Subtracts 2 matrices
pub inline fn sub(a: Mat4, b: Mat4) Mat4 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2], a[3] - b[3] };
}

/// Scales every element by a scalar
pub inline fn mulScalar(m: Mat4, scalar: f32) Mat4 {
    const s = zm.f32x4s(scalar);
    return .{ m[0] * s, m[1] * s, m[2] * s, m[3] * s };
}

/// Negates matrix
pub inline fn neg(m: Mat4) Mat4 {
    return .{ -m[0], -m[1], -m[2], -m[3] };
}

/// Multiplies 2 matrices. `mul(a, b)` applies `b` first, then `a`
pub inline fn mul(a: Mat4, b: Mat4) Mat4 {
    // Flipped, because zmath composes for row vectors and we compose for column ones.
    return zm.mul(b, a);
}

/// Transforms a vector by the matrix
pub inline fn mulVec(m: Mat4, v: Vec4) Vec4 {
    return zm.mul(v, m);
}

/// Transforms a position, so translation applies. Assumes an affine matrix,
/// use `projectPoint` when the matrix is a projection
pub inline fn transformPoint(m: Mat4, point: Vec3) Vec3 {
    return zm.mul(zm.f32x4(point[0], point[1], point[2], 1), m);
}

/// Transforms a direction, so translation is ignored
pub inline fn transformDirection(m: Mat4, direction: Vec3) Vec3 {
    return zm.mul(zm.f32x4(direction[0], direction[1], direction[2], 0), m);
}

/// Transforms a position and divides by w, giving normalized device
/// coordinates for a projection matrix
pub inline fn projectPoint(m: Mat4, point: Vec3) Vec3 {
    const clip = zm.mul(zm.f32x4(point[0], point[1], point[2], 1), m);
    if (clip[3] == 0) return clip;
    return clip / zm.f32x4s(clip[3]);
}

/// Flips matrix over its diagonal
pub const transpose = zm.transpose;

/// Sums the diagonal
pub inline fn trace(m: Mat4) f32 {
    return m[0][0] + m[1][1] + m[2][2] + m[3][3];
}

/// Returns matrix determinant, the factor by which it scales volumes
pub inline fn determinant(m: Mat4) f32 {
    return zm.determinant(m)[0];
}

/// Returns the inverse matrix, or null when the matrix is singular
pub inline fn inverse(m: Mat4) ?Mat4 {
    var det: zm.F32x4 = undefined;
    const inv = zm.inverseDet(m, &det);
    if (det[0] == 0) return null;
    return inv;
}

/// Returns the matrix for transforming normals, the inverse transpose,
/// or null when the matrix is singular
pub inline fn normalMatrix(m: Mat4) ?Mat3 {
    const inv = inverse(m) orelse return null;
    return zm.transpose(inv);
}

/// Checks for exact equality
pub inline fn eql(a: Mat4, b: Mat4) bool {
    return vec.eql(a[0], b[0]) and vec.eql(a[1], b[1]) and
        vec.eql(a[2], b[2]) and vec.eql(a[3], b[3]);
}

/// Checks for equality with `tolerance`
pub inline fn approxEql(a: Mat4, b: Mat4, tolerance: f32) bool {
    return zm.approxEqAbs(a[0], b[0], tolerance) and
        zm.approxEqAbs(a[1], b[1], tolerance) and
        zm.approxEqAbs(a[2], b[2], tolerance) and
        zm.approxEqAbs(a[3], b[3], tolerance);
}
