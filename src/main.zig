const lib = @import("root.zig");

pub fn main() !void {
    var inputs = lib.Inputs.init();

    while (true) {
        inputs.update();
        lib.std.debug.print("\x1b[10Hinputs struct: {any}", .{inputs});

        if (inputs.key_escape) {
            break;
        }
    }
}
