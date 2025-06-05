pub fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn build(x: T, y: T) Self {
            return Vec2(T){ .x = x, .y = y };
        }

        pub fn zeros() Self {
            return Vec2(T).build(0, 0);
        }

        pub fn neg(self: Self) Self {
            return Vec2(T).build(-self.x, -self.y);
        }

        pub fn add(self: Self, other: Self) Self {
            return Vec2(T).build(self.x + other.x, self.y + other.y);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Vec2(T).build(self.x - other.x, self.y - other.y);
        }

        pub fn mul(self: Self, scalar: T) Self {
            return Vec2(T).build(self.x * scalar, self.y * scalar);
        }

        pub fn div(self: Self, scalar: T) Self {
            const inv = 1 / scalar;
            return Vec2(T).build(self.x * inv, self.y * inv);
        }
    };
}

pub fn Vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub fn build(x: T, y: T, z: T) Self {
            return Vec2(T){ .x = x, .y = y, .z = z };
        }

        pub fn zeros() Self {
            return Vec3(T).build(0, 0, 0);
        }

        pub fn neg(self: Self) Self {
            return Vec3(T).build(-self.x, -self.y, -self.z);
        }

        pub fn add(self: Self, other: Self) Self {
            return Vec3(T).build(self.x + other.x, self.y + other.y, self.z + other.z);
        }

        pub fn sub(self: Self, other: Self) Self {
            return Vec3(T).build(self.x - other.x, self.y - other.y, self.z - other.z);
        }

        pub fn mul(self: Self, scalar: T) Self {
            return Vec3(T).build(self.x * scalar, self.y * scalar, self.z * scalar);
        }

        pub fn div(self: Self, scalar: T) Self {
            const inv = 1 / scalar;
            return Vec3(T).build(self.x * inv, self.y * inv, self.z * inv);
        }
    };
}
