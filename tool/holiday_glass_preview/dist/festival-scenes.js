import { TAU, W, LOOP, lerp, smooth, rnd, mix, rgba, phase, glow, stroke, line, ellipse } from './canvas.js';

const gold = [255, 199, 119];
const cream = [255, 233, 178];
const vermilion = [255, 93, 65];
const blue = [154, 205, 255];
const jade = [123, 212, 189];

function fill(g, path, color, opacity = 1) {
  g.fillStyle = rgba(color, opacity);
  g.fill(path);
}

function shade(g, path, x, y, endX, endY, stops) {
  const gradient = g.createLinearGradient(x, y, endX, endY);
  for (const [stop, color, opacity] of stops) {
    gradient.addColorStop(stop, rgba(color, opacity));
  }
  g.fillStyle = gradient;
  g.fill(path);
}

const starField = Array.from({ length: 58 }, (_, i) => ({
  x: rnd(i + 246) * W,
  y: rnd(i + 411) * 174,
  size: .45 + rnd(i + 603) * 1.25,
}));

function stars(g, t, color, opacity) {
  for (const [i, { x, y, size }] of starField.entries()) {
    const pulse = .5 + .5 * Math.sin(phase(t, 2, i * 5));
    ellipse(g, x, y, size, size, color, opacity * (.25 + .75 * pulse));
  }
}

function dust(g, t, color, count, span = 245) {
  for (const [i, { x, y, size }] of starField.slice(0, count).entries()) {
    const progress = (y / 174 + t / LOOP * (i % 2 + 1)) % 1;
    const sway = Math.sin(phase(t, 2, i)) * (5 + size * 4);
    const opacity = Math.sin(Math.PI * progress) * .53;
    const height = span * (1 - progress);
    ellipse(g, x + sway, height, size, size, color, opacity);
    if (i % 5 === 0) glow(g, x + sway, height, 9, color, opacity * .42);
  }
}

// 元旦 · 烟花先上升，再展开为有长尾的多层花火。
const skyline = Array.from({ length: 35 }, (_, i) => ({
  x: i * 17.2,
  w: 6 + rnd(i + 43) * 14,
  h: 12 + rnd(i + 71) ** 1.7 * 40,
  lights: rnd(i + 333),
}));
const bursts = [
  [1.05, 359, 79, 60, blue], [1.66, 497, 105, 52, gold],
  [2.18, 192, 63, 44, blue], [2.97, 440, 93, 101, gold],
  [3.22, 332, 50, 64, blue], [3.49, 538, 71, 46, vermilion],
  [6.02, 415, 90, 73, blue], [6.44, 242, 76, 51, gold],
  [8.45, 508, 75, 64, blue], [9.08, 377, 67, 81, gold],
  [10.72, 160, 93, 44, gold], [11.08, 479, 91, 74, cream],
].map(([at, x, y, radius, color], index) => ({
  at, x, y, radius, color,
  sparks: Array.from({ length: 44 }, (_, i) => {
    const seed = index * 97 + i;
    const angle = i / 44 * TAU + rnd(seed + 12) * .13;
    const speed = (.65 + .39 * rnd(seed + 31)) * (i % 5 === 0 ? .54 : 1);
    return [Math.cos(angle) * speed, Math.sin(angle) * speed];
  }),
}));

function newYearLight(t) {
  return .12 * Math.max(...bursts.map(({ at }) => t >= at ? Math.exp(-(t - at) * 3.9) : 0));
}

