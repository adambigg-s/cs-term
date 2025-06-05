const lib = @import("root.zig");
const vec = lib.vec;
const sim = lib.sim;
const ren = lib.ren;
const win = lib.win;
const std = lib.std;

pub const Application = struct {
    inputs: sim.Inputs,
    simulation: sim.Simulation,
    renderer: ren.Renderer,

    const Self = @This();

    pub fn run(self: *Self) !void {
        while (!self.inputs.key_escape) {
            self.inputs.update();

            std.debug.print("\x1b[20Hinputs printed: {any}\n", .{self.inputs});

            _ = win.SetCursorPos(1920, 1080);
            const handle = win.GetStdHandle(win.WIN_STD_HANDLE);
            var info: win.WinConsoleInfo = undefined;
            _ = win.GetConsoleScreenBufferInfo(handle, &info);

            std.debug.print("\x1b[22Hhandle: {any}\n", .{info});

            _ = self.renderer.main.set(10, 10, '#');

            try self.renderer.renderScene();
        }
    }

    pub fn deinit(self: *Self) void {
        self.simulation.deinit();
        self.renderer.deinit();
    }
};
