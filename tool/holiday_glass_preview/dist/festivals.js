// 2027 lunar dates follow the Hong Kong Observatory conversion table.
// https://www.hko.gov.hk/tc/gts/time/calendar/pdf/files/2027.pdf
export const FESTIVALS = [
  {
    id: 'yuandan', title: '元旦', date: [2027, 1, 1], tint: [159, 195, 255],
    caption: '烟花升起，新的一年开始。', still: 3.6,
  },
  {
    id: 'chuxi', title: '除夕', date: [2027, 2, 5], tint: [255, 153, 111],
    lunar: '腊月廿九', caption: '贴福守岁，灯下团圆。', still: 4.4,
  },
  {
    id: 'yuanxiao', title: '元宵节', date: [2027, 2, 20], tint: [255, 203, 128],
    lunar: '正月十五', caption: '灯随水去，映亮上元夜。', still: 5.3,
  },
  {
    id: 'laodong', title: '劳动节', date: [2027, 5, 1], tint: [246, 194, 110],
    caption: '劳动人民最光荣', still: 5.4,
  },
  {
    id: 'duanwu', title: '端午节', date: [2027, 6, 9], tint: [133, 221, 195],
    lunar: '五月初五', caption: '鼓点催桨，龙舟破浪。', still: 5.7,
  },
  {
    id: 'zhongqiu', title: '中秋节', date: [2027, 9, 15], tint: [244, 217, 155],
    lunar: '八月十五', caption: '云开见月，水映团圆。', still: 6.4,
  },
  {
    id: 'guoqing', title: '国庆节', date: [2027, 10, 1], tint: [249, 142, 123],
    caption: '金色灯火亮起，红绸随风舒展。', still: 5.6,
  },
];
