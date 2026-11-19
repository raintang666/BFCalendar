import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show mergeSort;
import 'package:lunar/calendar/Lunar.dart';

import '../../calendar/date_utils_ext.dart';

enum HolidayScene {
  ambient,
  snow,
  fireworks,
  lanterns,
  lichun,
  yushui,
  jingzhe,
  chunfen,
  qingming,
  guyu,
  lixia,
  xiaoman,
  mangzhong,
  xiazhi,
  xiaoshu,
  dashu,
  liqiu,
  chushu,
  bailu,
  qiufen,
  hanlu,
  shuangjiang,
  lidong,
  xiaoxue,
  daxue,
  dongzhi,
  xiaohan,
  dahan,
  yuandan,
  chuxi,
  yuanxiao,
  laodong,
  duanwu,
  zhongqiu,
  guoqing,
}

abstract final class HolidayCalendarDesign {
  static const background = Color(0xFF090B10);
  static const surface = Color(0xFF141821);
  static const text = Color(0xFFF2F3F5);
  static const secondaryText = Color(0xFFA5ADBD);
  static const ambient = Color(0xFF46C8D7);
  static const christmas = Color(0xFF8CB9FF);
  static const newYear = Color(0xFFFFB048);
  static const lunarNewYear = Color(0xFFFF6A45);
  static const lichun = Color(0xFF99D3A3);
  static const yushui = Color(0xFF84C4D7);
  static const jingzhe = Color(0xFFB7C79A);
  static const chunfen = Color(0xFFADC2AE);
  static const qingming = Color(0xFF89AFBF);
  static const guyu = Color(0xFFAECA8D);
  static const lixia = Color(0xFF6FCFB4);
  static const xiaoman = Color(0xFF8DCAAD);
  static const mangzhong = Color(0xFFE6AB59);
  static const xiazhi = Color(0xFFF1DA97);
  static const xiaoshu = Color(0xFF91C66D);
  static const dashu = Color(0xFFDAE27B);
  static const liqiu = Color(0xFFDA9877);
  static const chushu = Color(0xFF91C0CF);
  static const bailu = Color(0xFFB1CFC8);
  static const qiufen = Color(0xFFBFACC4);
  static const hanlu = Color(0xFF9EBED3);
  static const shuangjiang = Color(0xFFB2D3E9);
  static const lidong = Color(0xFFA9C4DD);
  static const xiaoxue = Color(0xFFA1C4E2);
  static const daxue = Color(0xFFA3BEE5);
  static const dongzhi = Color(0xFFDAC3AD);
  static const xiaohan = Color(0xFFDFC08A);
  static const dahan = Color(0xFFA2CFE9);
  static const equinoxGold = Color(0xFFF2AE6F);
  static const equinoxBlue = Color(0xFF9AB4F2);
  static const sceneCycleSeconds = 12.0;
  static const glassSceneCycleSeconds = 13.0;
  static const sowingCycleSeconds = glassSceneCycleSeconds / 2;
  static const dateFireworkCycleSeconds = 3.0;
  static const dateFireworkVisibleSeconds = 2.2;
  static const dateFireworkStillSeconds = 0.95;
}

extension HolidaySceneStyle on HolidayScene {
  bool get usesFestivalArtwork => const {
    HolidayScene.yuandan,
    HolidayScene.chuxi,
    HolidayScene.yuanxiao,
    HolidayScene.laodong,
    HolidayScene.duanwu,
    HolidayScene.zhongqiu,
    HolidayScene.guoqing,
  }.contains(this);

  bool get usesGlassCard =>
      usesFestivalArtwork ||
      const {
        HolidayScene.qingming,
        HolidayScene.guyu,
        HolidayScene.lixia,
        HolidayScene.xiaoman,
        HolidayScene.mangzhong,
        HolidayScene.xiazhi,
        HolidayScene.xiaoshu,
        HolidayScene.dashu,
        HolidayScene.liqiu,
        HolidayScene.chushu,
        HolidayScene.bailu,
        HolidayScene.qiufen,
        HolidayScene.hanlu,
        HolidayScene.shuangjiang,
        HolidayScene.lidong,
        HolidayScene.xiaoxue,
        HolidayScene.daxue,
        HolidayScene.dongzhi,
        HolidayScene.xiaohan,
        HolidayScene.dahan,
      }.contains(this);

