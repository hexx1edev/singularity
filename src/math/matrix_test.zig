const std = @import("std");
const mm = @import("matrix.zig");
const vm = @import("vector.zig");

const Mat4 = mm.Mat4;
const Vec3 = vm.Vec3;

const expect = std.testing.expect;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

const tolerance = 1e-4;

/// A matrix with no symmetry to hide index mistakes behind
const counting: [4][4]f32 = .{
    .{ 1.0, 2.0, 3.0, 4.0 },
    .{ 5.0, 6.0, 7.0, 8.0 },
    .{ 9.0, 10.0, 11.0, 12.0 },
    .{ 13.0, 14.0, 15.0, 16.0 },
};

/// Invertible, unlike `counting`, whose evenly spaced rows are dependent.
/// Tridiagonal with 2 on the diagonal, so its determinant is 5
const invertible: [4][4]f32 = .{
    .{ 2.0, 1.0, 0.0, 0.0 },
    .{ 1.0, 2.0, 1.0, 0.0 },
    .{ 0.0, 1.0, 2.0, 1.0 },
    .{ 0.0, 0.0, 1.0, 2.0 },
};

/// Compares a matrix against the expected value of each of its elements
fn expectMat(actual: Mat4, expected: [4][4]f32) !void {
    const got = actual.asArray();

    for (0..4) |r| {
        for (0..4) |c| {
            expectApproxEqAbs(expected[r][c], got[r][c], tolerance) catch |err| {
                std.debug.print("mismatch at row {d}, column {d}\n", .{ r, c });
                return err;
            };
        }
    }
}

/// Applies `M * v` the way GLSL does, so transforms can be checked on a point
fn transform(matrix: Mat4, point: [4]f32) [4]f32 {
    const rows = matrix.asArray();

    var result: [4]f32 = undefined;

    for (0..4) |r| {
        var sum: f32 = 0.0;

        for (0..4) |c| {
            sum += rows[r][c] * point[c];
        }

        result[r] = sum;
    }

    return result;
}

/// Compares a transformed point against its expected axis values
fn expectPoint(actual: [4]f32, expected: [4]f32) !void {
    for (0..4) |i| {
        try expectApproxEqAbs(expected[i], actual[i], tolerance);
    }
}

test "identity, fromScalar and fromArray build the matrix they name" {
    try expectMat(Mat4.identity(), .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    });

    try expect(Mat4.equals(Mat4.fromScalar(1.0), Mat4.identity()));

    try expectMat(Mat4.fromScalar(3.0), .{
        .{ 3.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 3.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 3.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 3.0 },
    });

    // fromArray keeps the rows as written, and asArray hands them back
    try expectMat(Mat4.fromArray(counting), counting);
}

test "equals compares every element" {
    const a = Mat4.fromArray(counting);

    try expect(Mat4.equals(a, Mat4.fromArray(counting)));
    try expect(!Mat4.equals(a, Mat4.identity()));

    var tweaked = counting;
    tweaked[2][3] += 1.0;
    try expect(!Mat4.equals(a, Mat4.fromArray(tweaked)));
}

test "add and sub are elementwise and undo each other" {
    const a = Mat4.fromArray(counting);
    const b = Mat4.fromArray(invertible);

    try expectMat(Mat4.add(a, b), .{
        .{ 3.0, 3.0, 3.0, 4.0 },
        .{ 6.0, 8.0, 8.0, 8.0 },
        .{ 9.0, 11.0, 13.0, 13.0 },
        .{ 13.0, 14.0, 16.0, 18.0 },
    });

    try expect(Mat4.equals(Mat4.sub(Mat4.add(a, b), b), a));
    try expect(Mat4.equals(Mat4.sub(a, a), Mat4.fromScalar(0.0)));
}

test "mulScalar scales every element" {
    try expectMat(Mat4.mulScalar(Mat4.fromArray(counting), 2.0), .{
        .{ 2.0, 4.0, 6.0, 8.0 },
        .{ 10.0, 12.0, 14.0, 16.0 },
        .{ 18.0, 20.0, 22.0, 24.0 },
        .{ 26.0, 28.0, 30.0, 32.0 },
    });

    try expect(Mat4.equals(Mat4.mulScalar(Mat4.fromArray(counting), 0.0), Mat4.fromScalar(0.0)));
}

test "mul leaves a matrix untouched when multiplied by identity" {
    const a = Mat4.fromArray(counting);

    try expect(Mat4.equals(Mat4.mul(a, Mat4.identity()), a));
    try expect(Mat4.equals(Mat4.mul(Mat4.identity(), a), a));
}

