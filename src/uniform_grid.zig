const Array2D = @import("./fast_2d_array.zig").Array2D;
const std = @import("std");

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
    var result = Array2D(usize, width, height);
    return result;
}

const UniformGridSimple = CreateUniformGridSimple(1.0, 10.0, 10.0);

pub fn insert(grid: *UniformGridSimple, point: Point, value: usize, cell_size: f32) void {
    const coord: GridPoint = world_to_grid(&point, cell_size);
    const cell_center = .{
        .x = @intToFloat(f32, coord.x) * cell_size + (cell_size / 2.0),
        .y = @intToFloat(f32, coord.y) * cell_size + (cell_size / 2.0),
    };

    if (point.x > cell_center.x) {
        if (grid.try_get(coord.x + 1, coord.y)) |v| {
            v.* = value;
        }

        if (point.y > cell_center.y) {
            if (grid.try_get(coord.x + 1, coord.y + 1)) |v| {
                v.* = value;
            }
        }
    }

    if (point.x < cell_center.x) {
        if (coord.x != 0) {
            if (grid.try_get(coord.x - 1, coord.y)) |v| {
                v.* = value;
            }
        }

        if (point.y < cell_center.y) {
            if (coord.x != 0 and coord.y != 0) {
                if (grid.try_get(coord.x - 1, coord.y - 1)) |v| {
                    v.* = value;
                }
            }
        }
    }

    if (point.y > cell_center.y) {
        if (grid.try_get(coord.x, coord.y + 1)) |v| {
            v.* = value;
        }
    }

    if (point.y < cell_center.y) {
        if (coord.y != 0) {
            if (grid.try_get(coord.x, coord.y - 1)) |v| {
                v.* = value;
            }
        }
    }

    grid.get(coord.x, coord.y).* = value;
}

fn world_to_grid(point: *const Point, cell_size: f32) GridPoint {
    const x = @floatToInt(usize, std.math.floor(point.*.x / cell_size));
    const y = @floatToInt(usize, std.math.floor(point.*.y / cell_size));
    return GridPoint{ .x = x, .y = y };
}

test "test uniformgrid" {
    var grid = UniformGridSimple.init();
    std.debug.assert(grid.width == 10);
    std.debug.assert(grid.height == 10);
}

test "test insert" {
    var grid = UniformGridSimple.init();
    const point = Point{ .x = 1.0, .y = 1.0 };
    insert(&grid, point, 1, 1.0);
    std.debug.assert(grid.get(1, 1).* == 1);
}
