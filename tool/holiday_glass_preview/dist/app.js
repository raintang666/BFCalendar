import { TAU, W, LOOP, clamp, lerp, smooth, out, rnd, mix, rgba, phase, glow, stroke, line, ellipse } from './canvas.js';
import { FESTIVALS } from './festivals.js?v=festival-icons';
import { festivalScenes } from './festival-scenes.js?v=festival-icons';

// Each scene is a pure function of time, in 584 × 440 card coordinates.
const $ = (id) => document.getElementById(id);
const chimeCool = [145, 192, 207];
const equinoxGold = [242, 174, 111];
const equinoxBlue = [154, 180, 242];
const equinoxTwilight = [191, 172, 196];
const SOLAR_TERMS = [
  { id:'qingming', title:'清明', en:'QINGMING', date:[2027,4,5], tint:[137,175,191], caption:'烟雨过远山，一伞入清明。', note:'烟雨蓝 · 远山 · 油纸伞', still:4.3 },
  { id:'guyu', title:'谷雨', en:'GRAIN RAIN', date:[2027,4,20], tint:[174,202,141], caption:'一场春雨，万物生长。', note:'新芽绿 · 雨珠 · 新苗', still:3.78 },
  { id:'lixia', title:'立夏', en:'SUMMER BEGINS', date:[2027,5,6], tint:[111,207,180], caption:'荷风初起，蜓影点水。', note:'荷塘碧 · 蜻蜓 · 涟漪', still:9.15 },
  { id:'xiaoman', title:'小满', en:'GRAIN BUDS', date:[2027,5,21], tint:[141,202,173], caption:'一穗新青，渐盈未满。', note:'初夏青 · 麦穗透光 · 逐粒灌浆', still:4.6 },
  { id:'mangzhong', title:'芒种', en:'GRAIN IN EAR', date:[2027,6,6], tint:[230,171,89], caption:'挥手播新种，田间正当时。', note:'田野金 · 农人撒种 · 新禾', still:2.5 },
  { id:'xiazhi', title:'夏至', en:'SUMMER SOLSTICE', date:[2027,6,21], tint:[241,218,151], caption:'日长至此，午影最短。', note:'浅日金 · 石刻日晷 · 正午短影', still:5.4 },
  { id:'xiaoshu', title:'小暑', en:'MINOR HEAT', date:[2027,7,7], tint:[145,198,109], caption:'叶底蝉鸣，暑气初起。', note:'叶荫绿 · 蝉翼 · 鸣声涟漪', still:5.4 },
  { id:'dashu', title:'大暑', en:'MAJOR HEAT', date:[2027,7,23], tint:[218,226,123], caption:'暑夜微凉，草间流萤。', note:'暮靛 · 草岸 · 暑夜流萤', still:6.75 },
  { id:'liqiu', title:'立秋', en:'AUTUMN BEGINS', date:[2027,8,8], tint:[218,152,119], caption:'风过梧桐，秋从叶落。', note:'梧桐赭 · 树影 · 秋风落叶', still:4.5 },
  { id:'chushu', title:'处暑', en:'END OF HEAT', date:[2027,8,23], tint:chimeCool, caption:'晚风入檐，暑气渐收。', note:'清风蓝 · 檐下风铃 · 暑色渐退', still:6.6 },
  { id:'bailu', title:'白露', en:'WHITE DEW', date:[2027,9,8], tint:[177,207,200], caption:'芦叶托露，晨风初凉。', note:'青白 · 晨雾 · 芦叶垂露', still:7.6 },
  { id:'qiufen', title:'秋分', en:'AUTUMN EQUINOX', date:[2027,9,23], tint:equinoxTwilight, caption:'落日沉秋水，新月照远山。', note:'暖金 · 暮蓝 · 日月平分', still:6.5 },
  { id:'hanlu', title:'寒露', en:'COLD DEW', date:[2027,10,8], tint:[158,190,211], caption:'冷露凝瓣，秋菊舒开。', note:'冷蓝 · 秋菊 · 瓣尖凝露', still:7.4 },
  { id:'shuangjiang', title:'霜降', en:'FROST DESCENT', date:[2027,10,23], tint:[178,211,233], caption:'薄霜上枝，晚柿犹红。', note:'霜白 · 柿红 · 枝头结晶', still:8.2 },
  { id:'lidong', title:'立冬', en:'WINTER BEGINS', date:[2027,11,7], tint:[169,196,221], caption:'初冬生炉火，隔窗煮新茶。', note:'冷蓝 · 炉火 · 围炉煮茶', still:7.1 },
  { id:'xiaoxue', title:'小雪', en:'LIGHT SNOW', date:[2027,11,22], tint:[161,196,226], caption:'松梢接初雪，风过落几片。', note:'雪蓝 · 松针 · 枝头积雪', still:7.75 },
  { id:'daxue', title:'大雪', en:'HEAVY SNOW', date:[2027,12,7], tint:[163,190,229], caption:'风雪漫山，窗灯渐暖。', note:'雪青 · 山屋 · 暖窗', still:8.1 },
  { id:'dongzhi', title:'冬至', en:'WINTER SOLSTICE', date:[2027,12,22], tint:[218,195,173], caption:'冬至一盘饺，今夜共团圆。', note:'瓷青 · 冬饺 · 筷间暖意', still:7.4 },
  { id:'xiaohan', title:'小寒', en:'MINOR COLD', date:[2028,1,6], tint:[223,192,138], caption:'寒风过枝，腊梅次第开。', note:'蜜蜡黄 · 雪枝 · 腊梅初绽', still:8.1 },
  { id:'dahan', title:'大寒', en:'MAJOR COLD', date:[2028,1,20], tint:[162,207,233], caption:'雪覆瓦屋，檐下冰凌长。', note:'雪屋 · 檐下冰凌 · 鹅毛雪', still:8.7 },
];
const themes = [...FESTIVALS, ...SOLAR_TERMS];
const festivalIds = new Set(FESTIVALS.map(th => th.id));
const isFestival = th => festivalIds.has(th.id);
const ambientTint = [70, 200, 215];

function themeById(id) {
  const canonicalId = id === 'qingmingjie' ? 'qingming' : id;
  return themes.find(th => th.id === canonicalId);
}
const ctx = (id) => { const g = $(id).getContext('2d'); g.scale(2,2); return g; };
const scene = ctx('scene'), overlay = ctx('overlay'), light = $('light').getContext('2d');
const reducedQuery = matchMedia('(prefers-reduced-motion: reduce)');
const hoverQuery = matchMedia('(hover: hover) and (pointer: fine)');
let theme = FESTIVALS[0], collection = FESTIVALS, time = 0;
let [year, month, selected] = theme.date;
let playing = !reducedQuery.matches, raf = 0, previous = 0, entered = 0;
let fromTheme = theme, changeAt = -1, fromPill = [76,392], pill = [76,392];
let tilt = [0,0], tiltTo = [0,0], gridRows = 5, labelChangedAt = 0;
let activeScene = true, manual = Boolean(window.__MANUAL || new URLSearchParams(location.search).has('rec'));
const particles = Array.from({length:100}, (_,i) => ({x:rnd(i+700),y:rnd(i+1000),r:rnd(i+1300),speed:rnd(i+1600)}));

// A lit translucent blade, with a vein and a darker folded side.
function leaf(g,x,y,length,width,angle,c,a=1) {
  g.save();g.translate(x,y);g.rotate(angle);
  const p=new Path2D();p.moveTo(0,0);p.bezierCurveTo(-width,-length*.28,-width*.5,-length*.84,0,-length);p.bezierCurveTo(width*.62,-length*.77,width,-length*.18,0,0);
  const gr=g.createLinearGradient(-width,0,width,-length);gr.addColorStop(0,rgba(mix(c,[13,38,34],.5),a));gr.addColorStop(.48,rgba(c,a));gr.addColorStop(.7,rgba(mix(c,[239,246,202],.35),a));gr.addColorStop(1,rgba(c,a*.1));
  g.fillStyle=gr;g.fill(p);line(g,0,0,0,-length,mix(c,[225,245,207],.35),a*.45,.65);g.restore();
}
function mist(g,t,c,a=1,base=90) {
  g.save();g.globalCompositeOperation='lighter';
  for(let k=0;k<22;k++) {
    const u=k/21,p=new Path2D();
    for(let x=-20;x<=604;x+=8){const y=base+u*44+16*Math.sin(x*.009+phase(t)+u*2)+9*Math.sin(x*.019-phase(t,2)+u);if(x===-20)p.moveTo(x,y);else p.lineTo(x,y);}
    stroke(g,p,mix(c,[129,164,220],u*.28),(.017+.028*Math.sin(Math.PI*u))*a,1.2);
  }g.restore();
}
function rain(g,t,c,density=46,alpha=1,height=280) {
  for(let i=0;i<density;i++) {
    const f=particles[i],y=((f.y*height+t/LOOP*(height+38)*(1+Math.round(f.speed*2)))%(height+38))-25;
    const x=f.x*W-10*Math.sin(phase(t))+y*.08;
    line(g,x,y,x-2.1,y-7-f.r*14,c,(.08+f.r*.18)*alpha,.5+f.r*.5);
    if(f.r>.93)glow(g,x,y,7,c,.08*alpha);
  }
}
function ripple(g,x,y,u,c,a=1,scale=1) {
  if(u<=0||u>=1)return;
  g.save();g.translate(x,y);g.scale(1,.24);g.strokeStyle=rgba(c,Math.sin(u*Math.PI)*(1-u)*.65*a);g.lineWidth=.9;
  for(let i=0;i<2;i++){g.beginPath();g.arc(0,0,(5+u*38+i*6)*scale,0,TAU);g.stroke();}g.restore();
}
function motes(g,t,c,count=25,a=1,up=false) {
  for(let i=0;i<count;i++){const f=particles[i+54],p=(f.y+t/LOOP*(1+Math.round(f.speed)))%1;const x=f.x*W+Math.sin(phase(t)+i)*9,y=up?260-p*290:p*270;
    const alpha=Math.sin(Math.PI*p)*(.15+f.r*.4)*a;
    if(i%5===0)glow(g,x,y,7,c,alpha*.22);ellipse(g,x,y,.55+f.r*.8,.55+f.r*.8,c,alpha);
  }
}

function paperUmbrella(g,x,y,r,t,a=1) {
  const opening=.68+.32*(.5-.5*Math.cos(phase(t)));
  g.save();g.translate(x,y);g.rotate(-.12+Math.sin(phase(t))*.035);g.scale(r/76,r/76);
  // A curved wooden handle stays below the canopy as the paper opens.
  stroke(g,new Path2D('M0 -44V48q0 13 10 11q7 -1 7 -9'),[178,162,119],a*.8,2);
  g.save();g.scale(opening,1);
  const canopy=new Path2D('M-76 0C-52 -61 52 -61 76 0Q57 -10 38 1Q19 -10 0 1Q-19 -10 -38 1Q-57 -10 -76 0Z');
  const paper=g.createLinearGradient(-56,-45,44,15);
  paper.addColorStop(0,rgba([233,224,198],a*.94));paper.addColorStop(.45,rgba([191,198,183],a*.88));paper.addColorStop(1,rgba([96,135,145],a*.9));
  g.fillStyle=paper;g.fill(canopy);stroke(g,canopy,[226,228,207],a*.57,1);
  for(const end of [-76,-57,-38,-19,0,19,38,57,76]) {
    const rib=new Path2D();rib.moveTo(0,-45);rib.quadraticCurveTo(end*.62,-29,end,end%38===0?0:-4);
    stroke(g,rib,[96,127,131],a*.6,.7);
  }
  // Small flecks of wet paper, rather than a botanical branch silhouette.
  for(let i=0;i<29;i++)ellipse(g,(rnd(i+71)-.5)*94,-9-rnd(i+140)*20,.55,.35,[247,241,214],a*.2);
  stroke(g,new Path2D('M-73 -2Q0 -89 73 -2'),[244,237,211],a*.34,.8);
  line(g,0,-49,0,-44,[228,223,195],a,2.2);g.restore();g.restore();
}
function qingming(g,t) {
  glow(g,360,18,285,[117,158,185],.19);glow(g,500,134,139,[166,185,180],.13);
  // Broad, fading mountain silhouettes replace blossom and willow branches.
  for(let layer=0;layer<3;layer++) {
    const ridge=new Path2D(),base=81+layer*35,shift=Math.sin(phase(t)+layer)*3;
    ridge.moveTo(-20,base+75);
    for(let x=-20;x<=604;x+=4) {
      const peak=Math.sin(x*.011+layer*1.7)*22+Math.sin(x*.026+layer)*10+Math.cos(x*.043+layer)*4;
      ridge.lineTo(x,base-peak+shift);
    }
    ridge.lineTo(604,base+75);ridge.closePath();
    const ink=g.createLinearGradient(0,base-40,0,base+75);
    ink.addColorStop(0,rgba([96+layer*6,137+layer*4,155+layer*4],.16+layer*.045));ink.addColorStop(1,rgba([54,86,111],0));
    g.fillStyle=ink;g.fill(ridge);
  }
  g.save();g.scale(1,.17);
  for(let i=0;i<4;i++)glow(g,80+i*150+Math.sin(phase(t)+i)*26,590+i*110,190,[164,186,196],.07);
  g.restore();
  const ux=424+Math.sin(phase(t))*9,uy=112+Math.sin(phase(t)+.7)*3;
  ellipse(g,ux+3,201,65,6,[134,173,187],.06);
  paperUmbrella(g,ux,uy,85,t);
  rain(g,t,[189,215,231],92,1.1,285);
  for(let i=0;i<7;i++)ripple(g,65+i*76,198+rnd(i+77)*47,(t/LOOP*4+i*.17)%1,[156,190,212],.64);
}
function sprout(g,x,y,s,t,seed=0,a=1) {
  g.save();g.translate(x,y);g.scale(s,s);const bend=Math.sin(phase(t)+seed)*6;
  const p=new Path2D();p.moveTo(0,0);p.quadraticCurveTo(bend*.3,-33,bend,-72);stroke(g,p,[129,189,119],a*.8,1.15);
  leaf(g,bend*.55,-38,43,8,-.9+Math.sin(phase(t)+seed)*.06,[150,203,123],a);
  leaf(g,bend*.3,-22,53,8,.76+Math.sin(phase(t)+seed+1)*.06,[115,179,118],a);
  leaf(g,bend,-68,29,5,.17,[181,214,137],a);
  g.restore();
}
function droplet(g,x,y,r,a=1) {
  glow(g,x,y,r*3,[160,225,208],.12*a);const gr=g.createRadialGradient(x-r*.3,y-r*.4,.1,x,y,r);gr.addColorStop(0,rgba([245,255,236],a));gr.addColorStop(.25,rgba([208,240,205],a*.8));gr.addColorStop(1,rgba([107,185,159],a*.15));g.fillStyle=gr;g.beginPath();g.arc(x,y,r,0,TAU);g.fill();
}
function guyu(g,t) {
  glow(g,408,136,200,[143,199,119],.24);glow(g,131,31,225,[118,170,183],.14);mist(g,t,[138,192,141],.8,103);
  // Layers of young shoots with independent, delayed bends.
  for(let i=0;i<13;i++) {const s=.42+rnd(i+90)*.5;sprout(g,240+i*26,211+rnd(i+120)*65,s,t,i,.26+rnd(i+160)*.3);}
  sprout(g,435,238,1.63,t,.4,.9);sprout(g,507,261,1.08,t,1.5,.8);sprout(g,349,236,.91,t,2.6,.65);
  rain(g,t,[203,231,208],68,.85,270);
  const bend=Math.sin(phase(t)+.4)*6;
  droplet(g,435+(bend*.55-34)*1.63,238-61*1.63,3.2,.9);
  // A bead gathers, falls, then opens into a ripple on the same x-coordinate.
  const u=(t/3.25)%1,dropX=435+(bend*.55-34)*1.63;
  if(u<.58)droplet(g,dropX,139+out(u/.58)*96,1.4+Math.sin(u/.58*Math.PI)*1.1,.8);
  else ripple(g,dropX,235,(u-.58)/.42,[173,217,175],.9);
  for(let i=0;i<5;i++)ripple(g,105+i*99,197+rnd(i+221)*47,(t/LOOP*4+i*.23)%1,[169,209,179],.45);
}
function lotus(g,x,y,r,flat,angle,t,a=1) {
  g.save();g.translate(x,y+Math.sin(phase(t)+r)*1.2);g.rotate(angle+Math.sin(phase(t))*.014);g.scale(1,flat);
  const p=new Path2D();for(let i=0;i<=80;i++){const an=i/80*TAU,rr=r*(1+.025*Math.sin(an*7));const xx=Math.cos(an)*rr,yy=Math.sin(an)*rr;i?p.lineTo(xx,yy):p.moveTo(xx,yy);}p.closePath();
  const gr=g.createRadialGradient(-r*.25,-r*.3,1,0,0,r);gr.addColorStop(0,rgba([172,213,142],a));gr.addColorStop(.4,rgba([79,155,118],a));gr.addColorStop(1,rgba([29,81,68],a*.55));g.fillStyle=gr;g.fill(p);
  for(let i=0;i<18;i++){const an=i/18*TAU;const v=new Path2D();v.moveTo(0,0);v.quadraticCurveTo(Math.cos(an)*r*.46+3,Math.sin(an)*r*.5-3,Math.cos(an)*r*.96,Math.sin(an)*r*.96);stroke(g,v,[191,230,160],a*.21,.65);}
  stroke(g,p,[141,213,159],a*.35,.85);ellipse(g,0,0,3,3,[208,231,167],a*.7);g.restore();
}
function dragonfly(g,x,y,s,t,a=1) {
  g.save();g.translate(x,y);g.scale(s,s);g.rotate(-.12+Math.sin(phase(t))*.1);
  const flutter=.38+.3*Math.sin(phase(t,96));
  for(const side of [-1,1])for(let j=0;j<2;j++){
    g.save();g.rotate(side*(.14+j*.3));const p=new Path2D();p.moveTo(0,j*4);p.bezierCurveTo(side*10,-16*flutter,side*41,-17*flutter,side*30,0);p.bezierCurveTo(side*18,5*flutter,side*6,5,0,j*4);
    g.fillStyle=rgba([205,240,226],.12*a);g.fill(p);stroke(g,p,[203,242,220],.45*a,.6);line(g,0,j*4,side*30,-1,[193,229,217],.2*a,.5);g.restore();
  }
  const p=new Path2D('M0 -8 Q-1 2 0 20');stroke(g,p,[206,207,123],a,2);ellipse(g,0,-8,2.4,2.1,[232,234,173],a);glow(g,0,-7,8,[210,237,151],.15*a);g.restore();
}
function lixia(g,t) {
  glow(g,420,83,195,[70,180,154],.24);glow(g,160,5,250,[154,192,150],.1);mist(g,t,[105,192,179],.8,121);
  for(let i=0;i<15;i++){const y=100+i*8;line(g,285+rnd(i+600)*140,y,400+rnd(i+640)*145,y,[130,205,178],.04,.7);}
  lotus(g,485,155,67,.57,-.22,t,.7);lotus(g,386,106,53,.62,.12,t,.88);lotus(g,525,69,33,.65,-.3,t,.45);
  const stem=new Path2D('M453 213 Q460 148 448 78');stroke(g,stem,[114,180,126],.65,1.5);
  for(let i=0;i<5;i++)leaf(g,448+(i-2)*2,83,24+Math.abs(i-2)*-3,5.6,(i-2)*.17,[221,172,186],.85);glow(g,448,65,24,[221,172,186],.08);
  const dx=303+Math.cos(phase(t))*81,dy=65+Math.sin(phase(t,2)) *15;
  glow(g,dx+10,dy+72,26,[93,178,161],.06);dragonfly(g,dx,dy,.83,t,.95);
  for(let i=0;i<4;i++)ripple(g,253+i*87,178+rnd(i+44)*47,(t/LOOP*3+i*.27)%1,[116,211,188],.65);
  motes(g,t,[180,229,175],17,.6,true);
}
// A macro study of one swelling green wheat grain, rather than another field.
const wheatStem = new Path2D('M-18 23C-12 5 -5 -26 0 -52Q5 -98 2 -157');
const wheatLeafLeft = new Path2D('M-9 -16C-36 -31 -64 -62 -123 -43C-77 -45 -50 -15 -9 -16Z');
const wheatLeafRight = new Path2D('M-8 -27C14 -53 47 -61 93 -92C63 -55 25 -46 -8 -27Z');
const wheatVeins = new Path2D('M-8 -16C-52 -25 -78 -46 -112 -44M-8 -27Q47 -64 83 -85');
const glume = new Path2D('M0 3C-13 -4 -16 -21 -10 -32Q-6 -39 0 -44Q9 -38 13 -25C16 -13 10 -1 0 3Z');
const wheatAwn = new Path2D('M0 -42Q1 -53 -4 -64');
const grain = new Path2D('M0 0C-8 -3 -11 -18 -6 -29Q-3 -35 0 -36C7 -31 10 -21 9 -11Q7 -2 0 0Z');
const grainVein = new Path2D('M1 -1Q-4 -18 0 -32');
const glumeGradient = [[0, [67, 128, 104]], [.54, [168, 213, 155]], [1, [89, 159, 136]]];
const grainGradient = [[0, [48, 112, 88]], [.38, [155, 206, 146]], [.64, [218, 232, 174]], [1, [83, 159, 124]]];

function wheatFill(t, tier = 2) {
  const start = .12 + tier * .65;
  return smooth(start, start + 1.45, t)
    * (1 - smooth(9.3 + tier * .12, LOOP, t));
}

function spikelet(g, y, angle, scale, filling) {
  g.save();
  g.translate(2, y);
  g.rotate(angle);
  g.scale(scale, scale);
  const husk = g.createLinearGradient(-13, -14, 14, -14);
  for (const [stop, color] of glumeGradient) husk.addColorStop(stop, rgba(color, .19));
  g.fillStyle = husk;
  g.fill(glume);
  stroke(g, glume, [157, 211, 169], .34 + filling * .25, .72);
  stroke(g, wheatAwn, [185, 214, 164], .56, .62);

  // The outer husk stays in place while the grain swells inside it.
  g.save();
  g.clip(glume);
  g.scale(lerp(.30, 1, filling), lerp(.49, 1, filling));
  const skin = g.createLinearGradient(-9, -4, 9, -30);
  for (const [stop, color] of grainGradient) skin.addColorStop(stop, rgba(color, .26 + filling * .72));
  g.fillStyle = skin;
  g.fill(grain);
  stroke(g, grainVein, [57, 111, 83], .25 + filling * .32, .78);
  g.clip(grain);
  const sheen = 4 * filling * (1 - filling);
  glow(g, -2, lerp(-1, -33, filling), 15, [245, 255, 181], .82 * sheen);
  g.restore();
  g.restore();
}

function wheatEar(g, x, y, scale, angle, t, leaves = false) {
  g.save();
  g.translate(x, y);
  g.rotate(angle + Math.sin(phase(t, 2)) * .12 + Math.sin(phase(t)) * .045);
  g.scale(scale, scale);
  if (leaves) {
    const blade = g.createLinearGradient(-89, -71, 64, -58);
    blade.addColorStop(0, 'rgba(69,120,110,.12)');
    blade.addColorStop(.46, 'rgba(83,154,124,.64)');
    blade.addColorStop(1, 'rgba(173,204,143,.26)');
    g.fillStyle = blade;
    g.fill(wheatLeafLeft);
    g.fill(wheatLeafRight);
    stroke(g, wheatVeins, [152, 198, 148], .36, .86);
  }
  stroke(g, wheatStem, [117, 169, 125], .86, 2.15);
  for (let tier = 0; tier < 6; tier++) {
    const y = -46 - tier * 16;
    const tierScale = 1.07 - tier * .102;
    const angle = .86 - tier * .087;
    // Later tiers fill later and stay smaller at the tip.
    const filling = wheatFill(t, tier) * (1 - tier * .065);
    spikelet(g, y, -angle, tierScale, filling);
    spikelet(g, y - 7, angle * .92, tierScale * .94, filling);
  }
  spikelet(g, -141, .06, .49, wheatFill(t, 5) * .54);
  if (leaves) {
    const lightLevel = .82 + Math.sin(phase(t, 1, .55)) * .14;
    droplet(g, -49, -32, 4.2, lightLevel);
    droplet(g, 21, -114, 2.7, lightLevel);
  }
  g.restore();
}