function newYear(g, t) {
  glow(g, 444, 112, 265, [71, 107, 212], .44);
  glow(g, 154, 65, 207, [64, 159, 173], .19);
  stars(g, t, blue, .64);
  glow(g, 454, 205, 170, blue, .15);
  for (const { x, w, h, lights } of skyline) {
    g.fillStyle = rgba([14, 23, 43], .91);
    g.fillRect(x, 225 - h, w, h + 46);
    if (lights > .34) {
      g.fillStyle = rgba(gold, .23 + .25 * lights);
      g.fillRect(x + w * .54, 233 - h, 1.6, 2.7);
      g.fillRect(x + w * .26, 240 - h, 1.5, 2.2);
    }
  }

  g.save();
  g.globalCompositeOperation = 'lighter';
  for (const { at, x, y, radius, color, sparks } of bursts) {
    const age = t - at;
    if (age < -.54 || age > 1.86) continue;
    if (age < 0) {
      const progress = smooth(-.54, 0, age);
      const head = lerp(235, y, progress);
      line(g, x - 5 * (1 - progress), head + 17, x, head, color, progress * .7, 1.6);
      glow(g, x, head, 9, cream, progress * .8);
      continue;
    }

    const opacity = 1 - smooth(.08, 1.84, age);
    const prev = Math.max(0, age - .14);
    const distance = radius * (1 - Math.exp(-2.5 * age));
    const tail = radius * (1 - Math.exp(-2.5 * prev));
    glow(g, x, y, radius * 1.9, color, .25 * Math.exp(-2.8 * age));
    for (const [i, [vx, vy]] of sparks.entries()) {
      const flicker = .72 + .28 * Math.cos(i * 3 + age * 30);
      const px = x + vx * distance;
      const py = y + vy * distance + age * age * 20;
      line(g, x + vx * tail, y + vy * tail + prev * prev * 20, px, py, color, opacity * flicker, 1.35);
      if (i % 4 === 0) ellipse(g, px, py, 1.45, 1.45, cream, opacity * flicker);
    }
  }
  g.restore();
}

const diamond = new Path2D('M0 -68L68 0 0 68 -68 0Z');
const diamondBorder = new Path2D('M0 -59L59 0 0 59 -59 0Z M0 -54L54 0 0 54 -54 0Z');
const roof = new Path2D('M-20 37Q23 43 66 14L119 5Q195 33 278 10L326 24Q420 42 450 3Q502 26 612 18L612 -17H-20Z');

// 除夕 · 檐下的福贴和窗格。
function fortunePaper(g, x, y, scale, t) {
  g.save();
  g.translate(x, y);
  g.rotate(Math.sin(phase(t)) * .056);
  g.scale(scale, scale);
  glow(g, 9, 0, 106, vermilion, .44);
  shade(g, diamond, -40, -62, 41, 66, [[0, [202, 53, 40]], [.52, [150, 33, 30]], [1, [86, 19, 27]]]);
  stroke(g, diamond, gold, .72, 1.15);
  stroke(g, diamondBorder, gold, .64, .88);
  for (const [px, py] of [[0, -47], [47, 0], [0, 47], [-47, 0]]) {
    ellipse(g, px, py, 2, 2, cream, .9);
  }
  g.font = '600 53px "Songti SC", "Noto Serif CJK SC", SimSun, serif';
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.fillStyle = rgba(cream, .97);
  g.fillText('福', 0, 4);
  g.restore();
}

function newYearsEve(g, t) {
  const warmth = .83 + .17 * Math.sin(phase(t, 2));
  glow(g, 435, 97, 239, [201, 61, 37], .51 * warmth);
  glow(g, 436, 160, 144, gold, .36 * warmth);
  const lattice = [83, 29, 28];
  for (let j = 0; j < 8; j++) {
    const x = 257 + j * 42;
    line(g, x, 14, x, 181, lattice, .64, 4);
    line(g, x, 52, x + 42, 91, gold, .13, 1);
    line(g, x, 91, x + 42, 52, gold, .13, 1);
  }
  for (const y of [49, 94, 183]) line(g, 257, y, 584, y, lattice, .74, 4);
  fill(g, roof, [28, 19, 29]);
  stroke(g, roof, gold, .23, 1.5);
  line(g, 428, 21, 428, 40, gold, .74);
  fortunePaper(g, 428, 102, .96, t);
  dust(g, t, gold, 22);
}