  Color get color => switch (this) {
    HolidayScene.ambient => HolidayCalendarDesign.ambient,
    HolidayScene.snow => HolidayCalendarDesign.christmas,
    HolidayScene.fireworks => HolidayCalendarDesign.newYear,
    HolidayScene.lanterns => HolidayCalendarDesign.lunarNewYear,
    HolidayScene.lichun => HolidayCalendarDesign.lichun,
    HolidayScene.yushui => HolidayCalendarDesign.yushui,
    HolidayScene.jingzhe => HolidayCalendarDesign.jingzhe,
    HolidayScene.chunfen => HolidayCalendarDesign.chunfen,
    HolidayScene.qingming => HolidayCalendarDesign.qingming,
    HolidayScene.guyu => HolidayCalendarDesign.guyu,
    HolidayScene.lixia => HolidayCalendarDesign.lixia,
    HolidayScene.xiaoman => HolidayCalendarDesign.xiaoman,
    HolidayScene.mangzhong => HolidayCalendarDesign.mangzhong,
    HolidayScene.xiazhi => HolidayCalendarDesign.xiazhi,
    HolidayScene.xiaoshu => HolidayCalendarDesign.xiaoshu,
    HolidayScene.dashu => HolidayCalendarDesign.dashu,
    HolidayScene.liqiu => HolidayCalendarDesign.liqiu,
    HolidayScene.chushu => HolidayCalendarDesign.chushu,
    HolidayScene.bailu => HolidayCalendarDesign.bailu,
    HolidayScene.qiufen => HolidayCalendarDesign.qiufen,
    HolidayScene.hanlu => HolidayCalendarDesign.hanlu,
    HolidayScene.shuangjiang => HolidayCalendarDesign.shuangjiang,
    HolidayScene.lidong => HolidayCalendarDesign.lidong,
    HolidayScene.xiaoxue => HolidayCalendarDesign.xiaoxue,
    HolidayScene.daxue => HolidayCalendarDesign.daxue,
    HolidayScene.dongzhi => HolidayCalendarDesign.dongzhi,
    HolidayScene.xiaohan => HolidayCalendarDesign.xiaohan,
    HolidayScene.dahan => HolidayCalendarDesign.dahan,
    HolidayScene.yuandan => const Color(0xFF9FC3FF),
    HolidayScene.chuxi => const Color(0xFFFF996F),
    HolidayScene.yuanxiao => const Color(0xFFFFCB80),
    HolidayScene.laodong => const Color(0xFFF6C26E),
    HolidayScene.duanwu => const Color(0xFF85DDC3),
    HolidayScene.zhongqiu => const Color(0xFFF4D99B),
    HolidayScene.guoqing => const Color(0xFFF98E7B),
  };

  String get label => switch (this) {
    HolidayScene.ambient => '微光',
    HolidayScene.snow => '飘雪',
    HolidayScene.fireworks => '烟花',
    HolidayScene.lanterns => '灯笼',
    HolidayScene.lichun => '春风与新芽',
    HolidayScene.yushui => '春雨与涟漪',
    HolidayScene.jingzhe => '春雷与初醒',
    HolidayScene.chunfen => '春风与归燕',
    HolidayScene.qingming => '烟雨与纸伞',
    HolidayScene.guyu => '雨润新苗',
    HolidayScene.lixia => '荷风与蜻蜓',
    HolidayScene.xiaoman => '青麦渐盈',
    HolidayScene.mangzhong => '撒种与新禾',
    HolidayScene.xiazhi => '日晷与午影',
    HolidayScene.xiaoshu => '树荫与蝉鸣',
    HolidayScene.dashu => '草岸与流萤',
    HolidayScene.liqiu => '梧桐与落叶',
    HolidayScene.chushu => '晚风与风铃',
    HolidayScene.bailu => '芦草与晨露',
    HolidayScene.qiufen => '日落与月升',
    HolidayScene.hanlu => '秋菊与凝露',
    HolidayScene.shuangjiang => '柿枝与薄霜',
    HolidayScene.lidong => '围炉煮茶',
    HolidayScene.xiaoxue => '松枝与初雪',
    HolidayScene.daxue => '山屋与风雪',
    HolidayScene.dongzhi => '青瓷与冬饺',
    HolidayScene.xiaohan => '雪枝与腊梅',
    HolidayScene.dahan => '雪屋与冰凌',
    HolidayScene.yuandan => '夜空烟花',
    HolidayScene.chuxi => '檐下福贴',
    HolidayScene.yuanxiao => '莲灯与倒影',
    HolidayScene.laodong => '劳动人民最光荣',
    HolidayScene.duanwu => '龙舟与水纹',
    HolidayScene.zhongqiu => '云间圆月',
    HolidayScene.guoqing => '红绸与城楼灯火',
  };

