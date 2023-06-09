// function hslToRgb(h, s, l){
//     var r, g, b;
//
//     if(s == 0){
//         r = g = b = l; // achromatic
//     }else{
//         var hue2rgb = function hue2rgb(p, q, t){
//             if(t < 0) t += 1;
//             if(t > 1) t -= 1;
//             if(t < 1/6) return p + (q - p) * 6 * t;
//             if(t < 1/2) return q;
//             if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
//             return p;
//         }
//
//         var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
//         var p = 2 * l - q;
//         r = hue2rgb(p, q, h + 1/3);
//         g = hue2rgb(p, q, h);
//         b = hue2rgb(p, q, h - 1/3);
//     }
//
//     return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
// }

const SDL = @import("sdl2");
const std = @import("std");

pub const HSL = struct {
    hue: f64,
    saturation: f64,
    lightness: f64,
};

const RGB = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub fn hslToRgb(hsl: HSL) SDL.Color {
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

    return SDL.Color.rgb(rgb.red, rgb.green, rgb.blue);
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