function water(g, t, y, color) {
  glow(g, 418, y + 28, 258, color, .19);
  for (let i = 0; i < 42; i++) {
    const x = rnd(i + 690) * W;
    const height = y + rnd(i + 90) ** 1.5 * 125;
    const breath = .5 + .5 * Math.sin(phase(t, 3, i));
    const length = 6 + rnd(i + 771) * 36;
    line(g, x - length / 2, height, x + length / 2, height, color, .1 + .22 * breath, .65 + .7 * breath);
  }
}

const lotusPetal = new Path2D('M0 5C-16 5 -24 -11 -17 -21Q-12 -17 -4 -15Q7 -7 0 5Z');

function lotusLight(g, x, y, scale, t) {
  g.save();
  g.translate(x, y);
  g.scale(scale, scale);
  const breath = .85 + .15 * Math.sin(phase(t, 8, x));
  glow(g, 0, -5, 64, gold, .65 * breath);
  for (const [angle, color] of [[-.56, [195, 59, 64]], [1.22, vermilion], [-.11, [253, 108, 85]], [.72, [255, 154, 100]]]) {
    g.save();
    g.rotate(angle);
    shade(g, lotusPetal, 0, 7, -18, -22, [[0, [109, 31, 56]], [.62, color], [1, cream]]);
    stroke(g, lotusPetal, gold, .6, .75);
    g.restore();
  }
  const flame = new Path2D('M0 -9Q-5 -12 -1 -17Q0 -20 1 -24Q8 -16 5 -11Q3 -8 0 -9Z');
  fill(g, flame, cream, breath);
  g.restore();
}

const riverLights = [[287, 153, .55], [477, 123, .57], [545, 168, .84], [384, 185, 1.52], [487, 206, 1.14], [124, 140, .33]];

// 元宵 · 莲花灯沿水面漂流，碎光随水纹摇动。
function lanternFestival(g, t) {
  glow(g, 440, 129, 247, [150, 65, 78], .54);
  stars(g, t, cream, .42);
  water(g, t, 126, [185, 100, 112]);
  for (const [i, [x0, y0, scale]] of riverLights.entries()) {
    const x = x0 + Math.sin(phase(t, 1, i)) * 19;
    const y = y0 + Math.sin(phase(t, 2, i)) * 4;
    for (let j = 0; j < 5; j++) {
      const dx = Math.sin(phase(t, 3, j + i)) * 9;
      const half = scale * (14 - j * 2);
      line(g, x + dx - half, y + j * 7 + 7, x + dx + half, y + j * 7 + 7, gold, .51 - j * .076, 1.4);
    }
    lotusLight(g, x, y, scale, t);
  }
}

const towerOutline = new Path2D('M515 204V25L527 10 540 25V204Z');
const boomOutline = new Path2D('M297 61L319 48H569L579 61Z');
const craneCables = new Path2D('M325 78L527 10 568 78');
const craneCab = new Path2D('M500 54H518V72H494V60Z');
const cabGlass = new Path2D('M501 57H513V65H496V62Z');
const liftHook = new Path2D('M0 -5V1C0 8 8 8 8 2');
const frameBack = new Path2D('M383 153L409 140H486L493 153V223H383Z');
const frameFront = new Path2D('M384 153H493V224H384Z');
const worksiteHorizon = new Path2D('M-7 216H47V182H73V203H107V181H130V209H192V185H213V205H257V167H279V190H317V213H537V169H557V193H589V245H-7Z');
const beamPlatform = new Path2D('M274 192H346L359 200H263Z');
const steelBeam = new Path2D('M-54 -5L-48 -10H59L54 -5V3H-54Z');
const frameBayWidths = [391, 415, 440, 465, 487];
const windowLights = [
  [399, 184, 0], [423, 203, 1], [447, 185, 2], [471, 205, 3],
  [423, 184, 4], [447, 204, 5], [471, 184, 6],
];

