const lib = @import("root.zig");

pub fn main() !void {
    var general_allocator = lib.std.heap.DebugAllocator(.{}).init;
    defer {
        const log = general_allocator.deinit();
        lib.std.debug.print("allocator status: {}", .{log});
    }
    const allocator = general_allocator.allocator();

    var app = lib.app.Application{
        .inputs = lib.sim.Inputs.init(),
        .simulation = try lib.sim.Simulation.init(allocator, 5),
        .renderer = try lib.ren.Renderer.init(100, 50, allocator),
    };
    defer app.deinit();

    app.run();
}
