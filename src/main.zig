const std = @import("std");

const MyError = error{
    Omg,
    SoNoob,
};

pub fn main() void {
    var value: i32 = undefined;
    value = errorTest() catch |err| switch (err) {
        error.Omg => 10,
        error.SoNoob => 20,
    };
    std.debug.print("{d}\n", .{value});
}

pub fn errorTest() MyError!i32 {
    return MyError.Omg;
}