  double get stillSeconds => switch (this) {
    HolidayScene.fireworks => HolidayCalendarDesign.dateFireworkStillSeconds,
    HolidayScene.jingzhe => 11.5,
    HolidayScene.chunfen => 5.5,
    HolidayScene.qingming => 12,
    HolidayScene.guyu => 3.78,
    HolidayScene.lixia => 9.15,
    HolidayScene.xiaoman => 4.6,
    HolidayScene.mangzhong => 2.5,
    HolidayScene.xiazhi => 5.4,
    HolidayScene.xiaoshu => 5.4,
    HolidayScene.dashu => 6.75,
    HolidayScene.liqiu => 4.5,
    HolidayScene.chushu => 6.6,
    HolidayScene.bailu => 7.6,
    HolidayScene.qiufen => 6.5,
    HolidayScene.hanlu => 7.4,
    HolidayScene.shuangjiang => 8.2,
    HolidayScene.lidong => 7.1,
    HolidayScene.xiaoxue => 7.75,
    HolidayScene.daxue => 8.1,
    HolidayScene.dongzhi => 7.4,
    HolidayScene.xiaohan => 8.1,
    HolidayScene.dahan => 8.7,
    HolidayScene.yuandan => 3.6,
    HolidayScene.chuxi => 4.4,
    HolidayScene.yuanxiao => 5.3,
    HolidayScene.laodong => 5.4,
    HolidayScene.duanwu => 5.7,
    HolidayScene.zhongqiu => 6.4,
    HolidayScene.guoqing => 5.6,
    _ => 2.4,
  };
}

class HolidayEvent {
  const HolidayEvent({
    required this.date,
    required this.title,
    required this.shortTitle,
    required this.scene,
  });
  final DateTime date;
  final String title;
  final String shortTitle;
  final HolidayScene scene;
}

/// Example events use the existing lunar dependency for festivals and solar terms.
abstract final class HolidayCalendarData {
  static final _years = <int, List<HolidayEvent>>{};

