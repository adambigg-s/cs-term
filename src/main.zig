const lib = @import("root.zig");

pub fn main() !void {
    var general_allocator = lib.std.heap.DebugAllocator(.{}).init;
    defer {
        const log = general_allocator.deinit();
        lib.std.debug.print("allocator status: {}", .{log});
    }

    var app = lib.app.Application{
        .inputs = lib.sim.Inputs.init(),
        .simulation = try lib.sim.Simulation.init(general_allocator.allocator(), 3),
        .renderer = try lib.ren.Renderer.init(general_allocator.allocator()),
    };
    defer app.deinit();

    try app.run();
}
