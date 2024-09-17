// https://www.shadertoy.com/view/XlSXzd

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec4 color1;
uniform vec4 color2;
uniform vec2 resolution;
uniform float size;
uniform float d;
uniform float x_off;
uniform float y_off;
uniform float z_off;

out vec4 fragColor;

const float merge_col = 64;

float do_mod(float a, float b) {
    return a - (b * floor(a / b));
}

void main() {
    float x = FlutterFragCoord().x - resolution.x / 2;
    float y = FlutterFragCoord().y - resolution.y;

    float y_world = y_off * 4;
    float z_world = y_world * d / y / 4;
    float x_world = x / d * z_world + x_off;

    float x_tile = do_mod(floor(x_world / size / 4), 2);
    float z_tile = do_mod(floor((z_world - z_off / 8) / size), 2);
    // why the 8 for it to look square?

    vec4 col = color1;
    vec4 other = color2;
    if (x_tile != z_tile) {
        col = color2;
        other = color1;
    }

    float merge_ = (y - resolution.y / merge_col) / resolution.y;
    if (merge_ < 0) merge_ = 0;
    col = mix(col, other, 0.5 - merge_);

    col.x *= col.a;
    col.y *= col.a;
    col.z *= col.a;
    fragColor = col;
}

// https://www.shadertoy.com/view/M33GW8

vec3 n_rand3(vec3 p) {
    vec3 r =
    fract(
    sin(
    vec3(
    dot(p, vec3(127.1,311.7,371.8)),
    dot(p,vec3(269.5,183.3,456.1)),
    dot(p,vec3(352.5,207.3,198.67))
    )
    ) * 43758.5453
    ) * 2.0 - 1.0;
    return normalize(vec3(r.x/cos(r.x), r.y/cos(r.y), r.z/cos(r.z)));
}

float noise(vec3 p) {

    vec3 fv = fract(p);
    vec3 nv = vec3(floor(p));

    vec3 u = fv*fv*fv*(fv*(fv*6.0-15.0)+10.0);

    return (
    mix(
    mix(
    mix(
    dot( n_rand3( nv+vec3(0.0,0.0,0.0) ), fv-vec3(0.0,0.0,0.0)),
    dot( n_rand3( nv+vec3(1.0,0.0,0.0) ), fv-vec3(1.0,0.0,0.0)),
    u.x
    ),
    mix(
    dot( n_rand3( nv+vec3(0.0,1.0,0.0) ), fv-vec3(0.0,1.0,0.0)),
    dot( n_rand3( nv+vec3(1.0,1.0,0.0) ), fv-vec3(1.0,1.0,0.0)),
    u.x
    ),
    u.y
    ),
    mix(
    mix(
    dot( n_rand3( nv+vec3(0.0,0.0,1.0) ), fv-vec3(0.0,0.0,1.0)),
    dot( n_rand3( nv+vec3(1.0,0.0,1.0) ), fv-vec3(1.0,0.0,1.0)),
    u.x
    ),
    mix(
    dot( n_rand3( nv+vec3(0.0,1.0,1.0) ), fv-vec3(0.0,1.0,1.0)),
    dot( n_rand3( nv+vec3(1.0,1.0,1.0) ), fv-vec3(1.0,1.0,1.0)),
    u.x
    ),
    u.y
    ),
    u.z
    )
    );
}

float oct_noise(vec3 pos, float o)
{

    float ns = 0.0;
    float d = 0.0;

    int io = int(o);
    float fo = fract(o);

    for(int i=0;i<=io;++i)
    {
        float v = pow(2.0,float(i));
        d += 1.0/v;
        ns += noise(pos*v)*(1.0/v);
    }


    float v = pow(2.0,float(io+1));
    d+= 1.0*fo/v;
    ns += noise(pos*v)*(1.0*fo/v);

    return ns/d;
}

float posterize(float v, int n)
{
    float fn = float(n);
    return floor(v*fn)/(fn-1.);
}

vec3 HP[] = vec3[4](
vec3(.85, .1, .0),
vec3(.9, .3, .1),
vec3(.9, .5, .2),
vec3(.9, .9, .3)
);

vec3 PF[] = vec3[4](
vec3(.65625, 0., .68359375),
vec3(.8515625, .19921875, .703125),
vec3(1., .59765625, .8359375),
vec3(.9375, .859375, .83203125)
);


float f (vec2 uv) {
    vec2 pos = uv;
    pos.x *= iResolution.x/iResolution.y;
    pos *=  10.0;

    float base = (-pow(abs(uv.y-.5)*2.,2.)+pow(uv.x+.1,8.)-pow(uv.x+.1,10.))*10.-pow(1.1-uv.x, 10.);
    float wave = oct_noise(vec3(pos+vec2(iTime*8.,0.), iTime*.5), (1.-uv.x)*4.)/2.;
    float flares = pow(sin(1.-(noise(vec3(pos*2.+vec2(iTime*16.,0.),iTime)))*3.141592653689),4.)/16.;

    return base+wave+flares;
}


vec2 grad( vec2 x )
{
    vec2 h = vec2( 0.01, 0.0 );
    return vec2( f(x+h.xy) - f(x-h.xy),
    f(x+h.yx) - f(x-h.yx) )/(2.0*h.x);
}

float border (vec2 uv)
{

    float v = f( uv );
    vec2  g = grad( uv );
    float de = abs(v)/length(g);
    float eps = .01;

    return smoothstep( 1.0*eps, 2.0*eps, de );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 pos = uv;
    pos.x *= iResolution.x/iResolution.y;
    pos *=  10.0;

    vec3 pal[] = HP;
    int pl = pal.length();

    float value = f(uv);

    float b = step(.5,border(uv));
    float alpha = step(0.,value);
    vec3 color = pal[int(posterize(value, pl)*float(pl))] - vec3(1.-alpha) - (1.-b);

    vec4 result = vec4(alpha == 1. ? color : vec3(.5), alpha);

    fragColor = vec4(result);
}
