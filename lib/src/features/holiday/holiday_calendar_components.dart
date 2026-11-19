import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/calendar_canvas_labels.dart';
import 'holiday_calendar_data.dart';
import 'holiday_calendar_chunfen.dart';
import 'holiday_calendar_jingzhe.dart';
import 'holiday_calendar_rain.dart';
import 'holiday_calendar_scenes.dart';
import 'holiday_glass_scene.dart';

class HolidaySelectionSlide {
  HolidaySelectionSlide({
    required this.days,
    required this.day,
    required this.from,
    required this.progress,
  }) : to = positionOf(days.indexOf(day));

  final List<DateTime> days;
  final DateTime day;
  final Offset from;
  final Offset to;
  final Animation<double> progress;

  Offset get position {
    // Match the web preview's quintic ease-out.
    final remaining = 1 - progress.value;
    final eased = 1 - remaining * remaining * remaining * remaining * remaining;
    return Offset.lerp(from, to, eased)!;
  }

  static Offset positionOf(int index) =>
      Offset((index % 7).toDouble(), (index ~/ 7).toDouble());
}

/// All date layout, touch handling, paging and selection remain in CalendarView.
class HolidayCalendarComponentBuilder extends CalendarComponentBuilder {
  const HolidayCalendarComponentBuilder({this.frames, this.selectionSlideFor});

  final ValueListenable<HolidaySceneFrame>? frames;
  final HolidaySelectionSlide? Function(DateTime month)? selectionSlideFor;

  @override
  EdgeInsetsGeometry get contentPadding => EdgeInsets.zero;

  @override
  List<String> orderedWeekLabels(int firstWeekday) => calendarOrderedWeekLabels(
    const ['日', '一', '二', '三', '四', '五', '六'],
    firstWeekday,
  );

  @override
  Widget buildMonthHeader(
    BuildContext context,
    DateTime month,
    double height,
  ) => const SizedBox.shrink();

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) =>
      CalendarCanvasLabel(
        data.label,
        style: const TextStyle(
          fontSize: 12,
          color: HolidayCalendarDesign.secondaryText,
        ),
      );

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    final scene = frames?.value.scene;
    final slide = selectionSlideFor?.call(data.focusedMonth);
    final index = slide?.days.indexOf(data.date) ?? -1;
    final paintsSlideBadge = slide != null && index == slide.days.length - 1;
    return CustomPaint(
      painter: _HolidayDayPainter(
        data: data,
        event: _eventOn(data.date, data.isSelected ? scene : null),
        frames: frames,
        slide: index >= 0 ? slide : null,
        gridPosition: HolidaySelectionSlide.positionOf(index),
        slideScene: index == 0 || paintsSlideBadge
            ? _eventOn(slide!.day, scene)?.scene
            : null,
        paintsSlideBadge: paintsSlideBadge,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }

  HolidayEvent? _eventOn(DateTime day, HolidayScene? scene) =>
      (scene == null ? null : HolidayCalendarData.eventOn(day, scene: scene)) ??
      HolidayCalendarData.eventOn(day);
}

class _HolidayDayPainter extends CustomPainter {
  _HolidayDayPainter({
    required this.data,
    required this.event,
    required this.textDirection,
    required this.textScaler,
    required this.slide,
    required this.gridPosition,
    required this.slideScene,
    required this.paintsSlideBadge,
    this.frames,
  }) : super(
         repaint: Listenable.merge([
           if (data.isSelected && event != null) frames,
           if (gridPosition == Offset.zero) slide?.progress,
         ]),
       );

  final CalendarDayCellData data;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final ValueListenable<HolidaySceneFrame>? frames;
  final HolidaySelectionSlide? slide;
  final Offset gridPosition;
  final HolidayScene? slideScene;
  final bool paintsSlideBadge;
  final HolidayEvent? event;
  final _day = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
  final _label = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
  Size? _lastSize;
  double? _lastHighlight;

