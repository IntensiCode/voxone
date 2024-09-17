// https://www.shadertoy.com/view/WlKyzW
// Created by tdhooper in 2021-01-14

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec2 iOffset;
uniform float iTime;

out vec4 fragColor;

#define fragCoord FlutterFragCoord()
#define time iTime

#define PI 3.14159265359
#define PHI 1.618033988749895

// HG_SDF
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}
float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Rotate on axis, blackle
vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax,p)*ax, p, cos(ro))+sin(ro)*cross(ax,p);
}

// Sign but returns -1 instead of 0
vec3 boolSign(vec3 v) {
    return max(vec3(0), sign(v)) * 2. - 1.;
}

// Closest icosahedron vertex
vec3 icosahedronVertex(vec3 p) {
    vec3 ap, v, v2, v3;
    ap = abs(p);
    v = vec3(PHI, 1, 0);
    v2 = v.yzx;
    v3 = v2.yzx;
    if (distance(ap, v2) < distance(ap, v)) v = v2;
    if (distance(ap, v3) < distance(ap, v)) v = v3;
    return normalize(v) * boolSign(p);
}

// Closest dodecahedron vertex
vec3 dodecahedronVertex(vec3 p) {
    vec3 ap, v, v2, v3, v4;
    ap = abs(p);
    v = vec3(PHI);
    v2 = vec3(0, 1, PHI + 1.);
    v3 = v2.yzx;
    v4 = v3.yzx;
    if (distance(ap, v2) < distance(ap, v)) v = v2;
    if (distance(ap, v3) < distance(ap, v)) v = v3;
    if (distance(ap, v4) < distance(ap, v)) v = v4;
    return normalize(v) * boolSign(p);
}

// Second closest dodecahedron vertex
vec3 secondDodecahedronVertex(vec3 p, vec3 iv, vec3 dv) {
    // Find which side of the icosahedron vertex -> dodecahedron vertex line we're on
    float side = sign(dot(p, cross(iv, dv)));
    // Rotate dodecahedron vertex around the dodecahedron face
    return erot(dv, iv, PI * 2. / 5. * side);
}

// The model to explode
float object(vec3 p) {
    pR(p.xz, 1.2);
    pR(p.xy, .3);
    float d = fBox(p, vec3(.25 - .02)) - .02;
    d = max(d, -d - .05);
    return d;
}

// https://iquilezles.org/articles/functions
float expImpulse( float x, float k )
{
    float h = k*x;
    return h*exp(1.0-h);
}

float map(vec3 p) {

    // Three closest vertices of a spherical pentakis dodecahedron
    // or, three closest faces of a buckyball
    vec3 a = icosahedronVertex(p);
    vec3 b = dodecahedronVertex(p);
    vec3 c = secondDodecahedronVertex(p, a, b);

    float d = 1e12;

    vec3 pp = p;

    // Render the nearest three fragments to get
    // a clean distance estimation

    for (int i = 0; i < 3; i++) {

        // Offset space
        float t = mod((iTime - dot(a.xy, vec2(1,-1)) / 6.) / 3., 1.);
        float t2 = min(t * 1.85, 1.);
        float explode = 1. - pow(1. - t2, 10.); // expand
        explode *= 1. - pow(t2, 5.); // contract
        t2 = max(t - .53, 0.) * 1.2;
        float wobble = sin(expImpulse(t2, 20.) * 2.2 + pow(3. * t2, 1.5) * 2. * PI * 2. - PI) * smoothstep(.4, .0, t2) * .15;
        float anim = wobble + explode;
        p -= a * anim / 2.8;

        // Build boundary edge of face
        float edgeA = dot(p, normalize(b - a));
        float edgeB = dot(p, normalize(c - a));
        float edge = max(edgeA, edgeB);

        // Intersect with object
        d = min(d, max(object(p), edge));

        // Reset space for next iteration
        p = pp;

        // Cycle faces for next iteration
        vec3 aa = a;
        a = b;
        b = c;
        c = aa;
    }

    return d;
}


// compile speed optim from IQ https://www.shadertoy.com/view/Xds3zN
vec3 calcNormal(vec3 pos){
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e);
    }
    return normalize(n);
}

// https://www.shadertoy.com/view/Xds3zN
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

void main()
{
    vec2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;

    vec3 camPos = vec3(0,0,3.2);
    vec3 rayDirection = normalize(vec3(p,-4));

    vec3 rayPosition = camPos;
    float rayLength = 0.;
    float dist = 0.;
    bool bg = false;
    vec3 bgcol = vec3(.007);
    vec3 col = bgcol;

    for (int i = 0; i < 150; i++) {
        rayLength += dist;
        rayPosition = camPos + rayDirection * rayLength;
        dist = map(rayPosition);

        if (abs(dist) < .001) {
            break;
        }

        if (rayLength > 5.) {
            bg = true;
            break;
        }
    }

    if ( ! bg) {
        vec3 albedo = vec3(1);
        vec3 n = calcNormal(rayPosition);
        vec3 lp = vec3(-.5,.5,.5);
        float l = max(dot(lp, n), 0.);
        vec3 ld = normalize(lp - rayPosition);
        l += .02;
        l += pow(max(0., 1. + dot(n, rayDirection)), 3.) * .05;
        float ao = calcAO(rayPosition, n);
        col = albedo * l * mix(1., ao, .8);
        col = mix(col, bgcol, 1.0 - exp2(-0.2 * pow(rayLength - 1., 3.)));
    }

    col = pow(col, vec3(1./2.2));

    fragColor = vec4(col,1);
}