function drawCrane(g, trolley, t) {
  const steel = [255, 181, 87];
  shade(g, towerOutline, 513, 80, 541, 80, [[0, [122, 77, 43]], [.48, [66, 49, 40]], [1, [189, 115, 53]]]);
  stroke(g, towerOutline, steel, .77, 1.4);
  for (let y = 68; y < 194; y += 17) {
    line(g, 516, y, 539, y, steel, .59, .95);
    line(g, 516, y, 539, y + 17, steel, .66, 1.2);
  }
  stroke(g, craneCables, gold, .58, .9);
  g.save();
  g.translate(0, 30);
  shade(g, boomOutline, 0, 48, 0, 61, [[0, [157, 98, 49]], [.52, [100, 69, 44]], [1, [176, 120, 60]]]);
  stroke(g, boomOutline, gold, .83, 1.3);
  for (let x = 320; x < 561; x += 14) {
    line(g, x, 60, x + 7, 49, gold, .58, .9);
    line(g, x + 7, 49, x + 14, 60, gold, .58, .9);
  }
  fill(g, craneCab, [100, 67, 42]);
  stroke(g, craneCab, gold, .83, 1);
  fill(g, cabGlass, [175, 209, 206], .75);
  g.fillStyle = rgba([218, 142, 64]);
  g.fillRect(550, 61, 19, 12);
  g.fillStyle = rgba([72, 53, 43]);
  g.fillRect(552, 67, 15, 4);
  line(g, trolley - 5, 63, trolley + 5, 63, cream, 1, 3.5);
  g.restore();

  const beacon = .55 + .35 * Math.sin(phase(t, 6));
  glow(g, 527, 11, 15, vermilion, beacon * .62);
  ellipse(g, 527, 11, 2.4, 2.4, cream, beacon);
}

function drawBuildingFrame(g, t, reset) {
  shade(g, frameBack, 364, 149, 457, 217, [[0, [86, 104, 128], .82], [.45, [57, 69, 89], .81], [1, [38, 46, 65], .18]]);
  fill(g, frameFront, [35, 45, 62], .87);
  stroke(g, frameBack, [130, 157, 176], .4, 1.1);
  for (const x of frameBayWidths) line(g, x, 154, x, 226, [124, 150, 172], .66, 2.2);
  for (const y of [162, 183, 205, 227]) line(g, 384, y, 493, y, [154, 172, 185], .53, 1.8);
  for (const [x, y, index] of windowLights) {
    const visible = smooth(8.18 + index * .31, 8.7 + index * .31, t) * reset;
    if (visible <= 0) continue;
    glow(g, x + 5, y - 9, 19, gold, .35 * visible);
    g.fillStyle = rgba(gold, .84 * visible);
    g.fillRect(x, y - 14, 10, 9);
    line(g, x + 5, y - 14, x + 5, y - 5, [123, 69, 36], .45 * visible, .7);
  }
}

function drawSteelBeam(g, x, y, a) {
  g.save();
  g.translate(x, y);
  g.globalAlpha *= a;
  shade(g, steelBeam, -7, -10, -5, 4, [[0, [228, 234, 218]], [.38, [170, 191, 200]], [1, [77, 99, 122]]]);
  stroke(g, steelBeam, [209, 225, 229], .74, .8);
  line(g, -54, -5, 54, -5, cream, .74, .8);
  for (const end of [-52, 52]) line(g, end, -6, end, 3, gold, .85, 1.5);
  g.restore();
}

function workshopLight(t) {
  const joined = smooth(7.9, 8.22, t) * (1 - smooth(8.45, 9.15, t));
  const lights = smooth(8.25, 10.75, t) * (1 - smooth(11.75, 13, t));
  return joined * .12 + lights * .056;
}

