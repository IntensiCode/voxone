// https://www.shadertoy.com/view/M33GW8

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

vec3 n_rand3(vec3 p) {
    vec3 r =
    fract(
    sin(
    vec3(
    dot(p, vec3(127.1, 311.7, 371.8)),
    dot(p, vec3(269.5, 183.3, 456.1)),
    dot(p, vec3(352.5, 207.3, 198.67))
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
    dot(n_rand3(nv+vec3(0.0, 0.0, 0.0)), fv-vec3(0.0, 0.0, 0.0)),
    dot(n_rand3(nv+vec3(1.0, 0.0, 0.0)), fv-vec3(1.0, 0.0, 0.0)),
    u.x
    ),
    mix(
    dot(n_rand3(nv+vec3(0.0, 1.0, 0.0)), fv-vec3(0.0, 1.0, 0.0)),
    dot(n_rand3(nv+vec3(1.0, 1.0, 0.0)), fv-vec3(1.0, 1.0, 0.0)),
    u.x
    ),
    u.y
    ),
    mix(
    mix(
    dot(n_rand3(nv+vec3(0.0, 0.0, 1.0)), fv-vec3(0.0, 0.0, 1.0)),
    dot(n_rand3(nv+vec3(1.0, 0.0, 1.0)), fv-vec3(1.0, 0.0, 1.0)),
    u.x
    ),
    mix(
    dot(n_rand3(nv+vec3(0.0, 1.0, 1.0)), fv-vec3(0.0, 1.0, 1.0)),
    dot(n_rand3(nv+vec3(1.0, 1.0, 1.0)), fv-vec3(1.0, 1.0, 1.0)),
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

    for (int i=0;i<=4;++i)
    {
        if (i > io) break;
        float v = pow(2.0, float(i));
        d += 1.0/v;
        ns += noise(pos*v)*(1.0/v);
    }


    float v = pow(2.0, float(io+1));
    d+= 1.0*fo/v;
    ns += noise(pos*v)*(1.0*fo/v);

    return ns/d;
}

float posterize(float v, int n)
{
    float fn = float(n);
    return floor(v*fn)/(fn-1.);
}

const vec3 HP0 = vec3(.1, .55, .0);
const vec3 HP1 = vec3(.3, .7, .1);
const vec3 HP2 = vec3(.5, .8, .2);
const vec3 HP3 = vec3(.9, .9, .3);

float f (vec2 uv) {
    vec2 pos = uv;
    pos.x *= iResolution.x/iResolution.y;
    pos *=  10.0;

    float base = (-pow(abs(uv.y-.5)*2., 2.)+pow(uv.x+.1, 8.)-pow(uv.x+.1, 10.))*10.-pow(1.1-uv.x, 10.);
    float wave = oct_noise(vec3(pos+vec2(iTime*8., 0.), iTime*.5), (1.-uv.x)*4.)/2.;
    float flares = pow(sin(1.-(noise(vec3(pos*2.+vec2(iTime*16., 0.), iTime)))*3.141592653689), 4.)/16.;

    return base+wave+flares;
}


vec2 grad(vec2 x)
{
    vec2 h = vec2(0.01, 0.0);
    return vec2(f(x+h.xy) - f(x-h.xy),
    f(x+h.yx) - f(x-h.yx))/(2.0*h.x);
}

float border (vec2 uv)
{

    float v = f(uv);
    vec2  g = grad(uv);
    float de = abs(v)/length(g);
    float eps = .01;

    return smoothstep(1.0*eps, 2.0*eps, de);
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord/iResolution.xy;
    vec2 pos = uv;
    pos.x *= iResolution.x/iResolution.y;
    pos *=  10.0;

    float value = f(uv);

    //    vec3 pal[] = HP;
    int pl = 4;// pal.length();
    int pal_idx = int(posterize(value, pl)*float(pl));
    vec3 pal = HP0;
    if (pal_idx == 1) pal = HP1;
    if (pal_idx == 2) pal = HP2;
    if (pal_idx == 3) pal = HP3;

    float b = step(.5, border(uv));
    float alpha = step(0., value);

    vec3 color = pal - vec3(1.-alpha) - (1.-b);

    if (alpha == 1.) fragColor = vec4(color, 1);

}