test "mul multiplies rows of the left by columns of the right" {
    const a = Mat4.fromArray(counting);
    const b = Mat4.fromArray(.{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 1.0, 1.0, 1.0, 1.0 },
    });

    // Every column of `b` but the last adds the fourth column of `a` to itself
    try expectMat(Mat4.mul(a, b), .{
        .{ 5.0, 6.0, 7.0, 4.0 },
        .{ 13.0, 14.0, 15.0, 8.0 },
        .{ 21.0, 22.0, 23.0, 12.0 },
        .{ 29.0, 30.0, 31.0, 16.0 },
    });

    // Order matters, so the operands cannot be swapped
    try expect(!Mat4.equals(Mat4.mul(a, b), Mat4.mul(b, a)));
}

test "transpose mirrors over the diagonal and is its own inverse" {
    try expectMat(Mat4.transpose(Mat4.fromArray(counting)), .{
        .{ 1.0, 5.0, 9.0, 13.0 },
        .{ 2.0, 6.0, 10.0, 14.0 },
        .{ 3.0, 7.0, 11.0, 15.0 },
        .{ 4.0, 8.0, 12.0, 16.0 },
    });

    const a = Mat4.fromArray(counting);
    try expect(Mat4.equals(Mat4.transpose(Mat4.transpose(a)), a));
    try expect(Mat4.equals(Mat4.transpose(Mat4.identity()), Mat4.identity()));
}

test "determinant of diagonal and block matrices" {
    try expectApproxEqAbs(@as(f32, 1.0), Mat4.determinant(Mat4.identity()), tolerance);
    try expectApproxEqAbs(@as(f32, 81.0), Mat4.determinant(Mat4.fromScalar(3.0)), tolerance);

    try expectApproxEqAbs(@as(f32, 120.0), Mat4.determinant(Mat4.fromArray(.{
        .{ 2.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 3.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 4.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 5.0 },
    })), tolerance);

    // Two 2x2 blocks, so the determinant is the product of theirs: -2 * -2
    try expectApproxEqAbs(@as(f32, 4.0), Mat4.determinant(Mat4.fromArray(.{
        .{ 1.0, 2.0, 0.0, 0.0 },
        .{ 3.0, 4.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 5.0, 6.0 },
        .{ 0.0, 0.0, 7.0, 8.0 },
    })), tolerance);
}

test "determinant of a singular matrix is zero" {
    // Evenly spaced rows, so they are linearly dependent
    try expectApproxEqAbs(@as(f32, 0.0), Mat4.determinant(Mat4.fromArray(counting)), tolerance);
    try expectApproxEqAbs(@as(f32, 0.0), Mat4.determinant(Mat4.fromScalar(0.0)), tolerance);

    // A repeated row
    try expectApproxEqAbs(@as(f32, 0.0), Mat4.determinant(Mat4.fromArray(.{
        .{ 1.0, 2.0, 3.0, 4.0 },
        .{ 9.0, 7.0, 5.0, 3.0 },
        .{ 1.0, 2.0, 3.0, 4.0 },
        .{ 2.0, 0.0, 6.0, 1.0 },
    })), tolerance);
}

test "determinant is 5 for the tridiagonal fixture" {
    try expectApproxEqAbs(@as(f32, 5.0), Mat4.determinant(Mat4.fromArray(invertible)), tolerance);
}

test "determinant follows a transpose and a scalar multiply" {
    const a = Mat4.fromArray(invertible);

    try expectApproxEqAbs(Mat4.determinant(a), Mat4.determinant(Mat4.transpose(a)), tolerance);

    // Scaling a 4x4 by k scales its determinant by k^4
    try expectApproxEqAbs(16.0 * Mat4.determinant(a), Mat4.determinant(Mat4.mulScalar(a, 2.0)), tolerance);
}

test "inverse multiplied by the original is identity" {
    const a = Mat4.fromArray(invertible);
    const a_inv = Mat4.inverse(a) orelse return error.ExpectedInverse;

    try expectMat(Mat4.mul(a, a_inv), Mat4.identity().asArray());
    try expectMat(Mat4.mul(a_inv, a), Mat4.identity().asArray());

    try expect(Mat4.equals(Mat4.inverse(Mat4.identity()) orelse return error.ExpectedInverse, Mat4.identity()));
}

test "inverse of a diagonal matrix inverts its diagonal" {
    const a = Mat4.inverse(Mat4.fromScalar(4.0)) orelse return error.ExpectedInverse;

    try expectMat(a, .{
        .{ 0.25, 0.0, 0.0, 0.0 },
        .{ 0.0, 0.25, 0.0, 0.0 },
        .{ 0.0, 0.0, 0.25, 0.0 },
        .{ 0.0, 0.0, 0.0, 0.25 },
    });
}

