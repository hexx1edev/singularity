//! Vectors, backed by zmath. Every vector is the same 4 wide SIMD register, so
//! `Vec2`, `Vec3` and `Vec4` are aliases of one type and the name only says how
//! many components the surrounding code means to use. Operations that depend on
//! that count carry it in their name, like `dot3` or `length2`.
//!
//! These are plain `@Vector` values, so `a + b`, `a - b`, `a * b` and `a / b`
//! work directly and there are no wrappers for them here.

const zm = @import("zmath");
const std = @import("std");

/// 4 wide SIMD vector, the type every vector alias resolves to
pub const Simd = zm.F32x4;

pub const Vec2 = zm.Vec;
pub const Vec3 = zm.Vec;
pub const Vec4 = zm.Vec;

/// Constructs a vector, leaving Z and W at zero
pub inline fn vec2(xv: f32, yv: f32) Vec2 {
    return zm.f32x4(xv, yv, 0, 0);
}

/// Constructs a vector, leaving W at zero, which marks it as a direction
pub inline fn vec3(xv: f32, yv: f32, zv: f32) Vec3 {
    return zm.f32x4(xv, yv, zv, 0);
}

/// Constructs a vector
pub inline fn vec4(xv: f32, yv: f32, zv: f32, wv: f32) Vec4 {
    return zm.f32x4(xv, yv, zv, wv);
}

/// Constructs a position, with W at one so that translation applies to it
pub inline fn point3(xv: f32, yv: f32, zv: f32) Vec4 {
    return zm.f32x4(xv, yv, zv, 1);
}

/// Constructs a vector with every component set to `scalar`
pub inline fn fromScalar(scalar: f32) Vec4 {
    return zm.f32x4s(scalar);
}

/// Constructs a vector from an array
pub inline fn fromArray(array: [4]f32) Vec4 {
    return zm.f32x4(array[0], array[1], array[2], array[3]);
}

/// Returns zero vector
pub inline fn zero() Vec4 {
    return zm.f32x4s(0);
}

/// Returns 1 vector
pub inline fn one() Vec4 {
    return zm.f32x4s(1);
}

/// Returns vector with X: 1 and the rest zero
pub inline fn unitX() Vec4 {
    return zm.f32x4(1, 0, 0, 0);
}

/// Returns vector with Y: 1 and the rest zero
pub inline fn unitY() Vec4 {
    return zm.f32x4(0, 1, 0, 0);
}

/// Returns vector with Z: 1 and the rest zero
pub inline fn unitZ() Vec4 {
    return zm.f32x4(0, 0, 1, 0);
}

/// Returns vector with W: 1 and the rest zero
pub inline fn unitW() Vec4 {
    return zm.f32x4(0, 0, 0, 1);
}

/// Returns vector X component
pub inline fn x(v: Vec4) f32 {
    return v[0];
}

/// Returns vector Y component
pub inline fn y(v: Vec4) f32 {
    return v[1];
}

/// Returns vector Z component
pub inline fn z(v: Vec4) f32 {
    return v[2];
}

/// Returns vector W component
pub inline fn w(v: Vec4) f32 {
    return v[3];
}

/// Returns the first 2 components as an array, ready to upload to the GPU
pub inline fn asArray2(v: Vec2) [2]f32 {
    return .{ v[0], v[1] };
}

/// Returns the first 3 components as an array, ready to upload to the GPU
pub inline fn asArray3(v: Vec3) [3]f32 {
    return .{ v[0], v[1], v[2] };
}

/// Returns a vector as an array, ready to upload to the GPU
pub inline fn asArray4(v: Vec4) [4]f32 {
    return .{ v[0], v[1], v[2], v[3] };
}

/// Scales vector by a scalar
pub inline fn scale(v: Vec4, scalar: f32) Vec4 {
    return v * zm.f32x4s(scalar);
}

/// Negates vector
pub inline fn neg(v: Vec4) Vec4 {
    return -v;
}

/// Returns an absolute vector
pub const abs = zm.abs;

/// Floors vector
pub const floor = zm.floor;

/// Ceils vector
pub const ceil = zm.ceil;

/// Rounds vector. zmath rounds halves to even, so 0.5 rounds down to 0,
/// unlike Zig's `@round` which rounds halves away from zero
pub const round = zm.round;

/// Rounds vector to zero
pub const trunc = zm.trunc;

/// Square root of every component
pub const sqrt = zm.sqrt;

/// Returns smaller vectors out of `a` and `b`
pub const min = zm.min;