// The steel beam rises, traverses the jib, and sits on the frame before the hook returns.
function labourDay(g, t) {
  const release = 8.1;
  const depart = smooth(2.85, 5.95, t);
  const turnBack = smooth(9.15, 12.05, t);
  const lifting = smooth(.68, 2.85, t);
  const lowering = smooth(6.15, release, t);
  const retract = smooth(release, 9.2, t);
  const trolley = lerp(310, 438, depart - turnBack);
  const beamY = 184 - 56 * lifting + 24 * lowering;
  const hookY = beamY - 30 - 27 * retract + 59 * smooth(11.8, 13, t);
  const reset = 1 - smooth(11.4, 12.75, t);
  const highlight = workshopLight(t);

  glow(g, 419, 134, 236, [82, 130, 183], .4);
  glow(g, 527, 163, 191, [252, 143, 63], .25 + highlight);
  shade(g, worksiteHorizon, 0, 165, 0, 245, [[0, [46, 67, 93], .83], [1, [30, 39, 56], .07]]);
  for (let i = 0; i < 4; i++) line(g, 244, 105 + i * 28, 584, 105 + i * 28, blue, .091, .72);
  for (let i = 0; i < 9; i++) line(g, 252 + i * 38, 77, 252 + i * 38, 216, blue, .062, .72);
  fill(g, beamPlatform, [84, 92, 104], .78);
  stroke(g, beamPlatform, [157, 171, 176], .52, 1);
  for (let i = 0; i < 6; i++) line(g, 273 + i * 13, 199, 280 + i * 13, 193, gold, .72, 1.3);

  drawBuildingFrame(g, t, reset);
  drawCrane(g, trolley, t);
  line(g, trolley, 94, trolley, hookY, [202, 218, 221], .8, 1);
  g.save();
  g.translate(trolley, hookY);
  stroke(g, liftHook, gold, .98, 1.5);
  g.restore();
  if (t < release) {
    const sway = Math.sin(phase(t, 2)) * Math.sin(Math.PI * depart) * 4;
    line(g, trolley + 3, hookY + 5, trolley - 35 + sway, beamY - 8, cream, .92, 1.2);
    line(g, trolley + 3, hookY + 5, trolley + 37 + sway, beamY - 8, cream, .92, 1.2);
    drawSteelBeam(g, trolley + sway, beamY, 1);
  } else {
    drawSteelBeam(g, 438, 152, reset);
    drawSteelBeam(g, 310, 184, smooth(11.9, 12.9, t));
    const reattached = smooth(12.68, 13, t) * .92;
    line(g, 313, hookY + 5, 275, 176, cream, reattached, 1.2);
    line(g, 313, hookY + 5, 347, 176, cream, reattached, 1.2);
    for (const x of [391, 487]) glow(g, x, 152, 31, gold, highlight * 3.8);
  }
}

const hull = new Path2D('M-110 -2Q-89 13 -47 11H65Q91 5 99 -15L111 -7Q99 31 65 33H-69Q-101 27 -110 -2Z');
const dragon = new Path2D('M72 22Q81 9 84 -16Q81 -32 94 -39L99 -49 104 -40Q111 -43 121 -36L133 -36 137 -31 130 -22 116 -23 110 -18 132 -16 127 -10 109 -10Q101 6 99 16Z');

function dragonBoat(g, x, y, scale, t) {
  g.save();
  g.translate(x, y);
  g.scale(scale, scale);
  for (let i = 0; i < 5; i++) {
    const px = -54 + i * 24;
    const strokePhase = phase(t, 8, i * .12);
    const hand = px + Math.sin(strokePhase) * 5;
    const ex = px - 13 + 21 * Math.cos(strokePhase);
    const ey = 30 + Math.sin(strokePhase) * 12;
    line(g, px - 2, -12, px + 3, 12, [181, 64, 47], .96, 10);
    ellipse(g, px + 1, -20, 4.3, 5.8, [233, 179, 129]);
    line(g, px - 5, -24, px + 6, -24, gold, .86, 2);
    line(g, px, -8, hand + 5, 3, cream, .87, 2.7);
    line(g, hand + 9, -7, ex, ey, gold, .89, 2.5);
    ellipse(g, ex, ey, 3.4, 6.5, [223, 154, 80], .96, -.35);
    const splash = smooth(.38, .92, Math.sin(strokePhase));
    for (let j = 0; j < 3; j++) ellipse(g, ex - j * 5, ey - j * 3, 1.4, 1, jade, splash * .84);
  }
  shade(g, hull, 0, -12, 0, 34, [[0, gold], [.34, [134, 164, 101]], [.58, [34, 120, 106]], [1, [31, 57, 67]]]);
  stroke(g, hull, gold, .82, 1.5);
  for (let x = -66; x < 87; x += 10) line(g, x, 18, x + 6, 25, gold, .61, .85);
  shade(g, dragon, 100, -47, 115, 16, [[0, gold], [.18, [181, 191, 102]], [.56, [52, 145, 118]], [1, [20, 77, 79]]]);
  stroke(g, dragon, gold, .93, 1.2);
  ellipse(g, 109, -33, 3.2, 3.2, cream);
  ellipse(g, 110, -33, 1.4, 1.4, [42, 33, 39]);
  line(g, 125, -20, 141, -24, gold, .78, 1);
  g.restore();
}

