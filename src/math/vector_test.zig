const std = @import("std");
const vm = @import("vector.zig");

const Vec2 = vm.Vec2;
const Vec3 = vm.Vec3;
const Vec4 = vm.Vec4;

const expect = std.testing.expect;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

const tolerance = 1e-5;

/// Every vector type, so shared behaviour is only spelled out once
const vector_types = .{ Vec2, Vec3, Vec4 };

/// Number of axis a vector type has
fn axisCount(comptime V: type) comptime_int {
    return @typeInfo(@FieldType(V, "Simd")).vector.len;
}

/// An expected value per axis, for the type agnostic tests
fn splat(comptime V: type, comptime value: f32) [axisCount(V)]f32 {
    return .{value} ** axisCount(V);
}

/// Compares a vector against the expected value of each of its axis
fn expectVec(comptime V: type, actual: V, expected: [axisCount(V)]f32) !void {
    const got = actual.asArray();

    inline for (expected, 0..) |value, i| {
        try expectApproxEqAbs(value, got[i], tolerance);
    }
}

test "zero, one and fromScalar agree" {
    inline for (vector_types) |V| {
        try expect(V.equals(V.zero(), V.fromScalar(0.0)));
        try expect(V.equals(V.one(), V.fromScalar(1.0)));
        try expect(!V.equals(V.zero(), V.one()));
    }
}

test "arithmetic is elementwise" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(3.0);
        const b = V.fromScalar(2.0);

        try expect(V.equals(V.add(a, b), V.fromScalar(5.0)));
        try expect(V.equals(V.sub(a, b), V.fromScalar(1.0)));
        try expect(V.equals(V.mul(a, 2.0), V.fromScalar(6.0)));
        try expect(V.equals(V.div(a, 2.0), V.fromScalar(1.5)));
        try expect(V.equals(V.abs(V.fromScalar(-3.0)), a));
        try expect(V.equals(V.min(a, b), b));
        try expect(V.equals(V.max(a, b), a));
    }
}

test "length and lengthSq match" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(2.0);
        const axis: f32 = @floatFromInt(axisCount(V));

        try expectApproxEqAbs(4.0 * axis, V.lengthSq(a), tolerance);
        try expectApproxEqAbs(@sqrt(4.0 * axis), V.length(a), tolerance);
        try expectApproxEqAbs(@as(f32, 0.0), V.length(V.zero()), tolerance);
    }
}

test "dot of a vector with itself is its square length" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(1.5);

        try expectApproxEqAbs(V.lengthSq(a), V.dot(a, a), tolerance);
        try expectApproxEqAbs(@as(f32, 0.0), V.dot(a, V.zero()), tolerance);
    }
}

test "normalize returns a unit vector and survives zero length" {
    inline for (vector_types) |V| {
        const n = V.normalize(V.fromScalar(4.0));

        try expectApproxEqAbs(@as(f32, 1.0), V.length(n), tolerance);
        try expect(V.equals(V.normalize(V.zero()), V.zero()));
    }
}

test "angle follows the direction of both vectors" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(2.0);

        try expectApproxEqAbs(@as(f32, 0.0), V.angle(a, a), tolerance);
        try expectApproxEqAbs(@as(f32, 0.0), V.angle(a, V.mul(a, 3.0)), tolerance);
        try expectApproxEqAbs(@as(f32, std.math.pi), V.angle(a, V.mul(a, -1.0)), tolerance);

        // A zero vector points nowhere, so there is no angle to report
        try expectApproxEqAbs(@as(f32, 0.0), V.angle(a, V.zero()), tolerance);
    }
}

test "distance is symmetric and zero for equal vectors" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(1.0);
        const b = V.fromScalar(4.0);

        try expectApproxEqAbs(V.distance(a, b), V.distance(b, a), tolerance);
        try expectApproxEqAbs(@as(f32, 0.0), V.distance(a, a), tolerance);
        try expectApproxEqAbs(V.length(V.sub(b, a)), V.distance(a, b), tolerance);
    }
}

test "lerp hits both ends and the midpoint" {
    inline for (vector_types) |V| {
        const a = V.fromScalar(-2.0);
        const b = V.fromScalar(6.0);

        try expect(V.equals(V.lerp(a, b, 0.0), a));
        try expect(V.equals(V.lerp(a, b, 1.0), b));
        try expect(V.equals(V.lerp(a, b, 0.5), V.fromScalar(2.0)));
    }
}