function xiaoman(g, t) {
  glow(g, 412, 104, 252, [89, 167, 138], .27);
  glow(g, 159, 20, 228, [104, 144, 174], .13);
  glow(g, 435, 98, 115, [176, 213, 157], .16 * wheatFill(t));

  // Grazing light picks out the awns while the date label stays in shadow.
  g.save();
  g.translate(405, 64);
  g.rotate(.26);
  g.scale(.64, 1.54);
  glow(g, 0, 0, 126, [169, 218, 177], .12);
  g.restore();
  wheatEar(g, 398, 222, 1.18, .19, t, true);
}

const sowingPeriod = LOOP / 2;
const farmer = {x: 333, y: 94, hip: 36};
const trousers = new Path2D('M-11 31L10 31L23 95L11 97L-1 59L-16 97L-28 95L-16 50Z');
const trouserSeams = new Path2D('M-12 49L-22 86M8 51L17 86');
const tunic = new Path2D('M-11 -8Q-1 -13 13 -4L18 36Q4 44 -18 35L-19 11Z');
const tunicSeams = new Path2D('M-3 -6L4 7L12 -1M3 7L0 33M-14 29L16 32');
const face = new Path2D('M12 -26L19 -20L13 -17Z');
const seedBasket = new Path2D('M-24 21Q-10 16 3 23L-1 38Q-10 44 -20 36Z');
const hatCone = new Path2D('M-30 2Q-10 -16 2 -19Q16 -12 30 2Z');
const hatRim = new Path2D('M-31 1Q0 11 31 1');
const terrain = Array.from({length: 4}, (_, i) => {
  const ridge = new Path2D();
  ridge.moveTo(183, 180 + i * 19);
  ridge.bezierCurveTo(333, 142 + i * 21, 454, 194 + i * 13, 610, 161 + i * 20);
  return ridge;
});

function strawHat(g, x, y, s, angle) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(s, s);
  const straw = g.createLinearGradient(-24, -10, 22, 4);
  straw.addColorStop(0, '#efca86');
  straw.addColorStop(.52, '#b68c51');
  straw.addColorStop(1, '#6e5537');
  g.fillStyle = straw;
  g.fill(hatCone);
  ellipse(g, 0, 2, 33, 5, [184, 145, 87]);
  for (let i = -5; i <= 5; i++) {
    line(g, 2, -17, i * 5.7, 2, [239, 206, 143], .34, .55);
  }
  stroke(g, hatRim, [243, 211, 151], .75, .85);
  g.restore();
}

function sowingPose(u) {
  const cast = smooth(.12, .43, u) * (1 - smooth(.50, .76, u));
  const lean = -.082 + cast * .13;
  const shoulderX = 11;
  const wristX = 18 + 51 * cast;
  const wristY = 24 - 39 * cast;
  const direction = Math.atan2(wristY, wristX - shoulderX);
  const halfReach = Math.hypot(wristX - shoulderX, wristY) / 2;
  const bend = Math.sqrt(31 ** 2 - halfReach ** 2);
  const elbowX = shoulderX + Math.cos(direction) * halfReach - Math.sin(direction) * bend;
  const elbowY = Math.sin(direction) * halfReach + Math.cos(direction) * bend;
  return {lean, shoulderX, wristX, wristY, elbowX, elbowY, direction};
}

function sowingFarmer(g, u) {
  const pose = sowingPose(u);
  g.save();
  g.translate(farmer.x, farmer.y);
  ellipse(g, -2, 98, 40, 4.6, [232, 183, 111], .13);
  g.fillStyle = '#414c40';
  g.fill(trousers);
  stroke(g, trouserSeams, [142, 150, 113], .38, .9);
  line(g, -27, 96, -14, 97, [126, 127, 102], .96, 3);
  line(g, 11, 97, 25, 96, [126, 127, 102], .96, 3);

  // The tunic turns from the hips. The two feet and both upper/lower arm lengths stay fixed.
  g.translate(0, farmer.hip);
  g.rotate(pose.lean);
  g.translate(0, -farmer.hip);
  const cloth = g.createLinearGradient(-21, -2, 18, 34);
  cloth.addColorStop(0, '#c49a64');
  cloth.addColorStop(.5, '#8b704c');
  cloth.addColorStop(1, '#524f3e');
  g.fillStyle = cloth;
  g.fill(tunic);
  stroke(g, tunicSeams, [229, 196, 136], .52, 1);
  line(g, 5, -17, 5, -6, [164, 126, 88], 1, 6);
  ellipse(g, 7, -23, 8.8, 11.5, [188, 148, 102], 1, .1);
  g.fillStyle = '#c6996b';
  g.fill(face);
  strawHat(g, 5, -32, .89, -.13);

  line(g, pose.shoulderX, 0, pose.elbowX, pose.elbowY, [159, 125, 80], 1, 9);
  line(g, pose.elbowX, pose.elbowY, pose.wristX, pose.wristY, [198, 157, 110], 1, 5.4);
  ellipse(g, pose.wristX + 2, pose.wristY, 4.5, 2.9, [205, 164, 115], 1, pose.direction);
  line(g, -13, 1, -25, 18, [160, 126, 82], 1, 8);
  line(g, -25, 18, -13, 26, [183, 141, 97], 1, 4.6);
  g.fillStyle = '#926b41';
  g.fill(seedBasket);
  ellipse(g, -10, 23, 14, 4, [219, 179, 105], .96);
  for (let i = 0; i < 4; i++) {
    line(g, -21 + i * 6, 25, -17 + i * 4, 37, [235, 197, 127], .45, .65);
  }
  line(g, -21, 30, 0, 32, [229, 194, 121], .5, .6);
  line(g, -19, 35, -2, 37, [229, 194, 121], .45, .6);
  g.restore();
}

const seeds = Array.from({length: 24}, (_, i) => {
  const born = .30 + rnd(i + 2300) * .106;
  const pose = sowingPose(born);
  const handX = pose.wristX + 4;
  const handY = pose.wristY - farmer.hip;
  const cos = Math.cos(pose.lean);
  const sin = Math.sin(pose.lean);
  return {
    born,
    flight: .24 + rnd(i + 2430) * .10,
    startX: farmer.x + cos * handX - sin * handY,
    startY: farmer.y + farmer.hip + sin * handX + cos * handY,
    endX: 430 + i * 5.75 + rnd(i + 2350) * 9,
    endY: 182 + rnd(i + 2400) * 33,
    lift: 39 + rnd(i + 2450) * 24,
    shootSize: .67 + .46 * rnd(i + 2510),
    grows: i % 4 === 0,
  };
});

const shootBlades = [
  {length: 24, bend: -17},
  {length: 34, bend: -10},
  {length: 32, bend: 3},
  {length: 26, bend: 13},
];

function riceTuft(g, x, y, t, growth, a) {
  g.save();
  g.translate(x, y);
  for (const blade of shootBlades) {
    const length = blade.length * growth;
    const bend = blade.bend * growth + Math.sin(phase(t, 2, x * .023)) * growth * 2.3;
    const path = new Path2D();
    path.moveTo(0, 0);
    path.quadraticCurveTo(bend * .14, -length * .57, bend, -length);
    path.quadraticCurveTo(bend * .52 + 1.6, -length * .38, 1, 0);
    const sap = g.createLinearGradient(0, 0, bend, -length);
    sap.addColorStop(0, rgba([45, 112, 77], a * .82));
    sap.addColorStop(.54, rgba([107, 177, 101], a));
    sap.addColorStop(1, rgba([196, 228, 144], a));
    g.fillStyle = sap;
    g.fill(path);
  }
  g.restore();
}

function mangzhong(g, t) {
  glow(g, 434, 54, 237, [234, 164, 74], .24);
  glow(g, 464, 205, 164, [134, 173, 125], .12);
  glow(g, 434, 51, 64, [238, 188, 107], .16);
  ellipse(g, 434, 51, 18, 18, [239, 197, 128], .17);
  terrain.forEach((ridge, i) => stroke(g, ridge, [182, 162, 104], .13 - i * .019, 1.1));

  const u = (t % sowingPeriod) / sowingPeriod;
  sowingFarmer(g, u);
  for (const seed of seeds) {
    const p = (u - seed.born) / seed.flight;
    if (p < 0) continue;
    if (p < 1) {
      const x = lerp(seed.startX, seed.endX, p);
      const y = lerp(seed.startY, seed.endY, p) - seed.lift * 4 * p * (1 - p);
      const slope = seed.endY - seed.startY - seed.lift * 4 * (1 - 2 * p);
      const direction = Math.atan2(slope, seed.endX - seed.startX);
      const a = lerp(.45, .99, smooth(0, .17, p));
      if (seed.grows) glow(g, x, y, 8, [254, 207, 131], .2 * a);
      ellipse(g, x, y, 2.65, 1.24, [254, 207, 131], a, direction);
      continue;
    }

    const landed = u - seed.born - seed.flight;
    const fade = 1 - smooth(.92, 1, u);
    const shine = (1 - smooth(0, .055, landed)) * fade;
    glow(g, seed.endX, seed.endY, 7, [244, 202, 125], .21 * shine);
    if (seed.grows && landed > .018) {
      const growth = smooth(.018, .24, landed) * seed.shootSize;
      riceTuft(g, seed.endX, seed.endY, t, growth, fade * .86);
    }
  }
}
const solsticeSun = [255, 226, 153];
const dialSide = new Path2D('M-104 0C-104 24 -58 43 0 43C58 43 104 24 104 0V12C104 36 58 55 0 55C-58 55 -104 36 -104 12Z');
const dialFoot = new Path2D('M-51 32H51L46 60Q0 81 -46 60Z');
const dialNeedle = new Path2D('M-7 3L-3 -42L17 -1L8 6Z');
const needleEdge = new Path2D('M-3 -42L17 -1L8 6Z');
const dialFace = new Path2D();
dialFace.ellipse(0, 0, 104, 43, 0, 0, TAU);
const dialGroove = new Path2D();
dialGroove.ellipse(0, 0, 91, 37.6, 0, 0, TAU);
const dialHours = Array.from({length: 25}, (_, i) => {
  const angle = i / 24 * Math.PI;
  const inner = i % 4 === 0 ? 79 : 86;
  const x = Math.cos(angle), y = Math.sin(angle) * .414;
  const path = new Path2D();
  path.moveTo(inner * x, inner * y);
  path.lineTo(98 * x, 98 * y);
  return {angle, path, major: i % 4 === 0};
});

function sunPosition(progress) {
  return [288 + 170 * progress, 94 - 66 * Math.sin(Math.PI * progress)];
}

const sunArc = new Path2D();
sunArc.moveTo(...sunPosition(0));
for (let i = 1; i <= 32; i++) sunArc.lineTo(...sunPosition(i / 32));

function solsticeLight(t) {
  const dawn = t >= 11.8;
  const progress = dawn ? 0 : clamp(t / 10.8);
  const opacity = dawn ? smooth(11.8, LOOP, t) : 1 - smooth(10.8, 11.8, t);
  const altitude = Math.sin(Math.PI * progress);
  const shadowAngle = lerp(.045, Math.PI - .045, progress);
  return {progress, opacity, altitude, shadowAngle};
}

function dialShadow(g, {shadowAngle, altitude, opacity}) {
  const length = lerp(94, 18, altitude);
  const x = Math.cos(shadowAngle) * length;
  const y = Math.sin(shadowAngle) * length * .414;
  const shade = g.createLinearGradient(0, 0, x, y);
  shade.addColorStop(0, rgba([21, 31, 37], .84 * opacity));
  shade.addColorStop(1, rgba([36, 43, 46], .60 * opacity));
  const path = new Path2D();
  path.moveTo(-5, -1);
  path.quadraticCurveTo(x * .38, y * .4 - 3, x, y);
  path.quadraticCurveTo(x * .4 + 5, y * .52 + 6, 10, 4);
  path.closePath();
  g.fillStyle = shade;
  g.fill(path);
}

function xiazhi(g, t) {
  const daylight = solsticeLight(t);
  const [sunX, sunY] = sunPosition(daylight.progress);
  const a = daylight.opacity;
  glow(g, 421, 120, 240, [105, 146, 170], .19);
  glow(g, sunX, sunY, 182, solsticeSun, (.16 + daylight.altitude * .16) * a);
  stroke(g, sunArc, [218, 211, 172], .18, .8);
  glow(g, sunX, sunY, 45, solsticeSun, .46 * a);
  ellipse(g, sunX, sunY, 9.2, 9.2, [255, 245, 200], .95 * a);

  g.save();
  g.translate(421, 154);
  ellipse(g, 4, 66, 101, 14, [13, 21, 29], .22);
  const pedestal = g.createLinearGradient(-51, 35, 51, 66);
  pedestal.addColorStop(0, '#515b59');
  pedestal.addColorStop(.52, '#3c4c51');
  pedestal.addColorStop(1, '#26343c');
  g.fillStyle = pedestal;
  g.fill(dialFoot);

  const rim = g.createLinearGradient(-102, 20, 100, 29);
  rim.addColorStop(0, '#69716a');
  rim.addColorStop(.48, '#909383');
  rim.addColorStop(1, '#414f54');
  g.fillStyle = rim;
  g.fill(dialSide);

  const face = g.createLinearGradient(-82, -28, 75, 39);
  face.addColorStop(0, '#b5b7a0');
  face.addColorStop(.44, '#a2aa9d');
  face.addColorStop(1, '#657879');
  g.fillStyle = face;
  g.fill(dialFace);
  g.save();
  g.clip(dialFace);
  const gleamX = lerp(-70, 70, daylight.progress);
  glow(g, gleamX, -13, 103, [255, 236, 178], (.32 + daylight.altitude * .34) * a);
  g.restore();
  stroke(g, dialFace, [218, 216, 180], .78, 1.2);
  stroke(g, dialGroove, [66, 82, 82], .60, .7);

  for (const hour of dialHours) {
    stroke(g, hour.path, [51, 66, 69], hour.major ? .88 : .60, hour.major ? 1.6 : .9);
    const lit = (1 - smooth(.02, .15, Math.abs(hour.angle - daylight.shadowAngle))) * a;
    if (lit > 0) stroke(g, hour.path, [255, 237, 164], lit, 1.4);
  }
  dialShadow(g, daylight);
  g.fillStyle = '#3a5155';
  g.fill(dialNeedle);
  const metal = g.createLinearGradient(-3, -42, 12, 5);
  metal.addColorStop(0, '#f4db9a');
  metal.addColorStop(.52, '#a7aa90');
  metal.addColorStop(1, '#617573');
  g.fillStyle = metal;
  g.fill(needleEdge);
  line(g, -3, -42, -7, 3, [218, 216, 174], .64, .9);
  g.restore();
}

function xiazhiBadge(g, t) {
  const daylight = solsticeLight(t);
  ellipse(g, 0, 4, 24, 10, [71, 94, 94]);
  ellipse(g, 0, 0, 24, 10, [225, 220, 176]);
  g.save();
  g.scale(.24, .24);
  dialShadow(g, daylight);
  g.fillStyle = '#324b4c';
  g.fill(dialNeedle);
  g.restore();
  const x = lerp(-15, 15, daylight.progress);
  const y = -12 - 8 * daylight.altitude;
  ellipse(g, x, y, 4.9, 4.9, [255, 242, 183], daylight.opacity);
}

const cicadaCalls = [.32, 1.25, 4.2, 5.05, 8.4, 9.23, 10.06];
const cicadaPerch = [426, 111];
const cicadaBranch = new Path2D('M268 242C365 203 440 105 584 68L602 95C475 127 400 219 278 258Z');
const cicadaBark = new Path2D('M291 244C405 191 455 115 580 84M352 222C398 198 425 163 474 133');
const cicadaWing = new Path2D('M3 -23C24 -17 37 14 32 34Q27 56 13 58C4 50 0 33 0 14Z');
const cicadaVeins = new Path2D('M4 -18C19 3 21 34 13 56M13 -7Q23 1 29 17M17 10Q27 17 32 29M19 27Q26 32 29 42M17 41Q22 46 23 51M16 14Q9 27 7 43');
const cicadaBody = new Path2D('M0 -29C-19 -27 -21 -8 -16 18C-15 36 -7 49 0 53C7 49 15 36 16 18C21 -8 19 -27 0 -29Z');
const cicadaThorax = new Path2D('M-16 -27Q0 -37 16 -27L18 -10Q0 7 -18 -10Z');
const cicadaHead = new Path2D('M-14 -28Q-20 -38 -11 -43Q1 -49 13 -42Q19 -38 14 -28Q0 -24 -14 -28Z');
const cicadaLegs = new Path2D('M11 -23L25 -27L32 -20L30 -15M15 -12L31 -11L38 0L35 5M14 1L30 7L35 19L31 23');
const cicadaRibs = Array.from({length: 6}, (_, i) => {
  const y = 3 + i * 6;
  const width = 13 - i * 1.35;
  const rib = new Path2D();
  rib.moveTo(-width, y);
  rib.quadraticCurveTo(0, y + 4, width, y);
  return rib;
});
const canopy = [
  [310, 0, 121, 35, 2.76, [72, 118, 74], .40],
  [365, -12, 99, 28, -2.44, [104, 142, 78], .36],
  [555, 6, 112, 29, -1.97, [98, 138, 68], .29],
  [589, 91, 105, 26, -1.38, [124, 160, 76], .57],
  [518, 113, 89, 26, 1.71, [70, 125, 79], .55],
  [373, 193, 109, 32, -.99, [116, 149, 75], .62],
  [354, 202, 89, 25, -1.78, [72, 119, 77], .45],
];

function cicadaEnergy(t) {
  let maximum = 0;
  for (const onset of cicadaCalls) {
    const age = t - onset;
    maximum = Math.max(maximum, smooth(0, .14, age) * (1 - smooth(.19, .7, age)));
  }
  return maximum;
}

function cicada(g, x, y, scale, angle, t, strength, detail = true) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(scale, scale);
  const quiver = Math.sin(phase(t, 118)) * strength;

  if (detail) {
    for (const side of [-1, 1]) {
      g.save();
      g.scale(side, 1);
      stroke(g, cicadaLegs, [121, 136, 86], .85, 2.1);
      g.restore();
    }
  }

  g.save();
  g.scale(1, 1 + .018 * quiver);
  const body = g.createLinearGradient(-17, 0, 17, 9);
  body.addColorStop(0, '#53714a');
  body.addColorStop(.46, '#819655');
  body.addColorStop(1, '#293f38');
  g.fillStyle = body;
  g.fill(cicadaBody);
  for (const rib of cicadaRibs) stroke(g, rib, [38, 59, 42], .62, 1.2);
  g.restore();

  for (const side of [-1, 1]) {
    g.save();
    g.scale(side, 1);
    g.rotate(-.034 - strength * .13 + quiver * .032);
    const membrane = g.createLinearGradient(2, -21, 33, 37);
    membrane.addColorStop(0, rgba([218, 229, 153], .70));
    membrane.addColorStop(.52, rgba([184, 210, 148], .52 + strength * .12));
    membrane.addColorStop(1, rgba([157, 199, 138], .24));
    g.fillStyle = membrane;
    g.fill(cicadaWing);
    stroke(g, cicadaWing, [222, 242, 175], .70, detail ? 1.05 : 2.7);
    if (detail) stroke(g, cicadaVeins, [230, 238, 179], .64, .8);
    g.restore();
  }

  g.fillStyle = '#5f7545';
  g.fill(cicadaThorax);
  stroke(g, cicadaThorax, [184, 197, 117], .75, detail ? .85 : 2);
  g.fillStyle = '#809458';
  g.fill(cicadaHead);
  for (const side of [-1, 1]) {
    ellipse(g, side * 13, -37, 5.1, 6.3, [23, 40, 34], .96, side * .22);
    ellipse(g, side * 13 - 1.1, -39, 1.4, 1.4, [226, 239, 168], .70);
  }
  g.restore();
}

function xiaoshu(g, t) {
  const strength = cicadaEnergy(t);
  const sway = Math.sin(phase(t));
  glow(g, 410, 75, 252, [101, 155, 97], .23);
  glow(g, 180, 108, 235, [70, 139, 142], .15);
  glow(g, 475 + sway * 24, 22, 179, [210, 220, 127], .20);
  glow(g, 424, 112, 124, [198, 219, 120], .16 * strength);

  for (const [i, [x, y, length, width, angle, color, opacity]] of canopy.entries()) {
    const breeze = Math.sin(phase(t, 2, i * .65)) * .13;
    leaf(g, x, y, length, width, angle + breeze, color, opacity);
  }
  const bark = g.createLinearGradient(298, 221, 567, 85);
  bark.addColorStop(0, 'rgba(53,67,51,.28)');
  bark.addColorStop(.53, 'rgba(113,110,64,.95)');
  bark.addColorStop(1, 'rgba(70,92,63,.78)');
  g.fillStyle = bark;
  g.fill(cicadaBranch);
  stroke(g, cicadaBark, [177, 166, 98], .36, 1.4);

  // Each call sends a pair of expanding arcs into the shade.
  for (const onset of cicadaCalls) {
    const progress = (t - onset) / 1.58;
    if (progress <= 0 || progress >= 1) continue;
    const radius = 23 + 112 * progress;
    const wave = new Path2D();
    wave.ellipse(cicadaPerch[0], cicadaPerch[1] + 6, radius, radius * .68, -.22, -2.9, .65);
    const echo = new Path2D();
    echo.ellipse(cicadaPerch[0], cicadaPerch[1] + 6, radius * .88, radius * .60, -.22, .74, 2.55);
    wave.addPath(echo);
    const opacity = Math.sin(Math.PI * progress) * (1 - progress * .55);
    stroke(g, wave, [220, 236, 147], .62 * opacity, 1.5);
  }
  cicada(g, ...cicadaPerch, 1.14, .64 + sway * .018, t, strength);
}

const fireflyGold = [224, 239, 122];
const nightBank = new Path2D('M238 232C323 220 338 185 429 196C479 201 537 183 587 173L587 283L238 283Z');
const bankEdge = new Path2D('M238 232C323 220 338 185 429 196C479 201 537 183 587 173');
const grassBlade = new Path2D('M0 0C-7 -22 -19 -44 -35 -61C-14 -53 0 -32 0 0Z');
const grassVein = new Path2D('M0 0Q-9 -35 -31 -55');
const dashuGrass = [
  [277, 232, .61, -.25, [89, 125, 99], .41],
  [278, 232, -.56, .37, [96, 135, 115], .36],
  [333, 214, .50, -.28, [91, 118, 111], .47],
  [541, 220, .86, .23, [87, 125, 117], .60],
  [548, 222, -.91, -.46, [102, 143, 108], .58],
  [557, 224, 1.05, .50, [117, 145, 99], .62],
  [571, 223, -.89, .19, [121, 145, 93], .55],
];
const nearestFireflies = [
  {x:394, y:131, rx:105, ry:43, turns:1, offset:.21, beats:3, pulse:.46, size:3.55},
  {x:437, y:101, rx:72, ry:31, turns:2, offset:2.3, beats:2, pulse:2.05, size:2.65},
  {x:473, y:148, rx:56, ry:46, turns:1, offset:4.07, beats:3, pulse:4.1, size:3.4},
  {x:365, y:166, rx:79, ry:32, turns:2, offset:5.1, beats:4, pulse:1.2, size:2.8},
];
const distantFireflies = Array.from({length: 15}, (_, i) => ({
  x: 280 + rnd(i + 7300) * 274,
  y: 79 + rnd(i + 7340) * 114,
  rx: 12 + rnd(i + 7380) * 33,
  ry: 8 + rnd(i + 7420) * 16,
  turns: 1 + (i % 2),
  offset: rnd(i + 7460) * TAU,
  beats: 2 + (i % 3),
  pulse: rnd(i + 7500) * TAU,
  size: .72 + rnd(i + 7540) * .82,
}));