const riverHills = new Path2D('M-20 132Q54 67 128 121Q216 33 296 119Q361 62 426 114Q510 30 599 109V166H-20Z');

// 端午 · 桨头排成一列同步入水，船后拖出浅色水纹。
function dragonBoatFestival(g, t) {
  glow(g, 409, 89, 243, [50, 157, 145], .45);
  shade(g, riverHills, 0, 62, 0, 166, [[0, [55, 97, 100], .83], [1, [23, 37, 45], .35]]);
  water(g, t, 144, jade);
  const x = 380 + 36 * Math.sin(phase(t));
  const y = 146 + 3 * Math.sin(phase(t, 4));
  for (let i = 0; i < 11; i++) {
    const u = (i / 11 + t / LOOP * 4) % 1;
    line(g, x - 79 - u * 133, y + 24 + u * 20, x - 54 - u * 67, y + 27 + u * 18, jade, (1 - u) * .64, 1.2);
  }
  dragonBoat(g, x, y, 1.01, t);
}

const moonPatches = [
  [-16, 6, 16, 23, -.22], [10, -19, 16, 9, -.62], [24, 11, 15, 17, .82],
  [-4, 23, 24, 8, -.15], [-31, -12, 10, 13, .91], [29, -21, 9, 13, -.15],
];
const cloud = new Path2D('M-132 11C-90 -2 -63 -7 -24 -7Q-2 -24 36 -18Q65 -22 84 -7Q106 -4 137 3Q69 8 22 11Q-39 17 -132 11Z');
const moonHills = new Path2D('M-20 193Q80 135 147 166Q210 116 285 157Q316 128 386 161Q481 120 605 149V207H-20Z');

function moon(g, x, y, radius) {
  g.save();
  glow(g, x, y, radius * 3.2, gold, .37);
  const face = new Path2D();
  face.arc(x, y, radius, 0, TAU);
  shade(g, face, x - radius * .5, y - radius, x + radius * .5, y + radius, [[0, [255, 249, 217]], [.53, cream], [1, [230, 185, 114]]]);
  g.clip(face);
  for (const [dx, dy, rx, ry, angle] of moonPatches) {
    const scale = radius / 52;
    ellipse(g, x + dx * scale, y + dy * scale, rx * scale, ry * scale, [177, 134, 83], .15, angle);
  }
  g.restore();
}

// 中秋 · 云层移开露出整轮月，水面亮纹逐段延伸。
function midAutumn(g, t) {
  const open = .5 - .5 * Math.cos(phase(t));
  const y = 91 - open * 12;
  glow(g, 436, 109, 258, [83, 93, 171], .42);
  stars(g, t, blue, .57);
  moon(g, 426, y, 51);
  shade(g, moonHills, 0, 121, 0, 207, [[0, [32, 49, 80], .96], [1, [18, 26, 42], .15]]);
  for (const [x, cy, size, opacity] of [[381 - open * 161, 87, 1.2, .83], [486 + open * 83, 117, .91, .73], [223 - open * 46, 54, .72, .47]]) {
    g.save();
    g.translate(x, cy);
    g.scale(size, size);
    shade(g, cloud, 0, -17, 0, 15, [[0, [71, 77, 111], opacity], [1, [25, 32, 58], opacity]]);
    stroke(g, cloud, cream, opacity * .25, .7);
    g.restore();
  }
  water(g, t, 169, [118, 140, 192]);
  for (let i = 0; i < 17; i++) {
    const w = 6 + rnd(i + 973) * 32;
    const dx = Math.sin(phase(t, 2, i)) * (9 + i);
    line(g, 426 + dx - w, 176 + i * 5, 426 + dx + w, 176 + i * 5, gold, open * .52 * (1 - i / 19), 1.2);
  }
}

