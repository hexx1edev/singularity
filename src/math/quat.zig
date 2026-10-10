//! Quaternions, backed by zmath. A quaternion is the same 4 wide vector with
//! the rotation axis in X, Y, Z and the scalar part in W.
//!
//! Composition follows the same rule as `matrix.mul`: `mul(a, b)` applies `b`
//! first, then `a`.

const zm = @import("zmath");
const vec = @import("vec.zig");
const mat = @import("mat.zig");

pub const Quat = zm.Quat;

/// Returns the rotation that does nothing
pub inline fn identity() Quat {
    return zm.f32x4(0, 0, 0, 1);
}

/// Constructs a rotation counter-clockwise around `axis` by `radians`
pub inline fn fromAxisAngle(axis: vec.Vec3, radians: f32) Quat {
    return zm.quatFromAxisAngle(axis, radians);
}

/// Constructs a rotation from roll, pitch and yaw, applied in that order
pub inline fn fromRollPitchYaw(roll: f32, pitch: f32, yaw: f32) Quat {
    return zm.quatFromRollPitchYaw(pitch, yaw, roll);
}

/// Constructs a rotation from a matrix
pub inline fn fromMat(m: mat.Mat4) Quat {
    return zm.quatFromMat(m);
}

/// Combines 2 rotations. `mul(a, b)` applies `b` first, then `a`
pub inline fn mul(a: Quat, b: Quat) Quat {
    // Flipped, to match the composition order used by `matrix.mul`.
    return zm.qmul(b, a);
}

/// Scales a rotation to unit length, which it must have to be a rotation
pub const normalize = zm.normalize4;

/// Returns the opposite rotation
pub inline fn inverse(q: Quat) Quat {
    return zm.inverse(q);
}

/// Interpolates between 2 rotations along the shortest arc
pub const slerp = zm.slerp;

/// Returns the rotation as a matrix
pub inline fn toMat(q: Quat) mat.Mat4 {
    return zm.quatToMat(q);
}

/// Writes the rotation out as an axis and an angle in radians
pub inline fn toAxisAngle(q: Quat, axis: *vec.Vec3, radians: *f32) void {
    zm.quatToAxisAngle(q, axis, radians);
}

/// Rotates a 3D vector by the rotation
pub inline fn rotateVec(q: Quat, v: vec.Vec3) vec.Vec3 {
    return zm.rotate(q, v);
}

/// Checks for equality with `tolerance`
pub const approxEql = zm.approxEqAbs;
