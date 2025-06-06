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

    pub fn deinit(self: *Self) void {
        self.simulation.deinit();
        self.renderer.deinit();
    }

    pub fn run(self: *Self) !void {
        while (!self.inputs.key_escape) {
            try self.inputs.updateDeltas();
            self.inputs.updateKeys();
            self.inputs.updatePos(1920, 1080);
            try win.setCursorPos(1920, 1080);

            try self.simulation.update(&self.inputs);

            self.renderer.clear();
            self.renderer.renderSimulation(&self.simulation);
            try self.renderer.commitPass();

            // debugging stuff
            {
                const info = win.getConsoleScreenBufferInfo() catch null;
                std.debug.print("\x1b[10Hinfo: {any}\n", .{info});
                std.debug.print("buffer size: {}, {}\n", .{ self.renderer.width, self.renderer.height });
                std.debug.print("inputs struct: {any}", .{self.inputs});
            }
        }
    }
};
