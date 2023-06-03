const Vec2 = @import("vec2.zig").Vec2;
const std = @import("std");
const UniformGridSimple = @import("uniform_grid.zig").UniformGridSimple;
const Point = @import("uniform_grid.zig").Point;
const Allocator = std.mem.Allocator;
const UniformGrid = @import("uniform_grid.zig");
const insert = UniformGrid.insert;
const init = UniformGrid.init;
const clear_uniform_grid = UniformGrid.clear_uniform_grid_simple;

pub const VerletObject = struct {
    position_current: Vec2,
    position_previous: Vec2,
    acceleration: Vec2,
    radius: f32,

    pub fn init(position_current: Vec2, radius: f32) VerletObject {
        return VerletObject{
            .position_current = position_current,
            .position_previous = position_current,
            .acceleration = Vec2.init(0.0, 0.0),
            .radius = radius,
        };
    }

    fn update_position(self: *VerletObject, dt: f32) void {
        const velocity = self.position_current.sub(self.position_previous);
        self.position_previous = self.position_current;
        self.position_current = self.position_current.add(velocity).add(self.acceleration.mul(dt * dt));

        self.acceleration = Vec2.init(0.0, 0.0);
    }

    fn accelerate(self: *VerletObject, acceleration: Vec2) void {
        self.acceleration = self.acceleration.add(acceleration);
    }

    fn set_velocity(self: *VerletObject, velocity: Vec2, dt: f32) void {
        self.position_previous = self.position_current.sub(velocity.mul(dt));
    }
};

pub const Solver = struct {
    gravity: Vec2,
    sub_steps: u32,
    world_height: f32,
    world_width: f32,
    cell_size: f32,
    grid: UniformGridSimple,

    pub fn init(sub_steps: u32, world_width: f32, world_height: f32, cell_size: f32, allocator: Allocator) Solver {
        // var grid = UniformGridSimple.init(allocator, @floatToInt(usize, world_width), @floatToInt(usize, world_width));
        var grid = UniformGrid.init(cell_size, world_width, world_height, allocator);

        // for (grid.get_as_1D()) |*item| {
        //     item.* = std.ArrayList(usize).init(allocator);
        // }

        return Solver{
            .gravity = Vec2.init(0.0, 0.3),
            .sub_steps = sub_steps,
            .world_height = world_height,
            .world_width = world_width,
            .cell_size = cell_size,
            .grid = grid,
        };
    }

    pub fn update(self: *Solver, objects: []VerletObject, dt: f32) void {
        var i: usize = 0;
        self.apply_gravity(objects);
        while (i < self.sub_steps) : (i += 1) {
            self.solve_collision(objects);
        }
        self.apply_constraints(objects);
        const subdt: f32 = @intToFloat(f32, self.sub_steps);
        Solver.update_position(objects, dt / subdt);
    }

    fn update_position(objects: []VerletObject, dt: f32) void {
        for (objects) |*object| {
            object.update_position(dt);
        }
    }

    fn apply_gravity(self: *Solver, objects: []VerletObject) void {
        for (objects) |*object| {
            object.accelerate(self.gravity);
        }
    }

    fn apply_constraints(self: *Solver, objects: []VerletObject) void {
        // for (objects) |*object| {
        //     if (object.position_current.x < object.radius) {
        //         object.position_current.x = object.radius;
        //         object.position_previous.x = object.position_current.x;
        //     } else if (object.position_current.x > self.world_width - object.radius) {
        //         object.position_current.x = self.world_width - object.radius;
        //         object.position_previous.x = object.position_current.x;
        //     }

        //     if (object.position_current.y < object.radius) {
        //         object.position_current.y = object.radius;
        //         object.position_previous.y = object.position_current.y;
        //     } else if (object.position_current.y > self.world_height - object.radius) {
        //         object.position_current.y = self.world_height - object.radius;
        //         object.position_previous.y = object.position_current.y;
        //     }
        // }

        var constraintCenter = Vec2.init(self.world_width / 2.0, self.world_height / 2.0);
        var constraintRadius: f32 = self.world_width / 2.0;

        for (objects) |*object| {
            var v = constraintCenter.sub(object.position_current);
            var dist = v.length();
            if (dist > (constraintRadius - object.radius)) {
                var n = v.div(dist);
                object.position_current = constraintCenter.add(n.mul(object.radius - constraintRadius));
            }
        }
    }

    fn solve_collision(self: *Solver, objects: []VerletObject) void {
        clear_uniform_grid(&self.grid);

        for (objects, 0..) |*object, i| {
            // std.debug.print("iciiii {}\n", .{i});
            self.replace_in_world(object);
            insert(&self.grid, Point{ .x = object.position_current.x, .y = object.position_current.y }, i, self.cell_size);
        }

        // for (objects, 0..) |*object_a, i_a| {
        //     for (objects, 0..) |*object_b, i_b| {
        //         if (i_a != i_b) {
        //             Solver.solve_object_to_object_collision(object_a, object_b);
        //         }
        //     }
        // }

        for (0..@floatToInt(usize, self.world_width / self.cell_size)) |x| {
            for (0..@floatToInt(usize, self.world_height / self.cell_size)) |y| {
                var cell = self.grid.get(x, y).*.items;

                if (cell.len > 1) {
                    // std.debug.print("len : {}", .{cell.len});

                    for (cell, 0..) |object_a_index, i| {
                        for (cell, 0..) |object_b_index, j| {
                            if (i != j) {
                                var object_a = &objects[object_a_index];
                                var object_b = &objects[object_b_index];
                                // object_a.position_current = Vec2.init(500, 500);
                                Solver.solve_object_to_object_collision(object_a, object_b);
                            }
                        }
                    }

                    // for (cell) |object_a_index| {
                    //     for (cell) |object_b_index| {
                    //         if (object_a_index != object_b_index) {
                    //             // std.debug.print("\nindex a : {}, index b : {}\n", .{ object_a_index, object_b_index });
                    //             if (object_a_index < object_b_index) {
                    //                 var object_a = objects[object_a_index];
                    //                 var object_b = objects[object_b_index];
                    //                 _ = object_b;
                    //                 object_a.position_current = Vec2.init(500, 500);
                    //                 // Solver.solve_object_to_object_collision(&object_a, &object_b);
                    //             }
                    //         }
                    //     }
                    // }
                }
            }
        }
    }

    fn solve_object_to_object_collision(object_a: *VerletObject, object_b: *VerletObject) void {
        const collision_axis: Vec2 = object_a.position_current.sub(object_b.position_current);
        const distance = collision_axis.length();
        const distance_length_difference = (object_a.radius + object_b.radius) - distance;

        // if collision
        if (distance_length_difference > 0) {
            const distance_normal = collision_axis.div(distance);
            const distance_difference = distance_normal.mul(distance_length_difference);

            object_a.position_current = object_a.position_current.add(distance_difference.mul(0.5));
            object_b.position_current = object_b.position_current.sub(distance_difference.mul(0.5));
        }
    }

    fn replace_in_world(self: *Solver, object: *VerletObject) void {
        if (object.position_current.x < 0) {
            object.position_current = Vec2.init(0.0, object.position_current.y);
        } else if (object.position_current.x > self.world_width) {
            object.position_current = Vec2.init(self.world_width - 1.0, object.position_current.y);
        }
        if (object.position_current.y < 0) {
            object.position_current = Vec2.init(object.position_current.x, 0.0);
        } else if (object.position_current.y > self.world_height) {
            object.position_current = Vec2.init(object.position_current.x, self.world_height - 1.0);
        }
    }
};
