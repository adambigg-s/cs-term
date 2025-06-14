const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;
const win = lib.win;
const ren = lib.ren;

pub const Simulation = struct {
    targets: std.ArrayList(Target),
    target_count: usize,
    target_size: f32,
    score: u16,
    spawn: ren.Box3,
    target_score: u16,
    player: Player,
    tick: usize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var simulation = Simulation{
            .targets = std.ArrayList(Target).init(allocator),
            .target_count = 10,
            .target_size = 10,
            .score = 0,
            .spawn = ren.Box3.build(
                vec.Vec3(f32).build(-500, -10, -500),
                vec.Vec3(f32).build(500, 150, 500),
            ),
            .target_score = 100,
            .player = Player.new(),
            .tick = 0,
        };
        simulation.addTarget();

        return simulation;
    }

    pub fn deinit(self: *Self) void {
        self.targets.deinit();
    }

    pub fn update(self: *Self, inputs: *Inputs) !void {
        self.player.update(inputs);
        if (inputs.mouse_click) {
            self.targetHit();
        }
        self.tick += 1;
    }

    pub fn isComplete(self: *Self) bool {
        return self.score >= self.target_score;
    }

    fn targetHit(self: *Self) void {
        for (self.targets.items, 0..self.targets.items.len) |target, index| {
            if (target.rayIntersection(self.player.pos, self.player.front)) {
                self.randomTargetIndex(index);
                self.score += 1;
            }
        }
    }

    fn randomTargetIndex(self: *Self, index: usize) void {
        self.targets.items[index] = self.randomTarget();
    }

    fn randomTarget(self: *Self) Target {
        return Target{
            .pos = lib.randomVec3().mulComponent(self.spawn.max),
            .size = self.target_size,
        };
    }

    fn addTarget(self: *Self) void {
        // ensure there is one target direclty where you spawn for debugging
        for (0..self.target_count) |_| {
            self.targets.append(self.randomTarget()) catch return;
        }
    }
};

pub const Target = struct {
    size: f32,
    pos: vec.Vec3(f32),

    const Self = @This();

    pub fn rayIntersection(self: *const Self, origin: vec.Vec3(f32), direction: vec.Vec3(f32)) bool {
        const relative = origin.sub(self.pos);
        const alpha = direction.innerProduct(direction);
        const beta = 2 * relative.innerProduct(direction);
        const gamma = relative.innerProduct(relative) - self.size * self.size;
        const discriminant = beta * beta - 4 * alpha * gamma;

        return discriminant > 0;
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
            .vertical_fov = math.degreesToRadians(45),
            .look_sensitivity = 1.2,
            .yaw_modifier = 0.02,
            .pitch_modifier = 0.02,
            .move_speed = 0.1,
            .near_plane = 0.01,
            .far_plane = 5000,
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
        if (inputs.key_r) {
            self.pos = self.pos.add(self.up.mul(self.move_speed));
        }
        if (inputs.key_f) {
            self.pos = self.pos.sub(self.up.mul(self.move_speed));
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

        self.yaw -= math.degreesToRadians(yaw_delta);
        self.pitch -= math.degreesToRadians(pitch_delta);
        self.pitch = math.clamp(self.pitch, math.degreesToRadians(-89), math.degreesToRadians(89));
    }

    fn updateVectors(self: *Self) void {
        self.front = vec.Vec3(f32).build(
            math.cos(self.pitch) * math.cos(self.yaw),
            math.sin(self.pitch),
            math.cos(self.pitch) * -math.sin(self.yaw),
        );
        self.front = self.front.normalize();

        self.right = self.front.crossProduct(self.world_up);
        self.right = self.right.normalize();

        self.up = self.right.crossProduct(self.front);
        self.up = self.up.normalize();
    }
};

pub const Inputs = struct {
    key_w: bool = false,
    key_a: bool = false,
    key_s: bool = false,
    key_d: bool = false,
    key_r: bool = false,
    key_f: bool = false,
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
        _ = win.getKeyState(win.vk_r);
        _ = win.getKeyState(win.vk_f);
        _ = win.getKeyState(win.vk_escape);
        _ = win.getKeyState(win.vk_mouse_lbutton);
        _ = win.setCursorPos(1920, 1080) catch unreachable;

        return Inputs{
            .mouse_delta = vec.Vec2(i32).zeros(),
            .mouse_pos = vec.Vec2(i32).build(1920, 1080),
        };
    }

    pub fn updateKeys(self: *Self) void {
        self.key_w = win.getKeyState(win.vk_w);
        self.key_a = win.getKeyState(win.vk_a);
        self.key_s = win.getKeyState(win.vk_s);
        self.key_d = win.getKeyState(win.vk_d);
        self.key_r = win.getKeyState(win.vk_r);
        self.key_f = win.getKeyState(win.vk_f);
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