const gateRoof = new Path2D('M-80 0Q-54 -4 -41 -19Q0 -15 41 -19Q54 -4 80 0L70 5H-70Z');
const gateBody = new Path2D('M-59 3H59V45H-59Z');

function litGate(g, x, y, scale, t) {
  g.save();
  g.translate(x, y);
  g.scale(scale, scale);
  shade(g, gateBody, 0, 0, 0, 45, [[0, [106, 38, 40]], [1, [42, 19, 31]]]);
  for (let i = -2; i <= 2; i++) {
    const dx = i * 20;
    line(g, dx - 6, 7, dx - 6, 43, [183, 73, 47], .72, 2);
    g.fillStyle = rgba(gold, .7 + .2 * Math.sin(phase(t, 3, i)));
    g.fillRect(dx - 2.5, 14, 6, 18);
    glow(g, dx + 1, 20, 15, gold, .31);
  }
  fill(g, gateRoof, [108, 37, 40]);
  stroke(g, gateRoof, gold, .88, 1.3);
  const roofRidge = new Path2D('M-77 0Q-33 -5 0 -4Q33 -5 77 0');
  stroke(g, roofRidge, cream, .81, 1);
  line(g, -73, 44, 73, 44, gold, .77, 1.25);
  g.restore();
}

// 国庆 · 红绸从城楼后掠过，重叠的丝缎边缘接住金光。
function nationalDay(g, t) {
  glow(g, 394, 81, 276, [220, 47, 43], .55);
  glow(g, 463, 163, 141, gold, .35);
  for (let layer = 0; layer < 3; layer++) {
    const height = 19 + layer * 12;
    const ribbon = new Path2D();
    const yAt = x => 35 + layer * 37 + (x - 280) * -.127
      + Math.sin(x * .011 + phase(t, 1, layer * 1.48)) * (23 + layer * 3);
    for (let x = -16; x <= 608; x += 8) {
      if (x === -16) ribbon.moveTo(x, yAt(x));
      else ribbon.lineTo(x, yAt(x));
    }
    for (let x = 608; x >= -16; x -= 8) ribbon.lineTo(x, yAt(x) + height);
    ribbon.closePath();
    shade(g, ribbon, 0, 125, 584, 19, [[0, [89, 21, 40], .36], [.35, [175, 40, 53], .56], [.63, vermilion, .71], [1, [152, 31, 45], .58]]);
    stroke(g, ribbon, gold, .18 + layer * .074, .9);
  }
  dust(g, t, gold, 35);
  litGate(g, 420, 140, 1.28, t);
  litGate(g, 420, 104, .91, t);
}

const calendarPage = new Path2D('M-19 -11Q-19 -16 -14 -16H15Q20 -16 20 -11V9L11 19H-14Q-19 19 -19 14Z');
const calendarHeader = new Path2D('M-19 -11Q-19 -16 -14 -16H15Q20 -16 20 -11V-6H-19Z');
const calendarFold = new Path2D('M11 19V12Q11 9 14 9H20Z');
const calendarOne = new Path2D('M-5 1L0 -2V12M-5 12H5');

