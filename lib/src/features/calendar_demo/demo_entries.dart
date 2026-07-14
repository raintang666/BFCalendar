class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.desc,
    required this.iconAsset,
    required this.indexType,
  });

  final String title;
  final String desc;
  final String iconAsset;
  final int indexType;
}

const demoEntries = <DemoEntry>[
  DemoEntry(
    title: 'iOS日历',
    desc: 'iOS系统垂直日历',
    iconAsset: 'assets/icons/ic_ios.png',
    indexType: 0,
  ),
  DemoEntry(
    title: '简单风格',
    desc: '这是最简单的日历',
    iconAsset: 'assets/icons/ic_simple_logo.png',
    indexType: 1,
  ),
  DemoEntry(
    title: '暗黑列表',
    desc: '暗黑垂直列表视图',
    iconAsset: 'assets/icons/ic_tab_logo.png',
    indexType: 2,
  ),
  DemoEntry(
    title: '垂直多彩',
    desc: '炫酷的垂直效果',
    iconAsset: 'assets/icons/ic_colorful_logo.png',
    indexType: 19,
  ),
  DemoEntry(
    title: '仿真日历',
    desc: '垂直翻页仿真视图',
    iconAsset: 'assets/icons/ic_simulation.png',
    indexType: 3,
  ),
  DemoEntry(
    title: '精美定制中国风',
    desc: '周末变色、圆点事件+文本标记',
    iconAsset: 'assets/icons/ic_custom.png',
    indexType: 5,
  ),
  DemoEntry(
    title: '全屏风格',
    desc: '如果你需要的话，分分钟的事',
    iconAsset: 'assets/icons/ic_full.png',
    indexType: 6,
  ),
  DemoEntry(
    title: '范围选择',
    desc: '如果你需要范围选择的日历',
    iconAsset: 'assets/icons/ic_range.png',
    indexType: 7,
  ),
  DemoEntry(
    title: '多选风格',
    desc: '如果你需要多选风格的日历',
    iconAsset: 'assets/icons/ic_multi.png',
    indexType: 8,
  ),
  DemoEntry(
    title: '多彩风格',
    desc: '取决于你怎么绘制',
    iconAsset: 'assets/icons/ic_colorful_logo.png',
    indexType: 9,
  ),
  DemoEntry(
    title: 'ViewPager风格',
    desc: '如果内容是ViewPager的话',
    iconAsset: 'assets/icons/ic_tab_logo.png',
    indexType: 10,
  ),
  DemoEntry(
    title: '单选风格',
    desc: '单选风格是比较受欢迎',
    iconAsset: 'assets/icons/ic_single.png',
    indexType: 11,
  ),
  DemoEntry(
    title: '进度条风格',
    desc: '如果你正在开发todo APP的话',
    iconAsset: 'assets/icons/ic_progress.png',
    indexType: 12,
  ),
  DemoEntry(
    title: '下标订阅风格',
    desc: '只要你想画，就能画',
    iconAsset: 'assets/icons/ic_index_logo.png',
    indexType: 13,
  ),
  DemoEntry(
    title: '星系风格',
    desc: '很简单就能定制',
    iconAsset: 'assets/icons/ic_solar_system.png',
    indexType: 14,
  ),
];
