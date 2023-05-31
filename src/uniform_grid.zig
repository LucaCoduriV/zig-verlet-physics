const Array2D = @import("./fast_2d_array.zig").Array2D;
const std = @import("std");

const WINDOW_DIMENSION = .{
    .HEIGHT = 10,
    .WIDTH = 10,
};

const Point = struct {
    x: f32,
    y: f32,
};

const GridPoint = struct {
    x: usize,
    y: usize,
};

pub fn CreateUniformGridSimple(comptime cell_size: f32, comptime world_width: f32, comptime world_height: f32) type {
    const width = @floatToInt(usize, std.math.ceil(world_width / cell_size));
    const height = @floatToInt(usize, std.math.ceil(world_height / cell_size));
    var result = Array2D(std.ArrayList(usize), width, height);
    return result;
}

pub const UniformGridSimple = CreateUniformGridSimple(1.0, WINDOW_DIMENSION.WIDTH, WINDOW_DIMENSION.HEIGHT);

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

fn world_to_grid(point: *const Point, cell_size: f32) GridPoint {
    const x = @floatToInt(usize, std.math.floor(point.*.x / cell_size));
    const y = @floatToInt(usize, std.math.floor(point.*.y / cell_size));
    return GridPoint{ .x = x, .y = y };
}

pub fn clear_uniform_grid_simple(grid: *UniformGridSimple) void {
    for (grid.get_as_1D()) |*item| {
        item.*.clearAndFree();
    }
}

test "test uniformgrid" {
    var grid = UniformGridSimple.init();
    const test_allocator = std.testing.allocator;
    for (grid.get_as_1D()) |*item| {
        item.* = std.ArrayList(usize).init(test_allocator);
    }
    std.debug.assert(grid.width == 10);
    std.debug.assert(grid.height == 10);

    for (grid.get_as_1D()) |*item| {
        item.*.deinit();
    }
}

test "test insert" {
    var grid = UniformGridSimple.init();
    const test_allocator = std.testing.allocator;
    for (grid.get_as_1D()) |*item| {
        item.* = std.ArrayList(usize).init(test_allocator);
    }
    const point = Point{ .x = 1.0, .y = 1.0 };
    insert(&grid, point, 1, 1.0);
    std.debug.assert(grid.get(1, 1).*.items.len == 1);

    clear_uniform_grid_simple(&grid);
    for (grid.get_as_1D()) |*item| {
        std.debug.assert(item.*.items.len == 0);
    }

    grid.get_as_1D()[0].append(183) catch unreachable;
    std.debug.assert(grid.get_as_1D()[0].getLast() == 183);

    for (grid.get_as_1D()) |*item| {
        item.*.deinit();
    }
}
