export const TAU = Math.PI * 2, W = 584, LOOP = 13;
export const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
export const lerp = (a, b, t) => a + (b - a) * t;
export const smooth = (a, b, v) => { const t = clamp((v - a) / (b - a)); return t * t * (3 - 2 * t); };
export const out = (v) => 1 - (1 - clamp(v)) ** 5;
export const rnd = (n) => { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };
export const mix = (a, b, t) => a.map((v, i) => lerp(v, b[i], t));
export const rgba = (c, a = 1) => `rgba(${c.map(Math.round).join(',')},${clamp(a)})`;
export const phase = (t, rate = 1, offset = 0) => TAU * t / LOOP * rate + offset;

export function glow(g,x,y,r,c,a) {
  if(r<=0 || a<=0) return;
  const gr=g.createRadialGradient(x,y,0,x,y,r); gr.addColorStop(0,rgba(c,a));gr.addColorStop(1,rgba(c,0));
  g.fillStyle=gr;g.beginPath();g.arc(x,y,r,0,TAU);g.fill();
}
export function stroke(g,path,c,a=1,width=1) {g.strokeStyle=rgba(c,a);g.lineWidth=width;g.lineCap='round';g.lineJoin='round';g.stroke(path);}
export function line(g,x,y,ex,ey,c,a,w=1) {const p=new Path2D();p.moveTo(x,y);p.lineTo(ex,ey);stroke(g,p,c,a,w);}
export function ellipse(g,x,y,rx,ry,c,a=1,angle=0) {g.fillStyle=rgba(c,a);g.beginPath();g.ellipse(x,y,rx,ry,angle,0,TAU);g.fill();}