function fireflyPosition(fly, t) {
  const travel = phase(t, fly.turns, fly.offset);
  return [
    fly.x + fly.rx * Math.sin(travel) + Math.sin(phase(t, 3, fly.offset)) * 9,
    fly.y + fly.ry * Math.cos(travel + .49) + Math.sin(phase(t, 4, fly.offset)) * 5,
  ];
}

function fireflyPulse(t, beats, offset) {
  const light = .5 + .5 * Math.sin(phase(t, beats, offset));
  return .16 + .84 * light ** 2.3;
}

function firefly(g, fly, t, near) {
  const [x, y] = fireflyPosition(fly, t);
  const light = fireflyPulse(t, fly.beats, fly.pulse);
  const radius = fly.size;
  if (near) {
    // Sample the fly's own trajectory to leave a short trail as it lights up.
    let previous = fireflyPosition(fly, t - .32);
    for (let step = 1; step <= 5; step++) {
      const position = fireflyPosition(fly, t - .32 * (1 - step / 5));
      line(g, ...previous, ...position, fireflyGold, light * step / 10, radius * .96);
      previous = position;
    }
    glow(g, x, y, 24, fireflyGold, light * .46);
    ellipse(g, x, y, radius * 1.23, radius * .80, [248, 254, 178], light);
  } else {
    glow(g, x, y, radius * 7, fireflyGold, light * .24);
    ellipse(g, x, y, radius, radius, [235, 244, 165], light * .70);
  }
}

function grass(g, x, y, scale, angle, color, opacity) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(scale, Math.abs(scale));
  const pigment = g.createLinearGradient(-31, -57, 0, 0);
  pigment.addColorStop(0, rgba(color, opacity));
  pigment.addColorStop(1, rgba(mix(color, [34, 59, 65], .7), opacity * .5));
  g.fillStyle = pigment;
  g.fill(grassBlade);
  stroke(g, grassVein, color, opacity * .60, .65);
  g.restore();
}

function dashu(g, t) {
  glow(g, 418, 118, 258, [83, 108, 174], .30);
  glow(g, 237, 60, 259, [80, 109, 152], .14);
  glow(g, 523, 211, 202, [77, 132, 130], .15);
  const ground = g.createLinearGradient(0, 180, 0, 272);
  ground.addColorStop(0, 'rgba(27,43,64,.79)');
  ground.addColorStop(1, 'rgba(25,44,52,0)');
  g.fillStyle = ground;
  g.fill(nightBank);
  stroke(g, bankEdge, [113, 157, 143], .24, .95);
  for (const [i, [x, y, scale, angle, color, opacity]] of dashuGrass.entries()) {
    const sway = Math.sin(phase(t, 2, i * .74)) * .12;
    grass(g, x, y, scale, angle + sway, color, opacity);
  }

  for (const fly of distantFireflies) firefly(g, fly, t, false);
  for (const fly of nearestFireflies) firefly(g, fly, t, true);
}

function dashuBadge(g, t) {
  grass(g, 5, 15, .55, -.12 + Math.sin(phase(t)) * .10, [148, 191, 120], .92);
  grass(g, 5, 15, -.38, .19, [167, 197, 123], .83);
  const x = -6 + Math.sin(phase(t, 2)) * 8;
  const y = -12 + Math.cos(phase(t, 2)) * 6;
  const glowLevel = .50 + .50 * fireflyPulse(t, 3, .9);
  glow(g, x, y, 17, fireflyGold, .43 * glowLevel);
  ellipse(g, x, y, 6, 4.3, [248, 253, 187], glowLevel, -.23);
  ellipse(g, 13, -16, 3.1, 3.1, [238, 247, 159], .62 + .31 * fireflyPulse(t, 3, 2.3));
}

const autumnLeafShape = new Path2D(
  'M0 39C-10 31 -22 33 -33 25C-40 21 -48 9 -52 3Q-41 0 -31 6Q-35 -6 -46 -25Q-28 -22 -17 -13Q-20 -24 -16 -37Q-6 -41 1 -58Q11 -43 19 -35Q23 -25 17 -11Q32 -24 48 -25Q39 -8 31 3Q45 -1 51 4C39 22 27 28 16 31Q8 33 0 39Z',
);
const autumnLeafStalk = new Path2D('M0 36Q-3 44 7 56');
const autumnLeafVeins = new Path2D(
  'M0 38Q-6 9 1 -55M-1 29Q-26 20 -48 5M-2 18Q-29 5 -42 -21M-4 3Q-17 -10 -14 -33M0 30Q24 21 48 5M-1 18Q24 8 45 -22M-1 2Q14 -13 17 -34',
);
const autumnFineVeins = new Path2D(
  'M-12 24Q-25 27 -36 20M-20 14L-34 9M-18 8L-27 -9M-15 -4L-30 -13M-5 -20L-12 -25M14 23Q24 26 30 20M15 10Q30 7 34 0M13 5L20 -14M6 -18L14 -28',
);
const autumnWater = new Path2D(
  'M-12 282C94 279 165 233 229 218C300 202 347 208 403 214C466 221 520 202 584 199L584 290H-12Z',
);
const autumnHorizon = new Path2D('M224 218C302 199 350 208 403 214C466 221 520 202 584 199');
const autumnGold = [230, 162, 102];
const autumnCrown = new Path2D(
  'M277 99C271 85 284 63 304 54C295 35 325 16 351 23C364 3 394 5 412 16C428 5 455 12 464 28C487 24 507 38 511 58C538 59 545 81 533 99C538 114 514 128 489 128C480 145 450 149 432 135C408 151 379 150 363 135C336 143 321 129 313 120C291 123 280 115 277 99Z',
);
const autumnTrunk = new Path2D(
  'M389 224C402 216 407 193 412 165C420 123 414 95 404 69L410 61C425 84 432 117 428 155C426 186 426 215 444 226C424 222 415 228 389 224Z',
);
const autumnBoughs = [
  ['M417 133Q400 108 372 93Q350 79 315 81', 6.7],
  ['M416 113Q405 91 388 72Q378 60 361 45', 5.0],
  ['M422 108Q424 72 414 39Q408 27 395 19', 4.7],
  ['M425 139Q442 105 463 94Q483 82 511 79', 6.2],
  ['M428 121Q441 95 448 68Q456 46 473 36', 4.4],
  ['M438 121Q461 113 492 115', 3.5],
  ['M395 104Q369 109 345 117', 3.1],
  ['M386 74Q360 77 334 62', 2.6],
].map(([path, width]) => ({path: new Path2D(path), width}));
const autumnBark = new Path2D('M413 214Q423 172 421 128Q422 104 414 83M421 214Q420 192 424 172');
const autumnTreeLeaves = [
  [302, 90, .22, -.82, .38, .65], [319, 67, .26, -1.41, .57, .82],
  [332, 100, .24, .93, .76, .63], [347, 45, .27, -.55, .45, .72],
  [357, 78, .25, 1.08, .42, .84], [366, 31, .22, -.47, .68, .72],
  [375, 110, .30, .48, .66, .81], [379, 66, .30, -1.12, .77, .87],
  [393, 43, .28, -.48, .49, .80], [408, 20, .22, .22, .46, .56],
  [407, 107, .27, -.62, .51, .77], [424, 55, .29, .63, .59, .88],
  [436, 38, .23, .94, .63, .61], [439, 110, .26, -.47, .68, .71],
  [453, 80, .28, 1.25, .78, .76], [467, 52, .26, .96, .58, .58],
  [481, 98, .27, -.72, .70, .66], [496, 69, .25, .63, .71, .53],
  [510, 92, .25, 1.43, .68, .55], [491, 122, .22, 1.24, .75, .59],
];
const autumnDrops = [
  {from:[333,94], to:[301,228], start:.32, travel:3.70, size:.31, angle:-.45, drift:-22, color:.55},
  {from:[466,100], to:[491,222], start:1.42, travel:4.15, size:.32, angle:.78, drift:32, color:.65, water:true},
  {from:[383,78], to:[356,221], start:2.70, travel:3.50, size:.37, angle:-.81, drift:-27, color:.43},
  {from:[500,106], to:[542,222], start:4.14, travel:3.75, size:.26, angle:.54, drift:23, color:.68, water:true},
  {from:[419,89], to:[464,229], start:5.44, travel:3.50, size:.33, angle:-.38, drift:-24, color:.52, water:true},
  {from:[355,105], to:[312,236], start:6.64, travel:3.50, size:.29, angle:.42, drift:-33, color:.71},
  {from:[445,120], to:[403,228], start:8.12, travel:3.30, size:.30, angle:.57, drift:-30, color:.61},
];

function autumnLight(t) {
  let falling = 0;
  for (const leaf of autumnDrops) {
    const progress = (t - leaf.start) / leaf.travel;
    if (progress > 0 && progress < 1) {
      falling = Math.max(falling, Math.sin(Math.PI * progress));
    }
  }
  return .06 * falling + .025 * (.5 + .5 * Math.sin(phase(t)));
}

function autumnLeaf(g, x, y, scale, angle, width, height, autumn, opacity) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(scale * width, scale * height);
  const skin = g.createLinearGradient(-35, -39, 44, 37);
  skin.addColorStop(0, rgba(mix([198, 218, 147], [254, 205, 133], autumn), opacity));
  skin.addColorStop(.46, rgba(mix([146, 173, 102], [211, 136, 82], autumn), opacity));
  skin.addColorStop(1, rgba(mix([60, 108, 78], [124, 65, 51], autumn), opacity));
  g.fillStyle = skin;
  g.fill(autumnLeafShape);
  const rim = mix([220, 229, 173], [254, 199, 130], autumn);
  stroke(g, autumnLeafShape, rim, .60 * opacity, 1.1);
  stroke(g, autumnLeafStalk, [179, 134, 83], .92 * opacity, 1.8);
  stroke(g, autumnLeafVeins, mix([68, 105, 67], [119, 63, 45], autumn), .62 * opacity, 1.25);
  stroke(g, autumnFineVeins, rim, .38 * opacity, .68);
  g.restore();
}

function autumnTree(g, t) {
  const shade = g.createLinearGradient(309, 23, 498, 132);
  shade.addColorStop(0, 'rgba(142,159,91,.30)');
  shade.addColorStop(.48, 'rgba(147,126,75,.28)');
  shade.addColorStop(1, 'rgba(101,83,65,.16)');
  g.fillStyle = shade;
  g.fill(autumnCrown);
  for (const bough of autumnBoughs) {
    stroke(g, bough.path, [101, 77, 62], .94, bough.width);
    stroke(g, bough.path, [191, 149, 94], .36, Math.max(.5, bough.width * .18));
  }
  const wood = g.createLinearGradient(400, 129, 438, 180);
  wood.addColorStop(0, '#9c7858');
  wood.addColorStop(.45, '#76563e');
  wood.addColorStop(1, '#4a3b34');
  g.fillStyle = wood;
  g.fill(autumnTrunk);
  stroke(g, autumnBark, [202, 161, 113], .48, 1.05);
  for (const [i, [x, y, size, angle, color, opacity]] of autumnTreeLeaves.entries()) {
    const breeze = Math.sin(phase(t, 2, i * .43)) * .10;
    autumnLeaf(g, x, y, size, angle + breeze, 1, 1, color, opacity);
  }
}

function autumnFallingLeaves(g, t) {
  const returnToBough = smooth(11.55, LOOP, t);
  for (const [i, leaf] of autumnDrops.entries()) {
    const breeze = Math.sin(phase(t, 2, i * .54)) * .10;
    if (t < leaf.start || returnToBough > 0) {
      const attached = t < leaf.start ? 1 : returnToBough;
      autumnLeaf(g, ...leaf.from, leaf.size, leaf.angle + breeze, 1, 1, leaf.color, attached);
    }
    if (t < leaf.start) continue;

    const age = t - leaf.start;
    const progress = clamp(age / leaf.travel);
    const opacity = 1 - smooth(leaf.travel + .65, leaf.travel + 1.65, age);
    if (opacity <= 0) continue;
    const settled = smooth(.81, 1, progress);
    const tumble = Math.sin(Math.PI * progress) * Math.sin(TAU * progress * .92);
    const x = lerp(leaf.from[0], leaf.to[0], progress) + tumble * leaf.drift;
    const fall = progress * (.70 + progress * .30);
    const y = lerp(leaf.from[1], leaf.to[1], fall) + Math.sin(TAU * progress) * 7;
    const angle = leaf.angle + breeze * (1 - progress) + .78 * Math.sin(TAU * progress + i * .3) * Math.sin(Math.PI * progress);
    const face = Math.cos(TAU * progress * (1.05 + (i % 3) * .16));
    const leafColor = lerp(leaf.color, 1, progress * .86);
    if (leaf.water) {
      ripple(g, ...leaf.to, (age - leaf.travel) / 1.55, [224, 194, 153], 1.05, 1.28);
    }
    autumnLeaf(g, x, y, leaf.size, angle, lerp(face, 1, settled),
      lerp(1, .29, settled), leafColor, opacity);
  }
}

function liqiu(g, t) {
  glow(g, 442, 117, 242, [113, 154, 179], .21);
  glow(g, 386, 68, 173, autumnGold, .12 + autumnLight(t));
  glow(g, 284, 63, 218, [123, 162, 126], .08);

  const water = g.createLinearGradient(0, 202, 0, 288);
  water.addColorStop(0, 'rgba(83,111,121,.30)');
  water.addColorStop(1, 'rgba(62,88,101,0)');
  g.fillStyle = water;
  g.fill(autumnWater);
  stroke(g, autumnHorizon, [156, 182, 179], .20, .9);
  for (let i = 0; i < 4; i++) {
    const start = 264 + i * 64 + 16 * Math.sin(phase(t, 1, i));
    const y = 219 + i * 8;
    line(g, start, y, start + 27 + i * 5, y, [151, 183, 179], .16 - i * .025, .8);
  }

  ellipse(g, 417, 223, 39, 6, [30, 37, 33], .26);
  autumnTree(g, t);
  autumnFallingLeaves(g, t);
}

function liqiuBadge(g, t) {
  const breeze = Math.sin(phase(t, 2)) * .16;
  glow(g, 0, -3, 30, autumnGold, .22);
  autumnLeaf(g, 0, -3, .47, -.43 + breeze, 1, 1, .92, 1);
}

const chimeWarm = [229, 176, 123];
const chimeEave = new Path2D('M219 -5H584V17C535 14 489 23 438 30C368 36 283 29 219 -5Z');
const chimeEaveLip = new Path2D('M219 -5C283 29 368 36 438 30C489 23 535 14 584 17');
const chimeHull = new Path2D(
  'M-43 48C-41 29 -35 13 -23 4Q-13 -4 0 -4Q13 -4 23 4C35 13 41 29 43 48Q0 66 -43 48Z',
);
const chimeHighlight = new Path2D('M-34 42C-32 27 -25 14 -16 9M19 6Q28 17 34 34');
const chimeRearRim = new Path2D('M-43 48Q0 35 43 48');
const chimeFrontRim = new Path2D('M-43 48Q0 65 43 48');
const chimePaper = new Path2D('M-10 0Q0 2 10 0L13 57Q1 62 -13 55Z');
const chimePaperFold = new Path2D('M0 2Q-2 27 2 57');

function chushuCooling(t) {
  return smooth(.45, 8.05, t) * (1 - smooth(10.6, LOOP, t));
}

function chushuWind(t) {
  return .78 * Math.sin(phase(t, 2, .32)) + .22 * Math.sin(phase(t, 3, 1.7));
}

function chimeGlass(g, tint, wind) {
  // Draw the far lip and clapper behind the translucent front of the bell.
  ellipse(g, 0, 48, 43, 9.5, [35, 58, 63], .67);
  stroke(g, chimeRearRim, tint, .57, 1.05);
  const clapperX = wind * 11;
  line(g, 0, 2, clapperX, 49, [201, 183, 142], .64, 1.3);
  ellipse(g, clapperX, 48, 5.8, 5, [182, 157, 113], .94, .15);
  ellipse(g, clapperX - 1.6, 46.5, 1.8, 1.3, [245, 226, 170], .82);

  const glass = g.createLinearGradient(-35, 8, 39, 49);
  glass.addColorStop(0, rgba(mix(tint, [248, 253, 232], .58), .49));
  glass.addColorStop(.30, rgba(tint, .34));
  glass.addColorStop(.60, rgba(mix(tint, [36, 70, 76], .42), .17));
  glass.addColorStop(.83, rgba(tint, .44));
  glass.addColorStop(1, rgba(tint, .19));
  g.fillStyle = glass;
  g.fill(chimeHull);
  stroke(g, chimeHull, mix(tint, [239, 249, 232], .44), .69, 1.3);
  stroke(g, chimeHighlight, [239, 249, 232], .57 + Math.abs(wind) * .19, 1.8);
  stroke(g, chimeFrontRim, mix(tint, [231, 246, 231], .35), .92, 2.45);
}

function chushu(g, t) {
  const cool = chushuCooling(t);
  const tint = mix(chimeWarm, chimeCool, cool);
  const wind = chushuWind(t);
  glow(g, 417, 78, 228, tint, .23);
  glow(g, 192 - cool * 54, 60, 230, [225, 164, 109], .17 * (1 - cool));
  glow(g, 326, 173, 241, [99, 159, 175], .18 * cool);
  const roof = g.createLinearGradient(0, 0, 0, 42);
  roof.addColorStop(0, 'rgba(32,44,47,.94)');
  roof.addColorStop(1, 'rgba(65,82,80,.51)');
  g.fillStyle = roof;
  g.fill(chimeEave);
  stroke(g, chimeEaveLip, tint, .28, 1.2);

  for (let i = 0; i < 5; i++) {
    const travel = (t / LOOP * 2 + i * .185) % 1;
    const x = 270 + travel * 298;
    const y = 108 + i * 18 + Math.sin(phase(t, 1, i)) * 7;
    const air = new Path2D();
    air.moveTo(x - 84, y + 2);
    air.bezierCurveTo(x - 59, y - 19, x - 26, y + 14, x, y - 5);
    stroke(g, air, tint, (.13 + Math.abs(wind) * .18) * Math.sin(Math.PI * travel), 1.05);
  }

  g.save();
  g.translate(415, 29);
  g.rotate(wind * .22);
  line(g, 0, 0, 0, 37, [215, 211, 169], .81, 1.4);
  ellipse(g, 0, 37, 4, 2.3, [213, 186, 135], .84);
  g.translate(0, 42);
  chimeGlass(g, tint, -wind);
  g.translate(-wind * 11, 53);
  const stripSwing = .52 * Math.sin(phase(t, 2, -.71)) + .15 * Math.sin(phase(t, 3, .35));
  g.rotate(stripSwing);
  line(g, 0, 0, 0, 17, [209, 199, 166], .78, 1.1);
  g.translate(0, 17);
  const paper = g.createLinearGradient(-10, 0, 13, 57);
  paper.addColorStop(0, rgba(mix(tint, [241, 234, 203], .72), .91));
  paper.addColorStop(.60, rgba(mix(tint, [219, 213, 172], .48), .79));
  paper.addColorStop(1, rgba(tint, .46));
  g.fillStyle = paper;
  g.fill(chimePaper);
  stroke(g, chimePaperFold, [236, 239, 210], .45, .9);
  g.restore();
}

function chushuBadge(g, t) {
  const wind = chushuWind(t);
  const tint = mix(chimeWarm, chimeCool, chushuCooling(t));
  g.save();
  g.translate(0, -13);
  g.scale(.52, .52);
  g.rotate(wind * .13);
  line(g, 0, -13, 0, -3, tint, .93, 2);
  chimeGlass(g, tint, -wind);
  line(g, -wind * 11, 52, wind * 6, 67, [234, 225, 185], .92, 2.2);
  g.restore();
}

const dewSilver = [225, 244, 237];

function reedCubicPoint([start, first, second, end], u) {
  const v = 1 - u;
  return [0, 1].map(axis => v ** 3 * start[axis] + 3 * v * v * u * first[axis]
    + 3 * v * u * u * second[axis] + u ** 3 * end[axis]);
}

function reedSurfacePoint(u, side, spine, faceWidth) {
  const [x, y] = spine(u);
  const [beforeX, beforeY] = spine(Math.max(0, u - .001));
  const [afterX, afterY] = spine(Math.min(1, u + .001));
  const dx = afterX - beforeX;
  const dy = afterY - beforeY;
  const taper = Math.sin(Math.PI * u) ** 1.1;
  const width = faceWidth * taper * (side < 0 ? 1 + .10 * Math.sin(u * 16) : .45 * (1 + .22 * Math.sin(u * 11)));
  const offset = side * (width + 1.8 * (1 - u)) / Math.hypot(dx, dy);
  return [x - dy * offset, y + dx * offset];
}

function traceReedCurve(path, surface, from, to, side, join = false) {
  const steps = 56;
  const start = surface(from, side);
  if (join) path.lineTo(...start);
  else path.moveTo(...start);
  for (let step = 1; step <= steps; step++) {
    path.lineTo(...surface(lerp(from, to, step / steps), side));
  }
}

function reedFace(surface, side) {
  const path = new Path2D();
  traceReedCurve(path, surface, 0, 1, side);
  traceReedCurve(path, surface, 1, 0, 1, true);
  path.closePath();
  return path;
}

const reedGrassColors = [
  ['#284337', '#46685a', '#668575', 'rgba(13,40,36,.30)'],
  ['#2b4e42', '#628064', '#8e9e73', 'rgba(15,47,42,.38)'],
  ['#2a5045', '#789573', '#a8ad78', 'rgba(24,49,39,.40)'],
];

// From back to front, three neighboring crowns send blades in different directions.
const dewGrass = [
  {curve: [[346, 238], [330, 159], [291, 124], [243, 135]], width: 6.3, color: 0, sway: -.054},
  {curve: [[356, 239], [346, 158], [301, 119], [307, 81]], width: 5.0, color: 0, sway: .055},
  {curve: [[353, 240], [355, 148], [382, 94], [364, 58]], width: 4.3, color: 1, sway: .043, bead: [.73, 2.2, .48]},
  {curve: [[369, 238], [379, 156], [401, 107], [446, 84]], width: 5.0, color: 0, sway: .065},
  {curve: [[361, 238], [394, 166], [468, 136], [492, 174]], width: 7.4, color: 2, sway: .052, drips: true},
  {curve: [[332, 239], [314, 197], [264, 169], [229, 186]], width: 5.8, color: 1, sway: .071},
  {curve: [[341, 238], [317, 192], [322, 148], [280, 118]], width: 8.6, color: 1, sway: .065, bead: [.61, 2.5, .21]},
  {curve: [[355, 239], [346, 195], [369, 137], [341, 96]], width: 6.8, color: 2, sway: .063, bead: [.83, 1.9, .72]},
  {curve: [[364, 239], [354, 192], [386, 151], [396, 124]], width: 4.7, color: 1, sway: .051},
  {curve: [[374, 238], [394, 181], [438, 169], [453, 156]], width: 5.7, color: 2, sway: .052, bead: [.67, 2.9, .38]},
  {curve: [[331, 241], [317, 226], [287, 220], [253, 224]], width: 4.8, color: 0, sway: .065},
  {curve: [[348, 240], [326, 224], [320, 187], [296, 172]], width: 6.0, color: 2, sway: .049},
  {curve: [[357, 241], [361, 211], [344, 190], [349, 163]], width: 3.3, color: 0, sway: .078},
  {curve: [[359, 241], [379, 221], [379, 203], [410, 186]], width: 6.0, color: 1, sway: .067},
  {curve: [[371, 241], [398, 219], [423, 214], [461, 224]], width: 4.8, color: 1, sway: .083},
].map(({curve, width, color, sway, bead, drips}, index) => {
  const spine = u => reedCubicPoint(curve, u);
  const surface = (u, side) => reedSurfacePoint(u, side, spine, width);
  const midrib = new Path2D();
  traceReedCurve(midrib, surface, .15, .94, 0);
  return {
    root: curve[0], tip: curve[3], blade: reedFace(surface, -1), fold: reedFace(surface, 0), midrib,
    colors: reedGrassColors[color], sway, delay: (index % 4) * .21, surface, bead, drips,
  };
});
const dewDripBlade = dewGrass.find(blade => blade.drips);