test "lerp extrapolates but lerpClamped does not" {
    inline for (vector_types) |V| {
        const a = V.zero();
        const b = V.fromScalar(10.0);

        try expect(V.equals(V.lerp(a, b, 2.0), V.fromScalar(20.0)));
        try expect(V.equals(V.lerpClamped(a, b, 2.0), b));
        try expect(V.equals(V.lerpClamped(a, b, -1.0), a));
    }
}

test "smoothstep and smootherstep keep the ends and the midpoint" {
    inline for (vector_types) |V| {
        const a = V.zero();
        const b = V.fromScalar(8.0);

        try expect(V.equals(V.smoothstep(a, b, 0.0), a));
        try expect(V.equals(V.smoothstep(a, b, 1.0), b));
        try expect(V.equals(V.smoothstep(a, b, 0.5), V.fromScalar(4.0)));

        try expect(V.equals(V.smootherstep(a, b, 0.0), a));
        try expect(V.equals(V.smootherstep(a, b, 1.0), b));
        try expect(V.equals(V.smootherstep(a, b, 0.5), V.fromScalar(4.0)));

        // Both ease in, so they trail a plain lerp over the first half
        try expect(V.length(V.smoothstep(a, b, 0.25)) < V.length(V.lerp(a, b, 0.25)));
        try expect(V.length(V.smootherstep(a, b, 0.25)) < V.length(V.smoothstep(a, b, 0.25)));
    }
}

test "cubicBezier easing keeps the ends" {
    inline for (vector_types) |V| {
        const a = V.zero();
        const b = V.fromScalar(5.0);

        // The CSS "ease" curve
        try expectVec(V, V.cubicBezier(a, b, 0.25, 0.1, 0.25, 1.0, 0.0), splat(V, 0.0));
        try expectVec(V, V.cubicBezier(a, b, 0.25, 0.1, 0.25, 1.0, 1.0), splat(V, 5.0));
    }
}

test "moveTowards steps by at most max_delta" {
    inline for (vector_types) |V| {
        const from = V.zero();
        const to = V.fromScalar(10.0);

        try expectApproxEqAbs(@as(f32, 1.0), V.length(V.moveTowards(from, to, 1.0)), tolerance);
        try expect(V.equals(V.moveTowards(from, to, 1000.0), to));
        try expect(V.equals(V.moveTowards(to, to, 0.0), to));
    }
}

test "bilinear returns every corner of the unit quad" {
    inline for (vector_types) |V| {
        const c00 = V.fromScalar(1.0);
        const c10 = V.fromScalar(2.0);
        const c01 = V.fromScalar(3.0);
        const c11 = V.fromScalar(4.0);

        try expect(V.equals(V.bilinear(c00, c10, c01, c11, 0.0, 0.0), c00));
        try expect(V.equals(V.bilinear(c00, c10, c01, c11, 1.0, 0.0), c10));
        try expect(V.equals(V.bilinear(c00, c10, c01, c11, 0.0, 1.0), c01));
        try expect(V.equals(V.bilinear(c00, c10, c01, c11, 1.0, 1.0), c11));
        try expect(V.equals(V.bilinear(c00, c10, c01, c11, 0.5, 0.5), V.fromScalar(2.5)));
    }
}

test "trilinear returns the corners of the unit cube" {
    inline for (vector_types) |V| {
        const c000 = V.fromScalar(1.0);
        const c100 = V.fromScalar(2.0);
        const c010 = V.fromScalar(3.0);
        const c110 = V.fromScalar(4.0);
        const c001 = V.fromScalar(5.0);
        const c101 = V.fromScalar(6.0);
        const c011 = V.fromScalar(7.0);
        const c111 = V.fromScalar(8.0);

        try expect(V.equals(V.trilinear(c000, c100, c010, c110, c001, c101, c011, c111, 0.0, 0.0, 0.0), c000));
        try expect(V.equals(V.trilinear(c000, c100, c010, c110, c001, c101, c011, c111, 1.0, 0.0, 0.0), c100));
        try expect(V.equals(V.trilinear(c000, c100, c010, c110, c001, c101, c011, c111, 0.0, 1.0, 0.0), c010));
        try expect(V.equals(V.trilinear(c000, c100, c010, c110, c001, c101, c011, c111, 0.0, 0.0, 1.0), c001));
        try expect(V.equals(V.trilinear(c000, c100, c010, c110, c001, c101, c011, c111, 1.0, 1.0, 1.0), c111));
    }
}