  static List<HolidayEvent> eventsForYear(
    int year,
  ) => _years.putIfAbsent(year, () {
    final lunarYear = Lunar.fromYmd(year, 1, 1);
    final spring = lunarYear.getSolar();
    final lichun = lunarYear.getJieQiTable()['立春']!;
    final yushui = lunarYear.getJieQiTable()['雨水']!;
    final jingzhe = lunarYear.getJieQiTable()['惊蛰']!;
    final chunfen = lunarYear.getJieQiTable()['春分']!;
    final qingming = lunarYear.getJieQiTable()['清明']!;
    final guyu = lunarYear.getJieQiTable()['谷雨']!;
    final lixia = lunarYear.getJieQiTable()['立夏']!;
    final xiaoman = lunarYear.getJieQiTable()['小满']!;
    final mangzhong = lunarYear.getJieQiTable()['芒种']!;
    final xiazhi = lunarYear.getJieQiTable()['夏至']!;
    final xiaoshu = lunarYear.getJieQiTable()['小暑']!;
    final dashu = lunarYear.getJieQiTable()['大暑']!;
    final liqiu = lunarYear.getJieQiTable()['立秋']!;
    final chushu = lunarYear.getJieQiTable()['处暑']!;
    final bailu = lunarYear.getJieQiTable()['白露']!;
    final qiufen = lunarYear.getJieQiTable()['秋分']!;
    final hanlu = lunarYear.getJieQiTable()['寒露']!;
    final shuangjiang = lunarYear.getJieQiTable()['霜降']!;
    final lidong = lunarYear.getJieQiTable()['立冬']!;
    final xiaoxue = lunarYear.getJieQiTable()['小雪']!;
    final daxue = lunarYear.getJieQiTable()['大雪']!;
    // The Chinese key 冬至 starts the table with the previous year's solstice.
    final dongzhi = lunarYear.getJieQiTable()['DONG_ZHI']!;
    final xiaohan = lunarYear.getJieQiTable()['小寒']!;
    final dahan = lunarYear.getJieQiTable()['大寒']!;
    DateTime lunarDate(int month, int day) {
      final solar = Lunar.fromYmd(year, month, day).getSolar();
      return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    }

    final eve = spring.next(-1);
    final events = [
      HolidayEvent(
        date: DateTime(xiaohan.getYear(), xiaohan.getMonth(), xiaohan.getDay()),
        title: '小寒',
        shortTitle: '小寒',
        scene: HolidayScene.xiaohan,
      ),
      HolidayEvent(
        date: DateTime(dahan.getYear(), dahan.getMonth(), dahan.getDay()),
        title: '大寒',
        shortTitle: '大寒',
        scene: HolidayScene.dahan,
      ),
      HolidayEvent(
        date: DateTime(lichun.getYear(), lichun.getMonth(), lichun.getDay()),
        title: '立春',
        shortTitle: '立春',
        scene: HolidayScene.lichun,
      ),
      HolidayEvent(
        date: DateTime(spring.getYear(), spring.getMonth(), spring.getDay()),
        title: '春节',
        shortTitle: '春节',
        scene: HolidayScene.lanterns,
      ),
      HolidayEvent(
        date: DateTime(yushui.getYear(), yushui.getMonth(), yushui.getDay()),
        title: '雨水',
        shortTitle: '雨水',
        scene: HolidayScene.yushui,
      ),
      HolidayEvent(
        date: DateTime(jingzhe.getYear(), jingzhe.getMonth(), jingzhe.getDay()),
        title: '惊蛰',
        shortTitle: '惊蛰',
        scene: HolidayScene.jingzhe,
      ),
      HolidayEvent(
        date: DateTime(chunfen.getYear(), chunfen.getMonth(), chunfen.getDay()),
        title: '春分',
        shortTitle: '春分',
        scene: HolidayScene.chunfen,
      ),
      HolidayEvent(
        date: DateTime(
          qingming.getYear(),
          qingming.getMonth(),
          qingming.getDay(),
        ),
        title: '清明',
        shortTitle: '清明',
        scene: HolidayScene.qingming,
      ),
      HolidayEvent(
        date: DateTime(guyu.getYear(), guyu.getMonth(), guyu.getDay()),
        title: '谷雨',
        shortTitle: '谷雨',
        scene: HolidayScene.guyu,
      ),
      HolidayEvent(
        date: DateTime(lixia.getYear(), lixia.getMonth(), lixia.getDay()),
        title: '立夏',
        shortTitle: '立夏',
        scene: HolidayScene.lixia,
      ),
      HolidayEvent(
        date: DateTime(xiaoman.getYear(), xiaoman.getMonth(), xiaoman.getDay()),
        title: '小满',
        shortTitle: '小满',
        scene: HolidayScene.xiaoman,
      ),
      HolidayEvent(
        date: DateTime(
          mangzhong.getYear(),
          mangzhong.getMonth(),
          mangzhong.getDay(),
        ),
        title: '芒种',
        shortTitle: '芒种',
        scene: HolidayScene.mangzhong,
      ),
      HolidayEvent(
        date: DateTime(xiazhi.getYear(), xiazhi.getMonth(), xiazhi.getDay()),
        title: '夏至',
        shortTitle: '夏至',
        scene: HolidayScene.xiazhi,
      ),
      HolidayEvent(
        date: DateTime(xiaoshu.getYear(), xiaoshu.getMonth(), xiaoshu.getDay()),
        title: '小暑',
        shortTitle: '小暑',
        scene: HolidayScene.xiaoshu,
      ),
      HolidayEvent(
        date: DateTime(dashu.getYear(), dashu.getMonth(), dashu.getDay()),
        title: '大暑',
        shortTitle: '大暑',
        scene: HolidayScene.dashu,
      ),
      HolidayEvent(
        date: DateTime(liqiu.getYear(), liqiu.getMonth(), liqiu.getDay()),
        title: '立秋',
        shortTitle: '立秋',
        scene: HolidayScene.liqiu,
      ),
      HolidayEvent(
        date: DateTime(chushu.getYear(), chushu.getMonth(), chushu.getDay()),
        title: '处暑',
        shortTitle: '处暑',
        scene: HolidayScene.chushu,
      ),
      HolidayEvent(
        date: DateTime(bailu.getYear(), bailu.getMonth(), bailu.getDay()),
        title: '白露',
        shortTitle: '白露',
        scene: HolidayScene.bailu,
      ),
      HolidayEvent(
        date: DateTime(qiufen.getYear(), qiufen.getMonth(), qiufen.getDay()),
        title: '秋分',
        shortTitle: '秋分',
        scene: HolidayScene.qiufen,
      ),
      HolidayEvent(
        date: DateTime(hanlu.getYear(), hanlu.getMonth(), hanlu.getDay()),
        title: '寒露',
        shortTitle: '寒露',
        scene: HolidayScene.hanlu,
      ),
      HolidayEvent(
        date: DateTime(
          shuangjiang.getYear(),
          shuangjiang.getMonth(),
          shuangjiang.getDay(),
        ),
        title: '霜降',
        shortTitle: '霜降',
        scene: HolidayScene.shuangjiang,
      ),
      HolidayEvent(
        date: DateTime(lidong.getYear(), lidong.getMonth(), lidong.getDay()),
        title: '立冬',
        shortTitle: '立冬',
        scene: HolidayScene.lidong,
      ),
      HolidayEvent(
        date: DateTime(xiaoxue.getYear(), xiaoxue.getMonth(), xiaoxue.getDay()),
        title: '小雪',
        shortTitle: '小雪',
        scene: HolidayScene.xiaoxue,
      ),
      HolidayEvent(
        date: DateTime(daxue.getYear(), daxue.getMonth(), daxue.getDay()),
        title: '大雪',
        shortTitle: '大雪',
        scene: HolidayScene.daxue,
      ),
      HolidayEvent(
        date: DateTime(dongzhi.getYear(), dongzhi.getMonth(), dongzhi.getDay()),
        title: '冬至',
        shortTitle: '冬至',
        scene: HolidayScene.dongzhi,
      ),
      HolidayEvent(
        date: DateTime(year, 12, 25),
        title: '圣诞节',
        shortTitle: '圣诞',
        scene: HolidayScene.snow,
      ),
      HolidayEvent(
        date: DateTime(year, 12, 31),
        title: '跨年夜',
        shortTitle: '跨年',
        scene: HolidayScene.fireworks,
      ),
      HolidayEvent(
        date: DateTime(year, 1, 1),
        title: '元旦',
        shortTitle: '元旦',
        scene: HolidayScene.yuandan,
      ),
      HolidayEvent(
        date: DateTime(eve.getYear(), eve.getMonth(), eve.getDay()),
        title: '除夕',
        shortTitle: '除夕',
        scene: HolidayScene.chuxi,
      ),
      HolidayEvent(
        date: lunarDate(1, 15),
        title: '元宵节',
        shortTitle: '元宵',
        scene: HolidayScene.yuanxiao,
      ),
      HolidayEvent(
        date: DateTime(year, 5, 1),
        title: '劳动节',
        shortTitle: '劳动',
        scene: HolidayScene.laodong,
      ),
      HolidayEvent(
        date: lunarDate(5, 5),
        title: '端午节',
        shortTitle: '端午',
        scene: HolidayScene.duanwu,
      ),
      HolidayEvent(
        date: lunarDate(8, 15),
        title: '中秋节',
        shortTitle: '中秋',
        scene: HolidayScene.zhongqiu,
      ),
      HolidayEvent(
        date: DateTime(year, 10, 1),
        title: '国庆节',
        shortTitle: '国庆',
        scene: HolidayScene.guoqing,
      ),
    ];
    // Keep the existing event first on coincident dates. The shortcuts can select either.
    mergeSort(events, compare: (a, b) => a.date.compareTo(b.date));
    return events;
  });

