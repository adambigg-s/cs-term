const math = @import("std").math;
const lib = @import("root.zig");
const vec = lib.vec;

pub fn Mat3(comptime T: type) type {
    return struct {
        inner: [3][3]T,

        pub const dim = 3;

        const Self = @This();

        pub fn identity() Self {
            comptime var inner: [3][3]T = undefined;
            comptime for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    inner[i][j] = if (i == j) 1 else 0;
                }
            };

            return Self{ .inner = inner };
        }

        pub fn mulVec(self: *const Self, v: vec.Vec3(T)) vec.Vec3(T) {
            const m = self.inner;

            return vec.Vec3(T).build(
                m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
                m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
                m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
            );
        }
    };
}

pub fn Mat4(comptime T: type) type {
    return struct {
        inner: [4][4]T,

        pub const dim = 4;

        const Self = @This();

        pub fn identity() Self {
            comptime var inner: [4][4]T = undefined;
            comptime for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    inner[i][j] = if (i == j) 1 else 0;
                }
            };

            return Self{ .inner = inner };
        }

        pub fn mulVec(self: *const Self, v: vec.Vec4(T)) vec.Vec4(T) {
            const m = self.inner;

            return vec.Vec4(T).build(
                m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w,
                m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w,
                m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w,
                m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w,
            );
        }
    };
}

pub fn MatN(comptime N: usize, comptime T: type) type {
    return struct {
        inner: [N][N]T,

        pub const width = N;
        pub const height = N;
    };
}

test "matrix mul testing" {
    const matrix = Mat4(f32).identity();
    const vector = vec.Vec4(f32).build(10, 10, 99, 123);

    const prod = matrix.mulVec(vector);

    lib.std.debug.print("product: {any}\nmatrix: {any}\nvec: {any}", .{ prod, matrix, vector });
}
