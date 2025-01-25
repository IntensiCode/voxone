#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iHash;

out vec4 fragColor;

// https://www.shadertoy.com/view/4s33RX

#define pradius 1.3
#define mradius 0.1
#define iterations 20.0
#define shadowit 10.0
#define line 0.39

vec4 NC0=vec4(0.0,157.0,113.0,270.0);
vec4 NC1=vec4(1.0,158.0,114.0,271.0);

vec4 hash4( vec4 n ) { return fract(sin(n)*(iHash/2+400)); }
//vec4 hash4( vec4 n ) { return fract(sin(n)*753.5453123); }
float noise3( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + dot(p.yz,vec2(157.0,113.0));
    vec4 s1=mix(hash4(vec4(n)+NC0),hash4(vec4(n)+NC1),vec4(f.x));
    return mix(mix(s1.x,s1.y,f.y),mix(s1.z,s1.w,f.y),f.z);
}

float heightMap(vec3 rad,float d)
{
    float iline=1.0/(1.0-line);
    float a=noise3(rad*1.6)*0.885;
    float na=a;
    if (a>line) a=pow((a-line)*iline,1.8)*(1.0-line)+line;
    if (abs(d-a)<0.2) {
        na+=noise3(rad*8.0)*0.1;
        a=na;
        if (a>line) a=pow((a-line)*iline,1.8)*(1.0-line)+line;
    }
    if (abs(d-a)<0.02) {
        na+=noise3(rad*32.0)*0.01;
        a=na;
        if (a>line) a=pow((a-line)*iline,1.8)*(1.0-line)+line;
    }
    if (abs(d-a)<0.01) a+=noise3(rad*128.0)*0.005;
    return a;
}

vec3 distObj(vec3 pos,vec3 ray,float radius,float minr)
{
    float b = dot(ray,pos);
    float c = dot(pos,pos) - b*b;

    float sta=radius-minr;
    float invm=1.0/sta;
    float rq=radius*radius;
    vec3 dist=ray*10000.0;
    if(c <rq)
    {
        vec3 r1 = (ray*(abs(b)-sqrt(rq-c))-pos);
        float maxs=abs(dot(r1,ray));//*0.5;
        if (c<minr*minr) {
            vec3 r2 = (ray*(abs(b)-sqrt(minr*minr-c))-pos);
            maxs=maxs-abs(dot(r2,ray));
        }// else {
        maxs*=0.5;
        //}
        float len;
        float h;

        for (float m=0.0; (m<iterations); m+=1.0) {
            len=length(r1);
            vec3 d=r1/len;
            h=sta*heightMap(d,(len-minr)*invm)+minr;
            if (abs(h-len)<0.0001) break;
            maxs=abs(maxs);
            if (len<h) maxs=-maxs;
            r1+=ray*maxs*abs(len-h);
            maxs*=0.99;
        }
        if (len<h+0.1) dist=r1+pos;
    }
    return dist;
}

float noiseSpace(vec3 ray,vec3 pos,float r,mat3 mr,float zoom,vec3 subnoise)
{
    float b = dot(ray,pos);
    float c = dot(pos,pos) - b*b;

    vec3 r1=vec3(0.0);

    float s=0.0;
    float d=0.0625*1.5;
    float d2=zoom/d;

    float rq=r*r;
    float l1=sqrt(abs(r-c));
    r1= (ray*(b-l1)-pos)*mr;

    r1*=d2;
    s+=abs(noise3(vec3(r1+subnoise))*d);
    s+=abs(noise3(vec3(r1*0.5+subnoise))*d*2.0);
    s+=abs(noise3(vec3(r1*0.25+subnoise))*d*4.0);
    return s;
}

void main()
{
    vec2 fragCoord = FlutterFragCoord();
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;

    vec2 rotate = iMouse;
    vec2 sins=sin(rotate);
    vec2 coss=cos(rotate);
    mat3 mr=mat3(vec3(coss.x,0.0,sins.x),vec3(0.0,1.0,0.0),vec3(-sins.x,0.0,coss.x));
    mr=mat3(vec3(1.0,0.0,0.0),vec3(0.0,coss.y,sins.y),vec3(0.0,-sins.y,coss.y))*mr;

    vec3 ray = normalize(vec3(p,2.0));
    vec3 ray1 = normalize(vec3(p+vec2(0.0,0.01),2.0));
    vec3 ray2 = normalize(vec3(p+vec2(0.01,0.0),2.0));
    vec3 pos = vec3(0.0,0.0,3.0);

    vec3 light=vec3(-30.0,0.0,-30.0);

    vec3 n1=distObj(pos*mr,ray1*mr,pradius,mradius);
    vec3 n2=distObj(pos*mr,ray2*mr,pradius,mradius);
    vec3 rt=distObj(pos*mr,ray*mr,pradius,mradius);

    vec3 lightn=normalize(light*mr-rt);
    vec3 sd=distObj((pos-light)*mr,-lightn,pradius,mradius);

    float shadow=1.0-clamp(pow(length(sd+light*mr-rt),2.0)*200.0,0.0,1.0);
    vec3 n=normalize(cross(n1-rt,n2-rt));

    if (length(n1)>100.0 || length(n2)>100.0 || length(rt)>100.0) {
        return;
    }

    fragColor.a = 1.0;

    float s4=noiseSpace(ray,pos,100.0,mr,0.5,vec3(0.0));
    if (fragColor.a<1.0) {
        //s4=pow(s4*1.8,5.7);
        //fragColor=vec4((mix(mix(vec3(1.0,0.0,0.0),vec3(0.0,0.0,1.0),s4*3.0),vec3(0.5),pow(s4*2.0,0.1))*s4*0.2),1.0);
        //fragColor=vec4(1.,1.,1.,1.);
    } else {
        rt=rt-pos*mr;
        float fd=(length(rt)-mradius)/(pradius-mradius);
        float c=dot(n,lightn)*shadow;
        if (fd<line) {
            fragColor.xyz = mix(vec3(0.21,0.19,0.0),vec3(1.0,0.99,1.0),noise3(rt*128.0)*0.9+noise3(rt*8.0)*0.1)*c;
        } else {
            fragColor.xyz = mix(mix(vec3(1.0,1.0,0.9),vec3(0.8,0.79,0.7),noise3(rt*128.0)*0.9+noise3(rt*8.0)*0.1),vec3(1.0),pow(fd+0.5,10.0))*c;
        }
    }

    //    fragColor = min( vec4(1.0), fragColor );
}
