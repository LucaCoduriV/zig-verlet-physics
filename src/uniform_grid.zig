const Array2D = @import("./fast_2d_array.zig").Array2D;
const std = @import("std");
const Allocator = std.mem.Allocator;

const WINDOW_DIMENSION = .{
    .HEIGHT = 1000,
    .WIDTH = 1000,
};

pub const Point = struct {
    x: f32,
    y: f32,
};

const GridPoint = struct {
    x: usize,
    y: usize,
};

pub const UniformGridSimple = Array2D(std.ArrayList(usize));

pub fn init(cell_size: f32, world_width: f32, world_height: f32, allocator: Allocator) UniformGridSimple {
    const width = @floatToInt(usize, std.math.ceil(world_width / cell_size));
    const height = @floatToInt(usize, std.math.ceil(world_height / cell_size));
    var grid = UniformGridSimple.init(allocator, width, height);

    for (0..height * width) |_| {
        grid.data.append(std.ArrayList(usize).init(allocator)) catch unreachable;
    }

    return grid;
}

pub fn insert(grid: *UniformGridSimple, point: Point, value: usize, cell_size: f32) void {
    const coord: GridPoint = world_to_grid(&point, cell_size);
    const cell_center = .{
        .x = @intToFloat(f32, coord.x) * cell_size + (cell_size / 2.0),
        .y = @intToFloat(f32, coord.y) * cell_size + (cell_size / 2.0),
    };

    if (point.x > cell_center.x) {
        if (grid.try_get(coord.x + 1, coord.y)) |v| {
            v.*.append(value) catch unreachable;
        }

        if (point.y > cell_center.y) {
            if (grid.try_get(coord.x + 1, coord.y + 1)) |v| {
                v.*.append(value) catch unreachable;
            }
        }
    }

    if (point.x < cell_center.x) {
        if (coord.x != 0) {
            if (grid.try_get(coord.x - 1, coord.y)) |v| {
                v.*.append(value) catch unreachable;
            }
        }

        if (point.y < cell_center.y) {
            if (coord.x != 0 and coord.y != 0) {
                if (grid.try_get(coord.x - 1, coord.y - 1)) |v| {
                    v.*.append(value) catch unreachable;
                }
            }
        }
    }

    if (point.y > cell_center.y) {
        if (grid.try_get(coord.x, coord.y + 1)) |v| {
            v.*.append(value) catch unreachable;
        }
    }

    if (point.y < cell_center.y) {
        if (coord.y != 0) {
            if (grid.try_get(coord.x, coord.y - 1)) |v| {
                v.*.append(value) catch unreachable;
            }
        }
    }

    grid.get(coord.x, coord.y).*.append(value) catch unreachable;
}

// used to transform a point in the world to a grid point
fn world_to_grid(point: *const Point, cell_size: f32) GridPoint {
    const x = @floatToInt(usize, point.*.x / cell_size);
    const y = @floatToInt(usize, point.*.y / cell_size);
    return GridPoint{ .x = x, .y = y };
}

pub fn clear_uniform_grid_simple(grid: *UniformGridSimple) void {
    for (grid.get_as_1D()) |*item| {
        item.*.clearAndFree();
    }
}

test "test uniformgrid" {
    const test_allocator = std.testing.allocator;
    var grid = init(10, 1000, 1000, test_allocator);
    for (grid.get_as_1D()) |*item| {
        item.* = std.ArrayList(usize).init(test_allocator);
    }
    std.debug.assert(grid.width == 1000 / 10);
    std.debug.assert(grid.height == 1000 / 10);

    grid.deinit();
}

test "test insert" {
    const test_allocator = std.testing.allocator;
    var grid = init(1, 10, 10, test_allocator);
    for (grid.get_as_1D()) |*item| {
        item.* = std.ArrayList(usize).init(test_allocator);
    }
    const point = Point{ .x = 1.0, .y = 1.0 };
    insert(&grid, point, 1, 1);
    std.debug.assert(grid.get(1, 1).*.items.len == 1);
    std.debug.print("\n", .{});
    for (0..10) |y| {
        for (0..10) |x| {
            std.debug.print("{} ", .{grid.get(x, y).*.items.len});
        }
        std.debug.print("\n", .{});
    }

    clear_uniform_grid_simple(&grid);
    for (grid.get_as_1D()) |*item| {
        std.debug.assert(item.*.items.len == 0);
    }

    grid.get_as_1D()[0].append(183) catch unreachable;
    std.debug.assert(grid.get_as_1D()[0].getLast() == 183);

    clear_uniform_grid_simple(&grid);
    grid.deinit();
}