const dewBadgeLeaf = new Path2D('M-27 12C-10 -20 16 -23 30 -5C8 -11 -10 0 -27 12Z');
const dewBadgeMidrib = new Path2D('M-24 10Q2 -12 27 -6');
const reedDewGrowth = t => smooth(.26, 3.25, t);

function whiteDewDrop(g, x, y, radius, opacity, t, stretch = 1) {
  if (opacity <= .01 || radius <= .1) return;
  glow(g, x, y, radius * 2.8, [189, 228, 221], opacity * .25);
  const glint = .53 + .47 * Math.sin(phase(t, 1, .65));
  const glass = g.createRadialGradient(
    x - radius * .35, y - radius * .43, radius * .04,
    x, y + radius * .12, radius * 1.35,
  );
  glass.addColorStop(0, rgba([252, 255, 241], opacity * .96));
  glass.addColorStop(.18, rgba([224, 247, 226], opacity * (.75 + glint * .15)));
  glass.addColorStop(.45, rgba([138, 180, 172], opacity * .45));
  glass.addColorStop(.77, rgba([75, 120, 124], opacity * .57));
  glass.addColorStop(1, rgba([182, 225, 220], opacity * .34));
  const drop = new Path2D();
  drop.ellipse(x, y, radius * .87, radius * 1.03 * stretch, 0, 0, TAU);
  g.fillStyle = glass;
  g.fill(drop);
  stroke(g, drop, dewSilver, opacity * .76, radius > 7 ? 1 : .68);
  ellipse(g, x - radius * .27, y - radius * .46, radius * .29, radius * .18,
    [251, 255, 242], opacity * (.78 + glint * .22), -.58);
  ellipse(g, x + radius * .23, y + radius * .59 * stretch, radius * .27, radius * .13,
    [216, 251, 232], opacity * .7, -.24);
}

function reedPlume(g, x, y, length, angle, t, opacity) {
  g.save();
  g.translate(x, y);
  g.rotate(angle + Math.sin(phase(t, 1, angle)) * .05);
  const stalk = new Path2D();
  stalk.moveTo(0, 0);
  stalk.quadraticCurveTo(6, -length * .58, -4, -length);
  stroke(g, stalk, [154, 165, 137], opacity * .74, 1.25);
  for (let i = 0; i < 12; i++) {
    const height = .63 + i * .032;
    const branch = new Path2D();
    const y = -length * height;
    const distance = 7 + Math.sin(i / 11 * Math.PI) * 9;
    branch.moveTo(0, y + 5);
    branch.quadraticCurveTo(-distance * .42, y - 4, -distance, y - 10);
    branch.moveTo(0, y + 5);
    branch.quadraticCurveTo(distance * .36, y - 6, distance * .82, y - 10);
    stroke(g, branch, [208, 212, 180], opacity * .68, 1.05);
    ellipse(g, -distance, y - 10, 1.25, 2.8, [224, 224, 194], opacity * .72, -.47);
    ellipse(g, distance * .82, y - 10, 1.25, 2.4, [224, 224, 194], opacity * .67, .42);
  }
  g.restore();
}

function reedGrassAngle({sway, delay}, t) {
  return Math.sin(phase(t, 2, -delay)) * sway;
}

function drawDewGrass(g, t) {
  for (const grass of dewGrass) {
    const {root, tip, blade, fold, midrib, colors, surface, bead} = grass;
    g.save();
    g.translate(...root);
    g.rotate(reedGrassAngle(grass, t));
    g.translate(-root[0], -root[1]);
    const paint = g.createLinearGradient(...root, ...tip);
    paint.addColorStop(0, colors[0]);
    paint.addColorStop(.60, colors[1]);
    paint.addColorStop(1, colors[2]);
    g.fillStyle = paint;
    g.fill(blade);
    g.fillStyle = colors[3];
    g.fill(fold);
    stroke(g, midrib, [200, 216, 170], .29, .65);
    if (bead) {
      const [u, size, delay] = bead;
      const formed = smooth(delay, delay + 1.2, t) * (1 - smooth(10.5, 12.85, t));
      const [x, y] = surface(u, -.20);
      whiteDewDrop(g, x, y, size * formed, .80 * formed, t + u);
    }
    g.restore();
  }
}

function drawReedDrip(g, t) {
  const release = 7.15;
  const fall = clamp((t - release) / 1.04);
  if (fall === 1) return;

  const attachedTime = Math.min(t, release);
  const slide = smooth(3.15, 6.35, attachedTime);
  const hanging = smooth(.83, 1, slide);
  const grown = reedDewGrowth(attachedTime);
  const radius = 2.6 + 5.8 * grown;
  const [rootX, rootY] = dewDripBlade.root;
  const [leafX, leafY] = dewDripBlade.surface(lerp(.61, 1, slide), -.20);
  const tension = smooth(6.65, release, attachedTime);
  const dx = leafX - rootX;
  const dy = leafY - rootY + hanging * radius * (1.03 + .18 * tension);
  const angle = reedGrassAngle(dewDripBlade, attachedTime);
  // Once released, the drop falls from the tip's position at that instant.
  const x = rootX + dx * Math.cos(angle) - dy * Math.sin(angle) + 2.8 * fall;
  const y = rootY + dx * Math.sin(angle) + dy * Math.cos(angle) + 10 * fall + 59 * fall * fall;
  const opacity = grown * (1 - smooth(.69, 1, fall));
  const stretch = lerp(.88, 1.27, hanging) + .13 * Math.sin(Math.PI * fall);
  whiteDewDrop(g, x, y, radius, opacity, t, stretch);
}

function bailu(g, t) {
  const morning = smooth(.15, 6.6, t) * (1 - smooth(10.5, LOOP, t));
  glow(g, 415, 107, 255, [117, 166, 175], .22);
  glow(g, 339, 36, 203, [223, 219, 181], .12 + morning * .18);
  glow(g, 495, 182, 190, [93, 157, 140], .13);

  for (let i = 0; i < 3; i++) {
    const drift = 18 * Math.sin(phase(t, 1, i * .75));
    g.save();
    g.translate(238 + i * 114 + drift, 184 + i * 14);
    g.scale(1, .19);
    glow(g, 0, 0, 166, [186, 219, 210], .08 * (1 - .57 * morning));
    g.restore();
  }

  reedPlume(g, 346, 239, 174, -.49, t, .34);
  reedPlume(g, 367, 239, 185, .28, t, .37);
  drawDewGrass(g, t);
  drawReedDrip(g, t);
}

function bailuBadge(g, t) {
  const leafPaint = g.createLinearGradient(-24, 9, 18, -14);
  leafPaint.addColorStop(0, '#679d8c');
  leafPaint.addColorStop(1, '#c8dfaa');
  g.fillStyle = leafPaint;
  g.fill(dewBadgeLeaf);
  stroke(g, dewBadgeMidrib, [224, 244, 207], .86, 1.55);
  const sway = 2.1 * Math.sin(phase(t, 2, .4));
  whiteDewDrop(g, 23 + sway, 6, 9.7, 1, t, 1.18);
}

const equinoxShore = 183;
const equinoxCrescent = new Path2D('M2.6 -27.9A28 28 0 1 0 24.9 13A23.45 23.45 0 1 1 2.6 -27.9Z');
const equinoxFarBank = new Path2D(
  'M212 183C241 181 256 171 273 172C291 172 302 178 327 176C350 175 364 158 383 157C406 157 424 175 454 174C479 173 492 157 515 160C538 163 557 179 584 181V191H212Z',
);
const equinoxNearBank = new Path2D(
  'M212 183C238 184 250 180 271 179C295 178 308 185 335 184C376 182 393 171 419 173C450 175 476 183 509 180C539 178 557 171 584 176V191H212Z',
);
const equinoxStars = Array.from({length: 20}, (_, i) => ({
  x: 389 + rnd(5400 + i) * 172,
  y: 60 + rnd(5500 + i) * 101,
  size: .48 + rnd(5600 + i) * 1.03,
  delay: rnd(5650 + i) * TAU,
})).filter(star => star.x < 452 || star.y > 80);
const equinoxRipples = Array.from({length: 24}, (_, i) => ({
  depth: (i + .32 + rnd(5700 + i) * .54) / 24,
  width: .27 + rnd(5800 + i) * .73,
  shift: rnd(5900 + i) - .5,
  delay: rnd(6000 + i) * TAU,
}));

function equinoxProgress(t) {
  return smooth(1.25, 11.75, t);
}

function equinoxVisibility(t) {
  return smooth(0, 1.05, t) * (1 - smooth(11.5, LOOP, t));
}

function equinoxSun(g, x, y, radius, opacity) {
  if (opacity <= 0) return;
  const disc = g.createLinearGradient(x, y - radius, x, y + radius);
  disc.addColorStop(0, rgba([255, 238, 177], opacity));
  disc.addColorStop(.57, rgba([255, 195, 122], opacity));
  disc.addColorStop(1, rgba([226, 119, 68], opacity));
  g.fillStyle = disc;
  g.beginPath();
  g.arc(x, y, radius, 0, TAU);
  g.fill();
}

function equinoxMoon(g, x, y, radius, opacity) {
  if (opacity <= 0) return;
  g.save();
  g.translate(x, y);
  g.scale(radius / 28, radius / 28);
  const light = g.createLinearGradient(-23, -15, 18, 24);
  light.addColorStop(0, rgba([231, 239, 255], opacity));
  light.addColorStop(.57, rgba([193, 212, 253], opacity));
  light.addColorStop(1, rgba([150, 174, 238], opacity));
  g.fillStyle = light;
  g.fill(equinoxCrescent);
  g.restore();
}

function equinoxBank(g, path, colors) {
  const fill = g.createLinearGradient(212, 0, 584, 0);
  fill.addColorStop(0, rgba(colors[0], 0));
  fill.addColorStop(.24, rgba(colors[0], .79));
  fill.addColorStop(.65, rgba(colors[1], .90));
  fill.addColorStop(1, rgba(colors[1], .58));
  g.fillStyle = fill;
  g.fill(path);
}

function equinoxReflection(g, t, body, color, offset) {
  if (body.opacity <= 0) return;
  const length = 42 + 25 * smooth(70, equinoxShore, body.y);
  g.save();
  g.translate(body.x, equinoxShore + length * .41);
  g.scale(1, .46);
  glow(g, 0, 0, length, color, body.opacity * .27);
  g.restore();
  for (const ripple of equinoxRipples) {
    const u = ripple.depth;
    const wave = Math.sin(phase(t, 3, ripple.delay + u * 7 + offset));
    const x = body.x + (ripple.shift * 27 + wave * 8) * (.24 + u);
    const lengthAtDepth = (17 + 47 * u) * ripple.width * (.84 + wave * .16);
    const shimmer = (.53 + wave * .26) * (1 - u * .71) * body.opacity;
    ellipse(g, x, equinoxShore + 4 + u * length, lengthAtDepth / 2, .58 + u, color, shimmer);
  }
}

function equinoxBirds(g, t) {
  const arrival = smooth(2.9, 8.85, t);
  const opacity = smooth(2.9, 4.2, t) * (1 - smooth(7.4, 8.85, t));
  if (opacity <= 0) return;
  for (const [index, offsetX, offsetY, size] of [[0, 0, 0, 8], [1, -17, 6, 6.3], [2, -30, 1, 5]]) {
    const x = 332 + 97 * arrival + offsetX;
    const y = 108 - 28 * arrival + offsetY;
    const flap = Math.sin(phase(t, 15, index * 1.2));
    const wing = new Path2D();
    wing.moveTo(x - size, y - 2.5 + flap * 3.5);
    wing.quadraticCurveTo(x - size * .44, y - 3, x, y);
    wing.quadraticCurveTo(x + size * .43, y - 4, x + size, y - 3 + flap * 3.7);
    stroke(g, wing, [224, 206, 192], opacity * .57, 1.25);
  }
}

function qiufen(g, t) {
  const progress = equinoxProgress(t);
  const visible = equinoxVisibility(t);
  const sun = {
    x: lerp(289, 317, progress), y: lerp(66, 204, progress),
    opacity: visible * (1 - smooth(.80, 1, progress)),
  };
  const moon = {
    x: lerp(516, 433, progress), y: lerp(204, 66, progress),
    opacity: visible * smooth(.09, .45, progress),
  };
  glow(g, 382, 154, 235, equinoxTwilight, .10);
  glow(g, sun.x, Math.min(sun.y, equinoxShore), 151, equinoxGold, sun.opacity * .34);
  glow(g, moon.x, Math.min(moon.y, equinoxShore), 146, equinoxBlue, moon.opacity * .36);

  g.save();
  g.beginPath();
  g.rect(201, 0, W - 201, equinoxShore);
  g.clip();
  const night = smooth(.28, .79, progress);
  for (const star of equinoxStars) {
    const twinkle = .61 + .39 * Math.sin(phase(t, 3, star.delay));
    ellipse(g, star.x, star.y, star.size, star.size, [218, 230, 252], visible * night * twinkle * .84);
  }
  equinoxSun(g, sun.x, sun.y, 26, sun.opacity);
  equinoxMoon(g, moon.x, moon.y, 28, moon.opacity);
  equinoxBirds(g, t);
  g.restore();

  equinoxBank(g, equinoxFarBank, [[117, 91, 90], [60, 72, 104]]);
  equinoxBank(g, equinoxNearBank, [[65, 62, 70], [41, 54, 77]]);
  line(g, 246, equinoxShore + 4, 567, equinoxShore + 4, [188, 182, 189], .22, .72);
  equinoxReflection(g, t, sun, [252, 177, 101], 0);
  equinoxReflection(g, t, moon, [172, 196, 249], 1.2);
}

function qiufenBadge(g, t) {
  const shift = 5 * (equinoxProgress(t) - .5);
  equinoxSun(g, -15, -2 + shift, 10, .98);
  equinoxMoon(g, 14, -2 - shift, 12, .98);
  line(g, -24, 13, -4, 13, [255, 214, 147], .77, 1.8);
  line(g, 5, 13, 23, 13, [199, 220, 255], .77, 1.8);
}

const chrysanthemumPetal = new Path2D(
  'M0 0C24 -6 52 -11 76 -14C90 -16 102 -12 100 -5C98 1 83 6 67 6C38 6 15 4 0 0Z',
);
const chrysanthemumFold = new Path2D(
  'M0 0C31 -2 58 -3 83 -7C92 -8 98 -9 100 -5C98 1 83 6 67 6C38 6 15 4 0 0Z',
);
const chrysanthemumVein = new Path2D('M21 -1C44 -2 66 -4 87 -8');
const chrysanthemumStems = new Path2D('M0 0C1 -49 7 -91 23 -126M3 -45C-23 -64 -57 -81 -80 -100');
const chrysanthemumLeaf = new Path2D(
  'M0 0C16 -9 17 -19 30 -21L28 -13C39 -20 42 -27 54 -25L51 -16C63 -20 69 -22 78 -18L73 -12C82 -15 90 -10 99 -6C87 -3 88 3 77 5L77 12C65 9 62 16 48 13L51 7C36 13 31 18 23 11L27 4C15 6 9 5 0 0Z',
);
const chrysanthemumLeafVein = new Path2D('M2 0Q50 -3 87 -7M25 -1L38 -15M43 -2L52 7M52 -4L63 -14M72 -5L81 1');
const chrysanthemumFoliage = [
  {x:2, y:-26, angle:-2.91, length:.82, width:.72},
  {x:5, y:-54, angle:-.33, length:.71, width:.68},
  {x:-38, y:-73, angle:2.99, length:.43, width:.60},
  {x:10, y:-84, angle:-2.36, length:.44, width:.53},
];

const chrysanthemumPetals = [
  {count:19, length:82, width:1.07, start:.65, end:5.15, root:[114, 65, 34], face:[212, 135, 65], tip:[248, 191, 107]},
  {count:17, length:66, width:.93, start:1.30, end:5.75, root:[142, 80, 35], face:[232, 158, 69], tip:[253, 209, 125]},
  {count:13, length:47, width:.82, start:1.85, end:6.22, root:[156, 90, 40], face:[240, 169, 76], tip:[255, 218, 131]},
  {count:10, length:29, width:.64, start:2.10, end:6.46, root:[158, 90, 44], face:[243, 170, 74], tip:[255, 221, 145]},
].map((ring, row) => ({
  ...ring,
  petals: Array.from({length:ring.count}, (_, i) => {
    const seed = 7000 + row * 64 + i;
    const angle = i / ring.count * TAU + row * .29 + (rnd(seed) - .5) * .15;
    return {
      angle,
      length: ring.length * (.88 + rnd(seed + 300) * .25),
      width: ring.width * (.80 + rnd(seed + 600) * .32),
      delay: rnd(seed + 900) * .70,
      light: .82 + .18 * (.56 * rnd(seed + 1200) + .44 * (.5 + .5 * Math.sin(angle))),
    };
  }),
}));

const chrysanthemumDewTips = new Map([
  [2, {radius:4.6, gathersAt:4.55}],
  [5, {radius:5.7, gathersAt:5.08}],
  [8, {radius:3.6, gathersAt:5.40}],
]);
const chrysanthemumPollen = Array.from({length:17}, (_, i) => {
  const angle = i * 2.39996;
  const radius = 2.1 * Math.sqrt(i);
  return [Math.cos(angle) * radius, Math.sin(angle) * radius, .8 + .85 * rnd(8800 + i)];
});

function chrysanthemumLight(t) {
  return smooth(.8, 6.7, t) * (1 - smooth(10.7, LOOP, t));
}

function drawChrysanthemumPetal(g, length, width, angle, colors, light) {
  g.save();
  g.rotate(angle);
  g.scale(length / 100, width);
  const paint = g.createLinearGradient(0, 3, 100, -10);
  paint.addColorStop(0, rgba(colors.root));
  paint.addColorStop(.48, rgba(colors.face));
  paint.addColorStop(1, rgba(mix(colors.root, colors.tip, light)));
  g.fillStyle = paint;
  g.fill(chrysanthemumPetal);
  g.fillStyle = rgba([110, 58, 34], .19);
  g.fill(chrysanthemumFold);
  stroke(g, chrysanthemumVein, colors.tip, .27, .77);
  g.restore();
}

function chrysanthemumBloom(g, t) {
  const settling = 1 - smooth(10.65, LOOP, t);
  const dew = [];
  g.save();
  g.scale(1, .75);
  g.rotate(-.14 + .019 * Math.sin(phase(t, 2, .8)));
  for (const [row, ring] of chrysanthemumPetals.entries()) {
    for (const [i, petal] of ring.petals.entries()) {
      const opening = smooth(ring.start + petal.delay, ring.end + petal.delay, t) * settling;
      const length = petal.length * lerp(.30 + row * .045, 1, opening);
      const angle = petal.angle + (1 - opening) * .37 + .023 * Math.sin(phase(t, 2, i * .71));
      const width = petal.width * lerp(.67, 1, opening);
      drawChrysanthemumPetal(g, length, width, angle, ring, petal.light);

      const drop = row === 0 && chrysanthemumDewTips.get(i);
      if (drop) {
        const formed = smooth(drop.gathersAt, drop.gathersAt + 1.6, t) * settling;
        const tip = length * .965;
        dew.push({
          x: tip * Math.cos(angle) + 5.6 * width * Math.sin(angle),
          y: tip * Math.sin(angle) - 5.6 * width * Math.cos(angle) + drop.radius * formed * .48,
          size: drop.radius * formed, formed, timing: t + i * .22,
        });
      }
    }
  }
  ellipse(g, 0, 0, 9.3, 8, [173, 105, 46]);
  for (const [x, y, radius] of chrysanthemumPollen) {
    ellipse(g, x, y, radius, radius * 1.12, [255, 218, 125], .71);
  }
  for (const drop of dew) {
    whiteDewDrop(g, drop.x, drop.y, drop.size, drop.formed, drop.timing, 1.23);
  }
  g.restore();
}

function chrysanthemumBud(g, t) {
  g.save();
  g.translate(-80, -100);
  g.rotate(-.29 + .06 * Math.sin(phase(t, 2, .2)));
  for (const [angle, length, width] of [[-2.8, 15, .54], [-2.26, 20, .62], [-1.72, 22, .65], [-1.26, 19, .59], [-.82, 15, .49]]) {
    drawChrysanthemumPetal(g, length, width, angle, chrysanthemumPetals[1], .79);
  }
  ellipse(g, 0, 0, 9, 4.5, [88, 107, 83], .96, -.12);
  g.restore();
}

function hanlu(g, t) {
  const light = chrysanthemumLight(t);
  glow(g, 397, 70, 244, [119, 153, 184], .21 + .20 * light);
  glow(g, 512, 161, 124, [171, 155, 115], .12 + .14 * light);
  for (let i = 0; i < 4; i++) {
    const drift = 36 * Math.sin(phase(t, 1, i * 1.3));
    g.save();
    g.translate(321 + i * 62 + drift, 158 + i * 17);
    g.scale(1, .11 + i * .019);
    glow(g, 0, 0, 150 - i * 9, [175, 203, 227], .11 + .025 * Math.sin(phase(t, 1, i)));
    g.restore();
  }

  g.save();
  g.translate(389, 243);
  g.rotate(.040 * Math.sin(phase(t, 2, .26)));
  stroke(g, chrysanthemumStems, [53, 73, 71], .84, 5.4);
  stroke(g, chrysanthemumStems, [134, 153, 116], .77, 2.1);
  for (const [i, blade] of chrysanthemumFoliage.entries()) {
    g.save();
    g.translate(blade.x, blade.y);
    g.rotate(blade.angle + .054 * Math.sin(phase(t, 2, i * .49)));
    g.scale(blade.length, blade.width);
    const tone = g.createLinearGradient(0, 8, 97, -13);
    tone.addColorStop(0, '#2b4746');
    tone.addColorStop(.60, '#5a7764');
    tone.addColorStop(1, '#849071');
    g.fillStyle = tone;
    g.fill(chrysanthemumLeaf);
    stroke(g, chrysanthemumLeafVein, [173, 190, 148], .58, .85);
    g.restore();
  }
  chrysanthemumBud(g, t);
  g.translate(23, -126);
  chrysanthemumBloom(g, t);
  g.restore();
}

function hanluBadge(g, t) {
  const sway = .11 * Math.sin(phase(t, 2, .4));
  g.save();
  g.translate(-7, -1);
  g.rotate(sway);
  for (let i = 0; i < 9; i++) {
    const angle = i * TAU / 9;
    drawChrysanthemumPetal(g, 17, .34, angle, chrysanthemumPetals[1], .99);
  }
  ellipse(g, 0, 0, 5, 4.7, [194, 120, 55]);
  ellipse(g, -.75, -.82, 2.4, 2.2, [255, 220, 129]);
  g.restore();
  whiteDewDrop(g, 17 + sway * 9, 5, 7.6, .99, t, 1.16);
}

const persimmonBranch = new Path2D(
  'M571 63C519 58 482 79 442 91C395 106 339 101 287 126M477 80Q485 96 481 121M389 102C385 114 389 126 395 138M432 94Q406 83 402 70M524 69Q521 88 510 96',
);
const persimmonBranchRim = new Path2D('M550 62C517 62 475 81 443 89C400 102 373 102 346 106M478 82Q486 103 481 119');
const persimmonOutline = new Path2D(
  'M0 -32C-16 -36 -37 -29 -42 -13C-49 6 -39 29 -23 34C-14 38 -6 38 0 36C7 38 16 37 24 33C38 25 47 11 43 -9C40 -26 18 -36 0 -32Z',
);
const persimmonSepals = new Path2D(
  'M0 -32C-8 -36 -16 -36 -23 -39Q-21 -33 -28 -30Q-17 -26 -7 -29Q-3 -28 -2 -22Q3 -26 5 -29Q13 -25 23 -25Q20 -31 28 -34Q15 -34 8 -36Z',
);
const persimmonShoulder = new Path2D(
  'M-47 -40H47V-6C38 -10 33 -10 27 -15C23 -19 18 -12 10 -17C4 -21 2 -14 -7 -14C-13 -12 -18 -20 -24 -14C-32 -10 -36 -17 -48 -11Z',
);
const persimmonLeaf = new Path2D('M0 0C20 -22 48 -32 80 -19C69 -3 44 19 0 0Z');
const persimmonLeafRim = new Path2D('M5 -5C21 -22 49 -31 79 -19C71 -8 59 1 47 5');
const persimmonLeafVeins = new Path2D('M0 0C28 -10 57 -11 78 -19M20 -6L29 -19M26 -8L39 6M37 -10L48 -25M47 -12L59 -1M57 -14L66 -24');

