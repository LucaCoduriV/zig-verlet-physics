pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2 {
            .x = x,
            .y = y
        };
    }

    pub fn sub(a: Vec2, b: Vec2) Vec2 {
        return Vec2 {
            .x = a.x - b.x,
            .y = a.y - b.y
        };
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2 {
            .x = a.x + b.x,
            .y = a.y + b.y
        };
    }

    pub fn mul(a : Vec2, s : f32) Vec2 {
        return Vec2 {
            .x = a.x * s,
            .y = a.y * s
        };
    }

    pub fn div(a : Vec2, s : f32) Vec2 {
        return Vec2 {
            .x = a.x / s,
            .y = a.y / s
        };
    }
};