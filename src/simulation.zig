const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;
const win = lib.win;

pub const Simulation = struct {
    targets: std.ArrayList(Target),
    player: Player,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, target_count: usize) !Self {
        return Simulation{
            .targets = try std.ArrayList(Target).initCapacity(allocator, target_count),
            .player = Player.new(),
        };
    }

    pub fn deinit(self: *Self) void {
        self.targets.deinit();
    }

    pub fn update(self: *Self) !void {
        self.player.update();
    }
};

pub const Player = struct {
    pos: vec.Vec3(f32),
    front: vec.Vec3(f32),
    right: vec.Vec3(f32),
    up: vec.Vec3(f32),
    pitch: f32,
    yaw: f32,

    const Self = @This();
    const math = lib.std.math;

    pub fn new() Self {
        return Player{
            .pos = vec.Vec3(f32).zeros(),
            .front = vec.Vec3(f32).zeros(),
            .right = vec.Vec3(f32).zeros(),
            .up = vec.Vec3(f32).build(0, 1, 0),
            .pitch = 0,
            .yaw = 0,
        };
    }

    pub fn update(self: *Self) void {
        self.updateVectors();
    }

    pub fn updateVectors(self: *Self) void {
        self.front = vec.Vec3(f32).build(
            math.cos(self.yaw) * math.cos(self.pitch),
            math.sin(self.pitch),
            math.sin(self.yaw) * math.cos(self.pitch),
        );
        self.front = self.front.normalize();
        self.right = self.front.cross_product(self.up).normalize();
    }
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
        _ = win.GetAsyncKeyState(win.VK_W);
        _ = win.GetAsyncKeyState(win.VK_A);
        _ = win.GetAsyncKeyState(win.VK_S);
        _ = win.GetAsyncKeyState(win.VK_D);
        _ = win.GetAsyncKeyState(win.VK_ESCAPE);
        _ = win.GetAsyncKeyState(win.MOUSE_LBUTTON);

        return Inputs{
            .mouse_delta = vec.Vec2(i32).zeros(),
            .mouse_pos = vec.Vec2(i32).zeros(),
        };
    }

    pub fn update(self: *Self) !void {
        self.key_w = win.GetAsyncKeyState(win.VK_W) != win.WIN_KEY_FALSE;
        self.key_a = win.GetAsyncKeyState(win.VK_A) != win.WIN_KEY_FALSE;
        self.key_s = win.GetAsyncKeyState(win.VK_S) != win.WIN_KEY_FALSE;
        self.key_d = win.GetAsyncKeyState(win.VK_D) != win.WIN_KEY_FALSE;
        self.key_escape = win.GetAsyncKeyState(win.VK_ESCAPE) != win.WIN_KEY_FALSE;
        self.mouse_click = win.GetAsyncKeyState(win.MOUSE_LBUTTON) != win.WIN_KEY_FALSE;

        var point: win.WinPoint = undefined;
        _ = win.GetCursorPos(&point);
        const new_pos = lib.vec2FromPoint(point);
        self.mouse_delta = new_pos.sub(self.mouse_pos);
        self.mouse_pos = new_pos;
    }
};

pub const Target = struct {
    size: f32,
    pos: vec.Vec3(f32),
};
