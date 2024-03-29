const math = @import("std").math;

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }

    pub fn sub(a: Vec2, b: Vec2) Vec2 {
        return Vec2{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn mul(a: Vec2, s: f32) Vec2 {
        return Vec2{ .x = a.x * s, .y = a.y * s };
    }

    pub fn div(a: Vec2, s: f32) Vec2 {
        return Vec2{ .x = a.x / s, .y = a.y / s };
    }

    pub fn length(a: Vec2) f32 {
        return math.sqrt(a.magnitude2());
    }

    pub fn magnitude2(a: Vec2) f32 {
        return a.x * a.x + a.y * a.y;
    }

    pub fn normalize(a: Vec2) Vec2 {
        const len = a.length();
        return Vec2{ .x = a.x / len, .y = a.y / len };
    }
};
