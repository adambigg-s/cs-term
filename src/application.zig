const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;
const sim = lib.sim;
const ren = lib.ren;
const win = lib.win;

pub const Application = struct {
    inputs: sim.Inputs,
    simulation: sim.Simulation,
    renderer: ren.Renderer,

    const Self = @This();

    pub fn run(self: *Self) void {
        while (!self.inputs.key_escape) {
            self.inputs.update();

            std.debug.print("\x1b[20Hinputs printed: {any}\n", .{self.inputs});

            _ = win.SetCursorPos(1920, 1080);
        }
    }

    pub fn deinit(self: *Self) void {
        self.simulation.deinit();
        self.renderer.deinit();
    }
};