  static HolidayEvent? eventOn(DateTime date, {HolidayScene? scene}) {
    for (final event in eventsForYear(date.year)) {
      if ((scene == null || event.scene == scene) &&
          CalendarDateUtils.isSameDay(event.date, date)) {
        return event;
      }
    }
    return null;
  }

  static List<HolidayEvent> nearbyEvents(DateTime month) {
    final start = DateTime(month.year, month.month);
    final thisYear = eventsForYear(month.year);
    return [...thisYear, ...eventsForYear(month.year + 1)]
        .where(
          (event) => !event.date.isBefore(start) && event.date.year <= 2099,
        )
        .take(thisYear.length)
        .toList();
  }
}

/// Animation affects only the selected scene. It never changes calendar dates.
class HolidaySceneFrame {
  const HolidaySceneFrame({required this.scene, required this.seconds});
  final HolidayScene scene;
  final double seconds;

  double get time => switch (scene) {
    HolidayScene.snow => 4.3 + seconds,
    HolidayScene.fireworks => 4.9 + seconds % 4.6,
    HolidayScene.lanterns => 10.6 + seconds % 5.4,
    _ => seconds,
  };
  double get snow => scene == HolidayScene.snow ? 1 : 0;
  double get fireworks => scene == HolidayScene.fireworks ? 1 : 0;
  double get lanterns => scene == HolidayScene.lanterns ? 1 : 0;
  double get ambient {
    if (scene == HolidayScene.ambient) return 1;
    if (scene.usesGlassCard ||
        const {
          HolidayScene.lichun,
          HolidayScene.yushui,
          HolidayScene.jingzhe,
          HolidayScene.chunfen,
        }.contains(scene)) {
      return .015;
    }
    return .1;
  }

  Color get tint => switch (scene) {
    HolidayScene.chushu => holidayChushuTint(seconds),
    HolidayScene.qiufen => holidayEquinoxTint(seconds),
    HolidayScene.shuangjiang => Color.lerp(
      const Color(0xFF9EA1B3),
      HolidayCalendarDesign.shuangjiang,
      holidayFrostGrowth(seconds),
    )!,
    HolidayScene.lidong => Color.lerp(
      HolidayCalendarDesign.lidong,
      const Color(0xFFEEB077),
      holidayWinterHeat(seconds) * .78,
    )!,
    HolidayScene.xiaohan => Color.lerp(
      const Color(0xFF9DB3C4),
      scene.color,
      .28 + .72 * holidayWintersweetOpening(seconds, .95),
    )!,
    _ => scene.color,
  };