test "cubicHermite starts at p0 and ends at p1" {
    inline for (vector_types) |V| {
        const p0 = V.fromScalar(1.0);
        const p1 = V.fromScalar(4.0);
        const m0 = V.zero();
        const m1 = V.zero();

        try expect(V.equals(V.cubicHermite(p0, m0, p1, m1, 0.0), p0));
        try expect(V.equals(V.cubicHermite(p0, m0, p1, m1, 1.0), p1));

        // With zero tangents it eases between the points, so the midpoint is theirs
        try expect(V.equals(V.cubicHermite(p0, m0, p1, m1, 0.5), V.fromScalar(2.5)));
    }
}

test "catmullRom passes through p1 and p2" {
    inline for (vector_types) |V| {
        const p0 = V.fromScalar(0.0);
        const p1 = V.fromScalar(1.0);
        const p2 = V.fromScalar(2.0);
        const p3 = V.fromScalar(3.0);

        try expectVec(V, V.catmullRom(p0, p1, p2, p3, 0.0), splat(V, 1.0));
        try expectVec(V, V.catmullRom(p0, p1, p2, p3, 1.0), splat(V, 2.0));

        // Evenly spaced points, so the spline is the straight line through them
        try expectVec(V, V.catmullRom(p0, p1, p2, p3, 0.5), splat(V, 1.5));
    }
}

test "bezier curves start and end on their outer control points" {
    inline for (vector_types) |V| {
        const p0 = V.fromScalar(0.0);
        const p1 = V.fromScalar(1.0);
        const p2 = V.fromScalar(2.0);
        const p3 = V.fromScalar(3.0);

        try expect(V.equals(V.quadBezier(p0, p1, p2, 0.0), p0));
        try expect(V.equals(V.quadBezier(p0, p1, p2, 1.0), p2));
        try expect(V.equals(V.quadBezier(p0, p1, p2, 0.5), V.fromScalar(1.0)));

        try expect(V.equals(V.bezier(p0, p1, p2, p3, 0.0), p0));
        try expect(V.equals(V.bezier(p0, p1, p2, p3, 1.0), p3));
        try expect(V.equals(V.bezier(p0, p1, p2, p3, 0.5), V.fromScalar(1.5)));
    }
}

test "Vec2 axis accessors and setters" {
    var a = Vec2.fromAxis(3.0, 4.0);

    try expectApproxEqAbs(@as(f32, 3.0), a.x(), tolerance);
    try expectApproxEqAbs(@as(f32, 4.0), a.y(), tolerance);
    try expectVec(Vec2, a, .{ 3.0, 4.0 });

    a.setX(-1.0);
    a.setY(-2.0);
    try expectVec(Vec2, a, .{ -1.0, -2.0 });

    try expect(Vec2.equals(Vec2.fromArray(.{ 7.0, 8.0 }), Vec2.fromAxis(7.0, 8.0)));
}

test "Vec2 geometry" {
    const a = Vec2.fromAxis(3.0, 4.0);

    try expectApproxEqAbs(@as(f32, 25.0), Vec2.lengthSq(a), tolerance);
    try expectApproxEqAbs(@as(f32, 5.0), Vec2.length(a), tolerance);
    try expectVec(Vec2, Vec2.normalize(a), .{ 0.6, 0.8 });
    try expectApproxEqAbs(@as(f32, 11.0), Vec2.dot(Vec2.fromAxis(1.0, 2.0), Vec2.fromAxis(3.0, 4.0)), tolerance);
    try expectApproxEqAbs(@as(f32, 5.0), Vec2.distance(Vec2.zero(), a), tolerance);
    try expectApproxEqAbs(@as(f32, std.math.pi / 2.0), Vec2.angle(Vec2.fromAxis(1.0, 0.0), Vec2.fromAxis(0.0, 1.0)), tolerance);
    try expectVec(Vec2, Vec2.lerp(Vec2.zero(), Vec2.fromAxis(10.0, 20.0), 0.25), .{ 2.5, 5.0 });
}

