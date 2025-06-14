const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;

pub fn Mat2(comptime T: type) type {
    return struct {
        inner: [Self.dim][Self.dim]T,

        pub const dim = 2;

        const Self = @This();

        pub fn identity() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = if (i == j) 1 else 0;
                    }
                }
            }
            return Self{ .inner = inner };
        }

        pub fn zeros() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = 0;
                    }
                }
            }

            return Self{ .inner = inner };
        }

        pub fn mulVec(self: *const Self, vector: vec.Vec2(T)) vec.Vec2(T) {
            const m = self.inner;
            const v = vector;

            return vec.Vec3(T).build(
                m[0][0] * v.x + m[0][1] * v.y,
                m[1][0] * v.x + m[1][1] * v.y,
            );
        }

        pub fn mulMat(self: *const Self, other: *const Self) Self {
            const a = self.inner;
            const b = other.inner;

            var inner: [Self.dim][Self.dim]T = Self.zeros().inner;

            for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    for (0..Self.dim) |k| {
                        inner[i][j] += a[i][k] * b[k][j];
                    }
                }
            }

            return Self{ .inner = inner };
        }
    };
}

pub fn Mat3(comptime T: type) type {
    return struct {
        inner: [Self.dim][Self.dim]T,

        pub const dim = 3;

        const Self = @This();

        pub fn identity() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = if (i == j) 1 else 0;
                    }
                }
            }
            return Self{ .inner = inner };
        }

        pub fn zeros() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = 0;
                    }
                }
            }

            return Self{ .inner = inner };
        }

        pub fn mulVec(self: *const Self, vector: vec.Vec3(T)) vec.Vec3(T) {
            const m = self.inner;
            const v = vector;

            return vec.Vec3(T).build(
                m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
                m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
                m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
            );
        }

        pub fn mulMat(self: *const Self, other: *const Self) Self {
            const a = self.inner;
            const b = other.inner;

            var inner: [Self.dim][Self.dim]T = Self.zeros().inner;

            for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    for (0..Self.dim) |k| {
                        inner[i][j] += a[i][k] * b[k][j];
                    }
                }
            }

            return Self{ .inner = inner };
        }
    };
}

pub fn Mat4(comptime T: type) type {
    return struct {
        inner: [Self.dim][Self.dim]T,

        pub const dim = 4;

        const Self = @This();

        pub fn identity() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = if (i == j) 1 else 0;
                    }
                }
            }
            return Self{ .inner = inner };
        }

        pub fn zeros() Self {
            comptime var inner: [Self.dim][Self.dim]T = undefined;
            comptime {
                for (0..Self.dim) |i| {
                    for (0..Self.dim) |j| {
                        inner[i][j] = 0;
                    }
                }
            }

            return Self{ .inner = inner };
        }

        pub fn mulVec(self: *const Self, vector: vec.Vec4(T)) vec.Vec4(T) {
            const m = self.inner;
            const v = vector;

            return vec.Vec4(T).build(
                m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w,
                m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w,
                m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w,
                m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w,
            );
        }

        pub fn mulMat(self: *const Self, other: *const Self) Self {
            const a = self.inner;
            const b = other.inner;

            var inner: [Self.dim][Self.dim]T = Self.zeros().inner;

            for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    for (0..Self.dim) |k| {
                        inner[i][j] += a[i][k] * b[k][j];
                    }
                }
            }

            return Self{ .inner = inner };
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

test "matrix vec mul testing" {
    const matrix = Mat4(f32).identity();
    const vector = vec.Vec4(f32).build(10, 10, 99, 123);

    const prod = matrix.mulVec(vector);

    std.debug.print("product: {any}\nmatrix: {any}\nvec: {any}\n", .{ prod, matrix, vector });
    try std.testing.expect(std.meta.eql(vector, prod));
}

test "matrix matrix mul testing" {
    const matrix1 = Mat4(f32).identity();
    const matrix2 = Mat4(f32).identity();

    const prod = matrix1.mulMat(&matrix2);

    std.debug.print("product: {any}\n", .{prod});
    try std.testing.expect(std.meta.eql(matrix1, prod));
}
