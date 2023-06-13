const std = @import("std");
//const SDL = @import("./../lib/SDL/src/wrapper/sdl.zig");
const SDL = @import("sdl2");
const Verlet = @import("verlet.zig");
const Vec2 = @import("vec2.zig");
const time = @import("std").time;
const img = @import("zigimg");
const coyote = @import("./coyote-test.zig");
const color = @import("./color.zig");
const Allocator = std.mem.Allocator;

const ArrayList = std.ArrayList;

const WINDOW_DIMENSION = .{
    .HEIGHT = 1000,
    .WIDTH = 1000,
};

const NUMBER_OF_CIRCLE = 13_000;
const CIRCLE_RADIUS = 5.0;
// Speed of the ball when spawned
const SPAWN_VELOCITY = 500.0;
const CIRCLE_DATA = @embedFile("./circle.png");

pub fn main() !void {
    std.debug.print("programm started !\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    var allocator = gpa.allocator();

    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = false,
    });
    defer SDL.quit();

    var window = try SDL.createWindow(
        "SDL2 Wrapper Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        WINDOW_DIMENSION.WIDTH,
        WINDOW_DIMENSION.HEIGHT,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    var objects = ArrayList(Verlet.VerletObject).init(allocator);
    defer objects.deinit();

    // runs one iteration of our simulation to get the final state of the objects
    const nb_circles = try runMainLoop(&window, &renderer, &objects, null, NUMBER_OF_CIRCLE, allocator);

    const image_path = "./res/donini.png";
    std.debug.print("Loading image at {s} !\n", .{image_path});
    var image = try img.Image.fromFilePath(allocator, image_path);
    defer image.deinit();
    std.debug.print("Immage loaded !\n", .{});

    var colors_pixels = ArrayList(img.color.Rgb24).init(allocator);
    defer colors_pixels.deinit();

    // get the color of the pixels at the position of the objects
    for (objects.items) |item| {
        try colors_pixels.append(getPixelColor(image.pixels.rgb24, @floatToInt(usize, item.position_current.x), @floatToInt(usize, item.position_current.y)));
    }

    objects.clearAndFree();

    // runs the simulation again with the color of the pixels
    _ = try runMainLoop(&window, &renderer, &objects, colors_pixels.items, nb_circles, allocator);
}

fn runMainLoop(window: *SDL.Window, renderer: *SDL.Renderer, objects: *ArrayList(Verlet.VerletObject), colors: ?[]img.color.Rgb24, nb_circles: usize, allocator: Allocator) !usize {
    const BACKGROUND_COLOR = .{ .r = 0x00, .g = 0x00, .b = 0x00 };

    var solver = Verlet.Solver.init(1000.0, 1000.0, CIRCLE_RADIUS * 2, allocator);
    defer solver.deinit();

    // Constant delta time f or deterministic simulation (represents 60fps)
    const dt = 16.6666;
    _ = dt;
    var timer = try time.Timer.start();
    const loopBetweenCircle: u8 = 3;
    var loopCount: u64 = 0;
    var color_gradient_counter: f64 = 0.0;

    var titleBuffer: [20]u8 = undefined;

    const texture = try SDL.image.loadTextureMem(renderer.*, CIRCLE_DATA[0..], SDL.image.ImgFormat.png);
    defer texture.destroy();

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        if (loopCount >= loopBetweenCircle and objects.items.len < nb_circles) {
            const CANNON_X = 10.0;
            const CANNON_Y = 10.0;
            for (0..18) |i| {
                try objects.append(ballSpawner(&solver, CANNON_X, CANNON_Y + @intToFloat(f32, i) * 15, 0, SPAWN_VELOCITY, &color_gradient_counter));
            }
            loopCount = 0;
        }

        try renderer.setColorRGB(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b);
        try renderer.clear();

        if (objects.items.len < nb_circles) {
            solver.update(objects.items);
        }

        for (objects.items, 0..) |object, index| {
            if (colors != null) {
                try texture.setColorMod(SDL.Color.rgb(colors.?[index].r, colors.?[index].g, colors.?[index].b));
            } else {
                const object_color = SDL.Color.rgb(object.color.red, object.color.green, object.color.blue);
                try texture.setColorMod(object_color);
            }
            // try fillCircle(renderer.*, @floatToInt(i32, object.position_current.x), @floatToInt(i32, object.position_current.y), @floatToInt(i32, object.radius));
            try renderer.copy(texture, SDL.Rectangle{ .x = @floatToInt(i32, object.position_current.x - CIRCLE_RADIUS), .y = @floatToInt(i32, object.position_current.y - CIRCLE_RADIUS), .height = 10, .width = 10 }, null);
        }

        renderer.present();
        loopCount += 1;

        var real_dt = timer.lap();
        var framerateTitle = try std.fmt.bufPrint(titleBuffer[0..], "time per frame: {}", .{real_dt / 1_000_000});
        titleBuffer[framerateTitle.len] = 0;
        SDL.c.SDL_SetWindowTitle(window.ptr, @ptrCast(*const u8, framerateTitle.ptr));

        if (16_000_000 > real_dt) {
            SDL.delay(@intCast(u32, 16 - real_dt / 1_000_000));
        }
    }
    return objects.items.len;
}

// Spawns a ball with a given speed and angle
// Color counter is used to make a rainbow effect
fn ballSpawner(solver: *Verlet.Solver, x: f32, y: f32, angle: f32, speed: f32, color_counter: *f64) Verlet.VerletObject {
    const angle_radian: f32 = std.math.pi * angle / 180;
    var object = Verlet.VerletObject.init(Vec2.Vec2.init(x, y), CIRCLE_RADIUS);
    const direction = Vec2.Vec2.init(std.math.cos(angle_radian), std.math.sin(angle_radian)).mul(speed);
    const hsl_object = color.HSL{ .hue = color_counter.*, .saturation = 1.0, .lightness = 0.5 };
    const rgb = color.hslToRgb(hsl_object);
    object.color = rgb;
    color_counter.* = if (color_counter.* >= 1.0) 0 else color_counter.* + 0.0001;

    //Mainly used to use the same delta time as the solver
    solver.*.setObjectSpeed(
        &object,
        direction,
    );

    return object;
}

fn getPixelColor(arr: []img.color.Rgb24, x: usize, y: usize) img.color.Rgb24 {
    return arr[y * 1000 + x];
}
