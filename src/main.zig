const std = @import("std");
//const SDL = @import("./../lib/SDL/src/wrapper/sdl.zig");
const SDL = @import("sdl2");
const Verlet = @import("verlet.zig");
const Vec2 = @import("vec2.zig").Vec2;
const time = @import("std").time;
const img = @import("zigimg");
const Uniform_Grid = @import("uniform_grid.zig");
const Allocator = std.mem.Allocator;

const ArrayList = std.ArrayList;

const WINDOW_DIMENSION = .{
    .HEIGHT = 1000,
    .WIDTH = 1000,
};

const NUMBER_OF_CIRCLE = 100;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    var allocator = gpa.allocator();

    var grid = Uniform_Grid.UniformGrid.init(100, 100, 20, allocator);
    defer grid.deinit();

    var obj1 = Verlet.VerletObject.init(Vec2.init(11, 11), 10);

    try grid.insert_in_cell(0, 0, &obj1);

    //std.debug.print("\ngrid.len: {}\n", .{grid.grid.len});
    std.debug.print("\ngrid[0].items.len: {}\n", .{grid.grid[0].items.len});

    // try SDL.init(.{
    //     .video = true,
    //     .events = true,
    //     .audio = false,
    // });
    // defer SDL.quit();

    // var window = try SDL.createWindow(
    //     "SDL2 Wrapper Demo",
    //     .{ .centered = {} },
    //     .{ .centered = {} },
    //     WINDOW_DIMENSION.WIDTH,
    //     WINDOW_DIMENSION.HEIGHT,
    //     .{ .vis = .shown },
    // );
    // defer window.destroy();

    // var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    // defer renderer.destroy();

    // var objects = ArrayList(Verlet.VerletObject).init(allocator);
    // defer objects.deinit();

    // try runMainLoop(&window, &renderer, &objects, null, allocator);

    // var image = try img.Image.fromFilePath(allocator, "./res/banana.png");
    // defer image.deinit();

    // var colors_pixels = ArrayList(img.color.Rgb24).init(allocator);
    // defer colors_pixels.deinit();

    // for (objects.items) |item| {
    //     try colors_pixels.append(getPixelColor(image.pixels.rgb24, @floatToInt(usize, item.position_current.x), @floatToInt(usize, item.position_current.y)));
    // }

    // objects.clearAndFree();

    // try runMainLoop(&window, &renderer, &objects, colors_pixels.items, allocator);
    // std.time.sleep(10_000_000_000);
}

fn runMainLoop(window: *SDL.Window, renderer: *SDL.Renderer, objects: *ArrayList(Verlet.VerletObject), colors: ?[]img.color.Rgb24, allocator: Allocator) !void {
    const BACKGROUND_COLOR = .{ .r = 0xF7, .g = 0xA4, .b = 0x1D };
    const DEFAULT_COLOR = .{ .r = 0xFF, .g = 0xFF, .b = 0xFF };

    var solver = Verlet.Solver.init(12, 1000.0, 1000.0, allocator);

    // Constant delta time for deterministic simulation (represents 60fps)
    const dt = 16.6666;
    var timer = try time.Timer.start();
    const loopBetweenCircle: u8 = 20;
    var loopCount: u8 = 0;

    var titleBuffer: [20]u8 = undefined; //try std.heap.c_allocator.alloc(u8, 256);

    mainLoop: while (true) {
        if (objects.items.len >= NUMBER_OF_CIRCLE) {
            break :mainLoop;
        }

        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        if (loopCount >= loopBetweenCircle) {
            try objects.append(Verlet.VerletObject.init(Vec2.init(600.0, 500.0), 10.0));
            objects.items[objects.items.len - 1].position_previous = Vec2.init(590.0, 520.0);
            loopCount = 0;
        }

        try renderer.setColorRGB(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b);
        try renderer.clear();

        solver.update(objects.items, dt);

        for (objects.items, 0..) |object, index| {
            if (colors != null) {
                try renderer.setColorRGB(colors.?[index].r, colors.?[index].g, colors.?[index].b);
            } else {
                try renderer.setColorRGB(DEFAULT_COLOR.r, DEFAULT_COLOR.g, DEFAULT_COLOR.b);
            }
            try fillCircle(renderer.*, @floatToInt(i32, object.position_current.x), @floatToInt(i32, object.position_current.y), @floatToInt(i32, object.radius));
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