  double get glassLight => switch (scene) {
    HolidayScene.yuandan => holidayNewYearLight(seconds),
    HolidayScene.laodong => holidayLabourLight(seconds),
    HolidayScene.xiaoman =>
      .11 *
          holidayWheatFill(
            seconds % HolidayCalendarDesign.glassSceneCycleSeconds,
          ),
    HolidayScene.xiazhi => holidaySolsticeLight(seconds).highlight,
    HolidayScene.xiaoshu => .10 * holidayCicadaEnergy(seconds),
    HolidayScene.dashu => .12 * holidayFireflyPulse(seconds, 3, .46),
    HolidayScene.liqiu => holidayAutumnLight(seconds),
    HolidayScene.chushu => .078 * holidayChushuWind(seconds).abs(),
    HolidayScene.bailu => .105 * holidayDewLight(seconds),
    HolidayScene.qiufen =>
      holidayEquinoxVisibility(seconds) *
          (.045 + .065 * math.sin(math.pi * holidayEquinoxProgress(seconds))),
    HolidayScene.hanlu => .107 * holidayChrysanthemumLight(seconds),
    HolidayScene.shuangjiang => .115 * holidayFrostGrowth(seconds),
    HolidayScene.lidong => holidayWinterGlassLight(seconds),
    HolidayScene.xiaoxue =>
      .106 * holidayPineSnowCover(seconds) +
          .034 * holidayPineSnowGust(seconds),
    HolidayScene.daxue =>
      .074 * holidayDeepSnowWind(seconds) + .05 * holidayDeepSnowDrift(seconds),
    HolidayScene.dongzhi =>
      .070 * holidayDumplingWarmth(seconds) +
          .052 * holidayDumplingLift(seconds),
    HolidayScene.xiaohan =>
      .087 * holidayWintersweetOpening(seconds, .95) +
          .035 * holidayWintersweetOpening(seconds, 3.35),
    HolidayScene.dahan =>
      .081 * holidayIcicleGrowth(seconds, .75) +
          .065 * holidayIcicleGlint(seconds, .25),
    _ => sowingLight,
  };

  double get sowingLight {
    if (scene != HolidayScene.mangzhong) return 0;
    final u =
        seconds %
        HolidayCalendarDesign.sowingCycleSeconds /
        HolidayCalendarDesign.sowingCycleSeconds;
    return .08 * holidaySmooth(.29, .43, u) * (1 - holidaySmooth(.43, .73, u));
  }

  /// Matches the webpage's 1.8-second accumulation after selecting Christmas.
  double get snowCapProgress {
    final progress = holidayClamp(seconds / 1.8);
    return progress * progress * (3 - 2 * progress);
  }

  double get flash {
    if (scene == HolidayScene.jingzhe) {
      return holidayThunderPulse(seconds) * 0.18;
    }
    if (scene != HolidayScene.fireworks) return 0;
    var result = 0.0;
    for (var k = 0; k < 8; k++) {
      final d = time - (4.9 + 0.36 + k * 0.36);
      if (d >= 0 && d < 1.7) result += math.exp(-d / 0.22);
    }
    return math.min(1, result);
  }
}

/// One slow, distant cloud glow every 10.5 seconds, shared with the webpage.
double holidayThunderPulse(double seconds) {
  final phase = seconds % 10.5;
  if (phase < 0.35 || phase > 1.65) return 0;
  final pulse = math.sin((phase - 0.35) / 1.3 * math.pi);
  return pulse * pulse;
}

double holidayClamp(double value) => value.clamp(0.0, 1.0);
double holidayLerp(double a, double b, double t) => a + (b - a) * t;
double holidaySmooth(double start, double end, double value) {
  final t = holidayClamp((value - start) / (end - start));
  return t * t * (3 - 2 * t);
}

double holidayWheatFill(double seconds, [int tier = 2]) {
  final start = .12 + tier * .65;
  return holidaySmooth(start, start + 1.45, seconds) *
      (1 -
          holidaySmooth(
            9.3 + tier * .12,
            HolidayCalendarDesign.glassSceneCycleSeconds,
            seconds,
          ));
}

({double progress, double opacity, double altitude, double highlight})
holidaySolsticeLight(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  const dawnStart = 11.8;
  const sunset = 10.8;
  final t = seconds % cycle;
  final dawn = t >= dawnStart;
  final progress = dawn ? 0.0 : holidayClamp(t / sunset);
  final opacity = dawn
      ? holidaySmooth(dawnStart, cycle, t)
      : 1 - holidaySmooth(sunset, dawnStart, t);
  final altitude = math.sin(math.pi * progress);
  return (
    progress: progress,
    opacity: opacity,
    altitude: altitude,
    highlight: .13 * altitude * opacity,
  );
}

