import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import 'holiday_calendar_components.dart';
import 'holiday_calendar_data.dart';
import 'holiday_calendar_scenes.dart';
import 'holiday_calendar_qingming.dart';
import 'holiday_calendar_guyu.dart';
import 'holiday_calendar_lixia.dart';
import 'holiday_calendar_xiaoman.dart';
import 'holiday_calendar_mangzhong.dart';
import 'holiday_calendar_xiazhi.dart';
import 'holiday_calendar_xiaoshu.dart';
import 'holiday_calendar_dashu.dart';
import 'holiday_calendar_liqiu.dart';
import 'holiday_calendar_chushu.dart';
import 'holiday_calendar_bailu.dart';
import 'holiday_calendar_qiufen.dart';
import 'holiday_calendar_hanlu.dart';
import 'holiday_calendar_shuangjiang.dart';
import 'holiday_calendar_lidong.dart';
import 'holiday_calendar_xiaoxue.dart';
import 'holiday_calendar_daxue.dart';
import 'holiday_calendar_dongzhi.dart';
import 'holiday_calendar_january.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

class HolidayCalendarPage extends StatefulWidget {
  const HolidayCalendarPage({super.key});

  @override
  State<HolidayCalendarPage> createState() => _HolidayCalendarPageState();
}

class _HolidayCalendarPageState extends State<HolidayCalendarPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final CalendarController _calendar;
  late final AnimationController _clock;
  late final AnimationController _selectionController;
  late final HolidayCalendarComponentBuilder _components;
  final _scroll = ScrollController();
  final _frames = ValueNotifier(
    const HolidaySceneFrame(scene: HolidayScene.snow, seconds: 0),
  );
  DateTime _selectedDay = DateTime(2026, 12, 25);
  DateTime? _highlightedDay;
  HolidaySelectionSlide? _selectionSlide;
  late HolidayEvent? _selectedEvent = HolidayCalendarData.eventOn(_selectedDay);
  DateTime _focusedMonth = DateTime(2026, 12);
  bool _playing = true;
  bool _reducedMotion = false;
  bool _configured = false;
  bool _foreground = true;
  double _previousClockValue = 0;
  double _elapsedCycles = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendar =
        CalendarController(
            focusedDay: _selectedDay,
            minDate: DateTime(2004),
            maxDate: DateTime(2099, 12, 31),
            markers: _markersForYear(_focusedMonth.year),
          )
          ..setWeekStart(DateTime.monday)
          ..setMonthViewShowMode(MonthViewShowMode.fitMonth)
          ..setInterceptBlocked(false);
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_updateFrame);
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1,
    );
    _highlightedDay = _calendar.selection.single;
    _calendar.addListener(_animateSelection);
    _components = HolidayCalendarComponentBuilder(
      frames: _frames,
      selectionSlideFor: (month) {
        final slide = _selectionSlide;
        return slide != null && CalendarDateUtils.isSameMonth(slide.day, month)
            ? slide
            : null;
      },
    );
  }

  Map<DateTime, List<CalendarMarker>> _markersForYear(int year) {
    final markers = <DateTime, List<CalendarMarker>>{};
    for (var y = year - 1; y <= year + 1; y++) {
      for (final event in HolidayCalendarData.eventsForYear(y)) {
        (markers[event.date] ??= []).add(
          CalendarMarker(label: event.title, color: event.scene.color),
        );
      }
    }
    return markers;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!_configured || reduced != _reducedMotion) {
      _configured = true;
      _reducedMotion = reduced;
      if (reduced) {
        _clock.stop();
        _finishSelection();
      }
      _updateFrame();
      _startIfAllowed();
    }
  }

  void _updateFrame() {
    final value = _clock.value;
    if (value < _previousClockValue) {
      _elapsedCycles += HolidayCalendarDesign.sceneCycleSeconds;
    }
    _previousClockValue = value;
    final scene = _selectedEvent?.scene ?? HolidayScene.ambient;
    _frames.value = HolidaySceneFrame(
      scene: scene,
      seconds: _reducedMotion
          ? scene.stillSeconds
          : _elapsedCycles + value * HolidayCalendarDesign.sceneCycleSeconds,
    );
  }

  void _startIfAllowed() {
    if (_playing && !_reducedMotion && _foreground) _clock.repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startIfAllowed();
    } else {
      _clock.stop();
      _finishSelection();
    }
  }

  void _animateSelection() {
    final previous = _highlightedDay;
    final next = _calendar.selection.single;
    if (next == previous) return;
    _highlightedDay = next;

    if (!_playing ||
        _reducedMotion ||
        !_foreground ||
        previous == null ||
        next == null) {
      _finishSelection();
      return;
    }

    final days = _visibleDays(next);
    final previousDays = CalendarDateUtils.isSameMonth(previous, next)
        ? days
        : _visibleDays(previous);
    final previousIndex = previousDays.indexOf(previous);
    if (previousIndex < 0 || !days.contains(next)) {
      _finishSelection();
      return;
    }
    final from =
        _selectionSlide?.position ??
        HolidaySelectionSlide.positionOf(previousIndex);
    final lastRow = (days.length ~/ 7 - 1).toDouble();
    _selectionSlide = HolidaySelectionSlide(
      days: days,
      day: next,
      from: Offset(from.dx, math.min(from.dy, lastRow)),
      progress: _selectionController,
    );
    _selectionController.forward(from: 0);
  }

  List<DateTime> _visibleDays(DateTime month) =>
      CalendarDateUtils.visibleMonthDays(
        month,
        firstWeekday: _calendar.firstWeekday,
        monthViewShowMode: _calendar.monthViewShowMode,
      );

  void _finishSelection() {
    _selectionSlide = null;
    _selectionController.value = 1;
  }

  /// CalendarView handles finger selection; shortcuts use the same controller.
  void _didSelectDay(DateTime day, {HolidayEvent? event}) {
    final previousYear = _focusedMonth.year;
    setState(() {
      _selectedDay = CalendarDateUtils.stripTime(day);
      _selectedEvent = event ?? HolidayCalendarData.eventOn(_selectedDay);
      _focusedMonth = DateTime(day.year, day.month);
      if (previousYear != day.year) {
        _calendar.setMarkers(_markersForYear(day.year));
      }
      _previousClockValue = 0;
      _elapsedCycles = 0;
      _clock.value = 0;
      _updateFrame();
      _startIfAllowed();
    });
  }

  void _selectDay(DateTime day) {
    if (_calendar.selectDay(day)) _didSelectDay(day);
  }

  void _monthChanged(DateTime day) {
    final previousYear = _focusedMonth.year;
    setState(() {
      _focusedMonth = DateTime(day.year, day.month);
      if (previousYear != day.year) {
        _calendar.setMarkers(_markersForYear(day.year));
      }
    });
  }

  void _changeMonth(int direction) {
    if (direction < 0) {
      _calendar.previousPage();
    } else {
      _calendar.nextPage();
    }
    _monthChanged(_calendar.focusedDay);
  }

  void _selectEvent(HolidayEvent event) {
    if (!_calendar.selectDay(event.date)) return;
    _didSelectDay(event.date, event: event);
    if (_scroll.hasClients) {
      if (_reducedMotion) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Future<void> _showEventPicker(BuildContext context) async {
    final events = HolidayCalendarData.nearbyEvents(_focusedMonth);
    final selectedEvent = _selectedEvent;
    final event = await showModalBottomSheet<HolidayEvent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: HolidayCalendarDesign.surface,
      constraints: const BoxConstraints(maxWidth: 600),
      sheetAnimationStyle: _reducedMotion ? AnimationStyle.noAnimation : null,
      builder: (context) =>
          _HolidayEventPicker(events: events, selectedEvent: selectedEvent),
    );
    if (mounted && event != null) _selectEvent(event);
  }

  void _toggleAnimation() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _startIfAllowed();
      } else {
        _clock.stop();
        _finishSelection();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendar.removeListener(_animateSelection);
    _selectionController.dispose();
    _clock.dispose();
    _frames.dispose();
    _calendar.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _selectedEvent?.scene.color ?? HolidayCalendarDesign.ambient;
    final glass = _selectedEvent?.scene.usesGlassCard ?? false;
    final textScaler = MediaQuery.textScalerOf(context);
    final rowHeight = math.max(
      60.0,
      textScaler.scale(18) * 1.2 + textScaler.scale(10) * 1.2 + 16,
    );
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: accent,
        scaffoldBackgroundColor: HolidayCalendarDesign.background,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: HolidayCalendarDesign.background,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('节日光影'),
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: HolidayCalendarDesign.background,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: _reducedMotion
                    ? '已开启减少动态效果'
                    : _playing
                    ? '暂停动效'
                    : '继续动效',
                onPressed: _reducedMotion ? null : _toggleAnimation,
                icon: Icon(
                  _playing && !_reducedMotion
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              TextButton(
                onPressed: () => _selectDay(DateTime.now()),
                style: TextButton.styleFrom(minimumSize: const Size(56, 48)),
                child: const Text('今天'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<HolidaySceneFrame>(
                      valueListenable: _frames,
                      builder: (context, frame, _) =>
                          CustomPaint(painter: HolidayBackdropPainter(frame)),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final margin = constraints.maxWidth < 360 ? 4.0 : 12.0;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: CustomScrollView(
                          controller: _scroll,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                margin,
                                8,
                                margin,
                                0,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: RepaintBoundary(
                                  key: const ValueKey('holiday-calendar-card'),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: HolidayCalendarDesign.surface
                                          .withValues(
                                            alpha: glass ? 0.74 : 0.9,
                                          ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: accent.withValues(
                                          alpha: glass ? 0.18 : 0.24,
                                        ),
                                      ),
                                      boxShadow: glass
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x99000000),
                                                blurRadius: 50,
                                                offset: Offset(0, 24),
                                                spreadRadius: -18,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: CustomPaint(
                                        foregroundPainter: glass
                                            ? HolidayGlassCardOverlayPainter(
                                                _frames,
                                              )
                                            : null,
                                        child: Column(
                                          children: [
                                            _HolidayHeader(
                                              day: _selectedDay,
                                              event: _selectedEvent,
                                              frames: _frames,
                                              glass: glass,
                                            ),
                                            _buildMonthToolbar(),
                                            CalendarView(
                                              key: const ValueKey(
                                                'holiday-calendar',
                                              ),
                                              controller: _calendar,
                                              pageOrientation:
                                                  CalendarPageOrientation
                                                      .horizontal,
                                              componentBuilder: _components,
                                              calendarHeight: rowHeight,
                                              weekBarHeight: math.max(
                                                36,
                                                textScaler.scale(12) + 12,
                                              ),
                                              monthHeaderHeight: 0,
                                              handleDaySelection: true,
                                              onDaySelected: _didSelectDay,
                                              onPageChanged: _monthChanged,
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                margin,
                                12,
                                margin,
                                24,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _buildEventShortcuts(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthToolbar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              '${_focusedMonth.year}年${_focusedMonth.month}月',
              key: const ValueKey('holiday-focused-month'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          tooltip: '上个月',
          onPressed: _calendar.canNavigateToPreviousPage()
              ? () => _changeMonth(-1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: '下个月',
          onPressed: _calendar.canNavigateToNextPage()
              ? () => _changeMonth(1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );

  Widget _buildEventShortcuts(BuildContext context) {
    final events = HolidayCalendarData.eventsForYear(
      _focusedMonth.year,
    ).where((event) => event.date.month == _focusedMonth.month).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: const Text(
                    '本月节日与节气',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: HolidayCalendarDesign.text,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showEventPicker(context),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('全部光影'),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _HolidayEventGrid(
          events: events,
          selectedEvent: _selectedEvent,
          onSelected: _selectEvent,
        ),
      ],
    );
  }
}

class _HolidayHeader extends StatelessWidget {
  const _HolidayHeader({
    required this.day,
    required this.event,
    required this.frames,
    required this.glass,
  });
  final DateTime day;
  final HolidayEvent? event;
  final ValueNotifier<HolidaySceneFrame> frames;
  final bool glass;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: event?.scene == HolidayScene.qingming
                  ? HolidayQingmingArtwork(
                      key: const ValueKey('holiday-qingming-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.guyu
                  ? HolidayGuyuArtwork(
                      key: const ValueKey('holiday-guyu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.lixia
                  ? HolidayLixiaArtwork(
                      key: const ValueKey('holiday-lixia-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.xiaoman
                  ? HolidayXiaomanArtwork(
                      key: const ValueKey('holiday-xiaoman-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.mangzhong
                  ? HolidayMangzhongArtwork(
                      key: const ValueKey('holiday-mangzhong-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.xiazhi
                  ? HolidayXiazhiArtwork(
                      key: const ValueKey('holiday-xiazhi-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.xiaoshu
                  ? HolidayXiaoshuArtwork(
                      key: const ValueKey('holiday-xiaoshu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.dashu
                  ? HolidayDashuArtwork(
                      key: const ValueKey('holiday-dashu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.liqiu
                  ? HolidayLiqiuArtwork(
                      key: const ValueKey('holiday-liqiu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.chushu
                  ? HolidayChushuArtwork(
                      key: const ValueKey('holiday-chushu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.bailu
                  ? HolidayBailuArtwork(
                      key: const ValueKey('holiday-bailu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.qiufen
                  ? HolidayQiufenArtwork(
                      key: const ValueKey('holiday-qiufen-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.hanlu
                  ? HolidayHanluArtwork(
                      key: const ValueKey('holiday-hanlu-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.shuangjiang
                  ? HolidayShuangjiangArtwork(
                      key: const ValueKey('holiday-shuangjiang-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.lidong
                  ? HolidayLidongArtwork(
                      key: const ValueKey('holiday-lidong-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.xiaoxue
                  ? HolidayXiaoxueArtwork(
                      key: const ValueKey('holiday-xiaoxue-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.daxue
                  ? HolidayDaxueArtwork(
                      key: const ValueKey('holiday-daxue-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.dongzhi
                  ? HolidayDongzhiArtwork(
                      key: const ValueKey('holiday-dongzhi-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.xiaohan
                  ? HolidayJanuaryArtwork.xiaohan(
                      key: const ValueKey('holiday-xiaohan-artwork'),
                      frames: frames,
                    )
                  : event?.scene == HolidayScene.dahan
                  ? HolidayJanuaryArtwork.dahan(
                      key: const ValueKey('holiday-dahan-artwork'),
                      frames: frames,
                    )
                  : event?.scene.usesFestivalArtwork == true
                  ? HolidaySceneArtwork(
                      key: ValueKey('holiday-${event!.scene.name}-artwork'),
                      frames: frames,
                      recordBackground: () =>
                          recordHolidayGlassBackdrop(event!.scene),
                      paintMotion: (canvas, seconds) => paintHolidayGlassMotion(
                        canvas,
                        event!.scene,
                        seconds,
                      ),
                      glass: true,
                      fadeToHeader: true,
                    )
                  : ValueListenableBuilder<HolidaySceneFrame>(
                      valueListenable: frames,
                      builder: (context, frame, _) =>
                          CustomPaint(painter: HolidayScenePainter(frame)),
                    ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            glass
                ? math.max(96.0, constraints.maxWidth * 152 / 584)
                : event?.scene == HolidayScene.yushui
                ? math.max(120.0, constraints.maxWidth * 0.62 - 80)
                : 84,
            20,
            20,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.year}年${day.month}月${day.day}日 · 星期${['一', '二', '三', '四', '五', '六', '日'][day.weekday - 1]}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HolidayCalendarDesign.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event?.title ?? '${day.month}月${day.day}日',
                  key: const ValueKey('holiday-selected-title'),
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: HolidayCalendarDesign.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HolidayEventPicker extends StatefulWidget {
  const _HolidayEventPicker({
    required this.events,
    required this.selectedEvent,
  });

  final List<HolidayEvent> events;
  final HolidayEvent? selectedEvent;

  @override
  State<_HolidayEventPicker> createState() => _HolidayEventPickerState();
}

class _HolidayEventPickerState extends State<_HolidayEventPicker> {
  final _eventsByMonth = <DateTime, List<HolidayEvent>>{};
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    for (final event in widget.events) {
      final month = DateTime(event.date.year, event.date.month);
      (_eventsByMonth[month] ??= []).add(event);
    }
    _month = _eventsByMonth.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('全部光影', style: theme.textTheme.titleLarge),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final width = constraints.maxWidth;
                final minWidth =
                    MediaQuery.textScalerOf(context).scale(34) + 24;
                final columns = ((width + gap) / (minWidth + gap))
                    .floor()
                    .clamp(1, width >= 480 ? 6 : 4);
                final buttonWidth = (width - (columns - 1) * gap) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final month in _eventsByMonth.keys)
                      SizedBox(
                        width: buttonWidth,
                        child: Semantics(
                          selected: month == _month,
                          child: OutlinedButton(
                            key: ValueKey(
                              'holiday-picker-month-${month.year}-${month.month}',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              backgroundColor: month == _month
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                              foregroundColor: month == _month
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            onPressed: () => setState(() => _month = month),
                            child: Text(
                              '${month.month}月',
                              semanticsLabel: '${month.year}年${month.month}月',
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                '${_month.year}年${_month.month}月',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            _HolidayEventGrid(
              events: _eventsByMonth[_month]!,
              selectedEvent: widget.selectedEvent,
              showSceneLabel: true,
              onSelected: (event) => Navigator.of(context).pop(event),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayEventGrid extends StatelessWidget {
  const _HolidayEventGrid({
    required this.events,
    required this.selectedEvent,
    required this.onSelected,
    this.showSceneLabel = false,
  });

  final List<HolidayEvent> events;
  final HolidayEvent? selectedEvent;
  final ValueChanged<HolidayEvent> onSelected;
  final bool showSceneLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final width = constraints.maxWidth;
      final minWidth = 76 + MediaQuery.textScalerOf(context).scale(45);
      final capacity = ((width + gap) / (minWidth + gap)).floor();
      final columns = !showSceneLabel && capacity >= 4
          ? 4
          : capacity.clamp(1, 2);
      final tileWidth = (width - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final event in events)
            SizedBox(
              width: tileWidth,
              child: _HolidayEventTile(
                event: event,
                selected: event == selectedEvent,
                showSceneLabel: showSceneLabel,
                onTap: () => onSelected(event),
              ),
            ),
        ],
      );
    },
  );
}

class _HolidayEventTile extends StatelessWidget {
  const _HolidayEventTile({
    required this.event,
    required this.selected,
    required this.showSceneLabel,
    required this.onTap,
  });
  final HolidayEvent event;
  final bool selected;
  final bool showSceneLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = event.scene.color;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected
            ? accent.withValues(alpha: 0.65)
            : HolidayCalendarDesign.secondaryText.withValues(alpha: 0.2),
      ),
    );
    return Semantics(
      key: ValueKey('holiday-shortcut-${event.scene.name}'),
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.12),
                HolidayCalendarDesign.surface,
              )
            : HolidayCalendarDesign.surface.withValues(alpha: 0.92),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_icon, size: 17, color: accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: HolidayCalendarDesign.text,
                          ),
                        ),
                        Text(
                          '${event.date.month}月${event.date.day}日',
                          style: const TextStyle(
                            fontSize: 12,
                            color: HolidayCalendarDesign.secondaryText,
                          ),
                        ),
                        if (showSceneLabel)
                          Text(
                            event.scene.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HolidayCalendarDesign.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded, size: 16, color: accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (event.scene) {
    HolidayScene.snow => Icons.ac_unit_rounded,
    HolidayScene.fireworks => Icons.auto_awesome_rounded,
    HolidayScene.lanterns => Icons.wb_incandescent_outlined,
    HolidayScene.ambient => Icons.calendar_month_outlined,
    HolidayScene.lichun => Icons.spa_outlined,
    HolidayScene.yushui => Icons.water_drop_outlined,
    HolidayScene.jingzhe => Icons.thunderstorm_outlined,
    HolidayScene.chunfen => Icons.local_florist_outlined,
    HolidayScene.qingming => Icons.umbrella_outlined,
    HolidayScene.guyu => Icons.grass_rounded,
    HolidayScene.lixia => Icons.wb_sunny_outlined,
    HolidayScene.xiaoman => Icons.grass_outlined,
    HolidayScene.mangzhong => Icons.agriculture_outlined,
    HolidayScene.xiazhi => Icons.schedule_outlined,
    HolidayScene.xiaoshu => Icons.bug_report_outlined,
    HolidayScene.dashu => Icons.nights_stay_outlined,
    HolidayScene.liqiu => Icons.eco_outlined,
    HolidayScene.chushu => Icons.air_rounded,
    HolidayScene.bailu => Icons.water_drop_outlined,
    HolidayScene.qiufen => Icons.nightlight_round,
    HolidayScene.hanlu => Icons.local_florist_outlined,
    HolidayScene.shuangjiang => Icons.ac_unit_rounded,
    HolidayScene.lidong => Icons.emoji_food_beverage_outlined,
    HolidayScene.xiaoxue => Icons.park_outlined,
    HolidayScene.daxue => Icons.cabin_outlined,
    HolidayScene.dongzhi => Icons.dinner_dining_outlined,
    HolidayScene.xiaohan => Icons.local_florist_outlined,
    HolidayScene.dahan => Icons.cabin_outlined,
    HolidayScene.yuandan => Icons.calendar_today_rounded,
    HolidayScene.chuxi => Icons.celebration_outlined,
    HolidayScene.yuanxiao => Icons.local_florist_outlined,
    HolidayScene.laodong => Icons.construction_rounded,
    HolidayScene.duanwu => Icons.directions_boat_outlined,
    HolidayScene.zhongqiu => Icons.nightlight_round,
    HolidayScene.guoqing => Icons.flag_outlined,
  };
}