// The elimination gives up on a pivot below 1e-8, so it only catches a matrix
// that has no pivot at all. A matrix that is singular on paper, like `counting`
// or one with a repeated row, leaves an f32 pivot near 1e-6 behind and gets
// "inverted" into nonsense instead
test "inverse is null for a singular matrix" {
    try expect(Mat4.inverse(Mat4.fromScalar(0.0)) == null);

    // A zeroed row leaves nothing to pivot on
    try expect(Mat4.inverse(Mat4.fromArray(.{
        .{ 1.0, 2.0, 3.0, 4.0 },
        .{ 0.0, 0.0, 0.0, 0.0 },
        .{ 5.0, 6.0, 7.0, 8.0 },
        .{ 9.0, 1.0, 2.0, 3.0 },
    })) == null);

    // So does a zeroed column
    try expect(Mat4.inverse(Mat4.fromArray(.{
        .{ 1.0, 0.0, 3.0, 4.0 },
        .{ 5.0, 0.0, 7.0, 8.0 },
        .{ 9.0, 0.0, 2.0, 1.0 },
        .{ 4.0, 0.0, 6.0, 3.0 },
    })) == null);
}

test "inverse undoes a transform" {
    const model = Mat4.scale(
        Mat4.rotate(Mat4.translate(Mat4.identity(), Vec3.fromAxis(1.0, -2.0, 3.0)), 0.75, Vec3.fromAxis(1.0, 1.0, 0.0)),
        Vec3.fromAxis(2.0, 3.0, 4.0),
    );
    const undo = Mat4.inverse(model) orelse return error.ExpectedInverse;

    const point: [4]f32 = .{ 5.0, 6.0, 7.0, 1.0 };
    try expectPoint(transform(undo, transform(model, point)), point);
}

test "perspective builds the projection OpenGL expects" {
    // A 90 degree FOV makes tan(fov / 2) exactly 1
    const p = Mat4.perspective(std.math.degreesToRadians(90.0), 2.0, 1.0, 100.0) orelse return error.ExpectedProjection;

    try expectMat(p, .{
        .{ 0.5, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, -101.0 / 99.0, -200.0 / 99.0 },
        .{ 0.0, 0.0, -1.0, 0.0 },
    });
}

test "perspective maps the near and far planes onto the depth range" {
    const near = 1.0;
    const far = 100.0;
    const p = Mat4.perspective(std.math.degreesToRadians(60.0), 16.0 / 9.0, near, far) orelse return error.ExpectedProjection;

    // The w of a projected point is its distance down -Z, and depth is z / w
    const on_near = transform(p, .{ 0.0, 0.0, -near, 1.0 });
    const on_far = transform(p, .{ 0.0, 0.0, -far, 1.0 });

    try expectApproxEqAbs(near, on_near[3], tolerance);
    try expectApproxEqAbs(far, on_far[3], tolerance);
    try expectApproxEqAbs(@as(f32, -1.0), on_near[2] / on_near[3], tolerance);
    try expectApproxEqAbs(@as(f32, 1.0), on_far[2] / on_far[3], tolerance);
}

test "perspective is null when its parameters divide by zero" {
    const fov = std.math.degreesToRadians(90.0);

    try expect(Mat4.perspective(fov, 2.0, 0.0, 100.0) == null);
    try expect(Mat4.perspective(fov, 0.0, 1.0, 100.0) == null);
    try expect(Mat4.perspective(fov, 2.0, 100.0, 100.0) == null);
    try expect(Mat4.perspective(0.0, 2.0, 1.0, 100.0) == null);
}

