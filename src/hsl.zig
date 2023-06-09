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

fn hue2rgb(p: f32, q: f32, t: f32) u8 {
    var t2 = t;
    if (t2 < 0) t2 += 1;
    if (t2 > 1) t2 -= 1;
    if (t2 < 1.0 / 6.0) return @floatToInt(u8, p + (q - p) * 6 * t2);
    if (t2 < 1.0 / 2.0) return @floatToInt(u8, q);
    if (t2 < 2.0 / 3.0) return @floatToInt(u8, p + (q - p) * (2.0 / 3.0 - t2) * 6);
    return @floatToInt(u8, p);
}

pub fn hslToRgb(h: f32, s: f32, l: f32) SDL.Color {
    var r: u8 = 0;
    var g: u8 = 0;
    var b: u8 = 0;

    if (s == 0.0) {
        r = 1;
        g = 1;
        b = 1;
    } else {
        var q = if (l < 0.5) l * (1 + s) else l + s - l * s;
        var p = 2 * l - q;
        r = hue2rgb(p, q, h + 1.0 / 3.0);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1.0 / 3.0);
    }

    return SDL.Color.rgb(r, g, b);
}