const persimmonAmber = [[255, 214, 145], [244, 152, 68], [208, 94, 40], [145, 48, 39]];
const persimmonRusset = [[253, 188, 109], [231, 122, 56], [182, 65, 35], [119, 44, 38]];
const rimeWhite = [225, 243, 252];
const rimeGrains = Array.from({length:112}, (_, i) => {
  const seed = 9100 + i;
  const depth = rnd(seed + 200);
  return {
    x: (rnd(seed) - .5) * (75 + depth * 21),
    y: -35 + depth ** 1.4 * 39,
    size: .42 + rnd(seed + 500) * 1.46,
    delay: depth * 2.4 + rnd(seed + 800) * 1.1,
    depth,
  };
});
const persimmonPores = Array.from({length:38}, (_, i) => ({
  x: (rnd(9700 + i) - .5) * 79,
  y: -1 + rnd(9800 + i) * 36,
  size: .36 + rnd(9900 + i) * .69,
}));
const persimmonCrystals = [
  [-28, -21, 2.74, 12, .3], [-17, -27, 3.54, 19, .9],
  [15, -30, 2.6, 16, 1.2], [30, -24, 3.38, 14, 1.85],
  [-8, -24, 2.92, 15, 2.15], [23, -21, 3.03, 11, 2.55],
];

function frostGrowth(t, delay = 0) {
  return smooth(1.85 + delay, 7.75 + delay * .8, t) * (1 - smooth(10.7, LOOP, t));
}

function frostFern(g, x, y, angle, length, growth, opacity = .78) {
  if (growth <= 0) return;
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  const twig = new Path2D();
  twig.moveTo(0, 0);
  twig.lineTo(0, -length * growth);
  for (let i = 1; i <= 4; i++) {
    const u = i * .175;
    const reach = smooth(u, u + .24, growth) * length * (.29 - u * .19);
    if (reach <= 0) continue;
    const base = -length * u;
    twig.moveTo(-reach, base - reach * .80);
    twig.lineTo(0, base);
    twig.lineTo(reach, base - reach * .80);
    const fork = reach * .55;
    twig.moveTo(-fork, base - fork * .80);
    twig.lineTo(-fork * 1.32, base - fork * 1.72);
    twig.moveTo(fork, base - fork * .80);
    twig.lineTo(fork * 1.32, base - fork * 1.72);
  }
  stroke(g, twig, rimeWhite, opacity * growth, .85);
  g.restore();
}

function paintPersimmon(g, palette) {
  const skin = g.createRadialGradient(-16, -15, 2, 5, 12, 59);
  skin.addColorStop(0, rgba(palette[0]));
  skin.addColorStop(.36, rgba(palette[1]));
  skin.addColorStop(.73, rgba(palette[2]));
  skin.addColorStop(1, rgba(palette[3]));
  g.fillStyle = skin;
  g.fill(persimmonOutline);
}

function paintPersimmonCalyx(g, frost) {
  line(g, 1, -31, -2, -43, [85, 78, 52], 1, 3.35);
  g.fillStyle = '#6d7149';
  g.fill(persimmonSepals);
  line(g, -15, -32, 20, -31, [177, 171, 118], .63, .84);
  stroke(g, persimmonSepals, rimeWhite, frost * .74, 1.28);
}

function frostedPersimmon(g, x, y, scale, angle, palette, t, delay) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(scale, scale);
  paintPersimmon(g, palette);
  const frost = frostGrowth(t, delay);
  g.save();
  g.clip(persimmonOutline);
  for (const pore of persimmonPores) {
    ellipse(g, pore.x, pore.y, pore.size, pore.size * .67, [117, 69, 48], .24);
  }
  const coat = g.createLinearGradient(0, -37, 0, -4);
  coat.addColorStop(0, rgba(rimeWhite, frost * .86));
  coat.addColorStop(.45, rgba([204, 227, 242], frost * .59));
  coat.addColorStop(1, rgba([191, 223, 242], 0));
  g.fillStyle = coat;
  g.fill(persimmonShoulder);
  for (const grain of rimeGrains) {
    const growth = frostGrowth(t, delay + grain.delay);
    ellipse(g, grain.x, grain.y, grain.size * growth, grain.size * growth * .74,
      rimeWhite, growth * (.91 - grain.depth * .52), -.53);
  }
  for (const [px, py, branchAngle, length, lag] of persimmonCrystals) {
    frostFern(g, px, py, branchAngle, length, frostGrowth(t, delay + lag), .91);
  }
  g.restore();
  paintPersimmonCalyx(g, frost);
  g.restore();
}

function frostedLeaf(g, t, x, y, angle, scale, warm) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(scale, scale);
  const tone = g.createLinearGradient(12, -26, 49, 9);
  tone.addColorStop(0, rgba(warm ? [147, 94, 55] : [109, 120, 88]));
  tone.addColorStop(.65, rgba(warm ? [121, 66, 47] : [69, 96, 81]));
  tone.addColorStop(1, rgba(warm ? [84, 56, 48] : [43, 67, 66]));
  g.fillStyle = tone;
  g.fill(persimmonLeaf);
  stroke(g, persimmonLeafVeins, [209, 180, 127], .56, 1.05);
  const frost = frostGrowth(t, -.75);
  stroke(g, persimmonLeafRim, rimeWhite, frost * .66, 1.23);
  stroke(g, persimmonLeafVeins, [181, 215, 230], frost * .66, .78);
  for (const [px, py, lag, length] of [[20, -14, .5, 10], [35, -20, .97, 15], [49, -22, 1.45, 13], [62, -22, 1.85, 10]]) {
    frostFern(g, px, py, 2.58, length, frostGrowth(t, lag), .76);
  }
  g.restore();
}

function frostSpark(g, x, y, t, peak) {
  const pulse = smooth(peak - .25, peak, t) * (1 - smooth(peak, peak + .40, t));
  if (pulse <= 0) return;
  const radius = 5.8 * pulse;
  glow(g, x, y, radius * 2, [200, 235, 255], .51 * pulse);
  line(g, x - radius, y, x + radius, y, rimeWhite, pulse, .95);
  line(g, x, y - radius, x, y + radius, rimeWhite, pulse, .95);
}

function shuangjiang(g, t) {
  const frost = frostGrowth(t);
  glow(g, 391, 79, 233, [136, 180, 219], .18 + .26 * frost);
  glow(g, 462, 167, 157, [230, 138, 82], .21 - .06 * frost);
  for (let i = 0; i < 3; i++) {
    const drift = 37 * Math.sin(phase(t, 1, i * 1.22));
    g.save();
    g.translate(323 + i * 83 + drift, 134 + i * 35);
    g.scale(1, .13 + i * .017);
    glow(g, 0, 0, 154, [173, 205, 226], .08 + .11 * frost);
    g.restore();
  }

  g.save();
  g.translate(0, 8);
  g.translate(555, 67);
  g.rotate(.022 * Math.sin(phase(t, 2, .33)));
  g.translate(-555, -67);
  stroke(g, persimmonBranch, [51, 43, 38], 1, 7.2);
  stroke(g, persimmonBranch, [132, 104, 78], .78, 3.7);
  stroke(g, persimmonBranchRim, [209, 225, 230], .58 * frost, 1.30);
  frostedLeaf(g, t, 365, 105, -2.76 + .058 * Math.sin(phase(t, 2, 1.1)), 1.02, true);
  frostedLeaf(g, t, 403, 71, -1.54 + .049 * Math.sin(phase(t, 2, .35)), .54, false);
  frostedLeaf(g, t, 509, 96, .16 + .041 * Math.sin(phase(t, 2, 1.9)), .62, false);
  frostedPersimmon(g, 481, 151, .89, .12, persimmonRusset, t, .42);
  frostedPersimmon(g, 396, 177, 1.12, -.08, persimmonAmber, t, 0);
  frostSpark(g, 383, 150, t, 8.16);
  frostSpark(g, 501, 135, t, 8.86);
  g.restore();
}

function shuangjiangBadge(g, t) {
  g.save();
  g.translate(-7, 1);
  g.scale(.39, .39);
  paintPersimmon(g, persimmonAmber);
  paintPersimmonCalyx(g, .40 + .50 * frostGrowth(t));
  g.restore();
  const twist = .09 * Math.sin(phase(t, 2, .4));
  for (let ray = 0; ray < 6; ray++) {
    frostFern(g, 17, -8, ray * TAU / 6 + twist, 9.5, 1, .96);
  }
}

const winterKettle = new Path2D(
  'M-42 -49Q-2 -59 42 -49C54 -39 63 -23 60 -7C57 13 33 22 1 23C-32 23 -54 13 -59 -4C-65 -24 -54 -40 -42 -49Z',
);
const winterSpout = new Path2D(
  'M-47 -36C-62 -34 -73 -41 -87 -54L-92 -59Q-99 -57 -95 -49C-86 -39 -76 -29 -72 -16Q-64 -6 -52 -6Z',
);
const winterHandle = new Path2D('M-40 -34C-51 -70 -29 -101 -1 -102C28 -103 51 -70 41 -34');
const winterKettleEdge = new Path2D('M-58 0C-48 15 -25 22 0 22C23 22 46 16 55 5');
const winterKettleLid = new Path2D('M-38 -50C-26 -67 29 -68 39 -50C19 -44 -21 -43 -38 -50Z');
const winterBrazier = new Path2D('M-55 -15C-57 4 -52 28 -42 33C-24 45 26 45 43 33C52 28 57 3 55 -15Z');
const winterBrazierRim = new Path2D('M-48 -13C-24 -1 26 -1 49 -14');
const winterFirebox = new Path2D('M-26 27L-26 16C-26 1 -14 -8 0 -8C16 -8 26 2 26 16L26 27Q0 38 -26 27Z');
const winterBrazierBand = new Path2D('M-49 16C-40 30 39 31 49 16');
const winterCup = new Path2D('M-20 0C-18 8 -13 15 -8 17Q0 21 8 17C14 15 18 6 20 0Z');
const winterSteamColor = [229, 238, 241];
const winterBrass = [231, 170, 108];
const winterTeaGlaze = {top:[111, 132, 137], middle:[48, 65, 72], base:[43, 37, 37], rim:[153, 178, 181]};
const winterBadgeGlaze = {top:[242, 200, 141], middle:[176, 106, 59], base:[115, 63, 45], rim:[249, 213, 158]};
const winterEmbers = Array.from({length:13}, (_, i) => ({
  x: (rnd(12000 + i) - .5) * 42,
  delay: rnd(12100 + i),
  size: .6 + 1.3 * rnd(12200 + i),
}));

function winterHeat(t) {
  return smooth(.85, 4.85, t) * (1 - smooth(9.85, LOOP, t));
}

function paintWinterKettle(g, heat, glaze) {
  stroke(g, winterHandle, [28, 33, 38], 1, 9.6);
  stroke(g, winterHandle, glaze.rim, .81, 6.2);
  stroke(g, winterHandle, glaze.base, .34, 3.35);

  const spoutPaint = g.createLinearGradient(-91, -55, -49, -14);
  spoutPaint.addColorStop(0, rgba(glaze.top));
  spoutPaint.addColorStop(.64, rgba(glaze.middle));
  spoutPaint.addColorStop(1, rgba(glaze.base));
  g.fillStyle = spoutPaint;
  g.fill(winterSpout);
  stroke(g, winterSpout, glaze.rim, .51, 1.05);
  ellipse(g, -92.7, -54.5, 4.0, 5.15, [31, 37, 42], 1, -.49);
  ellipse(g, -93.5, -56.4, 2.95, .85, glaze.rim, .8, -.49);

  const body = g.createLinearGradient(-38, -62, 39, 19);
  body.addColorStop(0, rgba(glaze.top));
  body.addColorStop(.39, rgba(glaze.middle));
  body.addColorStop(.69, rgba(glaze.base));
  body.addColorStop(1, rgba(mix(glaze.middle, winterBrass, .12 + .25 * heat)));
  g.fillStyle = body;
  g.fill(winterKettle);
  stroke(g, winterKettle, glaze.rim, .52, 1.15);
  stroke(g, winterKettleEdge, winterBrass, .40 + .46 * heat, 1.55);
  ellipse(g, -30, -31, 22, 3.6, glaze.rim, .18, -.43);

  const lid = g.createLinearGradient(0, -67, 0, -46);
  lid.addColorStop(0, rgba(glaze.top));
  lid.addColorStop(1, rgba(glaze.middle));
  g.fillStyle = lid;
  g.fill(winterKettleLid);
  stroke(g, winterKettleLid, glaze.rim, .8, 1.3);
  ellipse(g, 0, -64.5, 7, 4.6, glaze.middle);
  ellipse(g, 0, -66.3, 5.4, 2.1, glaze.rim, .92);
}

function winterFlame(g, t, x, height, width, delay, opacity, inner) {
  const sway = Math.sin(phase(t, 13, delay));
  const tip = x + (3.6 + width * .25) * sway;
  const base = 28;
  const flame = new Path2D();
  flame.moveTo(x - width * .86, base);
  flame.bezierCurveTo(x - width * 1.38, base - height * .31, tip - width * .66, base - height * .66, tip, base - height);
  flame.bezierCurveTo(tip + width * .14, base - height * .55, x + width * 1.47, base - height * .43, x + width * .92, base);
  flame.closePath();
  const paint = g.createLinearGradient(0, base, 0, base - height);
  paint.addColorStop(0, rgba(inner ? [255, 217, 121] : [225, 78, 40], opacity * .92));
  paint.addColorStop(.57, rgba(inner ? [255, 183, 79] : [250, 133, 59], opacity));
  paint.addColorStop(1, rgba([249, 176, 91], opacity * .23));
  g.fillStyle = paint;
  g.fill(flame);
}

function paintWinterStove(g, t, heat) {
  const clay = g.createLinearGradient(-51, -9, 42, 30);
  clay.addColorStop(0, '#79574d');
  clay.addColorStop(.51, '#4a3335');
  clay.addColorStop(1, '#674338');
  g.fillStyle = clay;
  g.fill(winterBrazier);
  stroke(g, winterBrazier, [151, 114, 92], .58, 1.4);
  stroke(g, winterBrazierBand, winterBrass, .19 + .25 * heat, .93);
  ellipse(g, 0, -16, 55, 12, [69, 52, 52]);
  ellipse(g, 0, -17, 49, 8.2, [31, 30, 34]);
  ellipse(g, 0, -17, 38, 5.5, [195, 92, 48], .19 + .22 * heat);
  stroke(g, winterBrazierRim, [196, 137, 94], .64, 1.5);
  g.fillStyle = '#241b22';
  g.fill(winterFirebox);
  g.save();
  g.clip(winterFirebox);
  glow(g, 0, 22, 36, [248, 118, 55], .16 + .62 * heat);
  for (const [x, size, width, delay] of [[-13, 27, 8, .4], [1, 37, 10, 1.8], [13, 29, 8.9, 3.5]]) {
    const flicker = .86 + .14 * Math.sin(phase(t, 17, delay));
    const height = size * (.22 + .78 * heat) * flicker;
    winterFlame(g, t, x, height, width, delay, .28 + .62 * heat, false);
    winterFlame(g, t, x + 1, height * .68, width * .49, delay + .6, .28 + .66 * heat, true);
  }
  for (const ember of winterEmbers) {
    const rise = (t / LOOP * 4 + ember.delay) % 1;
    const opacity = Math.sin(Math.PI * rise) * (.18 + .67 * heat);
    ellipse(g, ember.x + Math.sin(rise * 7) * 3.4, 28 - 32 * rise * heat,
      ember.size, ember.size * .77, [255, 219, 125], opacity);
  }
  g.restore();
  stroke(g, winterFirebox, [197, 131, 86], .57 + .26 * heat, 1.38);
}

function winterSteam(g, t) {
  const boil = smooth(2.22, 5.45, t) * (1 - smooth(10.1, LOOP, t));
  for (let packet = 0; packet < 4; packet++) {
    const rise = (t / LOOP * 3 + packet * .25) % 1;
    const opacity = boil * Math.sin(rise * Math.PI) ** .72;
    if (opacity <= .01) continue;
    const start = rise * .79;
    const end = start + .26 + .29 * rise;
    const wisp = new Path2D();
    for (let turn = 0; turn <= 24; turn++) {
      const u = lerp(start, end, turn / 24);
      const curl = Math.sin(u * 7.2 - phase(t, 2) + packet * .55);
      const x = 337 - 19 * u + (curl * (7 + 10 * u) + (packet - 1.5) * 3.6) * u;
      const y = 108 - 64 * u;
      if (turn === 0) wisp.moveTo(x, y);
      else wisp.lineTo(x, y);
    }
    stroke(g, wisp, [174, 203, 222], opacity * .13, 12 + rise * 9);
    stroke(g, wisp, winterSteamColor, opacity * .20, 5.5 + rise * 3.6);
    stroke(g, wisp, winterSteamColor, opacity * .41, 1.8 + rise * 1.35);
  }
}

function lidong(g, t) {
  const heat = winterHeat(t);
  glow(g, 349, 66, 235, [113, 150, 184], .25);
  glow(g, 433, 202, 183, [247, 123, 55], .075 + .32 * heat);
  g.save();
  g.translate(426, 240);
  g.scale(1, .18);
  glow(g, 0, 0, 142, [230, 132, 69], .15 + .27 * heat);
  g.restore();

  g.save();
  g.translate(429, 204);
  paintWinterStove(g, t, heat);
  g.translate(0, -42);
  paintWinterKettle(g, heat, winterTeaGlaze);
  g.restore();
  winterSteam(g, t);

  g.save();
  g.translate(318, 218);
  ellipse(g, 0, 18, 25, 5, [31, 37, 46], .86);
  const ceramic = g.createLinearGradient(-20, 0, 20, 11);
  ceramic.addColorStop(0, '#4b6069');
  ceramic.addColorStop(.63, '#263840');
  ceramic.addColorStop(1, rgba(mix([61, 81, 87], winterBrass, .20 + .32 * heat)));
  g.fillStyle = ceramic;
  g.fill(winterCup);
  ellipse(g, 0, 0, 20, 6.4, [136, 155, 153]);
  ellipse(g, 0, .1, 17.7, 4.65, [118, 72, 51]);
  ellipse(g, 4, 1.1, 10, 1.4, winterBrass, .35 + .43 * heat, -.10);
  g.restore();
}

function lidongBadge(g, t) {
  g.save();
  g.translate(4, 10);
  g.scale(.30, .30);
  paintWinterKettle(g, winterHeat(t), winterBadgeGlaze);
  g.restore();
  const curl = 3.1 * Math.sin(phase(t, 3, .8));
  const steam = new Path2D();
  steam.moveTo(-24, -9);
  steam.bezierCurveTo(-30, -13, -19 + curl, -18, -23 + curl, -26);
  stroke(g, steam, winterSteamColor, .84, 1.72);
}

const pineSnowWhite = [233, 246, 252];
const winterRidge = new Path2D('M221 218C278 207 293 191 335 192C357 192 383 213 422 211C465 209 485 182 519 187C549 192 567 206 584 209V258H221Z');
const snowyPineBough = new Path2D('M586 101C547 107 507 124 471 134C418 150 361 152 286 164C333 161 374 161 420 157C493 151 547 121 586 119Z');
const pineBoughRidge = new Path2D('M303 162C360 156 420 152 474 135C512 123 554 108 578 105');
const pineSnowCap = new Path2D('M-1 0C-.92 -.35 -.77 -.91 -.55 -.79C-.38 -.72 -.24 -1.1 -.06 -.99C.13 -.85 .30 -.81 .49 -.72C.72 -.62 .88 -.28 1 0C.81 .13 .63 .02 .49 .17C.34 .30 .17 .20 .04 .19C-.15 .35 -.31 .17 -.49 .22C-.71 .18 -.88 .21 -1 0Z');
const pineSnowCrystal = new Path2D();
for (let ray = 0; ray < 6; ray++) {
  const a = ray * TAU / 6;
  const x = Math.sin(a), y = -Math.cos(a);
  pineSnowCrystal.moveTo(0, 0);
  pineSnowCrystal.lineTo(x, y);
  pineSnowCrystal.moveTo(.57 * x + .23 * y, .57 * y - .23 * x);
  pineSnowCrystal.lineTo(.78 * x, .78 * y);
  pineSnowCrystal.lineTo(.57 * x - .23 * y, .57 * y + .23 * x);
}

// Paired needles follow each twig and taper toward its tip.
const snowyPineFans = [
  [553, 111, 514, 78, 15], [545, 116, 565, 154, 16],
  [519, 123, 475, 103, 16], [511, 127, 535, 172, 18],
  [491, 133, 447, 82, 19], [479, 137, 491, 178, 17],
  [458, 143, 402, 108, 17], [442, 148, 450, 199, 18],
  [419, 151, 367, 125, 17], [399, 155, 387, 201, 15],
  [374, 156, 325, 122, 16], [352, 160, 324, 186, 13], [329, 161, 281, 152, 13],
].map(([x, y, tx, ty, spread], index) => {
  const length = Math.hypot(tx - x, ty - y);
  const base = new Path2D();
  base.moveTo(0, 0);
  base.quadraticCurveTo(length * .52, 5, length, 0);
  const needles = [new Path2D(), new Path2D(), new Path2D()];
  const pairs = 13 + Math.floor(rnd(15500 + index) * 7);
  for (let pair = 0; pair < pairs; pair++) {
    for (const side of [-1, 1]) {
      const seed = 13400 + index * 41 + pair * 2 + (side > 0 ? 1 : 0);
      const u = .07 + pair / (pairs - 1) * .71 + rnd(seed) * .027;
      const tap = Math.sin(u * Math.PI) ** .73;
      const fromX = u * length;
      const fromY = Math.sin(u * Math.PI) * 2.5;
      const reach = (spread + (1 - u) * length * .10) * tap * (.56 + rnd(seed + 700) * .54);
      const toX = fromX + reach * (.86 + rnd(seed + 1200) * .64);
      const toY = fromY + reach * side;
      const path = needles[Math.floor(rnd(seed + 1600) * needles.length)];
      path.moveTo(fromX, fromY);
      path.quadraticCurveTo(fromX + reach * .58, fromY + reach * side * .43, toX, toY);
    }
  }
  return {x, y, angle:Math.atan2(ty - y, tx - x), base, needles};
});

const pineSnowPatches = [
  [315, 158, 13, 3.5, .44, -.13], [347, 154, 21, 4.3, .05, -.10],
  [389, 151, 25, 5.1, .15, -.12], [433, 144, 23, 5.2, .40, -.24],
  [480, 131, 24, 5.1, .22, -.30], [526, 116, 25, 5.1, .15, -.32],
  [573, 104, 22, 5.1, .20, -.22], [344, 130, 8.4, 2.7, 1.25, .32],
  [385, 132, 11, 3.4, 1.05, .40], [415, 115, 10, 3.6, .77, .32],
  [458, 94, 9, 3.5, 1.24, .44], [486, 105, 10, 3.3, .96, .24],
  [522, 86, 9.3, 3.2, 1.19, .26],
];

