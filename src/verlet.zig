const Vec2 = @import("vec2.zig").Vec2;
const std = @import("std");
const math = std.math;
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
    inertia: f32,
    move_acc: f32,

    pub fn init(position_current: Vec2, radius: f32) VerletObject {
        return VerletObject{
            .position_current = position_current,
            .position_previous = position_current,
            .acceleration = Vec2.init(0.0, 0.0),
            .radius = radius,
            .inertia = 1.0,
            .move_acc = 0.0,
        };
    }

    fn update_position(self: *VerletObject, dt: f32) void {
        const current_velocity = self.position_current.sub(self.position_previous);

        self.inertia = 1.0 + self.move_acc / (current_velocity.length() + 1.0);
        self.move_acc *= 0.5;

        self.acceleration = self.acceleration.sub(current_velocity.mul(35));

        const anti_pressure_factor: f32 = math.pow(f32, 1.0 / self.inertia, 2);

        self.position_previous = self.position_current;
        self.position_current = self.position_current.add(current_velocity.add(self.acceleration.mul(anti_pressure_factor * dt * dt)));

        self.acceleration = Vec2.init(0.0, 0.0);
    }

    fn accelerate(self: *VerletObject, acceleration: Vec2) void {
        self.acceleration = self.acceleration.add(acceleration);
    }

    pub fn move_self(self: *VerletObject, delta: Vec2) void {
        self.position_current = self.position_current.add(delta);
        self.move_acc += (@fabs(delta.x) + @fabs(delta.y));
    }

    fn set_velocity(self: *VerletObject, new_velocity: Vec2, dt: f32) void {
        self.position_previous = self.position_previous.sub(new_velocity.mul(dt));
    }

    fn velocity(self: *VerletObject) Vec2 {
        return self.position_current.sub(self.position_previous);
    }
};

pub const Solver = struct {
    gravity: Vec2,
    sub_steps: u32,
    frame_dt: f32,
    world_height: f32,
    world_width: f32,
    cell_size: f32,
    grid: UniformGridSimple,

    pub fn init(world_width: f32, world_height: f32, cell_size: f32, allocator: Allocator) Solver {
        return Solver{
            .gravity = Vec2.init(0.0, 200.0),
            .sub_steps = 1,
            .frame_dt = 1.0 / 60.0,
            .world_height = world_height,
            .world_width = world_width,
            .cell_size = cell_size,
            .grid = UniformGrid.init(cell_size, world_width, world_height, allocator),
        };
    }

    pub fn update(self: *Solver, objects: []VerletObject) void {
        self.apply_gravity(objects);

        self.apply_constraints(objects);
        self.solve_collision(objects);
        self.apply_constraints(objects);

        Solver.update_position(objects, self.frame_dt);
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
        for (objects) |*object| {
            var pos = object.position_current;
            var radius = object.radius;

            if (pos.x < radius) {
                object.move_self(Vec2.init(radius - pos.x, 0.0));
            } else if (pos.x > (self.world_width - radius)) {
                object.move_self(Vec2.init(self.world_width - radius - pos.x, 0.0));
            }

            if (pos.y < radius) {
                object.move_self(Vec2.init(0.0, radius - pos.y));
            } else if (pos.y > (self.world_height - radius)) {
                object.move_self(Vec2.init(0.0, self.world_height - radius - pos.y));
            }
        }
    }

    fn solve_collision(self: *Solver, objects: []VerletObject) void {
        clear_uniform_grid(&self.grid);

        for (objects, 0..) |*object, i| {
            insert(&self.grid, Point{ .x = object.position_current.x, .y = object.position_current.y }, i, self.cell_size);
        }

        for (0..self.grid.width) |x| {
            for (0..self.grid.height) |y| {
                var cell = self.grid.get(x, y).*.items;

                for (0..cell.len) |i| {
                    for (i + 1..cell.len) |j| {
                        var object_a = &objects[cell[i]];
                        var object_b = &objects[cell[j]];
                        self.solve_object_to_object_collision(object_a, object_b);
                    }
                }
            }
        }
    }

    fn solve_object_to_object_collision(self: *Solver, object_a: *VerletObject, object_b: *VerletObject) void {
        const col_radius: f32 = object_a.radius + object_b.radius;
        const col_axe: Vec2 = object_a.position_current.sub(object_b.position_current);
        const length2 = col_axe.magnetude2();

        if (length2 < (col_radius * col_radius) and length2 > 0.01) {
            const m1 = object_a.inertia;
            const m2 = object_b.inertia;
            const mass_tot = 1.0 / (m1 + m2);
            const mass_factor_1 = m1 * mass_tot;
            const mass_factor_2 = m2 * mass_tot;
            const delta_col = 0.5 * (col_radius - col_axe.length());

            const norm_col_axe: Vec2 = col_axe.normalize();
            object_a.move_self(norm_col_axe.mul(delta_col * mass_factor_2));
            object_b.move_self(norm_col_axe.mul(-1 * delta_col * mass_factor_1));

            const cohesion = 0.1;
            const delta_v = object_a.velocity().sub(object_b.velocity());

            object_a.set_velocity(delta_v.mul(-1 * cohesion), self.frame_dt);
            object_b.set_velocity(delta_v.mul(cohesion), self.frame_dt);
        }
    }

    fn replace_in_world(self: *Solver, object: *VerletObject) void {
        if (object.position_current.x < 0) {
            object.position_current = Vec2.init(0.0, object.position_current.y);
        } else if (object.position_current.x > self.world_width) {
            object.position_current = Vec2.init(self.world_width, object.position_current.y);
        }
        if (object.position_current.y < 0) {
            object.position_current = Vec2.init(object.position_current.x, 0.0);
        } else if (object.position_current.y > self.world_height) {
            object.position_current = Vec2.init(object.position_current.x, self.world_height);
        }
    }

    pub fn deinit(self: *Solver) void {
        clear_uniform_grid(&self.grid);
        self.grid.deinit();
    }
};