test "translate moves a point and leaves a direction alone" {
    const t = Mat4.translate(Mat4.identity(), Vec3.fromAxis(1.0, 2.0, 3.0));

    try expectMat(t, .{
        .{ 1.0, 0.0, 0.0, 1.0 },
        .{ 0.0, 1.0, 0.0, 2.0 },
        .{ 0.0, 0.0, 1.0, 3.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    });

    try expectPoint(transform(t, .{ 0.0, 0.0, 0.0, 1.0 }), .{ 1.0, 2.0, 3.0, 1.0 });
    try expectPoint(transform(t, .{ 5.0, 5.0, 5.0, 1.0 }), .{ 6.0, 7.0, 8.0, 1.0 });

    // A direction has w = 0, so a translation cannot reach it
    try expectPoint(transform(t, .{ 1.0, 0.0, 0.0, 0.0 }), .{ 1.0, 0.0, 0.0, 0.0 });

    try expect(Mat4.equals(Mat4.translate(Mat4.identity(), Vec3.zero()), Mat4.identity()));
}

test "translate accumulates" {
    const a = Mat4.translate(Mat4.identity(), Vec3.fromAxis(1.0, 2.0, 3.0));
    const b = Mat4.translate(a, Vec3.fromAxis(10.0, 20.0, 30.0));

    try expectPoint(transform(b, .{ 0.0, 0.0, 0.0, 1.0 }), .{ 11.0, 22.0, 33.0, 1.0 });
}

test "rotate turns a point counterclockwise around the axis" {
    const quarter = std.math.pi / 2.0;

    const around_z = Mat4.rotate(Mat4.identity(), quarter, Vec3.fromAxis(0.0, 0.0, 1.0));
    try expectPoint(transform(around_z, .{ 1.0, 0.0, 0.0, 1.0 }), .{ 0.0, 1.0, 0.0, 1.0 });

    const around_x = Mat4.rotate(Mat4.identity(), quarter, Vec3.fromAxis(1.0, 0.0, 0.0));
    try expectPoint(transform(around_x, .{ 0.0, 1.0, 0.0, 1.0 }), .{ 0.0, 0.0, 1.0, 1.0 });

    const around_y = Mat4.rotate(Mat4.identity(), quarter, Vec3.fromAxis(0.0, 1.0, 0.0));
    try expectPoint(transform(around_y, .{ 0.0, 0.0, 1.0, 1.0 }), .{ 1.0, 0.0, 0.0, 1.0 });
}

test "rotate normalizes its axis and keeps lengths" {
    const angle = 0.9;
    const axis = Vec3.fromAxis(1.0, 2.0, 3.0);

    const unit = Mat4.rotate(Mat4.identity(), angle, Vec3.normalize(axis));
    const scaled = Mat4.rotate(Mat4.identity(), angle, Vec3.mul(axis, 7.0));
    try expectMat(scaled, unit.asArray());

    // A rotation is rigid, so it cannot change the length of a vector
    const point: [4]f32 = .{ 3.0, -4.0, 5.0, 1.0 };
    const spun = transform(unit, point);
    const before = @sqrt(point[0] * point[0] + point[1] * point[1] + point[2] * point[2]);
    const after = @sqrt(spun[0] * spun[0] + spun[1] * spun[1] + spun[2] * spun[2]);
    try expectApproxEqAbs(before, after, tolerance);

    // And its inverse is its transpose
    try expectMat(Mat4.mul(unit, Mat4.transpose(unit)), Mat4.identity().asArray());
}

test "rotate by a full turn or around no axis changes nothing" {
    const axis = Vec3.fromAxis(0.0, 1.0, 0.0);

    try expectMat(Mat4.rotate(Mat4.identity(), 0.0, axis), Mat4.identity().asArray());
    try expectMat(Mat4.rotate(Mat4.identity(), std.math.tau, axis), Mat4.identity().asArray());

    // An axis with no length leaves the matrix as it was
    const a = Mat4.fromArray(counting);
    try expect(Mat4.equals(Mat4.rotate(a, 1.0, Vec3.zero()), a));
}

test "scale stretches each axis" {
    const s = Mat4.scale(Mat4.identity(), Vec3.fromAxis(2.0, 3.0, 4.0));

    try expectMat(s, .{
        .{ 2.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 3.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 4.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    });

    try expectPoint(transform(s, .{ 1.0, 1.0, 1.0, 1.0 }), .{ 2.0, 3.0, 4.0, 1.0 });
    try expect(Mat4.equals(Mat4.scale(Mat4.identity(), Vec3.one()), Mat4.identity()));
}

test "transforms apply right to left" {
    const t = Vec3.fromAxis(10.0, 0.0, 0.0);
    const s = Vec3.fromAxis(2.0, 2.0, 2.0);

    // Scale is the rightmost factor, so it runs first and the offset is untouched
    const scale_then_move = Mat4.scale(Mat4.translate(Mat4.identity(), t), s);
    try expectPoint(transform(scale_then_move, .{ 1.0, 0.0, 0.0, 1.0 }), .{ 12.0, 0.0, 0.0, 1.0 });

    // The other way round the scale also doubles the offset
    const move_then_scale = Mat4.translate(Mat4.scale(Mat4.identity(), s), t);
    try expectPoint(transform(move_then_scale, .{ 1.0, 0.0, 0.0, 1.0 }), .{ 22.0, 0.0, 0.0, 1.0 });
}
