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
            try self.inputs.updateKeys();
            try self.inputs.updatePos(1920, 1080);
            _ = win.SetCursorPos(1920, 1080);

            try self.simulation.update(&self.inputs);

            self.renderer.clear();
            self.renderer.renderSimulation(&self.simulation);
            try self.renderer.commitPass();

            // debugging stuff
            {
                std.debug.print("\x1b[20Hinputs printed: {any}\n", .{self.inputs});
                const handle = win.GetStdHandle(win.WIN_STD_HANDLE);
                var info: win.WinConsoleInfo = undefined;
                _ = win.GetConsoleScreenBufferInfo(handle, &info);
                std.debug.print("\x1b[22Hhandle: {any}\n", .{info});
                var font_info: win.WinConsoleFontInfo = undefined;
                _ = win.GetCurrentConsoleFont(win.WIN_STD_HANDLE, win.WIN_CONSOLE_CURRENT, &font_info);
                std.debug.print("\x1b[23Hfont: {any}\n", .{font_info});
            }
        }
    }
};