function newYearBadge(g, t) {
  glow(g, 0, 1, 31, blue, .5);
  shade(g, calendarPage, -12, -16, 12, 19, [[0, [244, 250, 255]], [1, [166, 203, 250]]]);
  shade(g, calendarHeader, 0, -17, 0, -6, [[0, [88, 152, 236]], [1, [49, 92, 166]]]);
  fill(g, calendarFold, [106, 157, 221]);
  stroke(g, calendarPage, [238, 248, 255], .9, 1.45);
  stroke(g, calendarOne, [32, 65, 127], .99, 3.5);
  for (const x of [-10, 11]) line(g, x, -21, x, -12, gold, .98, 3.8);
  const glint = .7 + .3 * Math.sin(phase(t, 2));
  line(g, 22, -17, 32, -17, cream, glint, 1.7);
  line(g, 27, -22, 27, -12, cream, glint, 1.7);
}

const helmetDome = new Path2D('M-21 6Q-20 -12 -10 -16Q0 -22 12 -15Q22 -10 23 6Z');
const helmetBrim = new Path2D('M-25 5Q-12 8 10 6L25 4Q30 5 30 8Q20 15 -5 15Q-20 14 -25 11Q-30 9 -25 5Z');
const helmetRidge = new Path2D('M-5 5Q-5 -13 2 -18Q7 -19 9 -16Q4 -9 4 5Z');

function labourBadge(g) {
  glow(g, 1, 1, 32, gold, .43);
  shade(g, helmetDome, -7, -19, 13, 9, [[0, cream], [.46, gold], [1, [208, 114, 37]]]);
  shade(g, helmetRidge, 1, -19, 1, 5, [[0, [255, 241, 181]], [1, [240, 157, 62]]]);
  shade(g, helmetBrim, -3, 5, -3, 15, [[0, [255, 221, 140]], [.46, gold], [1, [168, 76, 26]]]);
  stroke(g, helmetDome, cream, .82, 1.45);
  stroke(g, helmetBrim, cream, .77, 1.4);
}

function flagStar(g, x, y, radius, angle) {
  const star = new Path2D();
  for (let i = 0; i < 10; i++) {
    const theta = angle + i * TAU / 10;
    const r = i % 2 === 0 ? radius : radius * .382;
    const px = x + Math.cos(theta) * r;
    const py = y + Math.sin(theta) * r;
    if (i === 0) star.moveTo(px, py);
    else star.lineTo(px, py);
  }
  star.closePath();
  fill(g, star, [255, 222, 57]);
}

const flagCloth = new Path2D('M0 0H30V20H0Z');

function nationalBadge(g) {
  glow(g, 3, -5, 32, vermilion, .36);
  line(g, -20, -21, -20, 21, gold, 1, 3.7);
  ellipse(g, -20, -22, 2.4, 2.4, cream);
  g.save();
  g.translate(-18, -18);
  g.scale(1.46, 1.46);
  shade(g, flagCloth, 0, 0, 30, 20, [[0, [237, 62, 53]], [.66, [209, 40, 45]], [1, [170, 28, 34]]]);
  stroke(g, flagCloth, [245, 112, 96], .96, .62);
  // The stars use the 30 × 20 grid defined in the national flag construction sheet.
  // https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/bgt/art/2023/art_5e1206b52a484dfdba6ea8b76d75a7f0.html
  flagStar(g, 5, 5, 3, -Math.PI / 2);
  for (const [x, y] of [[10, 2], [12, 4], [12, 7], [10, 9]]) {
    flagStar(g, x, y, 1, Math.atan2(5 - y, 5 - x));
  }
  g.restore();
}

export const festivalScenes = {
  yuandan: { draw: newYear, light: newYearLight, badge: newYearBadge },
  chuxi: { draw: newYearsEve, badge: (g, t) => fortunePaper(g, 0, 0, .32, t) },
  yuanxiao: { draw: lanternFestival, badge: (g, t) => lotusLight(g, 0, 8, 1, t) },
  laodong: { draw: labourDay, light: workshopLight, badge: labourBadge },
  duanwu: { draw: dragonBoatFestival, badge: (g, t) => dragonBoat(g, -2, 2, .23, t) },
  zhongqiu: { draw: midAutumn, badge: (g) => moon(g, 0, 0, 17) },
  guoqing: { draw: nationalDay, badge: nationalBadge },
};