  void _layout(Size size, double highlight) {
    if (_lastSize == size && _lastHighlight == highlight) return;
    _lastSize = size;
    _lastHighlight = highlight;
    final selectedColor = switch (event?.scene) {
      final scene? when scene.usesFestivalArtwork => const Color(0xFF131A26),
      HolidayScene.xiaoman ||
      HolidayScene.xiazhi ||
      HolidayScene.xiaoshu ||
      HolidayScene.dashu ||
      HolidayScene.liqiu ||
      HolidayScene.chushu ||
      HolidayScene.bailu ||
      HolidayScene.qiufen ||
      HolidayScene.hanlu ||
      HolidayScene.shuangjiang ||
      HolidayScene.lidong ||
      HolidayScene.xiaoxue ||
      HolidayScene.daxue ||
      HolidayScene.dongzhi ||
      HolidayScene.xiaohan ||
      HolidayScene.dahan => const Color(0xFF10221E),
      _ => Colors.white,
    };
    const outsideMonthColor = Color(0xFF606978);
    final color = Color.lerp(
      data.isCurrentMonth ? HolidayCalendarDesign.text : outsideMonthColor,
      selectedColor,
      highlight,
    );
    _day.text = TextSpan(
      text: '${data.date.day}',
      style: TextStyle(
        fontFamily: 'HolidayHostGrotesk',
        fontSize: textScaler.scale(18),
        fontWeight: FontWeight.lerp(
          FontWeight.w400,
          FontWeight.w600,
          highlight,
        ),
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    _day.layout();
    if (_day.width > size.width - 8) {
      _day.text = TextSpan(
        text: '${data.date.day}',
        style: TextStyle(
          fontFamily: 'HolidayHostGrotesk',
          fontSize: textScaler.scale(18) * (size.width - 8) / _day.width,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      );
      _day.layout();
    }
    _label.text = TextSpan(
      text: event?.shortTitle ?? data.lunarText,
      style: TextStyle(
        fontSize: math.min(textScaler.scale(10), (size.width - 6) / 2),
        color: Color.lerp(
          data.isCurrentMonth
              ? event?.scene.color ?? HolidayCalendarDesign.secondaryText
              : outsideMonthColor,
          selectedColor.withValues(alpha: 0.85),
          highlight,
        ),
      ),
    );
    _label.layout();
  }

  void _paintHighlight(Canvas canvas, RRect selection, HolidayScene? scene) {
    final color = scene?.color ?? HolidayCalendarDesign.ambient;
    final frame = frames?.value;
    final selectedFrame = frame?.scene == scene ? frame : null;
    final glassLight = selectedFrame?.glassLight ?? 0;
    final selectionColor = selectedFrame?.tint ?? color;
    canvas.drawRRect(
      selection,
      Paint()
        ..color = selectionColor.withValues(alpha: 0.32 + glassLight)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final colors = switch (scene) {
      HolidayScene.lichun => const [Color(0xFF47714A), Color(0xFF294A35)],
      HolidayScene.yushui => const [Color(0xFF3D7182), Color(0xFF284D60)],
      HolidayScene.jingzhe => const [Color(0xFF626D43), Color(0xFF3C4C32)],
      HolidayScene.qingming => const [Color(0xFF47758B), Color(0xFF2D4959)],
      HolidayScene.guyu => const [Color(0xFF728951), Color(0xFF465F3E)],
      HolidayScene.lixia => const [Color(0xFF4D9076), Color(0xFF2D6255)],
      HolidayScene.xiaoman => const [Color(0xFFAAD7C2), Color(0xFF638A7E)],
      HolidayScene.mangzhong => const [Color(0xFF87623B), Color(0xFF54402B)],
      HolidayScene.xiazhi => const [Color(0xFFF5E3B1), Color(0xFFA49570)],
      HolidayScene.xiaoshu => const [Color(0xFFADD492), Color(0xFF658855)],
      HolidayScene.dashu => const [Color(0xFFE3E99C), Color(0xFF959A5E)],
      HolidayScene.liqiu => const [Color(0xFFE3B299), Color(0xFFAA7F6C)],
      final scene? when scene.usesFestivalArtwork => [
        Color.lerp(selectionColor, Colors.white, .25)!,
        Color.lerp(selectionColor, const Color(0xFF141428), .35)!,
      ],
      HolidayScene.chushu ||
      HolidayScene.bailu ||
      HolidayScene.qiufen ||
      HolidayScene.hanlu ||
      HolidayScene.shuangjiang ||
      HolidayScene.lidong ||
      HolidayScene.xiaoxue ||
      HolidayScene.daxue ||
      HolidayScene.dongzhi ||
      HolidayScene.xiaohan ||
      HolidayScene.dahan => [
        Color.lerp(selectionColor, Colors.white, .25)!,
        Color.lerp(selectionColor, const Color(0xFF141428), .35)!,
      ],
      HolidayScene.chunfen => const [Color(0xFF63786B), Color(0xFF3E5650)],
      _ => [
        Color.lerp(color, Colors.white, 0.12)!,
        Color.lerp(color, const Color(0xFF1A2133), 0.48)!,
      ],
    };
    canvas.drawRRect(
      selection,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(selection.outerRect),
    );
    canvas.drawRRect(
      selection.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final motion = slide;
    final slidePosition = motion != null && motion.progress.value < 1
        ? motion.position
        : null;
    final delta = slidePosition == null
        ? Offset.zero
        : slidePosition - gridPosition;
    final selected = data.isSelected && data.isCurrentMonth;
    final highlight = slidePosition == null
        ? (selected ? 1.0 : 0.0)
        : (1 - delta.dx.abs()).clamp(0.0, 1.0) *
              (1 - delta.dy.abs()).clamp(0.0, 1.0);
    _layout(size, highlight);
    final center = size.center(Offset.zero);
    final selection = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: math.min(48, size.width - 6),
        height: size.height - 10,
      ),
      const Radius.circular(16),
    );
    final direction = textDirection == TextDirection.rtl ? -1 : 1;
    final translation = Offset(
      direction * delta.dx * size.width,
      delta.dy * size.height,
    );
    if (slidePosition != null && gridPosition == Offset.zero) {
      // The first cell paints before every date label on this month's canvas.
      // Its coordinate system follows the month as the pager scrolls.
      _paintHighlight(canvas, selection.shift(translation), slideScene);
    } else if (slidePosition == null && selected) {
      _paintHighlight(canvas, selection, event?.scene);
    }
    if (data.isToday && highlight < 1) {
      canvas.drawRRect(
        selection.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = HolidayCalendarDesign.ambient.withValues(
            alpha: 0.7 * (1 - highlight),
          ),
      );
    }
    final textHeight = _day.height + 2 + _label.height;
    final top = (size.height - textHeight) / 2;
    _day.paint(canvas, Offset((size.width - _day.width) / 2, top));
    _label.paint(
      canvas,
      Offset((size.width - _label.width) / 2, top + _day.height + 2),
    );
    if (event != null && highlight < 1) {
      canvas.drawCircle(
        Offset(center.dx, size.height - 5),
        1.5,
        Paint()..color = event!.scene.color.withValues(alpha: 1 - highlight),
      );
    }
    final selectedScene = event?.scene;
    final movingScene = slideScene;
    if (slidePosition == null && selected && selectedScene != null) {
      _paintBadge(canvas, size, selection, selectedScene);
    } else if (slidePosition != null &&
        paintsSlideBadge &&
        movingScene != null) {
      // Paint after the date labels so the decoration follows the highlight.
      canvas.save();
      canvas.translate(translation.dx, translation.dy);
      _paintBadge(canvas, size, selection, movingScene);
      canvas.restore();
    }
  }

  void _paintBadge(
    Canvas canvas,
    Size size,
    RRect selection,
    HolidayScene scene,
  ) {
    final center = size.center(Offset.zero);
    if (scene == HolidayScene.snow) {
      paintHolidaySnowCap(
        canvas,
        Offset(center.dx, selection.top + 17),
        frames?.value.snowCapProgress ?? 1,
      );
    }
    if (scene == HolidayScene.lichun) {
      paintHolidaySpringBud(
        canvas,
        Offset(center.dx, 20),
        scale: size.width * 7 / 584,
        seconds: frames?.value.seconds ?? 2.4,
      );
    }
    if (scene == HolidayScene.yushui) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      paintHolidayRainDate(
        canvas,
        selection.outerRect,
        frames?.value.seconds ?? 2.4,
      );
      canvas.restore();
    }
    if (scene == HolidayScene.jingzhe) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      paintHolidayJingzheDate(
        canvas,
        Offset(center.dx, 20),
        scale: size.width * 7 / 584,
        seconds: frames?.value.seconds ?? HolidayScene.jingzhe.stillSeconds,
      );
      canvas.restore();
    }
    if (scene == HolidayScene.chunfen) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      paintHolidayChunfenDate(
        canvas,
        Offset(center.dx, 20),
        scale: size.width * 7 / 584,
        seconds: frames?.value.seconds ?? HolidayScene.chunfen.stillSeconds,
      );
      canvas.restore();
    }
    if (scene.usesGlassCard) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      final scale = size.width * 7 / 584;
      final alignToHighlight =
          scene.usesFestivalArtwork ||
          scene == HolidayScene.xiaoman ||
          scene == HolidayScene.xiazhi ||
          scene == HolidayScene.xiaoshu ||
          scene == HolidayScene.dashu ||
          scene == HolidayScene.liqiu ||
          scene == HolidayScene.chushu ||
          scene == HolidayScene.bailu ||
          scene == HolidayScene.qiufen ||
          scene == HolidayScene.hanlu ||
          scene == HolidayScene.shuangjiang ||
          scene == HolidayScene.lidong ||
          scene == HolidayScene.xiaoxue ||
          scene == HolidayScene.daxue ||
          scene == HolidayScene.dongzhi ||
          scene == HolidayScene.xiaohan ||
          scene == HolidayScene.dahan;
      final badgeScale = alignToHighlight ? math.min(.72, scale) : scale;
      final badgeCenter = alignToHighlight
          ? Offset(
              selection.left + 36 * badgeScale,
              selection.top + 22 * badgeScale,
            )
          : Offset(center.dx, 20);
      paintHolidayGlassDate(
        canvas,
        scene,
        badgeCenter,
        scale: badgeScale,
        seconds: frames?.value.seconds ?? scene.stillSeconds,
      );
      canvas.restore();
    }
    if (scene == HolidayScene.fireworks) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, -10, size.width, size.height + 10));
      paintHolidayFireworkBadge(
        canvas,
        Offset(selection.left + 4, selection.top - 2),
        frames?.value.seconds ?? HolidayCalendarDesign.dateFireworkStillSeconds,
      );
      canvas.restore();
    }
    if (scene == HolidayScene.lanterns) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      paintHolidayLanternBadge(
        canvas,
        Offset(selection.left + 4, selection.top + 3),
        frames?.value.seconds ?? 2.4,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HolidayDayPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.event != event ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.frames != frames ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.slide != slide ||
      oldDelegate.gridPosition != gridPosition ||
      oldDelegate.slideScene != slideScene ||
      oldDelegate.paintsSlideBadge != paintsSlideBadge;
}
