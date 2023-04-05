const Verlet = @import("verlet.zig");
const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vec2 = @import("vec2.zig").Vec2;
const expect = @import("std").testing.expect;
const math = @import("std").math;

pub const UniformGrid = struct {
    grid: []ArrayList(*Verlet.VerletObject),
    circle_size: usize,
    allocator: Allocator,
    nb_col: usize,

    pub fn init(comptime window_width: usize, comptime window_height: usize, comptime circle_size: usize, allocator: Allocator) UniformGrid {
        var grid: [window_width / circle_size * window_height / circle_size]ArrayList(*Verlet.VerletObject) = undefined;
        for (0..grid.len) |index| {
            grid[index] = ArrayList(*Verlet.VerletObject).initCapacity(allocator, 10) catch unreachable;
        }

        return UniformGrid{
            .allocator = allocator,
            .circle_size = circle_size,
            .nb_col = window_width / circle_size,
            .grid = &grid,
        };
    }

    pub fn insert(self: *UniformGrid, obj: *Verlet.VerletObject) !void {
        const x = @floatToInt(usize, obj.position_current.x / @intToFloat(f32, self.circle_size));
        const y = @floatToInt(usize, obj.position_current.y / @intToFloat(f32, self.circle_size));

        const cell_center: Vec2 = Vec2.init(
            @intToFloat(f32, x * self.circle_size + self.circle_size / 2),
            @intToFloat(f32, y * self.circle_size + self.circle_size / 2),
        );

        const distance = obj.position_current.sub(cell_center);

        try self.insert_in_cell(x, x, obj);

        if (distance.x < 0) {
            const sub_x = math.sub(usize, x, 1) catch null;

            if (distance.y < 0) {
                // top left
                const sub_y = math.sub(usize, y, 1) catch null;

                if (sub_x != null) {
                    try self.insert_in_cell(sub_x.?, y, obj);
                }
                if (sub_y != null) {
                    try self.insert_in_cell(x, sub_y.?, obj);
                }
                if (sub_x != null and sub_y != null) {
                    try self.insert_in_cell(sub_x.?, sub_y.?, obj);
                }
            } else {
                // bottom left
                const add_y = math.add(usize, y, 1) catch null;

                if (sub_x != null) {
                    try self.insert_in_cell(sub_x.?, y, obj);
                }
                if (add_y != null) {
                    try self.insert_in_cell(x, add_y.?, obj);
                }
                if (sub_x != null and add_y != null) {
                    try self.insert_in_cell(sub_x.?, add_y.?, obj);
                }
            }
        } else {
            const add_x = math.sub(usize, x, 1) catch null;
            if (distance.y < 0) {
                // top right
                const sub_y = math.sub(usize, y, 1) catch null;

                if (add_x != null) {
                    try self.insert_in_cell(add_x.?, y, obj);
                }
                if (sub_y != null) {
                    try self.insert_in_cell(x, sub_y.?, obj);
                }
                if (add_x != null and sub_y != null) {
                    try self.insert_in_cell(add_x.?, sub_y.?, obj);
                }
            } else {
                // bottom right
                const add_y = math.add(usize, y, 1) catch null;

                if (add_x != null) {
                    try self.insert_in_cell(add_x.?, y, obj);
                }
                if (add_y != null) {
                    try self.insert_in_cell(x, add_y.?, obj);
                }
                if (add_x != null and add_y != null) {
                    try self.insert_in_cell(add_x.?, add_y.?, obj);
                }
            }
        }
    }

    pub fn insert_in_cell(self: *UniformGrid, x: usize, y: usize, obj: *Verlet.VerletObject) !void {
        const index = y * self.nb_col + x;
        const arr = &(self.grid[index]);
        try arr.append(obj);
    }

    pub fn deinit(self: *UniformGrid) void {
        for (self.grid) |cell| {
            cell.deinit();
        }
    }
};

test "grid insertion" {
    var allocator = std.testing.allocator;

    var grid = UniformGrid.init(100, 100, 20, allocator);
    //defer grid.deinit();

    var obj1 = Verlet.VerletObject.init(Vec2.init(11, 11), 10);

    try grid.insert(&obj1);

    //std.debug.print("\ngrid.len: {}\n", .{grid.grid.len});
    std.debug.print("\ngrid[0].items.len: {}\n", .{grid.grid[0].items.len});
    try expect(grid.grid[0].items.len == 1);
}
