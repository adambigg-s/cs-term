const math = @import("std").math;

pub fn Mat3(comptime T: type) type {
    return struct {
        inner: [3][3]T,

        const Self = @This();

        const dim = 3;

        pub fn identity() Self {
            var inner = undefined;
            for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    inner[i][j] = if (i == j) 1 else 0;
                }
            }

            return Self{ .inner = inner };
        }
    };
}

pub fn Mat4(comptime T: type) type {
    return struct {
        inner: [4][4]T,

        const Self = @This();

        const dim = 4;

        pub fn identity() Self {
            var inner = undefined;
            for (0..Self.dim) |i| {
                for (0..Self.dim) |j| {
                    inner[i][j] = if (i == j) 1 else 0;
                }
            }

            return Self{ .inner = inner };
        }
    };
}