test "Vec3 axis accessors and setters" {
    var a = Vec3.fromAxis(1.0, 2.0, 3.0);

    try expectApproxEqAbs(@as(f32, 1.0), a.x(), tolerance);
    try expectApproxEqAbs(@as(f32, 2.0), a.y(), tolerance);
    try expectApproxEqAbs(@as(f32, 3.0), a.z(), tolerance);
    try expectVec(Vec3, a, .{ 1.0, 2.0, 3.0 });

    a.setX(-1.0);
    a.setY(-2.0);
    a.setZ(-3.0);
    try expectVec(Vec3, a, .{ -1.0, -2.0, -3.0 });

    try expect(Vec3.equals(Vec3.fromArray(.{ 7.0, 8.0, 9.0 }), Vec3.fromAxis(7.0, 8.0, 9.0)));
}

test "Vec3 geometry" {
    const a = Vec3.fromAxis(1.0, 2.0, 2.0);

    try expectApproxEqAbs(@as(f32, 9.0), Vec3.lengthSq(a), tolerance);
    try expectApproxEqAbs(@as(f32, 3.0), Vec3.length(a), tolerance);
    try expectApproxEqAbs(@as(f32, 1.0), Vec3.length(Vec3.normalize(a)), tolerance);
    try expectApproxEqAbs(@as(f32, 32.0), Vec3.dot(Vec3.fromAxis(1.0, 2.0, 3.0), Vec3.fromAxis(4.0, 5.0, 6.0)), tolerance);
    try expectApproxEqAbs(@as(f32, 5.0), Vec3.distance(Vec3.fromAxis(1.0, 0.0, 0.0), Vec3.fromAxis(4.0, 4.0, 0.0)), tolerance);
    try expectApproxEqAbs(@as(f32, std.math.pi / 2.0), Vec3.angle(Vec3.fromAxis(1.0, 0.0, 0.0), Vec3.fromAxis(0.0, 0.0, 1.0)), tolerance);
    try expectVec(Vec3, Vec3.lerp(Vec3.zero(), Vec3.fromAxis(10.0, 20.0, 30.0), 0.25), .{ 2.5, 5.0, 7.5 });
}

test "Vec4 axis accessors and setters" {
    var a = Vec4.fromAxis(1.0, 2.0, 3.0, 4.0);

    try expectApproxEqAbs(@as(f32, 1.0), a.x(), tolerance);
    try expectApproxEqAbs(@as(f32, 2.0), a.y(), tolerance);
    try expectApproxEqAbs(@as(f32, 3.0), a.z(), tolerance);
    try expectApproxEqAbs(@as(f32, 4.0), a.w(), tolerance);
    try expectVec(Vec4, a, .{ 1.0, 2.0, 3.0, 4.0 });

    a.setX(-1.0);
    a.setY(-2.0);
    a.setZ(-3.0);
    a.setW(-4.0);
    try expectVec(Vec4, a, .{ -1.0, -2.0, -3.0, -4.0 });

    try expect(Vec4.equals(Vec4.fromArray(.{ 6.0, 7.0, 8.0, 9.0 }), Vec4.fromAxis(6.0, 7.0, 8.0, 9.0)));
}

test "Vec4 geometry" {
    const a = Vec4.fromAxis(1.0, 2.0, 3.0, 4.0);

    try expectApproxEqAbs(@as(f32, 30.0), Vec4.lengthSq(a), tolerance);
    try expectApproxEqAbs(@sqrt(@as(f32, 30.0)), Vec4.length(a), tolerance);
    try expectApproxEqAbs(@as(f32, 1.0), Vec4.length(Vec4.normalize(a)), tolerance);
    try expectApproxEqAbs(@as(f32, 10.0), Vec4.dot(a, Vec4.one()), tolerance);
    try expectApproxEqAbs(@as(f32, 2.0), Vec4.distance(a, Vec4.fromAxis(1.0, 2.0, 3.0, 6.0)), tolerance);
    try expectVec(Vec4, Vec4.lerp(Vec4.zero(), Vec4.fromAxis(4.0, 8.0, 12.0, 16.0), 0.25), .{ 1.0, 2.0, 3.0, 4.0 });
}
