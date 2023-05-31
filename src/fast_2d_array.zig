const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn Array2D(comptime T: type) type {
    return struct {
        height: usize,
        width: usize,
        data: ArrayList(T),

        const Array2DType = Array2D(T);

        pub fn init(allocator: Allocator, width: usize, height: usize) Array2DType {
            return Array2DType{
                .height = height,
                .width = width,
                .data = ArrayList(T).initCapacity(allocator, height * width) catch unreachable,
            };
        }

        pub fn insert(self: *Array2DType, data: T, x: usize, y: usize) void {
            self.data.items[y * self.width + x] = data;
        }

        pub fn get(self: *Array2DType, x: usize, y: usize) *T {
            return &self.data.items[y * self.width + x];
        }

        pub fn try_get(self: *Array2DType, x: usize, y: usize) ?*T {
            if (self.is_in_bounds(x, y)) {
                return self.get(x, y);
            }
            return null;
        }

        pub fn get_width(self: *Array2DType) usize {
            return self.width;
        }

        pub fn get_height(self: *Array2DType) usize {
            return self.height;
        }

        pub fn get_size(self: *Array2DType) usize {
            return self.height * self.width;
        }

        pub fn is_in_bounds(self: *Array2DType, x: usize, y: usize) bool {
            return x < self.width and y < self.height;
        }

        pub fn debug_print(self: *Array2DType) void {
            for (0..self.height) |y| {
                for (0..self.width) |x| {
                    std.debug.print("{} ", .{self.get(x, y).*});
                }
                std.debug.print("\n", .{});
            }
        }

        pub fn get_as_1D(self: *Array2DType) []T {
            return &self.data.items;
        }

        pub fn deinit(self: *Array2DType) void {
            self.data.deinit();
        }
    };
}

test "fast2darray test" {
    const assert = @import("std").debug.assert;
    const x: usize = 2;
    const test_allocator = std.testing.allocator;

    var array = Array2D(i32).init(test_allocator, x, x);
    for (0..x * x) |_| {
        array.data.append(0) catch unreachable;
    }
    array.insert(1, 0, 0);
    array.insert(2, 1, 0);
    array.insert(3, 0, 1);
    array.insert(4, 1, 1);

    assert(array.get(0, 0).* == 1);
    assert(array.get(1, 0).* == 2);
    assert(array.get(0, 1).* == 3);
    assert(array.get(1, 1).* == 4);

    assert(array.try_get(0, 0).? == array.get(0, 0));
    assert(array.try_get(2, 2) == null);

    array.get(0, 0).* = 6;
    assert(array.get(0, 0).* == 6);

    assert(array.get_width() == 2);
    assert(array.get_height() == 2);
    assert(array.get_size() == 4);
    assert(array.is_in_bounds(2, 2) == false);
    assert(array.is_in_bounds(1, 1) == true);
    std.debug.print("array:\n", .{});
    array.debug_print();

    array.deinit();
}