const driftingSnow = Array.from({length:70}, (_, i) => ({
  x: 214 + rnd(15000 + i) * 370,
  offset: rnd(15100 + i),
  size: i < 47 ? .54 + rnd(15200 + i) * 1.07 : 1.3 + rnd(15200 + i) * 1.47,
  speed: i < 47 ? 1 : 2,
  drift: 9 + rnd(15300 + i) * 25,
  delay: rnd(15400 + i) * TAU,
}));
const loosenedSnow = Array.from({length:23}, (_, i) => ({
  x: 328 + rnd(15600 + i) * 128,
  delay: rnd(15700 + i) * .40,
  drift: 14 + rnd(15800 + i) * 42,
  size: .54 + rnd(15900 + i) * 1.92,
}));

function pineSnowGust(t) {
  return smooth(7.9, 8.35, t) * (1 - smooth(8.48, 9.68, t));
}

function pineSnowCover(t, delay = 0) {
  const settled = smooth(1.3 + delay, 7.45 + delay * .65, t);
  return settled * (1 - .24 * smooth(8.08, 9.02, t)) * (1 - smooth(10.85, LOOP, t));
}

function paintPineSnowCap(g, x, y, width, thickness, cover, angle = 0) {
  if (cover <= .01) return;
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(width * (.61 + .39 * cover), thickness * cover);
  const snow = g.createLinearGradient(0, -1, 0, .24);
  snow.addColorStop(0, rgba(pineSnowWhite, .90));
  snow.addColorStop(.59, rgba([187, 216, 230], .95));
  snow.addColorStop(1, rgba([145, 179, 204], .78));
  g.globalAlpha *= smooth(.015, .37, cover);
  g.fillStyle = snow;
  g.fill(pineSnowCap);
  g.restore();
}

function pineSnowFlurry(g, t, from, to) {
  const gust = pineSnowGust(t);
  const strength = .65 + .35 * smooth(.6, 3.5, t) * (1 - smooth(10.2, LOOP, t));
  for (let i = from; i < to; i++) {
    const flake = driftingSnow[i];
    const fall = (t / LOOP * flake.speed + flake.offset) % 1;
    const x = flake.x + flake.drift * Math.sin(phase(t, 2, flake.delay) + fall * 4) + gust * (16 + flake.size * 9);
    const y = -9 + fall * 278;
    const opacity = strength * Math.sin(Math.PI * fall) ** .75 * (.30 + flake.size * .24);
    if (i >= 47 && i % 5 === 0) {
      g.save();
      g.translate(x, y);
      g.rotate(phase(t, 1, flake.delay));
      const radius = flake.size * 1.9;
      g.scale(radius, radius);
      stroke(g, pineSnowCrystal, pineSnowWhite, opacity * .86, .16);
      g.restore();
    } else {
      ellipse(g, x, y, flake.size, flake.size * .85, pineSnowWhite, opacity, .3);
    }
  }
}

function xiaoxue(g, t) {
  const cover = pineSnowCover(t);
  const gust = pineSnowGust(t);
  glow(g, 424, 87, 266, [130, 172, 216], .24 + .20 * cover);
  glow(g, 503, 183, 174, [102, 146, 170], .14 + .10 * cover);
  const ridge = g.createLinearGradient(224, 209, 540, 241);
  ridge.addColorStop(0, '#32465300');
  ridge.addColorStop(.59, '#344c6266');
  ridge.addColorStop(1, '#7299b117');
  g.fillStyle = ridge;
  g.fill(winterRidge);
  pineSnowFlurry(g, t, 0, 47);

  g.save();
  g.translate(571, 109);
  g.rotate(-.028 * cover + .020 * Math.sin(phase(t, 2, .2)) + .057 * gust);
  g.translate(-571, -109);
  const bark = g.createLinearGradient(335, 154, 570, 112);
  bark.addColorStop(0, '#405253');
  bark.addColorStop(.59, '#564b48');
  bark.addColorStop(1, '#363d3e');
  g.fillStyle = bark;
  g.fill(snowyPineBough);
  stroke(g, pineBoughRidge, [144, 148, 143], .52, 1.08);
  for (const [index, fan] of snowyPineFans.entries()) {
    g.save();
    g.translate(fan.x, fan.y);
    g.rotate(fan.angle + .048 * Math.sin(phase(t, 2, index * .49)) + gust * .085);
    stroke(g, fan.base, [99, 107, 95], .92, 1.9);
    stroke(g, fan.needles[0], [55, 91, 94], .90, 1.28);
    stroke(g, fan.needles[1], [78, 121, 122], .93, 1.07);
    stroke(g, fan.needles[2], [130, 160, 155], .82, .76);
    g.restore();
  }
  for (const [x, y, width, thickness, delay, angle] of pineSnowPatches) {
    paintPineSnowCap(g, x, y, width, thickness, pineSnowCover(t, delay), angle);
  }
  g.restore();

  for (const flake of loosenedSnow) {
    const fall = (t - 8.12 - flake.delay) / 1.32;
    if (fall <= 0 || fall >= 1) continue;
    const opacity = Math.sin(Math.PI * fall) * .93;
    const y = 147 + (454 - flake.x) * .08 + 15 * fall + 89 * fall ** 2;
    ellipse(g, flake.x + flake.drift * fall, y, flake.size, flake.size * .80, pineSnowWhite, opacity, -.28);
  }
  pineSnowFlurry(g, t, 47, driftingSnow.length);
}

const pineSnowBadgeBranch = new Path2D('M-23 11Q-2 5 21 -11');
const pineSnowBadgeNeedles = new Path2D('M-15 8L-21 -4M-15 8L-7 12M-9 5L-13 -10M-9 5L3 11M-2 2L-6 -15M-2 2L13 6M5 -2L2 -19M5 -2L17 1M12 -7L11 -20M12 -7L23 -5M18 -10L20 -20');

function xiaoxueBadge(g, t) {
  const cover = pineSnowCover(t);
  g.save();
  g.rotate(.06 * Math.sin(phase(t, 2, .6)));
  stroke(g, pineSnowBadgeBranch, [152, 168, 148], .99, 2.2);
  stroke(g, pineSnowBadgeNeedles, [136, 195, 184], .96, 1.95);
  paintPineSnowCap(g, -5, 2, 10, 3.4, .43 + .57 * cover);
  paintPineSnowCap(g, 12, -9, 9.6, 3.2, .45 + .55 * cover);
  g.translate(-16, -17 + 2.8 * Math.sin(phase(t, 1, .25)));
  g.rotate(phase(t, 1));
  g.scale(6.4, 6.4);
  stroke(g, pineSnowCrystal, pineSnowWhite, .87, .18);
  g.restore();
}

const deepSnowPeaks = new Path2D('M206 170L268 127L304 103L340 58L352 68L380 112L405 124L456 66L469 63L493 92L528 118L552 111L584 145V225H206Z');
const deepSnowRidge = new Path2D('M216 229C252 213 283 201 319 204C357 206 393 232 431 219C479 201 514 199 584 207V269H259C248 253 233 240 216 229Z');
const deepSnowPeakLight = new Path2D('M284 121L340 58L352 68L379 111L353 98L342 84L329 99L319 96ZM427 99L456 66L469 63L493 92L471 84L461 84L452 93L447 87Z');
const deepSnowFir = new Path2D('M0 -1L.26 -.71L.14 -.73L.48 -.46L.29 -.48L.67 -.24L.45 -.25L.84 -.02Q.35 .06 .07 0L.06 .07H-.05V0Q-.36 .06 -.77 -.03L-.43 -.23L-.65 -.21L-.30 -.44L-.48 -.40L-.16 -.63L-.27 -.60Z');
const deepSnowFirLight = new Path2D('M-.25 -.60Q-.06 -.61 .21 -.68M-.48 -.40Q-.12 -.41 .39 -.47M-.65 -.20Q-.17 -.20 .60 -.25');
const deepSnowHouseFront = new Path2D('M-52 -8L-7 -58L39 -9V57H-52Z');
const deepSnowHouseSide = new Path2D('M39 -9L73 -28V37L39 57Z');
const deepSnowRoof = new Path2D('M-8 -62L30 -82L85 -31L47 -10Z');
const deepSnowFascia = new Path2D('M-61 -6L-8 -62L47 -10L42 -4L-8 -52L-55 -2Z');
const deepSnowBoards = new Path2D('M-48 1H37M-48 13H37M-48 26H37M-48 39H37M-48 52H37M42 0L71 -16M42 14L71 -2M42 28L71 12M42 42L71 26');
const deepSnowSlateLines = new Path2D('M2 -66L56 -15M12 -72L66 -21M22 -77L76 -26M11 -43L47 -63M22 -32L58 -52M32 -22L69 -42');
const deepSnowStep = new Path2D('M-71 54C-51 49 -42 51 -35 50C-26 48 -14 52 -7 50C6 45 11 51 24 50C41 49 54 43 67 44Q78 45 87 49L68 63C51 68 42 67 29 69C14 71 2 69 -15 71C-40 71 -62 68 -77 65Z');
const deepSnowBadgeHouse = new Path2D('M-18 -4L-4 -18L13 -5V14H-18ZM13 -5L23 -10V8L13 14Z');
const snowHouseOrigin = [433, 165];
const deepSnowIce = [225, 241, 255];
const deepSnowGold = [255, 193, 106];

const deepSnowflakes = Array.from({length:146}, (_, i) => {
  const layer = i < 86 ? 0 : i < 114 ? 1 : 2;
  return {
    layer, x:172 + rnd(17600 + i) * 392, offset:rnd(17800 + i),
    size:(.64 + rnd(18000 + i) * 1.12) * (1 + layer * .74),
    speed:2 + layer, wave:rnd(18200 + i) * TAU, lift:rnd(18400 + i),
  };
});

function deepSnowWind(t) {
  return smooth(.65, 3.75, t) * (1 - smooth(9.35, 12.85, t));
}

function deepSnowDrift(t) {
  return smooth(1.55, 8.65, t) * (1 - smooth(10.10, LOOP, t));
}

function deepSnowWindowLight(t) {
  const lit = smooth(2.45, 5.35, t) * (1 - smooth(10.3, LOOP, t));
  return .14 + lit * (.81 + .05 * Math.sin(phase(t, 3, .3)));
}

function deepSnowFlurry(g, t, wind, from, to) {
  const pulse = .78 + .22 * Math.sin(phase(t, 2, -.3));
  for (let i = from; i < to; i++) {
    const flake = deepSnowflakes[i];
    const fall = (t / LOOP * flake.speed + flake.offset) % 1;
    const blow = 35 + (92 + flake.layer * 15) * wind * pulse;
    const x = flake.x + (fall - .42) * blow + 12 * Math.sin(fall * 6 + flake.wave + phase(t));
    const y = -14 + fall * (264 + flake.layer * 14);
    const span = Math.sin(Math.PI * fall);
    const strength = .23 + (.64 + flake.lift * .24) * wind;
    const opacity = span * strength * (.43 + flake.layer * .19);
    if (flake.layer === 2 && flake.size > 2.75) {
      glow(g, x, y, flake.size * 2.6, [193, 221, 250], .18 * opacity);
    }
    ellipse(g, x, y, flake.size * (.82 + .54 * wind), flake.size * .68,
      deepSnowIce, opacity, .71);
  }
}

function deepSnowTree(g, x, y, height, width, opacity, settled) {
  g.save();
  g.translate(x, y);
  g.scale(width, height);
  const evergreen = g.createLinearGradient(0, -1, 0, .06);
  evergreen.addColorStop(0, rgba([85, 117, 136], opacity));
  evergreen.addColorStop(1, rgba([30, 51, 68], opacity));
  g.fillStyle = evergreen;
  g.fill(deepSnowFir);
  stroke(g, deepSnowFirLight, [163, 198, 224], (.18 + .47 * settled) * opacity, .044);
  g.restore();
}

function drawDeepSnowRoof(g, cover) {
  if (cover < .01) return;
  const depth = 2 + 12.5 * cover;
  const snow = new Path2D();
  snow.moveTo(-64, -8 - depth * .36);
  snow.bezierCurveTo(-49, -22 - depth, -24, -57 - depth, -8, -62 - depth);
  snow.quadraticCurveTo(13, -76 - depth, 30, -82 - depth);
  snow.bezierCurveTo(44, -78 - depth, 68, -47 - depth, 86, -31 - depth * .55);
  snow.quadraticCurveTo(91, -29 - depth * .27, 87, -27);
  snow.bezierCurveTo(76, -22, 72, -28, 58, -17);
  snow.bezierCurveTo(52, -12, 49, -8, 44, -7);
  snow.bezierCurveTo(31, -17, 13, -36, -8, -55);
  snow.bezierCurveTo(-21, -43, -47, -12, -59, -5);
  snow.quadraticCurveTo(-63, -3, -64, -8 - depth * .36);
  snow.closePath();
  const shine = g.createLinearGradient(-6, -73 - depth, 40, -5);
  shine.addColorStop(0, rgba([241, 249, 255], cover * .97));
  shine.addColorStop(.48, rgba([196, 219, 240], cover * .98));
  shine.addColorStop(1, rgba([151, 185, 218], cover * .96));
  g.fillStyle = shine;
  g.fill(snow);
  stroke(g, snow, [227, 244, 254], .38 * cover, 1.15);
}

function deepSnowHouse(g, settled, lamp) {
  g.save();
  g.translate(...snowHouseOrigin);
  const siding = g.createLinearGradient(-50, -37, 35, 56);
  siding.addColorStop(0, '#66545c');
  siding.addColorStop(.46, '#4a3d47');
  siding.addColorStop(1, '#382f3e');
  g.fillStyle = siding;
  g.fill(deepSnowHouseFront);
  g.fillStyle = '#342f40';
  g.fill(deepSnowHouseSide);
  stroke(g, deepSnowHouseFront, [126, 115, 126], .56, 1.2);
  stroke(g, deepSnowBoards, [137, 111, 112], .58, .73);
  g.fillStyle = '#242837';
  g.fillRect(6, 9, 25, 48);
  g.fillStyle = '#4d3a41';
  g.fillRect(10, 12, 17, 44);
  line(g, 18, 15, 18, 55, [138, 104, 98], .45, .9);
  ellipse(g, 23, 35, 1.7, 1.7, [194, 145, 101], .89);

  glow(g, -26, 21, 56, deepSnowGold, .49 * lamp);
  g.fillStyle = '#282534';
  g.fillRect(-45, 4, 36, 34);
  const window = g.createLinearGradient(-40, 9, -13, 33);
  window.addColorStop(0, rgba(mix([119, 77, 70], [255, 223, 152], lamp)));
  window.addColorStop(1, rgba(mix([49, 39, 50], [233, 138, 74], lamp)));
  g.fillStyle = window;
  g.fillRect(-41, 8, 28, 26);
  line(g, -27, 9, -27, 34, [73, 43, 52], .85, 1.9);
  line(g, -41, 20, -13, 20, [73, 43, 52], .83, 1.7);
  line(g, -44, 36, -10, 36, [171, 135, 112], .74, 1.3);

  g.fillStyle = '#3a4359';
  g.fill(deepSnowRoof);
  stroke(g, deepSnowSlateLines, [112, 128, 152], .63, 1.06);
  g.fillStyle = '#4c4a5b';
  g.fill(deepSnowFascia);
  drawDeepSnowRoof(g, .13 + .87 * settled);

  g.save();
  g.translate(0, -.8 - 3.7 * settled);
  const bank = g.createLinearGradient(0, 44, 0, 71);
  bank.addColorStop(0, rgba([211, 231, 248], .19 + .76 * settled));
  bank.addColorStop(1, rgba([135, 167, 206], .10 + .49 * settled));
  g.fillStyle = bank;
  g.fill(deepSnowStep);
  g.restore();
  g.save();
  g.translate(-31, 57);
  g.scale(1, .29);
  glow(g, 0, 0, 41, deepSnowGold, .27 * lamp);
  g.restore();
  g.restore();
}

function daxue(g, t) {
  const wind = deepSnowWind(t), settled = deepSnowDrift(t), lamp = deepSnowWindowLight(t);
  glow(g, 403, 90, 279, [119, 156, 212], .24 + .23 * wind);
  glow(g, 496, 170, 165, [169, 200, 239], .13 + .12 * settled);
  const mountain = g.createLinearGradient(237, 168, 497, 223);
  mountain.addColorStop(0, '#546b8d00');
  mountain.addColorStop(.52, '#526582b3');
  mountain.addColorStop(1, '#3b4865e3');
  g.fillStyle = mountain;
  g.fill(deepSnowPeaks);
  g.fillStyle = rgba([142, 173, 211], .18 + .14 * wind);
  g.fill(deepSnowPeakLight);
  const drift = g.createLinearGradient(0, 201, 0, 269);
  drift.addColorStop(0, '#7694b977');
  drift.addColorStop(.40, '#7694b968');
  drift.addColorStop(1, '#5f7a9a00');
  g.fillStyle = drift;
  g.fill(deepSnowRidge);
  deepSnowFlurry(g, t, wind, 0, 86);

  deepSnowTree(g, 318, 208, 76, 23, .72, settled);
  deepSnowTree(g, 349, 217, 98, 27, .91, settled);
  deepSnowTree(g, 553, 208, 112, 32, .89, settled);
  deepSnowHouse(g, settled, lamp);
  deepSnowFlurry(g, t, wind, 86, deepSnowflakes.length);
}

function daxueBadge(g, t) {
  const settled = deepSnowDrift(t), lamp = deepSnowWindowLight(t);
  g.fillStyle = '#657a97';
  g.fill(deepSnowBadgeHouse);
  const roof = new Path2D();
  roof.moveTo(-23, -2);
  roof.lineTo(-4, -22 - settled * 2);
  roof.lineTo(6, -26 - settled * 2);
  roof.quadraticCurveTo(15, -22, 26, -11);
  roof.lineTo(14, -4);
  roof.lineTo(-4, -18);
  roof.lineTo(-19, -1);
  roof.closePath();
  g.fillStyle = rgba(mix([178, 202, 227], [239, 248, 255], .39 + .56 * settled));
  g.fill(roof);
  glow(g, -5, 6, 16, deepSnowGold, .39 * lamp);
  g.fillStyle = rgba(mix([173, 126, 92], [255, 209, 127], lamp));
  g.fillRect(-11, 1, 12, 10);
  line(g, -5, 2, -5, 11, [102, 76, 89], .9, 1.1);
  line(g, -20, 15, 22, 9, [196, 219, 245], .88, 1.9);
}

const winterDumpling = new Path2D(
  'M-34 5C-35 0 -29 -2 -26 -7Q-27 -11 -21 -12Q-21 -18 -15 -16Q-13 -22 -7 -19Q-4 -24 1 -21Q6 -23 10 -19Q16 -20 19 -15Q25 -15 27 -9Q33 -7 32 -2Q37 3 34 7C31 17 10 22 -7 20C-21 19 -29 14 -34 5Z',
);
const winterDumplingSeam = new Path2D('M-29 3C-22 -5 -14 -15 0 -16C12 -17 23 -7 29 1');
const winterDumplingPleats = new Path2D('M-25 -7Q-23 -4 -23 0M-20 -12Q-18 -10 -18 -5M-14 -16Q-12 -14 -12 -9M-7 -19Q-5 -16 -5 -12M1 -20Q4 -18 4 -13M9 -19Q12 -16 11 -11M17 -16Q20 -12 18 -8M24 -12Q27 -9 24 -5M29 -7Q32 -5 28 -2');
const winterDumplingRim = new Path2D('M-25 9C-16 15 8 18 23 11');
const winterDumplingPlate = [
  {x:366, y:188, size:.79, tilt:-.16, light:.72},
  {x:418, y:181, size:.84, tilt:.12, light:.77},
  {x:471, y:183, size:.76, tilt:.27, light:.73},
  {x:344, y:207, size:.82, tilt:-.22, light:.91},
  {x:403, y:219, size:.92, tilt:.05, light:.99},
];
const winterPlateCenter = [423, 206];
const winterDumplingHome = [470, 215];

function winterDumplingLift(t) {
  return smooth(3.32, 6.75, t) * (1 - smooth(8.60, 10.95, t));
}

function winterDumplingWarmth(t) {
  return smooth(1.08, 6.3, t) * (1 - smooth(10.3, LOOP, t));
}

function paintWinterDumpling(g, x, y, size, tilt, light = 1) {
  g.save();
  g.translate(x, y);
  g.rotate(tilt);
  g.scale(size, size);
  const dough = g.createLinearGradient(-12, -24, 19, 21);
  dough.addColorStop(0, rgba(mix([199, 200, 196], [255, 243, 216], light)));
  dough.addColorStop(.40, rgba(mix([167, 174, 171], [238, 215, 179], light)));
  dough.addColorStop(.74, rgba(mix([156, 157, 150], [224, 199, 163], light)));
  dough.addColorStop(1, rgba(mix([101, 118, 119], [167, 144, 123], light)));
  g.fillStyle = dough;
  g.fill(winterDumpling);
  stroke(g, winterDumpling, [96, 80, 77], .50, 1.05);
  stroke(g, winterDumplingSeam, [255, 245, 224], .58 + .27 * light, 1.12);
  stroke(g, winterDumplingPleats, [154, 119, 93], .67, 1.34);
  g.save();
  g.translate(-.7, -.65);
  stroke(g, winterDumplingPleats, [252, 239, 213], .78, .83);
  g.restore();
  stroke(g, winterDumplingRim, [251, 230, 197], .38, 1.5);
  g.restore();
}

function paintWinterCeramic(g, warmth) {
  g.save();
  g.translate(...winterPlateCenter);
  ellipse(g, 1, 23, 139, 22, [24, 30, 37], .65);
  ellipse(g, 0, 4, 133, 38, [37, 62, 64]);
  const glaze = g.createLinearGradient(-70, -31, 95, 36);
  glaze.addColorStop(0, '#8aa99f');
  glaze.addColorStop(.52, '#5b837e');
  glaze.addColorStop(1, '#3d656b');
  const plate = new Path2D();
  plate.ellipse(0, 0, 133, 37, 0, 0, TAU);
  g.fillStyle = glaze;
  g.fill(plate);
  stroke(g, plate, [170, 204, 190], .60, 1.21);
  ellipse(g, 0, -1, 120, 28, [73, 108, 104]);
  ellipse(g, 0, -1, 117, 24.5, [81, 120, 114], .84);
  const rim = new Path2D();
  rim.ellipse(0, 0, 125, 32, 0, .12, Math.PI - .12);
  stroke(g, rim, [185, 214, 202], .30 + .19 * warmth, 1.2);
  g.restore();
}

function winterChopstick(g, x, y, side, opacity) {
  if (opacity <= .01) return;
  const endX = x + 150, endY = y - 68 + side * 3;
  const shaft = new Path2D();
  shaft.moveTo(x - .5, y - 1.05);
  shaft.lineTo(endX - 1.1, endY - 3.1);
  shaft.quadraticCurveTo(endX + 3, endY - 2.6, endX + 2, endY + 2.65);
  shaft.lineTo(x + .4, y + 1.05);
  shaft.closePath();
  const wood = g.createLinearGradient(x, y, endX, endY);
  wood.addColorStop(0, rgba([224, 167, 103], opacity));
  wood.addColorStop(.53, rgba([166, 101, 61], opacity));
  wood.addColorStop(1, rgba([110, 59, 48], opacity));
  g.fillStyle = wood;
  g.fill(shaft);
  stroke(g, shaft, [96, 63, 53], opacity * .62, .75);
  line(g, x + 2, y - .5, endX - 3, endY - 1.9, [245, 204, 146], opacity * .6, .68);
}

