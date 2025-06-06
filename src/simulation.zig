const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;
const win = lib.win;

pub const Simulation = struct {
    targets: std.ArrayList(Target),
    target_count: usize,
    player: Player,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, target_count: usize) !Self {
        var simulation = Simulation{
            .targets = try std.ArrayList(Target).initCapacity(allocator, target_count),
            .target_count = target_count,
            .player = Player.new(),
        };
        simulation.targets.expandToCapacity();
        simulation.randomTargets();

        return simulation;
    }

    pub fn deinit(self: *Self) void {
        self.targets.deinit();
    }

    pub fn update(self: *Self, inputs: *Inputs) !void {
        self.player.update(inputs);
    }

    fn randomTargets(self: *Self) void {
        for (0..self.target_count) |index| {
            const target = Target{
                .pos = lib.randomVec3().mulComponent(vec.Vec3(f32).build(5, 0, 5)),
                .size = 5,
            };
            self.targets.items[index] = target;
        }
    }
};

pub const Player = struct {
    pos: vec.Vec3(f32),
    front: vec.Vec3(f32),
    right: vec.Vec3(f32),
    up: vec.Vec3(f32),
    world_up: vec.Vec3(f32),
    pitch: f32,
    yaw: f32,
    vertical_fov: f32,
    look_sensitivity: f32,
    yaw_modifier: f32,
    pitch_modifier: f32,
    move_speed: f32,
    near_plane: f32,
    far_plane: f32,

    const Self = @This();

    const math = lib.std.math;

    pub fn new() Self {
        return Player{
            .pos = vec.Vec3(f32).zeros(),
            .front = vec.Vec3(f32).zeros(),
            .right = vec.Vec3(f32).zeros(),
            .up = vec.Vec3(f32).zeros(),
            .world_up = vec.Vec3(f32).build(0, 1, 0),
            .pitch = 0,
            .yaw = 0,
            .vertical_fov = math.degreesToRadians(55),
            .look_sensitivity = 2.5,
            .yaw_modifier = 0.01,
            .pitch_modifier = 0.01,
            .move_speed = 0.03,
            .near_plane = 0.1,
            .far_plane = 1000,
        };
    }

    pub fn update(self: *Self, inputs: *Inputs) void {
        self.updateTranslation(inputs);
        self.updateRotation(inputs);
        self.updateVectors();
    }

    fn updateTranslation(self: *Self, inputs: *Inputs) void {
        if (inputs.key_w) {
            self.pos = self.pos.add(self.front.mul(self.move_speed));
        }
        if (inputs.key_s) {
            self.pos = self.pos.sub(self.front.mul(self.move_speed));
        }
        if (inputs.key_a) {
            self.pos = self.pos.sub(self.right.mul(self.move_speed));
        }
        if (inputs.key_d) {
            self.pos = self.pos.add(self.right.mul(self.move_speed));
        }
    }

    fn updateRotation(self: *Self, inputs: *Inputs) void {
        const mouse_dx: f32, const mouse_dy: f32 = .{
            @floatFromInt(inputs.mouse_delta.x),
            @floatFromInt(inputs.mouse_delta.y),
        };
        const yaw_delta, const pitch_delta = .{
            mouse_dx * self.look_sensitivity * self.yaw_modifier,
            mouse_dy * self.look_sensitivity * self.pitch_modifier,
        };

        self.yaw += math.degreesToRadians(yaw_delta);
        self.pitch -= math.degreesToRadians(pitch_delta);

        self.pitch = math.clamp(self.pitch, math.degreesToRadians(-80), math.degreesToRadians(80));
    }

    fn updateVectors(self: *Self) void {
        self.front = vec.Vec3(f32).build(
            math.cos(self.yaw) * math.cos(self.pitch),
            math.sin(self.pitch),
            math.sin(self.yaw) * math.cos(self.pitch),
        );
        self.right = self.front.cross_product(self.world_up);
        self.up = self.right.cross_product(self.front);

        self.front = self.front.normalize();
        self.right = self.right.normalize();
        self.up = self.up.normalize();
    }
};

pub const Target = struct {
    size: f32,
    pos: vec.Vec3(f32),
};

pub const Inputs = struct {
    key_w: bool = false,
    key_a: bool = false,
    key_s: bool = false,
    key_d: bool = false,
    key_escape: bool = false,
    mouse_click: bool = false,
    mouse_delta: vec.Vec2(i32),
    mouse_pos: vec.Vec2(i32),

    const Self = @This();

    pub fn init() Self {
        // this prevents bugs where the first call is ub
        _ = win.getKeyState(win.vk_w);
        _ = win.getKeyState(win.vk_a);
        _ = win.getKeyState(win.vk_s);
        _ = win.getKeyState(win.vk_d);
        _ = win.getKeyState(win.vk_escape);
        _ = win.getKeyState(win.vk_mouse_lbutton);

        return Inputs{
            .mouse_delta = vec.Vec2(i32).zeros(),
            .mouse_pos = vec.Vec2(i32).zeros(),
        };
    }

    pub fn updateKeys(self: *Self) void {
        self.key_w = win.getKeyState(win.vk_w);
        self.key_a = win.getKeyState(win.vk_a);
        self.key_s = win.getKeyState(win.vk_s);
        self.key_d = win.getKeyState(win.vk_d);
        self.key_escape = win.getKeyState(win.vk_escape);
        self.mouse_click = win.getKeyState(win.vk_mouse_lbutton);
    }

    pub fn updateDeltas(self: *Self) !void {
        const x, const y = try win.getCursorPosition();
        self.mouse_delta = vec.Vec2(i32).build(x, y).sub(self.mouse_pos);
    }

    pub fn updatePos(self: *Self, x: i32, y: i32) void {
        self.mouse_pos.x = x;
        self.mouse_pos.y = y;
    }
};
