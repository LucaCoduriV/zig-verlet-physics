const std = @import("std");
//const SDL = @import("./../lib/SDL/src/wrapper/sdl.zig");
const SDL = @import("sdl2");

pub fn main() !void {
    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();

    var window = try SDL.createWindow(
        "SDL2 Wrapper Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();

        try renderer.setColorRGB(0xFF, 0xFF, 0xFF);
        try fillCircle(renderer, 100, 100, 50);

        try renderer.drawLine(0, 0, 100, 100);

        renderer.present();
    }
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
