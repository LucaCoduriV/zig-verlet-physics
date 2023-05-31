const Vec2 = @import("vec2.zig").Vec2;
const std = @import("std");
const UniformGridSimple = @import("uniform_grid.zig").UniformGridSimple;
const Allocator = std.mem.Allocator;

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
    grid: UniformGridSimple,

    pub fn init(sub_steps: u32, world_width: f32, world_height: f32, allocator: Allocator) Solver {
        var uniform_grid = UniformGridSimple.init();
        for (uniform_grid.get_as_1D()) |*item| {
            item.* = std.ArrayList(usize).init(allocator);
        }

        return Solver{
            .gravity = Vec2.init(0.0, 0.3),
            .sub_steps = sub_steps,
            .world_height = world_height,
            .world_width = world_width,
            .grid = uniform_grid,
        };
    }

    pub fn update(self: *Solver, objects: []VerletObject, dt: f32) void {
        var i: usize = 0;
        self.apply_gravity(objects);
        while (i < self.sub_steps) : (i += 1) {
            Solver.solve_collision(objects);
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

    fn solve_collision(objects: []VerletObject) void {
        for (objects, 0..) |*object_a, i_a| {
            for (objects, 0..) |*object_b, i_b| {
                if (i_a != i_b) {
                    Solver.solve_object_to_object_collision(object_a, object_b);
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
};
