const std = @import("std");
//const SDL = @import("./../lib/SDL/src/wrapper/sdl.zig");
const SDL = @import("sdl2");
const Verlet = @import("verlet.zig");
const Vec2 = @import("vec2.zig");
const time = @import("std").time;
const img = @import("zigimg");
const coyote = @import("./coyote-test.zig");
const Allocator = std.mem.Allocator;

const ArrayList = std.ArrayList;

const WINDOW_DIMENSION = .{
    .HEIGHT = 1000,
    .WIDTH = 1000,
};

const NUMBER_OF_CIRCLE = 10_000;
const CIRCLE_RADIUS = 5.0;
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

    try runMainLoop(&window, &renderer, &objects, null, allocator);

    const image_path = "./res/banana.png";
    std.debug.print("Loading image at {s} !\n", .{image_path});
    var image = try img.Image.fromFilePath(allocator, image_path);
    defer image.deinit();
    std.debug.print("Immage loaded !\n", .{});

    var colors_pixels = ArrayList(img.color.Rgb24).init(allocator);
    defer colors_pixels.deinit();

    for (objects.items) |item| {
        try colors_pixels.append(getPixelColor(image.pixels.rgb24, @floatToInt(usize, item.position_current.x), @floatToInt(usize, item.position_current.y)));
    }

    objects.clearAndFree();

    try runMainLoop(&window, &renderer, &objects, colors_pixels.items, allocator);
}

fn runMainLoop(window: *SDL.Window, renderer: *SDL.Renderer, objects: *ArrayList(Verlet.VerletObject), colors: ?[]img.color.Rgb24, allocator: Allocator) !void {
    const BACKGROUND_COLOR = .{ .r = 0xF7, .g = 0xA4, .b = 0x1D };
    const DEFAULT_COLOR = .{ .r = 0xFF, .g = 0xFF, .b = 0xFF };

    var solver = Verlet.Solver.init(1000.0, 1000.0, CIRCLE_RADIUS * 2, allocator);
    defer solver.deinit();

    // Constant delta time f or deterministic simulation (represents 60fps)
    const dt = 16.6666;
    _ = dt;
    var timer = try time.Timer.start();
    const loopBetweenCircle: u8 = 3;
    var loopCount: u64 = 0;

    var titleBuffer: [20]u8 = undefined; //try std.heap.c_allocator.alloc(u8, 256);

    const texture = try SDL.image.loadTextureMem(renderer.*, CIRCLE_DATA[0..], SDL.image.ImgFormat.png);
    defer texture.destroy();

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        if (loopCount >= loopBetweenCircle and objects.items.len < NUMBER_OF_CIRCLE) {
            const CANNON_X = 10.0;
            const CANNON_Y = 90.0;
            for (0..15) |i| {
                try objects.append(ballSpawner(&solver, CANNON_X, CANNON_Y + @intToFloat(f32, i) * 15, 0, SPAWN_VELOCITY));
            }
            loopCount = 0;
        }

        try renderer.setColorRGB(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b);
        try renderer.clear();

        if (objects.items.len < NUMBER_OF_CIRCLE) {
            solver.update(objects.items);
        }

        for (objects.items, 0..) |object, index| {
            if (colors != null) {
                try renderer.setColorRGB(colors.?[index].r, colors.?[index].g, colors.?[index].b);
            } else {
                try renderer.setColorRGB(DEFAULT_COLOR.r, DEFAULT_COLOR.g, DEFAULT_COLOR.b);
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
}

fn ballSpawner(solver: *Verlet.Solver, x: f32, y: f32, angle: f32, speed: f32) Verlet.VerletObject {
    const angle_radian: f32 = std.math.pi * angle / 180;
    var object = Verlet.VerletObject.init(Vec2.Vec2.init(x, y), CIRCLE_RADIUS);
    const direction = Vec2.Vec2.init(std.math.cos(angle_radian), std.math.sin(angle_radian)).mul(speed);

    solver.*.setObjectSpeed(
        &object,
        direction,
    );

    return object;
}

fn getPixelColor(arr: []img.color.Rgb24, x: usize, y: usize) img.color.Rgb24 {
    return arr[y * 1000 + x];
}

fn drawCircle(renderer: SDL.Renderer, centreX: i32, centreY: i32, radius: i32) !void {
    const diameter: i32 = (radius * 2);

    var x: i32 = (radius - 1);
    var y: i32 = 0;
    var tx: i32 = 1;
    var ty: i32 = 1;
    var hasError: i32 = (tx - diameter);

    while (x >= y) {
        //  Each of the following renders an octant of the circle
        try renderer.drawPoint(centreX + x, centreY - y);
        try renderer.drawPoint(centreX + x, centreY + y);
        try renderer.drawPoint(centreX - x, centreY - y);
        try renderer.drawPoint(centreX - x, centreY + y);
        try renderer.drawPoint(centreX + y, centreY - x);
        try renderer.drawPoint(centreX + y, centreY + x);
        try renderer.drawPoint(centreX - y, centreY - x);
        try renderer.drawPoint(centreX - y, centreY + x);

        if (hasError <= 0) {
            y += 1;
            hasError += ty;
            ty += 2;
        }

        if (hasError > 0) {
            x -= 1;
            tx += 2;
            hasError += (tx - diameter);
        }
    }
}

fn fillCircle(renderer: SDL.Renderer, x: i32, y: i32, radius: i32) !void {
    var offsetx: i32 = undefined;
    var offsety: i32 = undefined;
    var d: i32 = undefined;
    var status: i32 = undefined;

    offsetx = 0;
    offsety = radius;
    d = radius - 1;
    status = 0;

    while (offsety >= offsetx) {
        try renderer.drawLine(x - offsety, y + offsetx, x + offsety, y + offsetx);
        try renderer.drawLine(x - offsetx, y + offsety, x + offsetx, y + offsety);
        try renderer.drawLine(x - offsetx, y - offsety, x + offsetx, y - offsety);
        try renderer.drawLine(x - offsety, y - offsetx, x + offsety, y - offsetx);

        if (d >= 2 * offsetx) {
            d -= 2 * offsetx + 1;
            offsetx += 1;
        } else if (d < 2 * (radius - offsety)) {
            d += 2 * offsety - 1;
            offsety -= 1;
        } else {
            d += 2 * (offsety - offsetx - 1);
            offsety -= 1;
            offsetx += 1;
        }
    }
}