const holidayCicadaCalls = [.32, 1.25, 4.2, 5.05, 8.4, 9.23, 10.06];

double holidayCicadaEnergy(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  var energy = 0.0;
  for (final onset in holidayCicadaCalls) {
    final age = t - onset;
    final envelope =
        holidaySmooth(0, .14, age) * (1 - holidaySmooth(.19, .7, age));
    energy = math.max(energy, envelope);
  }
  return energy;
}

double holidayFireflyPulse(double seconds, double beats, double offset) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final angle = seconds % cycle / cycle * (math.pi * 2) * beats + offset;
  final light = .5 + .5 * math.sin(angle);
  return .16 + .84 * math.pow(light, 2.3).toDouble();
}

const holidayAutumnDrops = [
  (
    from: Offset(333, 94),
    to: Offset(301, 228),
    start: .32,
    travel: 3.70,
    size: .31,
    angle: -.45,
    drift: -22.0,
    color: .55,
    water: false,
  ),
  (
    from: Offset(466, 100),
    to: Offset(491, 222),
    start: 1.42,
    travel: 4.15,
    size: .32,
    angle: .78,
    drift: 32.0,
    color: .65,
    water: true,
  ),
  (
    from: Offset(383, 78),
    to: Offset(356, 221),
    start: 2.70,
    travel: 3.50,
    size: .37,
    angle: -.81,
    drift: -27.0,
    color: .43,
    water: false,
  ),
  (
    from: Offset(500, 106),
    to: Offset(542, 222),
    start: 4.14,
    travel: 3.75,
    size: .26,
    angle: .54,
    drift: 23.0,
    color: .68,
    water: true,
  ),
  (
    from: Offset(419, 89),
    to: Offset(464, 229),
    start: 5.44,
    travel: 3.50,
    size: .33,
    angle: -.38,
    drift: -24.0,
    color: .52,
    water: true,
  ),
  (
    from: Offset(355, 105),
    to: Offset(312, 236),
    start: 6.64,
    travel: 3.50,
    size: .29,
    angle: .42,
    drift: -33.0,
    color: .71,
    water: false,
  ),
  (
    from: Offset(445, 120),
    to: Offset(403, 228),
    start: 8.12,
    travel: 3.30,
    size: .30,
    angle: .57,
    drift: -30.0,
    color: .61,
    water: false,
  ),
];

double holidayAutumnLight(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  var falling = 0.0;
  for (final leaf in holidayAutumnDrops) {
    final progress = (t - leaf.start) / leaf.travel;
    if (progress > 0 && progress < 1) {
      falling = math.max(falling, math.sin(math.pi * progress));
    }
  }
  return .06 * falling + .025 * (.5 + .5 * math.sin(math.pi * 2 * t / cycle));
}

double holidayQuintOut(double value) =>
    1 - math.pow(1 - holidayClamp(value), 5).toDouble();

double holidayRandom(int seed) {
  final x = math.sin(seed * 127.1 + 311.7) * 43758.5453;
  return x - x.floor();
}

double holidayChushuCooling(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(.45, 8.05, t) * (1 - holidaySmooth(10.6, cycle, t));
}

Color holidayChushuTint(double seconds) => Color.lerp(
  const Color(0xFFE5B07B),
  HolidayCalendarDesign.chushu,
  holidayChushuCooling(seconds),
)!;

double holidayChushuWind(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final angle = (math.pi * 2) * (seconds % cycle) / cycle;
  return .78 * math.sin(angle * 2 + .32) + .22 * math.sin(angle * 3 + 1.7);
}

double holidayDewGrowth(double seconds) => holidaySmooth(.26, 3.25, seconds);

double holidayDewLight(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  return holidayDewGrowth(t) * (1 - holidaySmooth(10.35, 12.7, t));
}

double holidayEquinoxProgress(double seconds) => holidaySmooth(
  1.25,
  11.75,
  seconds % HolidayCalendarDesign.glassSceneCycleSeconds,
);

double holidayEquinoxVisibility(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(0, 1.05, t) * (1 - holidaySmooth(11.5, cycle, t));
}

Color holidayEquinoxTint(double seconds) => Color.lerp(
  HolidayCalendarDesign.qiufen,
  Color.lerp(
    HolidayCalendarDesign.equinoxGold,
    HolidayCalendarDesign.equinoxBlue,
    holidayEquinoxProgress(seconds),
  )!,
  holidayEquinoxVisibility(seconds),
)!;

