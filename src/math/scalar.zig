//! Scalar helpers. zmath is vector-first: its `lerp`, `clamp` and `saturate`
//! take SIMD vectors, not plain floats, and it has no scalar interpolation at
//! all, so none of this has a zmath equivalent to delegate to.

const std = @import("std");

pub const pi = std.math.pi;
pub const tau = std.math.tau;

/// Converts degrees to radians
pub inline fn toRadians(degrees: f32) f32 {
    return degrees * (pi / 180.0);
}

/// Converts radians to degrees
pub inline fn toDegrees(radians: f32) f32 {
    return radians * (180.0 / pi);
}

/// Rounds in smaller direction
pub inline fn floor(value: f32) f32 {
    return @floor(value);
}

/// Rounds in bigger direction
pub inline fn ceil(value: f32) f32 {
    return @ceil(value);
}

/// Rounds in closest direction
pub inline fn round(value: f32) f32 {
    return @round(value);
}

/// Rounds to zero
pub inline fn trunc(value: f32) f32 {
    return @trunc(value);
}

/// Fractional part, always in [0, 1): `fract(-0.25) == 0.75`
pub inline fn fract(value: f32) f32 {
    return value - @floor(value);
}

/// Removes the sign
pub inline fn abs(value: f32) f32 {
    return @abs(value);
}

/// Square root
pub inline fn sqrt(value: f32) f32 {
    return @sqrt(value);
}

/// -1, 0 or 1.
pub inline fn sign(value: f32) f32 {
    return std.math.sign(value);
}

/// Smaller number between `a` and `b
pub inline fn min(a: f32, b: f32) f32 {
    return @min(a, b);
}

/// Bigger number between `a` and `b`
pub inline fn max(a: f32, b: f32) f32 {
    return @max(a, b);
}

/// Rounds to the nearest multiple of `increment`
pub inline fn snap(value: f32, increment: f32) f32 {
    if (increment == 0.0) return value;
    return @round(value / increment) * increment;
}

/// Clamps `value` between `lower` and `upper`
pub inline fn clamp(value: f32, lower: f32, upper: f32) f32 {
    return @min(@max(value, lower), upper);
}

/// Clamps `value` to [0, 1]
pub inline fn saturate(value: f32) f32 {
    return clamp(value, 0.0, 1.0);
}

/// Wraps `value` into [0, length), keeping the result positive
pub inline fn repeat(value: f32, length: f32) f32 {
    if (length == 0.0) return 0.0;
    return clamp(@mod(value, length), 0.0, length);
}

/// The inverse `lerp`
pub inline fn inverseLerp(a: f32, b: f32, value: f32) f32 {
    if (a == b) return 0.0;
    return (value - a) / (b - a);
}

/// Maps `value` from the `in_*` range onto the `out_*` range
pub inline fn remap(value: f32, in_min: f32, in_max: f32, out_min: f32, out_max: f32) f32 {
    return lerp(out_min, out_max, inverseLerp(in_min, in_max, value));
}

/// Steps `current` toward `target` by at most `max_delta`
pub inline fn moveTowards(current: f32, target: f32, max_delta: f32) f32 {
    const delta = target - current;
    if (@abs(delta) <= max_delta) return target;
    return current + std.math.sign(delta) * max_delta;
}

/// Checks for equality with tolerance
pub inline fn approxEql(a: f32, b: f32, tolerance: f32) bool {
    return @abs(a - b) <= tolerance;
}

/// GLSL-style step: 0 below `edge`, 1 at or above it
pub inline fn step(edge: f32, value: f32) f32 {
    return if (value < edge) 0.0 else 1.0;
}

/// Linear interpolation
pub inline fn lerp(a: f32, b: f32, t: f32) f32 {
    return @mulAdd(f32, b - a, t, a);
}

/// `lerp` with `t` clamped to [0, 1], so it never extrapolates
pub inline fn lerpClamped(a: f32, b: f32, t: f32) f32 {
    return lerp(a, b, saturate(t));
}

/// Interpolates between two angles in radians along the shortest arc.
pub inline fn lerpAngle(a: f32, b: f32, t: f32) f32 {
    return a + wrapAngle(b - a) * t;
}

/// Wraps an angle in radians into (-pi, pi]. Not delegated to zmath:
/// its `modAngle32` is broken, returning -2pi for an input of 0
pub inline fn wrapAngle(radians: f32) f32 {
    return @mod(radians + pi, tau) - pi;
}

/// Hermite blend between the edges: 0 below `edge0`, 1 above `edge1`, with a
/// zero first derivative at both ends
pub inline fn smoothstep(edge0: f32, edge1: f32, value: f32) f32 {
    const t = saturate(inverseLerp(edge0, edge1, value));
    return t * t * (3.0 - 2.0 * t);
}

/// Like `smoothstep` but with a zero second derivative at both ends too
pub inline fn smootherstep(edge0: f32, edge1: f32, value: f32) f32 {
    const t = saturate(inverseLerp(edge0, edge1, value));
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

/// Bilinear interpolation over a unit quad. Corners are named `c{x}{y}`
pub inline fn bilinear(c00: f32, c10: f32, c01: f32, c11: f32, tx: f32, ty: f32) f32 {
    return lerp(lerp(c00, c10, tx), lerp(c01, c11, tx), ty);
}

/// Trilinear interpolation over a unit cube. Corners are named `c{x}{y}{z}`
pub inline fn trilinear(
    c000: f32,
    c100: f32,
    c010: f32,
    c110: f32,
    c001: f32,
    c101: f32,
    c011: f32,
    c111: f32,
    tx: f32,
    ty: f32,
    tz: f32,
) f32 {
    const near = bilinear(c000, c100, c010, c110, tx, ty);
    const far = bilinear(c001, c101, c011, c111, tx, ty);
    return lerp(near, far, tz);
}

/// Cubic Hermite spline segment from `p0` (tangent `m0`) to `p1` (tangent `m1`)
pub inline fn cubicHermite(p0: f32, m0: f32, p1: f32, m1: f32, t: f32) f32 {
    const t2 = t * t;
    const t3 = t2 * t;
    const h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
    const h10 = t3 - 2.0 * t2 + t;
    const h01 = -2.0 * t3 + 3.0 * t2;
    const h11 = t3 - t2;
    return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1;
}

/// Catmull-Rom spline segment: passes through `p1` at t = 0 and `p2` at t = 1,
/// using `p0` and `p3` only to derive the tangents
pub inline fn catmullRom(p0: f32, p1: f32, p2: f32, p3: f32, t: f32) f32 {
    const t2 = t * t;
    const t3 = t2 * t;
    return 0.5 * (2.0 * p1 +
        (p2 - p0) * t +
        (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
        (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3);
}

/// Bezier curve, where `t` is the position along curve and `p1` and `p2` are coords of 2 control points
pub inline fn bezier(t: f64, p1: f64, p2: f64) f64 {
    const u = 1.0 - t;

    return 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t;
}

/// Cubic bezier curve, just like in CSS. `x0, y0, x1, y1` are shape points where 0 is bottom left corner and 1 is top right
pub inline fn cubicBezier(x: f32, x0: f32, y0: f32, x1: f32, y1: f32) f32 {
    const target = saturate(x);

    var low: f32 = 0.0;
    var high: f32 = 1.0;

    for (0..30) |_| {
        const t = (low + high) * 0.5;
        const bx = bezier(t, x0, x1);

        if (bx < target) {
            low = t;
        } else {
            high = t;
        }
    }

    const t = (low + high) * 0.5;
    return @floatCast(bezier(t, y0, y1));
}
