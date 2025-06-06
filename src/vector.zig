pub const math = @import("std").math;

pub fn Vec2(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,

        const Self = @This();

        pub fn build(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn zeros() Self {
            return Self.build(0, 0);
        }

        pub fn splat(value: T) Self {
            return Self.build(value, value);
        }

        pub fn neg(self: Self) Self {
            return Self.build(-self.x, -self.y);
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.build(self.x + other.x, self.y + other.y);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self.build(self.x - other.x, self.y - other.y);
        }

        pub fn mul(self: Self, scalar: T) Self {
            return Self.build(self.x * scalar, self.y * scalar);
        }

        pub fn div(self: Self, scalar: T) Self {
            const inv = 1 / scalar;
            return Self.build(self.x * inv, self.y * inv);
        }

        pub fn inner_product(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
        }

        pub fn cross_product(self: Self, other: Self) T {
            return self.x * other.y - self.y * other.x;
        }

        pub fn length_sq(self: Self) T {
            return self.inner_product(self);
        }

        pub fn length(self: Self) T {
            return math.sqrt(self.length_sq());
        }

        pub fn normalize(self: Self) Self {
            return self.div(self.length());
        }

        pub fn mulComponent(self: Self, other: Self) Self {
            return Self.build(self.x * other.x, self.y * other.y);
        }
    };
}

pub fn Vec3(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,
        z: T = 0,

        const Self = @This();

        pub fn build(x: T, y: T, z: T) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn zeros() Self {
            return Self.build(0, 0, 0);
        }

        pub fn splat(value: T) Self {
            return Self.build(value, value, value);
        }

        pub fn neg(self: Self) Self {
            return Self.build(-self.x, -self.y, -self.z);
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.build(self.x + other.x, self.y + other.y, self.z + other.z);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self.build(self.x - other.x, self.y - other.y, self.z - other.z);
        }

        pub fn mul(self: Self, scalar: T) Self {
            return Self.build(self.x * scalar, self.y * scalar, self.z * scalar);
        }

        pub fn div(self: Self, scalar: T) Self {
            const inv = 1 / scalar;
            return Self.build(self.x * inv, self.y * inv, self.z * inv);
        }

        pub fn inner_product(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z;
        }

        pub fn cross_product(self: Self, other: Self) Self {
            return Self.build(
                self.y * other.z - self.z * other.y,
                self.x * other.z - self.z * other.x,
                self.x * other.y - self.y * other.x,
            );
        }

        pub fn length_sq(self: Self) T {
            return self.inner_product(self);
        }

        pub fn length(self: Self) T {
            return math.sqrt(self.length_sq());
        }

        pub fn rotateX(self: Self, angle: T) Self {
            const sin, const cos = .{ math.sin(angle), math.cos(angle) };

            return Self.build(
                self.x,
                self.y * cos + self.z * -sin,
                self.y * sin + self.z * cos,
            );
        }

        pub fn rotateY(self: Self, angle: T) Self {
            const sin, const cos = .{ math.sin(angle), math.cos(angle) };

            return Self.build(
                self.x * cos + self.z * sin,
                self.y,
                self.x * -sin + self.z * cos,
            );
        }

        pub fn rotateZ(self: Self, angle: T) Self {
            const sin, const cos = .{ math.sin(angle), math.cos(angle) };

            return Self.build(
                self.x * cos + self.y * -sin,
                self.x * sin + self.y * cos,
                self.z,
            );
        }

        pub fn rotateXYZ(self: Self, angles: Self) Self {
            return self.rotateX(angles.x).rotateY(angles.y).rotateZ(angles.z);
        }

        pub fn rotateZYX(self: Self, angles: Self) Self {
            return self.rotateZ(angles.z).rotateY(angles.y).rotateX(angles.x);
        }

        pub fn normalize(self: Self) Self {
            return self.div(self.length());
        }

        pub fn mulComponent(self: Self, other: Self) Self {
            return Self.build(self.x * other.x, self.y * other.y, self.z * other.z);
        }

        pub fn directionCosineVec(self: Self, xp: Self, yp: Self, zp: Self) Self {
            return Self.build(
                self.inner_product(xp),
                self.inner_product(yp),
                self.inner_product(zp),
            );
        }
    };
}