double holidayChrysanthemumLight(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(.8, 6.7, t) * (1 - holidaySmooth(10.7, cycle, t));
}

double holidayFrostGrowth(double seconds, [double delay = 0]) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(1.85 + delay, 7.75 + delay * .8, t) *
      (1 - holidaySmooth(10.7, cycle, t));
}

double holidayWinterHeat(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(.85, 4.85, t) * (1 - holidaySmooth(9.85, cycle, t));
}

double holidayWinterGlassLight(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final flicker = math.sin(math.pi * 2 * (seconds % cycle) / cycle * 7);
  return holidayWinterHeat(seconds) * (.079 + .035 * flicker * flicker);
}

double holidayPineSnowGust(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  return holidaySmooth(7.9, 8.35, t) * (1 - holidaySmooth(8.48, 9.68, t));
}

double holidayPineSnowCover(double seconds, [double delay = 0]) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  final settled = holidaySmooth(1.3 + delay, 7.45 + delay * .65, t);
  return settled *
      (1 - .24 * holidaySmooth(8.08, 9.02, t)) *
      (1 - holidaySmooth(10.85, cycle, t));
}

double holidayDeepSnowWind(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  return holidaySmooth(.65, 3.75, t) * (1 - holidaySmooth(9.35, 12.85, t));
}

double holidayDeepSnowDrift(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(1.55, 8.65, t) * (1 - holidaySmooth(10.10, cycle, t));
}

double holidayDumplingLift(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  return holidaySmooth(3.32, 6.75, t) * (1 - holidaySmooth(8.60, 10.95, t));
}

double holidayDumplingWarmth(double seconds) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(1.08, 6.3, t) * (1 - holidaySmooth(10.3, cycle, t));
}

double holidayWintersweetOpening(double seconds, double start) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(start, start + 3.5, t) *
      (1 - holidaySmooth(10.15, cycle, t));
}

double holidayIcicleGrowth(double seconds, double start) {
  const cycle = HolidayCalendarDesign.glassSceneCycleSeconds;
  final t = seconds % cycle;
  return holidaySmooth(start, start + 4.9, t) *
      (1 - holidaySmooth(10.47, cycle, t));
}

double holidayIcicleGlint(double seconds, double offset) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  return holidaySmooth(6.12 + offset, 7.95 + offset, t) *
      (1 - holidaySmooth(8.5 + offset, 9.5 + offset, t));
}

// The burst schedule also drives the glass lighting.
const holidayNewYearBursts = [
  (at: 1.05, x: 359.0, y: 79.0, radius: 60.0, color: Color(0xFF9ACDFF)),
  (at: 1.66, x: 497.0, y: 105.0, radius: 52.0, color: Color(0xFFFFC777)),
  (at: 2.18, x: 192.0, y: 63.0, radius: 44.0, color: Color(0xFF9ACDFF)),
  (at: 2.97, x: 440.0, y: 93.0, radius: 101.0, color: Color(0xFFFFC777)),
  (at: 3.22, x: 332.0, y: 50.0, radius: 64.0, color: Color(0xFF9ACDFF)),
  (at: 3.49, x: 538.0, y: 71.0, radius: 46.0, color: Color(0xFFFF5D41)),
  (at: 6.02, x: 415.0, y: 90.0, radius: 73.0, color: Color(0xFF9ACDFF)),
  (at: 6.44, x: 242.0, y: 76.0, radius: 51.0, color: Color(0xFFFFC777)),
  (at: 8.45, x: 508.0, y: 75.0, radius: 64.0, color: Color(0xFF9ACDFF)),
  (at: 9.08, x: 377.0, y: 67.0, radius: 81.0, color: Color(0xFFFFC777)),
  (at: 10.72, x: 160.0, y: 93.0, radius: 44.0, color: Color(0xFFFFC777)),
  (at: 11.08, x: 479.0, y: 91.0, radius: 74.0, color: Color(0xFFFFE9B2)),
];

double holidayNewYearLight(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  var flash = 0.0;
  for (final burst in holidayNewYearBursts) {
    final age = t - burst.at;
    if (age >= 0) flash = math.max(flash, math.exp(-age * 3.9));
  }
  return .12 * flash;
}

double holidayLabourLight(double seconds) {
  final t = seconds % HolidayCalendarDesign.glassSceneCycleSeconds;
  final joined =
      holidaySmooth(7.9, 8.22, t) * (1 - holidaySmooth(8.45, 9.15, t));
  final lights =
      holidaySmooth(8.25, 10.75, t) * (1 - holidaySmooth(11.75, 13, t));
  return joined * .12 + lights * .056;
}
