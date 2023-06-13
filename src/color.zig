const SDL = @import("sdl2");
const std = @import("std");

pub const HSL = struct {
    hue: f64,
    saturation: f64,
    lightness: f64,
};

pub const RGB = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub fn hslToRgb(hsl: HSL) RGB {
    var rgb: RGB = undefined;

    if (hsl.saturation == 0.0) {
        rgb.red = @floatToInt(u8, hsl.lightness * 255.0);
        rgb.green = rgb.red;
        rgb.blue = rgb.red;
    } else {
        var q: f64 = if (hsl.lightness < 0.5) hsl.lightness * (1.0 + hsl.saturation) else hsl.lightness + hsl.saturation - hsl.lightness * hsl.saturation;

        var p: f64 = 2.0 * hsl.lightness - q;

        rgb.red = hueToRgb(p, q, hsl.hue + (1.0 / 3.0));
        rgb.green = hueToRgb(p, q, hsl.hue);
        rgb.blue = hueToRgb(p, q, hsl.hue - (1.0 / 3.0));
    }

    return rgb;
}

fn hueToRgb(p: f64, q: f64, t: f64) u8 {
    var t2 = t;
    if (t2 < 0.0) t2 += 1.0;
    if (t2 > 1.0) t2 -= 1.0;

    if (t2 < 1.0 / 6.0) {
        return @floatToInt(u8, (p + (q - p) * 6.0 * t2) * 255.0);
    } else if (t2 < 1.0 / 2.0) {
        return @floatToInt(u8, q * 255.0);
    } else if (t2 < 2.0 / 3.0) {
        return @floatToInt(u8, (p + (q - p) * (2.0 / 3.0 - t2) * 6.0) * 255.0);
    } else {
        return @floatToInt(u8, p * 255.0);
    }
}