/// Returns bigger vectors out of `a` and `b`
pub const max = zm.max;

/// Clamps vector between `lower` and `upper`
pub const clamp = zm.clamp;

/// Clamps every component to [0, 1]
pub const saturate = zm.saturate;

/// Remainder of every component
pub const mod = zm.mod;

/// Vector linear interpolation
pub const lerp = zm.lerp;

/// Vector linear interpolation, with `t` per component
pub const lerpV = zm.lerpV;

/// Reorders components, as in `swizzle(v, .z, .y, .x, .w)`
pub const swizzle = zm.swizzle;

/// Dot production out of two 2D vectors
pub inline fn dot2(a: Vec2, b: Vec2) f32 {
    return zm.dot2(a, b)[0];
}

/// Dot production out of two 3D vectors
pub inline fn dot3(a: Vec3, b: Vec3) f32 {
    return zm.dot3(a, b)[0];
}

/// Dot production out of two 4D vectors
pub inline fn dot4(a: Vec4, b: Vec4) f32 {
    return zm.dot4(a, b)[0];
}

/// Cross product, a vector perpendicular to both `a` and `b`, right-handed
pub const cross3 = zm.cross3;

/// Returns squared 2D length, skipping the square root
pub inline fn lengthSq2(v: Vec2) f32 {
    return zm.lengthSq2(v)[0];
}

/// Returns squared 3D length, skipping the square root
pub inline fn lengthSq3(v: Vec3) f32 {
    return zm.lengthSq3(v)[0];
}

/// Returns squared 4D length, skipping the square root
pub inline fn lengthSq4(v: Vec4) f32 {
    return zm.lengthSq4(v)[0];
}

/// Returns 2D length
pub inline fn length2(v: Vec2) f32 {
    return zm.length2(v)[0];
}

/// Returns 3D length
pub inline fn length3(v: Vec3) f32 {
    return zm.length3(v)[0];
}

/// Returns 4D length
pub inline fn length4(v: Vec4) f32 {
    return zm.length4(v)[0];
}

/// Scales a 2D vector to unit length, giving inf/NaN for a zero vector
pub const normalize2 = zm.normalize2;

/// Scales a 3D vector to unit length, giving inf/NaN for a zero vector
pub const normalize3 = zm.normalize3;

/// Scales a 4D vector to unit length, giving inf/NaN for a zero vector
pub const normalize4 = zm.normalize4;

/// Scales a 3D vector to unit length, returning zero vector when it has no length
pub inline fn normalize3OrZero(v: Vec3) Vec3 {
    const len_sq = lengthSq3(v);
    if (len_sq == 0) return zero();
    return v * zm.f32x4s(1.0 / @sqrt(len_sq));
}

/// Returns 2D distance between `a` and `b`
pub inline fn distance2(a: Vec2, b: Vec2) f32 {
    return length2(b - a);
}

/// Returns 3D distance between `a` and `b`
pub inline fn distance3(a: Vec3, b: Vec3) f32 {
    return length3(b - a);
}

/// Reflects a 3D vector around `normal`, which must be normalized
pub inline fn reflect3(v: Vec3, normal: Vec3) Vec3 {
    return v - normal * zm.f32x4s(2 * dot3(v, normal));
}

/// Returns the part of a 3D `v` that lies along `other`
pub inline fn project3(v: Vec3, other: Vec3) Vec3 {
    const len_sq = lengthSq3(other);
    if (len_sq == 0) return zero();
    return other * zm.f32x4s(dot3(v, other) / len_sq);
}

/// Returns unsigned angle between two 3D directions, in [0, pi]
pub inline fn angleBetween3(a: Vec3, b: Vec3) f32 {
    const denom = @sqrt(lengthSq3(a) * lengthSq3(b));
    if (denom == 0) return 0;
    return std.math.acos(std.math.clamp(dot3(a, b) / denom, -1, 1));
}

/// Rotates a 3D vector counter-clockwise around `axis`, which must be normalized
pub inline fn rotateAroundAxis3(v: Vec3, axis: Vec3, radians: f32) Vec3 {
    const c = @cos(radians);
    const s = @sin(radians);
    const along = axis * zm.f32x4s(dot3(v, axis) * (1 - c));
    return v * zm.f32x4s(c) + cross3(axis, v) * zm.f32x4s(s) + along;
}

/// Checks for exact equality across all 4 components
pub inline fn eql(a: Vec4, b: Vec4) bool {
    return @reduce(.And, a == b);
}

/// Checks for equality with `tolerance`
pub const approxEql = zm.approxEqAbs;