function dongzhi(g, t) {
  const lift = winterDumplingLift(t);
  const warmth = winterDumplingWarmth(t);
  glow(g, 385, 84, 221, [131, 159, 190], .24);
  glow(g, 429, 168, 193, [222, 159, 112], .13 + .20 * warmth);
  g.save();
  g.translate(430, 229);
  g.scale(1, .18);
  glow(g, 0, 0, 151, [216, 162, 124], .17 + .10 * warmth);
  g.restore();

  paintWinterCeramic(g, warmth);
  for (const dumpling of winterDumplingPlate) {
    ellipse(g, dumpling.x + 2, dumpling.y + 11, dumpling.size * 30, 8.7, [37, 59, 58], .58);
    paintWinterDumpling(g, dumpling.x, dumpling.y, dumpling.size, dumpling.tilt, dumpling.light);
  }

  const [homeX, homeY] = winterDumplingHome;
  const x = homeX - 21.5 * lift + lift * Math.sin(phase(t, 2, .55)) * 2;
  const y = homeY - 94 * lift;
  const tilt = .09 - .26 * lift + .049 * lift * Math.sin(phase(t, 2));
  ellipse(g, homeX + 4 - lift * 5, homeY + 10, 29 + 5 * lift,
    8.7 + 4 * lift, [29, 53, 51], .55 - .39 * lift);
  const approach = smooth(.48, 3.18, t) * (1 - smooth(10.98, 12.56, t));
  const pinch = smooth(2.36, 3.38, t) * (1 - smooth(10.88, 11.35, t));
  const gripX = x + lerp(68, 11, approach), gripY = y + lerp(-48, -10, approach);
  const gap = lerp(15, 4.4, pinch);
  const visible = smooth(.39, 1.64, t) * (1 - smooth(11.53, 12.8, t));
  winterChopstick(g, gripX - gap * .62, gripY - gap, -1, .85 * visible);
  paintWinterDumpling(g, x, y, .93, tilt, 1);
  winterChopstick(g, gripX + gap * .62, gripY + gap, 1, visible);
}

function dongzhiBadge(g, t) {
  const lift = winterDumplingLift(t);
  g.save();
  g.translate(0, 1 - 5.4 * lift);
  const tilt = -.17 + .13 * lift + .038 * Math.sin(phase(t, 1, .5));
  paintWinterDumpling(g, 0, 0, .76, tilt, 1);
  g.restore();
}

const wintersweetBranch = new Path2D('M586 225Q541 193 498 167C453 136 409 126 376 109Q350 96 324 91L307 81Q333 87 360 97C397 114 441 124 483 143Q538 167 589 203Z');
const wintersweetBranchGrain = new Path2D('M583 210C529 176 479 151 441 137Q395 122 369 108M571 211Q537 186 514 174M501 153Q469 137 432 126M388 112L365 101');
const wintersweetTwigs = [
  ['M477 151Q456 128 432 112Q414 95 405 68Q397 55 384 47', 5.1],
  ['M427 125Q400 135 373 148Q351 158 331 156', 4.2],
  ['M425 102Q439 88 449 74L456 61', 3.1],
  ['M521 173Q512 183 501 201L482 211', 3.5],
  ['M355 102Q336 108 320 117L308 123', 2.6],
  ['M543 182Q554 155 571 149', 3.2],
].map(([curve, width]) => ({path: new Path2D(curve), width}));
const wintersweetSnow = new Path2D('M313 82Q330 84 346 92M353 95Q367 100 376 104M403 114Q425 121 440 127M451 131Q466 136 483 144M493 148Q508 155 522 162M532 167Q552 178 567 188M394 52Q404 60 407 71M438 89L448 76');
const wintersweetPetal = new Path2D('M-1 4C-5 -2 -10 -11 -7 -21Q-6 -28 0 -31Q7 -29 8 -22C10 -13 5 -2 2 4Z');
const wintersweetVein = new Path2D('M0 0Q-3 -9 -1 -17Q1 -24 0 -28');
const wintersweetBudShell = new Path2D('M0 4C-9 5 -13 -7 -7 -13Q2 -20 9 -12C15 -6 9 4 0 4Z');
const wintersweetBudSeam = new Path2D('M-3 -12Q-6 -5 0 3M4 -13Q8 -5 3 2');
const wintersweetBadgeTwig = new Path2D('M-11 18Q0 9 13 -4L22 -9');
const wintersweetBlossoms = [
  {x:321, y:115, size:.57, tilt:-.44, depth:.75, turns:.3, start:2.3},
  {x:405, y:67, size:.66, tilt:-.40, depth:.81, turns:1.0, start:2.8},
  {x:372, y:147, size:.72, tilt:.22, depth:.68, turns:-.3, start:1.45},
  {x:481, y:146, size:.87, tilt:.52, depth:.91, turns:.4, start:3.35},
  {x:503, y:197, size:.65, tilt:.17, depth:.72, turns:1.4, start:4.15},
  {x:429, y:108, size:1.15, tilt:-.21, depth:.94, turns:0, start:.95},
];

function wintersweetOpening(t, start) {
  return smooth(start, start + 3.5, t) * (1 - smooth(10.15, 13, t));
}

function paintWintersweetBud(g, x, y, size, tilt, opacity = 1) {
  g.save();
  g.translate(x, y);
  g.rotate(tilt);
  g.scale(size, size);
  const bud = g.createLinearGradient(0, -17, 1, 5);
  bud.addColorStop(0, rgba([249, 220, 130], opacity));
  bud.addColorStop(.58, rgba([201, 146, 70], opacity));
  bud.addColorStop(1, rgba([98, 66, 54], opacity));
  g.fillStyle = bud;
  g.fill(wintersweetBudShell);
  stroke(g, wintersweetBudSeam, [254, 223, 142], .62 * opacity, 1);
  g.restore();
}

function paintWintersweetFlower(g, x, y, size, tilt, bloom, depth = 1, turns = 0) {
  paintWintersweetBud(g, x, y, size * .84, tilt, 1 - smooth(.17, .61, bloom));
  if (bloom <= .01) return;
  g.save();
  g.translate(x, y);
  g.rotate(tilt);
  g.scale(size, size * depth);
  const opacity = smooth(.01, .23, bloom);
  const spread = lerp(.23, 1, bloom);
  const petal = g.createLinearGradient(0, -30, 1, 5);
  petal.addColorStop(0, rgba([255, 243, 187], opacity));
  petal.addColorStop(.44, rgba([241, 204, 113], opacity));
  petal.addColorStop(.78, rgba([209, 145, 72], opacity));
  petal.addColorStop(1, rgba([129, 72, 52], opacity));
  const inner = g.createLinearGradient(0, -30, 0, 4);
  inner.addColorStop(0, rgba([247, 219, 137], opacity));
  inner.addColorStop(.42, rgba([222, 165, 84], opacity));
  inner.addColorStop(1, rgba([112, 57, 53], opacity));
  for (const [count, ring, color] of [[9, 1, petal], [6, .65, inner]]) {
    for (let n = 0; n < count; n++) {
      const waviness = rnd(n + count * 10);
      g.save();
      g.rotate(n * TAU / count + turns + ring * .25 + waviness * .13);
      g.translate(0, -3 * spread * ring);
      g.scale(ring * (.61 + .45 * waviness), ring * spread * (.82 + waviness * .24));
      g.fillStyle = color;
      g.fill(wintersweetPetal);
      stroke(g, wintersweetPetal, [255, 234, 162], opacity * .47, .86);
      stroke(g, wintersweetVein, [255, 249, 205], opacity * .43, .86);
      g.restore();
    }
  }
  ellipse(g, 0, 0, 6.3 * spread, 5.4 * spread, [137, 68, 54], opacity);
  for (let i = 0; i < 6; i++) {
    const a = i * TAU / 6 + .34;
    const x = Math.cos(a) * spread * 4;
    const y = Math.sin(a) * spread * 3.2;
    ellipse(g, x, y, 1.5, 1.15, [255, 219, 140], opacity, a);
  }
  g.restore();
}

function xiaohan(g, t) {
  const bloom = wintersweetOpening(t, .95);
  glow(g, 453, 111, 198, [125, 159, 190], .25);
  glow(g, 407, 125, 134, [239, 176, 104], .075 + .15 * bloom);
  g.save();
  g.translate(584, 213);
  g.rotate(.018 * Math.sin(phase(t)) + .012 * Math.sin(phase(t, 2, 1.1)));
  g.translate(-584, -213);
  const bark = g.createLinearGradient(367, 98, 343, 163);
  bark.addColorStop(0, '#97766a');
  bark.addColorStop(.48, '#604743');
  bark.addColorStop(1, '#42343e');
  g.fillStyle = bark;
  g.fill(wintersweetBranch);
  stroke(g, wintersweetBranchGrain, [176, 135, 115], .53, 1.25);
  for (const {path, width} of wintersweetTwigs) {
    stroke(g, path, [87, 67, 67], 1, width);
    g.save();
    g.translate(0, -.95);
    stroke(g, path, [164, 127, 110], .66, width * .34);
    g.restore();
  }
  stroke(g, wintersweetSnow, [170, 197, 214], .55, 4.4);
  g.save();
  g.translate(0, -1.35);
  stroke(g, wintersweetSnow, [226, 239, 246], .75, 1.9);
  g.restore();

  for (const [x, y, size, tilt] of [[309, 82, .64, -1], [384, 48, .39, -.65], [455, 62, .55, .64], [331, 156, .42, -1.1], [483, 210, .48, -.96], [570, 149, .60, .7]]) {
    paintWintersweetBud(g, x, y, size, tilt);
  }
  for (const flower of wintersweetBlossoms) {
    paintWintersweetFlower(g, flower.x, flower.y, flower.size, flower.tilt,
      wintersweetOpening(t, flower.start), flower.depth, flower.turns);
  }
  g.restore();

  for (let i = 0; i < 26; i++) {
    const f = particles[i];
    const u = (f.y + t / LOOP * (1 + Math.round(f.speed))) % 1;
    const x = 246 + f.x * 348 - 49 * u;
    const y = 12 + u * 205;
    const opacity = Math.sin(Math.PI * u) * (.16 + f.r * .32);
    ellipse(g, x, y, .65 + f.r * 1.55, .59 + f.r * .86, [224, 238, 247], opacity, -.35);
  }
}

function xiaohanBadge(g, t) {
  const bloom = .38 + .62 * wintersweetOpening(t, .95);
  stroke(g, wintersweetBadgeTwig, [175, 136, 120], 1, 3.2);
  paintWintersweetBud(g, 15, -5, .62, .48);
  paintWintersweetFlower(g, -4, -5, .86, -.19, bloom, .94);
}

const frozenHouseGable = new Path2D('M-105 -59L-78 -92L-55 -43V49L-105 28Z');
const frozenHouseFront = new Path2D('M-55 -45L98 -66V29L-55 49Z');
const frozenHouseBoards = new Path2D('M-103 -47L-57 -34M-103 -35L-57 -20M-103 -22L-57 -7M-103 -9L-57 6M-103 4L-57 19M-103 17L-57 32M-103 27L-57 44');
const frozenHouseVent = new Path2D('M-95 -31L-76 -25V-7L-95 -13Z');
const frozenHouseChimney = new Path2D('M4 -104V-125L22 -129L29 -124V-103L12 -100Z');
const frozenHouseChimneyShade = new Path2D('M22 -129L29 -124V-103L22 -102Z');
const frozenHouseDrift = new Path2D('M-121 35Q-98 25 -77 34Q-55 42 -33 42Q-9 40 6 42Q23 37 44 38Q76 31 104 24Q118 23 129 29Q121 38 103 42Q77 41 61 49Q42 55 24 55Q10 63 -32 61Q-69 60 -93 51Q-108 47 -121 35Z');
const frozenHouseStep = new Path2D('M37 42L76 37L85 41L45 47Z M45 47L85 41V45L45 51Z');
const frozenRoof = new Path2D('M-77 -98L65 -114Q75 -102 84 -91Q99 -72 113 -66L-60 -42Q-71 -63 -77 -98Z');
const frozenRoofEave = new Path2D('M-114 -58Q-97 -74 -77 -98Q-68 -68 -60 -42L113 -66L109 -59L-60 -35L-77 -87Q-94 -65 -109 -55Z');
const frozenRoofSnow = new Path2D('M-115 -58Q-104 -74 -94 -84Q-88 -95 -76 -101Q-66 -106 -55 -105Q-27 -109 -12 -108Q1 -113 21 -112Q46 -119 67 -117Q75 -111 80 -100Q88 -93 96 -85Q101 -82 102 -78Q88 -77 74 -72Q60 -75 51 -68Q35 -68 22 -64Q8 -68 -4 -61Q-17 -62 -27 -57Q-40 -59 -53 -53Q-60 -52 -65 -49Q-71 -63 -77 -86Q-91 -71 -110 -56Q-114 -54 -115 -58Z');
const frozenRoofSnowEdge = new Path2D('M-111 -60Q-96 -79 -81 -94M-73 -100Q-55 -105 -39 -105M-33 -106L-14 -108M-4 -109Q11 -113 25 -112M33 -114Q51 -116 66 -115');
const frozenEaveY = x => -42 - (x + 60) * .139;
const frozenTileEnds = Array.from({length:14}, (_,i) => -58 + i * 12.2);
const icicleOutline = new Path2D('M-12 1Q-6 -4 0 0L9 -1L12 7L8 30L7 37L6 51L3 64L2 79L-.5 94L-3 105L-4 98L-5 82L-7 71L-7.5 56L-10 37L-10 30L-13 15Z');
const icicleRightFacet = new Path2D('M1 1L9 -1L12 7L8 30L7 37L6 51L3 64L2 79L-.5 94L-3 105L-1 75L-.5 57L2 35L0 26L3 17Z');
const icicleLeftFacet = new Path2D('M-12 1L-6 2L-5 14L-4 22L-6 38L-4 55L-4 70L-3 86L-3 105L-5 82L-7 71L-7.5 56L-10 37L-10 30L-13 15Z');
const icicleRidges = new Path2D('M-3 8L-4 21L-2 33L-4 49L-3 66L-3 77M7 6L6 20L4 31L4 43L2 59L1 71M-9 6L-8 18L-8 27');
const icicleFractures = new Path2D('M-12 14L-8 17L-5 18M10 13L7 17L5 17M-8 30L-5 34L-2 34M7 42L4 44L2 47');
const frozenBadgeGable = new Path2D('M-23 -4L-17 -20L-7 -4V18L-23 13Z');
const frozenBadgeFront = new Path2D('M-7 -5L21 -9V14L-7 18Z');
const frozenBadgeSnow = new Path2D('M-27 -5L-18 -23L12 -27L26 -10L-8 -4L-18 -18L-24 -4Z');
const frozenBadgeRim = new Path2D('M-25 -4L-18 -20L-8 -4L25 -10');
const eavesIcicles = [
  {x:-53, width:11, length:37, tilt:.11, start:1.9},
  {x:-35, width:10, length:27, tilt:.08, start:2.1},
  {x:-16, width:13, length:49, tilt:-.04, start:1.22},
  {x:7, width:17, length:68, tilt:-.09, start:.75},
  {x:27, width:12, length:48, tilt:.06, start:3.2},
  {x:49, width:15, length:73, tilt:-.05, start:1.56},
  {x:74, width:17, length:81, tilt:.07, start:2.7},
  {x:99, width:13, length:51, tilt:-.06, start:3.65},
];

function iceGrowth(t, start) {
  return smooth(start, start + 4.9, t) * (1 - smooth(10.47, 13, t));
}

function iceGlint(t, offset) {
  return smooth(6.12 + offset, 7.95 + offset, t) * (1 - smooth(8.5 + offset, 9.5 + offset, t));
}

function paintIcicle(g, x, y, width, length, angle, intensity = 1, glint = 0) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.scale(width / 25, length / 105);
  const frozen = g.createLinearGradient(-13, 9, 10, 49);
  frozen.addColorStop(0, rgba([195, 236, 250], .92 * intensity));
  frozen.addColorStop(.25, rgba([116, 184, 216], .79 * intensity));
  frozen.addColorStop(.56, rgba([108, 169, 204], .48 * intensity));
  frozen.addColorStop(1, rgba([184, 226, 246], .87 * intensity));
  g.fillStyle = frozen;
  g.fill(icicleOutline);
  g.fillStyle = rgba([69, 119, 157], .54 * intensity);
  g.fill(icicleRightFacet);
  g.fillStyle = rgba([220, 247, 255], (.27 + .51 * glint) * intensity);
  g.fill(icicleLeftFacet);
  stroke(g, icicleOutline, [203, 238, 248], .66 * intensity, .88);
  stroke(g, icicleRidges, [205, 241, 255], (.54 + .38 * glint) * intensity, 1.15);
  stroke(g, icicleFractures, [231, 247, 252], .49 * intensity, 1.09);
  g.restore();
}

function paintFrozenRoof(g) {
  const tiles = g.createLinearGradient(-9, -107, 4, -37);
  tiles.addColorStop(0, '#7a97ad');
  tiles.addColorStop(.44, '#4b657d');
  tiles.addColorStop(1, '#26384d');
  g.fillStyle = tiles;
  g.fill(frozenRoof);
  const channels = g.createLinearGradient(-5, 0, 5, 0);
  channels.addColorStop(0, rgba([36, 51, 68], .68));
  channels.addColorStop(.5, rgba([151, 185, 205], .65));
  channels.addColorStop(1, rgba([63, 83, 106], .35));
  g.save();
  g.clip(frozenRoof);
  for (const x of frozenTileEnds) {
    g.save();
    g.translate(x, frozenEaveY(x));
    g.transform(1, 0, .54, 1, 0, 0);
    g.fillStyle = channels;
    g.fillRect(-5, -74, 10, 74);
    line(g, 5.6, -70, 5.6, 0, [176, 200, 215], .30, .9);
    g.restore();
  }
  g.restore();
  g.fillStyle = '#40424f';
  g.fill(frozenRoofEave);
  for (const x of frozenTileEnds) {
    const y = frozenEaveY(x) + 1.2;
    ellipse(g, x, y, 4.9, 2.9, [39, 52, 69]);
    ellipse(g, x - .36, y - .48, 3.5, 2.06, [119, 154, 179]);
    ellipse(g, x + .28, y - .21, 2.25, 1.35, [61, 84, 106]);
  }

  const snow = g.createLinearGradient(-32, -111, -12, -53);
  snow.addColorStop(0, '#e1edf6');
  snow.addColorStop(.54, '#bfd3e1');
  snow.addColorStop(1, '#7896ad');
  g.fillStyle = snow;
  g.fill(frozenRoofSnow);
  stroke(g, frozenRoofSnowEdge, [239, 249, 253], .75, 1.6);
  g.save();
  g.clip(frozenRoofSnow);
  for (let i = 0; i < 70; i++) {
    const f = particles[i];
    ellipse(g, -115 + f.x * 230, -117 + f.y * 65, .40 + .7 * f.r, .42,
      f.r > .55 ? [238, 248, 252] : [70, 103, 134], .31);
  }
  g.restore();
}

function paintFrozenHouse(g) {
  const gable = g.createLinearGradient(-106, -55, -59, 45);
  gable.addColorStop(0, '#6f6a71');
  gable.addColorStop(.48, '#4f4c5a');
  gable.addColorStop(1, '#343849');
  g.fillStyle = gable;
  g.fill(frozenHouseGable);
  stroke(g, frozenHouseBoards, [172, 146, 143], .38, 1.1);
  const plaster = g.createLinearGradient(-44, -41, 42, 41);
  plaster.addColorStop(0, '#777478');
  plaster.addColorStop(.38, '#9d8980');
  plaster.addColorStop(1, '#5d5865');
  g.fillStyle = plaster;
  g.fill(frozenHouseFront);
  stroke(g, frozenHouseFront, [169, 146, 137], .62, 1.2);
  line(g, -56, -39, -56, 48, [76, 60, 64], .95, 5);
  line(g, 95, -60, 95, 30, [79, 66, 75], .85, 5);
  line(g, -53, 37, 94, 17, [105, 84, 88], .56, 1.6);

  g.fillStyle = '#2b374c';
  g.fill(frozenHouseVent);
  stroke(g, frozenHouseVent, [131, 126, 133], .68, 1.6);
  line(g, -93, -24, -78, -19, [117, 120, 138], .75, 1.4);
  line(g, -93, -19, -78, -14, [117, 120, 138], .75, 1.4);

  g.save();
  g.transform(1, -.139, 0, 1, 0, 0);
  g.fillStyle = '#594350';
  g.fillRect(37, -20, 38, 63);
  const door = g.createLinearGradient(42, -15, 68, 39);
  door.addColorStop(0, '#79594f');
  door.addColorStop(1, '#4f3e47');
  g.fillStyle = door;
  g.fillRect(41, -16, 30, 58);
  line(g, 55, -16, 55, 42, [62, 50, 58], .84, 1.7);
  line(g, 42, -12, 69, -12, [174, 134, 108], .5, 1.2);
  ellipse(g, 60, 16, 1.7, 1.7, [208, 160, 109]);

  glow(g, -23, 2, 48, [255, 197, 119], .23);
  g.fillStyle = '#4e3b46';
  g.fillRect(-46, -18, 47, 40);
  const lamplight = g.createLinearGradient(-41, -15, -4, 20);
  lamplight.addColorStop(0, '#f4deb4');
  lamplight.addColorStop(.44, '#e4bb87');
  lamplight.addColorStop(1, '#a66e58');
  g.fillStyle = lamplight;
  g.fillRect(-42, -14, 39, 31);
  line(g, -23, -14, -23, 18, [111, 78, 79], .91, 2.7);
  line(g, -42, 1, -3, 1, [111, 78, 79], .91, 2.4);
  line(g, -47, 22, 3, 22, [171, 145, 133], .75, 2.2);
  g.restore();
}

const dahanSnowLayers = [
  {count:64, left:176, span:442, minSize:1.3, sizeRange:2.8, color:[202, 224, 244]},
  {count:44, left:194, span:412, minSize:3.9, sizeRange:4.6, color:[221, 239, 252]},
  {count:38, left:221, span:395, minSize:7.1, sizeRange:7.1, color:[234, 247, 255]},
].map((style, depth) => ({
  color: style.color,
  flakes: Array.from({length:style.count}, (_, i) => {
    const seed = 24100 + depth * 700 + i * 8;
    return {
      x: style.left + rnd(seed) * style.span,
      offset: rnd(seed + 1),
      size: style.minSize + rnd(seed + 2) * style.sizeRange,
      fallRate: 2 + Math.round(rnd(seed + 3)) + (depth === 2 ? 1 : 0),
      sway: rnd(seed + 4) * TAU,
      turns: rnd(seed + 5) > .5 ? 1 : -1,
      opacity: .38 + rnd(seed + 6) * .43,
      soft: rnd(seed + 7) < .25,
    };
  }),
}));

function dahanSnowfall(g, t, depth) {
  const {color, flakes} = dahanSnowLayers[depth];
  const air = .80 + .20 * Math.sin(phase(t, 2, -.4));
  for (const flake of flakes) {
    const u = (flake.offset + t / LOOP * flake.fallRate) % 1;
    const x = flake.x - (u - .42) * (52 + depth * 21) * air +
      Math.sin(flake.sway + u * 8 + phase(t)) * (8 + depth * 3.5);
    const y = -24 + u * (280 + depth * 14);
    const visible = smooth(0, .09, u) * (1 - smooth(.85, 1, u));
    const textSpace = lerp(1, smooth(169, 255, x), smooth(132, 174, y));
    const overEaves = smooth(340, 380, x) * (1 - smooth(503, 541, x)) *
      smooth(103, 126, y) * (1 - smooth(191, 227, y));
    const opacity = flake.opacity * visible * textSpace *
      (.64 + .18 * depth) * (1 - .55 * overEaves);

    if (depth === 0 || (depth === 1 && flake.soft)) {
      ellipse(g, x, y, flake.size * .78, flake.size * .64, color, opacity, -.3);
      continue;
    }
    if (depth === 2 && flake.soft) glow(g, x, y, flake.size * 1.35, color, opacity * .29);
    const tilt = flake.sway + phase(t, flake.turns) + .32 * Math.sin(u * TAU);
    g.save();
    g.translate(x, y);
    g.rotate(tilt);
    g.scale(flake.size, flake.size * (.84 + .16 * Math.cos(phase(t, 2, flake.sway))));
    stroke(g, pineSnowCrystal, color, opacity, depth === 2 ? .148 : .159);
    g.restore();
  }
}

