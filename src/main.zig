const lib = @import("root.zig");

pub fn main() !void {
    const allocator = lib.std.heap.page_allocator;
    var app = lib.app.Application{
        .inputs = lib.sim.Inputs.init(),
        .simulation = try lib.app.Simulation.init(allocator, 5),
        .renderer = try lib.ren.Renderer.init(100, 50, allocator),
    };
    defer app.deinit();

    app.run();
}