function dahan(g, t) {
  const frozen = iceGrowth(t, .75);
  const shine = iceGlint(t, .25);
  glow(g, 458, 102, 206, [99, 158, 217], .23 + .13 * frozen);
  glow(g, 424, 153, 156, [156, 220, 246], .055 + .15 * shine);
  dahanSnowfall(g, t, 0);
  deepSnowTree(g, 309, 211, 66, 16, .40, .86);
  deepSnowTree(g, 549, 214, 87, 23, .48, .9);
  deepSnowTree(g, 569, 220, 62, 16, .32, .88);
  dahanSnowfall(g, t, 1);

  g.save();
  g.translate(424, 182);
  const ground = g.createLinearGradient(0, 27, 0, 67);
  ground.addColorStop(0, '#647b98aa');
  ground.addColorStop(.48, '#9ab3c8a6');
  ground.addColorStop(1, '#647e9f0e');
  g.fillStyle = ground;
  g.fill(frozenHouseDrift);
  ellipse(g, 6, 42, 90, 10, [45, 58, 77], .32, -.10);

  paintFrozenHouse(g);
  g.fillStyle = '#635763';
  g.fill(frozenHouseChimney);
  g.fillStyle = '#394453';
  g.fill(frozenHouseChimneyShade);
  line(g, 4, -126, 22, -131, [208, 234, 247], .92, 3.9);
  line(g, 22, -131, 30, -125, [175, 204, 228], .86, 3.2);
  g.fillStyle = '#a4afbd';
  g.fill(frozenHouseStep);
  line(g, 44, 47, 84, 41, [204, 222, 233], .84, 1.5);

  for (const [i, ice] of eavesIcicles.entries()) {
    const growth = iceGrowth(t, ice.start);
    const glint = iceGlint(t, i * .18);
    const y = frozenEaveY(ice.x) + 4;
    const length = lerp(5 + ice.length * .06, ice.length, growth);
    paintIcicle(g, ice.x, y, ice.width * lerp(.59, 1, growth), length,
      ice.tilt, .68 + .3 * growth, glint);
    if (i % 2 === 0) {
      paintIcicle(g, ice.x + 7.5, y - .9, ice.width * .48, length * .51,
        ice.tilt + .14, .61 + .14 * growth, glint);
    }
  }
  paintFrozenRoof(g);
  g.restore();

  const gust = .66 * (1 - smooth(0, 1.4, t)) + .72 * smooth(10.94, 13, t);
  mist(g, t, [180, 213, 244], .29 + gust, 176);
  dahanSnowfall(g, t, 2);
}

function dahanBadge(g, t) {
  const growth = iceGrowth(t, .75);
  const shine = iceGlint(t, .25);
  g.translate(0, -4);
  g.scale(1.02, 1.02);
  g.fillStyle = '#586780';
  g.fill(frozenBadgeGable);
  g.fillStyle = '#9294a0';
  g.fill(frozenBadgeFront);
  g.fillStyle = '#edc38f';
  g.fillRect(-3, 1, 9, 9);
  g.fillStyle = '#534759';
  g.fillRect(13, 1, 5, 14);
  paintIcicle(g, -6, -5, 5.8, 7 + 10 * growth, .05, 1, shine);
  paintIcicle(g, 9, -7, 7.1, 8 + 19 * growth, -.04, 1, shine);
  paintIcicle(g, 22, -9, 6.2, 7 + 18 * growth, .08, 1, shine);
  g.fillStyle = '#d3eaf6';
  g.fill(frozenBadgeSnow);
  stroke(g, frozenBadgeRim, [148, 182, 207], .96, 2.2);
  line(g, -22, 14, -7, 19, [171, 201, 220], .85, 1.6);
}

const scenes={qingming,guyu,lixia,xiaoman,mangzhong,xiazhi,xiaoshu,dashu,liqiu,chushu,bailu,qiufen,hanlu,shuangjiang,lidong,xiaoxue,daxue,dongzhi,xiaohan,dahan};

const dateKernel = new Path2D(
  'M0 15C-9 15 -13 6 -12 -3Q-10 -14 0 -21Q10 -14 12 -3C13 6 9 15 0 15Z',
);
const dateKernelCrease = new Path2D('M1 10Q-5 -2 0 -15');

function xiaomanBadge(g, t) {
  // The two kernels meet at the base and leave a gap for the dew above.
  for (const [x, y, angle, scale] of [[-11, 1, -.66, .91], [10, -3, .51, 1.05]]) {
    g.save();
    g.translate(x, y);
    g.rotate(angle);
    g.scale(scale, scale);
    const color = g.createLinearGradient(-11, -15, 10, 10);
    color.addColorStop(0, '#e6f3b0');
    color.addColorStop(.42, '#b2d795');
    color.addColorStop(1, '#56a48d');
    g.fillStyle = color;
    g.fill(dateKernel);
    stroke(g, dateKernel, [217, 237, 172], .7, 1.5);
    stroke(g, dateKernelCrease, [34, 103, 82], .66, 2.1);
    g.restore();
  }
  droplet(g, -2, -20, 4.4, .82 + .14 * Math.sin(phase(t)));
}

function badge(g,t,cx,cy) {
  g.save();g.translate(cx-21,cy-20);g.scale(.4,.4);
  const festival = festivalScenes[theme.id];
  if (festival) {
    festival.badge(g, t);
  } else if(theme.id==='qingming') {
    paperUmbrella(g,0,0,23,t);
  }else if(theme.id==='guyu'){sprout(g,0,15,.56,t,0,1);droplet(g,-13,-14,3.5);}
  else if(theme.id==='lixia'){lotus(g,0,0,22,.62,-.1,t,.95);dragonfly(g,11,-14,.48,t);}
  else if(theme.id==='xiaoman'){xiaomanBadge(g,t);}
  else if(theme.id==='xiazhi'){xiazhiBadge(g,t);}
  else if(theme.id==='xiaoshu'){cicada(g, 0, -3, .53, .6, t, cicadaEnergy(t), false);}
  else if(theme.id==='dashu'){dashuBadge(g,t);}
  else if(theme.id==='liqiu'){liqiuBadge(g,t);}
  else if(theme.id==='chushu'){chushuBadge(g,t);}
  else if(theme.id==='bailu'){bailuBadge(g,t);}
  else if(theme.id==='qiufen'){qiufenBadge(g,t);}
  else if(theme.id==='hanlu'){hanluBadge(g,t);}
  else if(theme.id==='shuangjiang'){shuangjiangBadge(g,t);}
  else if(theme.id==='lidong'){lidongBadge(g,t);}
  else if(theme.id==='xiaoxue'){xiaoxueBadge(g,t);}
  else if(theme.id==='daxue'){daxueBadge(g,t);}
  else if(theme.id==='dongzhi'){dongzhiBadge(g,t);}
  else if(theme.id==='xiaohan'){xiaohanBadge(g,t);}
  else if(theme.id==='dahan'){dahanBadge(g,t);}
  else {strawHat(g,0,-4,.65,-.2);for(let i=0;i<3;i++){const u=(t/sowingPeriod+i*.2)%1;ellipse(g,10+u*24,-10+u*u*25,1,2,[243,196,111],Math.sin(u*Math.PI));}}
  g.restore();
}
function targetPill() {
  const first=(new Date(year,month-1,1).getDay()+6)%7,index=first+selected-1;
  return [40+(index%7)*72+36,296+Math.floor(index/7)*(320/gridRows)+160/gridRows];
}
function eventOn(y, m, d) {
  return collection.find(({ date }) => date[0] === y && date[1] === m && date[2] === d);
}
function updateLabel() {
  const selectedEvent=eventOn(year,month,selected);const d=new Date(year,month-1,selected);
  const wd=['SUN','MON','TUE','WED','THU','FRI','SAT'][d.getDay()];
  const mo=['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][month-1];
  $('edition-year').textContent=year;
  const day = String(selected).padStart(2, '0');
  const weekday = '日一二三四五六'[d.getDay()];
  $('eyebrow').textContent = collection === FESTIVALS
    ? `${year}.${String(month).padStart(2, '0')}.${day} · ${selectedEvent?.lunar ?? `周${weekday}`}`
    : `${wd} · ${day} ${mo} ${year}`;
  $('month-label').textContent = `${year} 年 ${month} 月`;
  $('title').textContent=selectedEvent?.title ?? `${month}月${selected}日`;
  $('caption').textContent = selectedEvent?.caption ?? '';
  $('scene-note').textContent = selectedEvent?.note ?? '';
  $('grid').setAttribute('aria-label',`${year}年${month}月`);
}
function buildGrid() {
  const first=(new Date(year,month-1,1).getDay()+6)%7,days=new Date(year,month,0).getDate();
  gridRows=Math.max(5,Math.ceil((first+days)/7));$('grid').classList.toggle('six',gridRows===6);
  $('grid').replaceChildren();
  for(let i=0;i<gridRows*7;i++) {
    const d=i-first+1,isOut=d<1||d>days;
    const adjacentDate=isOut?new Date(year,month-1,d):null;
    const day=adjacentDate?.getDate()??d;
    const b=document.createElement('button');b.className=`day${isOut?' out':''}${!isOut&&d===selected?' selected':''}`;b.textContent=day;
    const mark = isOut ? undefined : eventOn(year, month, d);
    const cellYear=adjacentDate?.getFullYear()??year;
    const cellMonth=adjacentDate?adjacentDate.getMonth()+1:month;
    b.setAttribute('aria-label',`${cellYear}年${cellMonth}月${day}日${mark?' '+mark.title:''}`);
    b.setAttribute('aria-pressed',String(!isOut&&d===selected));
    if(mark){const dot=document.createElement('i');dot.className='dot';dot.style.background=rgba(mark.tint);b.append(dot);}
    b.onclick = event => {
      selectDate(cellYear, cellMonth, day);
      if (event.detail === 0) $('grid').querySelector('.selected').focus({ preventScroll: true });
    };
    $('grid').append(b);
  }
}
function setTint(tint) {
  document.documentElement.style.setProperty('--tint', tint.join(' '));
  document.documentElement.style.setProperty('--accent', rgba(tint));
}

function selectDate(y, m, d) {
  const event = eventOn(y, m, d);
  if (event) {
    activate(event);
    return;
  }

  [year, month, selected] = [y, m, d];
  activeScene = false;
  fromPill = [...pill];
  labelChangedAt = performance.now();
  if (collection === FESTIVALS) setTint(ambientTint);
  updateChoiceSelection();
  buildGrid();
  updateLabel();
  render(time);
}

function buildChoices() {
  const festivals = collection === FESTIVALS;
  document.body.dataset.view = festivals ? 'festival' : 'solar';
  for (const link of document.querySelectorAll('.view-switch a')) {
    if (link.dataset.view === document.body.dataset.view) link.setAttribute('aria-current', 'true');
    else link.removeAttribute('aria-current');
  }
  $('edition-kind').textContent = festivals ? 'CHINESE FESTIVALS' : 'SOLAR TERMS';
  $('calendar-note').textContent = festivals ? '2027 年节日日期' : '节气日期 · 2027—2028';
  $('scene-count').textContent = collection.length;
  const weekdays = festivals ? ['周一','周二','周三','周四','周五','周六','周日'] : ['MON','TUE','WED','THU','FRI','SAT','SUN'];
  document.querySelectorAll('.weekdays span').forEach((day, i) => { day.textContent = weekdays[i]; });

  const choices = $('choices');
  choices.setAttribute('aria-label', festivals ? '选择节日' : '选择节气');
  choices.replaceChildren(...collection.map((item, index) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.dataset.term = item.id;
    const marker = document.createElement('span');
    marker.setAttribute('aria-hidden', 'true');
    marker.className = festivals ? 'festival-dot' : 'term-no';
    if (festivals) marker.style.background = rgba(item.tint);
    else marker.textContent = String(index + 1).padStart(2, '0');
    const name = document.createElement('span');
    name.textContent = item.title;
    const detail = document.createElement('small');
    detail.textContent = festivals ? `${item.date[1]} 月 ${item.date[2]} 日` : item.en;
    button.append(marker, name, detail);
    button.onclick = () => {
      if (manual && !reducedQuery.matches) resumePlayback();
      activate(item);
    };
    return button;
  }));
}

function updateChoiceSelection() {
  for (const button of $('choices').children) {
    button.setAttribute('aria-pressed', String(activeScene && button.dataset.term === theme.id));
  }
}

function activate(th) {
  fromTheme = theme;
  theme = th;
  const nextCollection = isFestival(th) ? FESTIVALS : SOLAR_TERMS;
  if (collection !== nextCollection || !$('choices').childElementCount) {
    collection = nextCollection;
    buildChoices();
  }
  changeAt = performance.now();
  labelChangedAt = changeAt;
  time = reducedQuery.matches || (isFestival(th) && !playing) ? th.still : 0;
  previous = 0;
  entered = 0;
  [year, month, selected] = th.date;
  activeScene = true;
  fromPill = [...pill];
  setTint(th.tint);
  $('card').dataset.scene = th.id;
  $('scene-number').textContent = String(collection.indexOf(th) + 1).padStart(2, '0');
  updateChoiceSelection();
  history.replaceState(null, '', `#${th.id}`);
  buildGrid();
  updateLabel();
  render(time);
  ensureFrame();
}
function drawLight(t,c,highlight) {
  light.fillStyle='#07080a';light.fillRect(0,0,540,540);light.save();light.scale(.5,.5);
  const p=phase(t);glow(light,380+60*Math.sin(p),300+40*Math.cos(p),560,c,.34+highlight);glow(light,760-50*Math.sin(p),820+30*Math.cos(p*2),520,mix(c,[60,70,160],.6),.26);glow(light,540,216,300,c,.2+highlight);light.restore();
}
function sceneHighlight(t) {
  const festival = festivalScenes[theme.id];
  if (festival) return festival.light?.(t) ?? 0;
  switch (theme.id) {
    case 'xiaoman':
      return .11 * wheatFill(t);
    case 'mangzhong': {
      const sowing = (t % sowingPeriod) / sowingPeriod;
      return .08 * smooth(.29, .43, sowing) * (1 - smooth(.43, .73, sowing));
    }
    case 'xiazhi': {
      const {altitude, opacity} = solsticeLight(t);
      return .13 * altitude * opacity;
    }
    case 'xiaoshu':
      return .10 * cicadaEnergy(t);
    case 'dashu':
      return .12 * fireflyPulse(t, 3, .46);
    case 'liqiu':
      return autumnLight(t);
    case 'chushu':
      return .078 * Math.abs(chushuWind(t));
    case 'bailu':
      return .105 * reedDewGrowth(t) * (1 - smooth(10.35, 12.7, t));
    case 'qiufen':
      return equinoxVisibility(t) * (.045 + .065 * Math.sin(Math.PI * equinoxProgress(t)));
    case 'hanlu':
      return .107 * chrysanthemumLight(t);
    case 'shuangjiang':
      return .115 * frostGrowth(t);
    case 'lidong':
      return winterHeat(t) * (.079 + .035 * Math.sin(phase(t, 7)) ** 2);
    case 'xiaoxue':
      return .106 * pineSnowCover(t) + .034 * pineSnowGust(t);
    case 'daxue':
      return .074 * deepSnowWind(t) + .05 * deepSnowDrift(t);
    case 'dongzhi':
      return .070 * winterDumplingWarmth(t) + .052 * winterDumplingLift(t);
    case 'xiaohan':
      return .087 * wintersweetOpening(t, .95) + .035 * wintersweetOpening(t, 3.35);
    case 'dahan':
      return .081 * iceGrowth(t, .75) + .065 * iceGlint(t, .25);
    default:
      return 0;
  }
}

function themeTintAt(term, t) {
  if (term.id === 'chushu') return mix(chimeWarm, term.tint, chushuCooling(t));
  if (term.id === 'qiufen') {
    const tint = mix(equinoxGold, equinoxBlue, equinoxProgress(t));
    return mix(term.tint, tint, equinoxVisibility(t));
  }
  if (term.id === 'shuangjiang') return mix([158, 161, 179], term.tint, frostGrowth(t));
  if (term.id === 'lidong') return mix(term.tint, [238, 176, 119], winterHeat(t) * .78);
  if (term.id === 'xiaohan') return mix([157, 179, 196], term.tint, .28 + .72 * wintersweetOpening(t, .95));
  return term.tint;
}

function render(t) {
  if(!Number.isFinite(t))return;time=((t%LOOP)+LOOP)%LOOP;
  const now=performance.now(),transition=reducedQuery.matches||manual||!playing?1:smooth(0,650,now-changeAt);
  const c = !activeScene && collection === FESTIVALS
    ? ambientTint
    : mix(themeTintAt(fromTheme,time),themeTintAt(theme,time),transition);
  const highlight = activeScene ? transition * sceneHighlight(time) : 0;
  drawLight(time,c,highlight);scene.clearRect(0,0,W,440);overlay.clearRect(0,0,W,648);
  if(activeScene){
    if (transition < 1 && fromTheme !== theme) {
      scene.save();
      scene.globalAlpha = 1 - transition;
      (festivalScenes[fromTheme.id]?.draw ?? scenes[fromTheme.id])(scene, time);
      scene.restore();
    }
    scene.save();
    scene.globalAlpha = fromTheme === theme ? 1 : transition;
    (festivalScenes[theme.id]?.draw ?? scenes[theme.id])(scene, time);
    scene.restore();
  }else{mist(scene,time,ambientTint,1,70);glow(scene,330,50,250,ambientTint,.14);}
  const en=reducedQuery.matches||manual||!playing?1:out(entered/.85),target=targetPill(),pe=reducedQuery.matches||manual||!playing?1:out((now-labelChangedAt)/500);
  pill=[lerp(fromPill[0],target[0],pe),lerp(fromPill[1],target[1],pe)];
  const pillColor=activeScene?c:ambientTint;
  $('pill').style.transform=`translate(${(pill[0]-24).toFixed(2)}px,${(pill[1]-24).toFixed(2)}px) scale(${.85+.15*en})`;
  $('pill').style.background=`linear-gradient(160deg,${rgba(mix(pillColor,[255,255,255],.25))},${rgba(mix(pillColor,[20,20,40],.35))})`;
  $('pill').style.boxShadow=`0 0 32px ${rgba(pillColor,.24+highlight)},0 8px 24px -6px ${rgba(pillColor,.45)}`;
  $('edge').style.boxShadow=`inset 0 0 0 1px ${rgba(c,.18+highlight)},inset 0 2px 0 ${rgba(mix(c,[255,255,255],.6),.16+highlight)}`;
  if(activeScene)badge(overlay,time,pill[0],pill[1]);
  // Very sparse foreground particles make the living scene meet the glass.
  if(activeScene&&(theme.id==='qingming'||theme.id==='guyu'))rain(overlay,time,[190,218,205],18,.16,648);
  if(activeScene&&theme.id==='mangzhong')motes(overlay,time,[250,208,133],8,.25,true);
  const labelOpacity=reducedQuery.matches||manual||!playing?1:out((now-labelChangedAt-45)/480);
  $('label').style.opacity=.35+.65*labelOpacity;$('label').style.filter=`blur(${((1-labelOpacity)*5).toFixed(2)}px)`;$('label').style.transform=`translateY(${((1-labelOpacity)*8).toFixed(2)}px)`;
  tilt=tilt.map((v,i)=>lerp(v,tiltTo[i],.08));
  $('card').style.transform=`translateY(${(1-en)*30}px) rotateX(${tilt[0]}deg) rotateY(${tilt[1]}deg) scale(${.96+.04*en})`;
  const displayTime = t === LOOP ? LOOP : time;
  $('time').value=displayTime.toFixed(1).padStart(4,'0');$('timeline').value=displayTime;
}
function tick(now) {
  raf=0;const dt=previous?Math.min((now-previous)/1000,.1):0;previous=now;
  if(playing){entered+=dt;time=(time+dt)%LOOP;}
  render(time);
  if(playing&&!document.hidden&&!manual)raf=requestAnimationFrame(tick);
}
function ensureFrame(){if(!raf&&playing&&!document.hidden&&!manual){previous=0;raf=requestAnimationFrame(tick);}}
function setPlaying(value){playing=value;if(!value&&raf){cancelAnimationFrame(raf);raf=0;}previous=0;$('play-label').textContent=value?'暂停':'播放';$('play').setAttribute('aria-label',value?'暂停动效':'播放动效');$('play').setAttribute('aria-pressed',String(!value));$('play-icon').setAttribute('d',value?'M7 5v10M13 5v10':'M7 4l8 6-8 6Z');ensureFrame();}
function resumePlayback() {
  manual = false;
  const url = new URL(location.href);
  if (url.searchParams.has('rec')) {
    url.searchParams.delete('rec');
    history.replaceState(null, '', url);
  }
  setPlaying(true);
}
function togglePlayback() {
  if (playing) setPlaying(false);
  else resumePlayback();
}
function resize(){const box=document.querySelector('.workspace').getBoundingClientRect();const s=Math.max(.1,Math.min((box.width-32)/652,(box.height-45)/720,1));$('stage').style.transform=`translate(-50%,-50%) scale(${s})`;if(!playing)render(time);}
for (const link of document.querySelectorAll('.masthead a')) {
  link.addEventListener('click', event => {
    if (link.hash !== location.hash || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    activate(themeById(link.hash.slice(1)));
  });
}
$('play').onclick = togglePlayback;
$('restart').onclick = () => {
  entered = 0;
  resumePlayback();
  render(0);
};
$('timeline').oninput=(e)=>{setPlaying(false);entered=1;render(Number(e.target.value));};
for (const [id, direction] of [['prev', -1], ['next', 1]]) {
  $(id).onclick = () => {
    const next = new Date(year, month - 1 + direction, 1);
    selectDate(next.getFullYear(), next.getMonth() + 1, 1);
    if (collection === FESTIVALS && !manual && !reducedQuery.matches) {
      for (const animation of $('grid').getAnimations()) animation.cancel();
      $('grid').animate([
        { opacity: 0, transform: `translateX(${direction * 28}px)` },
        { opacity: 1, transform: 'translateX(0)' },
      ], { duration: 360, easing: 'cubic-bezier(.2, .7, .2, 1)' });
    }
  };
}
document.querySelector('.workspace').addEventListener('pointermove',e=>{if(reducedQuery.matches||!hoverQuery.matches||!playing)return;const b=e.currentTarget.getBoundingClientRect();tiltTo=[-(e.clientY-b.top-b.height/2)/b.height*4.8,(e.clientX-b.left-b.width/2)/b.width*4.8];});
document.querySelector('.workspace').addEventListener('pointerleave',()=>{tiltTo=[0,0];});
new ResizeObserver(resize).observe(document.querySelector('.workspace'));
window.addEventListener('hashchange', () => {
  const next = themeById(location.hash.slice(1)) ?? FESTIVALS[0];
  if (next !== theme || !activeScene) activate(next);
});
document.addEventListener('visibilitychange',()=>{if(document.hidden){if(raf)cancelAnimationFrame(raf);raf=0;previous=0;}else ensureFrame();});
reducedQuery.addEventListener('change',e=>{if(e.matches){setPlaying(false);tilt=[0,0];tiltTo=[0,0];entered=1;render(theme.still);}});
window.addEventListener('keydown',e=>{if(e.metaKey||e.ctrlKey||e.altKey||e.repeat||/INPUT|BUTTON/.test(e.target.tagName))return;if(e.code==='Space'){e.preventDefault();togglePlayback();}if(e.key.toLowerCase()==='r')$('restart').click();});
window.__LOOP=LOOP;window.__render=(t)=>{setPlaying(false);manual=true;entered=1;tilt=[0,0];tiltTo=[0,0];render(t);};
window.__selectTerm=(id)=>{const th=themeById(id);if(th)activate(th);};
window.__previewState=()=>({theme:theme.id,year,month,selected,time,playing,activeScene,gridRows});
await Promise.race([document.fonts.ready,new Promise(resolve=>setTimeout(resolve,3000))]);
const initial=themeById(location.hash.slice(1))??FESTIVALS[0];
resize();activate(initial);if(reducedQuery.matches){setPlaying(false);render(initial.still);}else if(manual){setPlaying(false);render(initial.still);}
$('stage').classList.add('live');ensureFrame();
