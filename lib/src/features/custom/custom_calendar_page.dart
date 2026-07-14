import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';

class CustomCalendarPage extends StatefulWidget {
  const CustomCalendarPage({super.key});

  @override
  State<CustomCalendarPage> createState() => _CustomCalendarPageState();
}

class _CustomCalendarPageState extends State<CustomCalendarPage> {
  late final CalendarController _calendarController;
  late final CalendarInteractiveController _interactiveController;
  late final CalendarMonthYearController _monthYearController;

  @override
  void initState() {
    super.initState();
    final now = CalendarDateUtils.stripTime(DateTime.now());
    _calendarController =
        CalendarController(
            focusedDay: now,
            minDate: DateTime(1964),
            maxDate: DateTime(2080, 12, 31),
            markers: _buildMarkers(now.year, now.month),
          )
          ..setWeekStart(DateTime.sunday)
          ..setMonthViewShowMode(MonthViewShowMode.allMonth)
          ..setInterceptBlocked(false);
    _interactiveController = CalendarInteractiveController();
    _monthYearController = CalendarMonthYearController();
  }

  @override
  void dispose() {
    _monthYearController.dispose();
    _interactiveController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  Map<DateTime, List<CalendarMarker>> _buildMarkers(int year, int month) {
    final specs = <(int, int, String)>[
      (1, 0xFF40DB25, '假'),
      (2, 0xFFE69138, '游'),
      (3, 0xFFDF1356, '事'),
      (4, 0xFFAACC44, '车'),
      (5, 0xFFBC13F0, '驾'),
      (6, 0xFF542261, '记'),
      (7, 0xFF4A4BD2, '会'),
      (8, 0xFFE69138, '车'),
      (9, 0xFF542261, '考'),
      (10, 0xFF87AF5A, '记'),
      (11, 0xFF40DB25, '会'),
      (12, 0xFFCDA1AF, '游'),
      (13, 0xFF95AF1A, '事'),
      (14, 0xFF33AADD, '学'),
      (15, 0xFF1AFF1A, '码'),
      (16, 0xFF22ACAF, '驾'),
      (17, 0xFF99A6FA, '校'),
      (18, 0xFFE69138, '车'),
      (19, 0xFF40DB25, '码'),
      (20, 0xFFE69138, '火'),
      (21, 0xFF40DB25, '假'),
      (22, 0xFF99A6FA, '记'),
      (23, 0xFF33AADD, '假'),
      (24, 0xFF40DB25, '校'),
      (25, 0xFF1AFF1A, '假'),
      (26, 0xFF40DB25, '议'),
      (27, 0xFF95AF1A, '假'),
      (28, 0xFF40DB25, '码'),
    ];

    final lastDay = CalendarDateUtils.daysInMonth(DateTime(year, month));
    return {
      for (final spec in specs.where((spec) => spec.$1 <= lastDay))
        DateTime(year, month, spec.$1): [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
        ],
    };
  }

  void _syncMarkersForFocusedMonth() {
    _calendarController.setMarkers(
      _buildMarkers(
        _calendarController.focusedDay.year,
        _calendarController.focusedDay.month,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            AnimatedBuilder(
              animation: Listenable.merge([
                _calendarController,
                _interactiveController,
                _monthYearController,
              ]),
              builder: (context, _) => _buildToolbar(),
            ),
            Expanded(
              child: CalendarMonthYearView(
                controller: _calendarController,
                interactionController: _interactiveController,
                monthYearController: _monthYearController,
                pageOrientation: _interactiveController.pageOrientation,
                calendarHeight: 76,
                weekBarHeight: 40,
                monthHeaderHeight: 54,
                componentBuilder: const _ChinaCalendarComponentBuilder(),
                onFocusedDayChanged: (_) => _syncMarkersForFocusedMonth(),
                onMonthSelected: (_) => _syncMarkersForFocusedMonth(),
                onDaySelected: (day) {
                  _calendarController.selectDay(day);
                  _syncMarkersForFocusedMonth();
                },
                contentBuilder: (context, scrollController, physics) {
                  return _ArticleList(
                    controller: scrollController,
                    physics: physics,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final selected = _calendarController.focusedDay;
    final lunar = _monthYearController.isYearMode
        ? ''
        : _calendarController.focusedDay ==
              CalendarDateUtils.stripTime(DateTime.now())
        ? '今日'
        : _ChinaCalendarComponentBuilder.lunarTextFor(selected);
    final orientationAsset =
        _interactiveController.pageOrientation ==
            CalendarPageOrientation.horizontal
        ? 'assets/icons/ic_horizontal.png'
        : 'assets/icons/ic_vertical.png';

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_interactiveController.isCollapsed) {
                _interactiveController.expand();
                return;
              }
              _monthYearController.showYearMode();
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  _monthYearController.isYearMode
                      ? '${_monthYearController.visibleYear}'
                      : '${selected.month}月${selected.day}日',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _monthYearController.isYearMode
                            ? ''
                            : '${selected.year}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        lunar,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _ToolbarIconButton(
            asset: orientationAsset,
            onTap: () {
              if (_monthYearController.isYearMode) {
                return;
              }
              _interactiveController.togglePageOrientation();
            },
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _calendarController.jumpToDay(
                CalendarDateUtils.stripTime(DateTime.now()),
              );
              _syncMarkersForFocusedMonth();
            },
            child: _TodayButton(day: DateTime.now().day),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ChinaCalendarComponentBuilder extends CalendarComponentBuilder {
  const _ChinaCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: 10);

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    const labels = <String>['日', '一', '二', '三', '四', '五', '六'];
    return switch (firstWeekday) {
      DateTime.monday => [...labels.skip(1), labels.first],
      DateTime.saturday => [labels.last, ...labels.take(6)],
      _ => labels,
    };
  }

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '${month.month}月',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Positioned(left: 10, right: 10, bottom: 2, child: _Hairline()),
        ],
      ),
    );
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
      data.label,
      style: const TextStyle(color: Color(0xFFE1E1E1), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return _ChinaDayCell(data: data);
  }

  static String lunarTextFor(DateTime day) {
    return LunarService.metadataForDate(day).lunarText;
  }
}

class _ChinaDayCell extends StatelessWidget {
  const _ChinaDayCell({required this.data});

  final CalendarDayCellData data;

  @override
  Widget build(BuildContext context) {
    final marker = data.primaryMarker;
    final isWeekend = data.isWeekend && data.isCurrentMonth;
    final textColor = data.isSelected
        ? Colors.white
        : isWeekend
        ? const Color(0xFF489DFF)
        : data.isToday
        ? Colors.red
        : data.isCurrentMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final lunarColor = data.isSelected
        ? Colors.white
        : isWeekend
        ? const Color(0xFF489DFF)
        : data.isCurrentMonth
        ? const Color(0xFFCFCFCF)
        : const Color(0xFFE1E1E1);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (data.showBottomDivider)
          const Positioned(left: 0, right: 0, bottom: 0, child: _Hairline()),
        Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: data.isSelected
                  ? const Color(0xFF046CEA)
                  : data.isToday
                  ? const Color(0xFFEAEAEA)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        if (marker != null)
          Positioned(
            top: 8,
            right: 4,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                marker.label,
                style: TextStyle(
                  color: marker.color,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${data.date.day}',
                style: TextStyle(color: textColor, fontSize: 16, height: 1),
              ),
              const SizedBox(height: 8),
              Text(
                data.lunarText,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(color: lunarColor, fontSize: 10, height: 1),
              ),
            ],
          ),
        ),
        if (marker != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 9,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: data.isSelected ? Colors.white : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArticleList extends StatefulWidget {
  const _ArticleList({required this.controller, required this.physics});

  final ScrollController controller;
  final ScrollPhysics physics;

  @override
  State<_ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<_ArticleList> {
  static const double _headerHeight = 46;
  static const double _itemHeight = 108;
  static const int _sectionCount = 16;

  late final List<_ArticleSection> _sections = List.generate(_sectionCount, (
    index,
  ) {
    final group = _articleGroups[index % _articleGroups.length];
    return _ArticleSection('${group.title}$index', group.items);
  });

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScrollChanged);
  }

  @override
  void didUpdateWidget(covariant _ArticleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleScrollChanged);
      widget.controller.addListener(_handleScrollChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScrollChanged);
    super.dispose();
  }

  void _handleScrollChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];
    for (final section in _sections) {
      slivers.add(
        SliverToBoxAdapter(child: _ArticleGroupHeader(section.title)),
      );
      slivers.add(
        SliverList.builder(
          itemCount: section.items.length,
          itemBuilder: (context, index) {
            return _ArticleItemView(item: section.items[index]);
          },
        ),
      );
    }

    final stickyState = _currentStickyState();
    return Stack(
      children: [
        CustomScrollView(
          controller: widget.controller,
          physics: widget.physics,
          slivers: slivers,
        ),
        if (stickyState.visible)
          IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, stickyState.offsetY),
              child: _ArticleGroupHeader(stickyState.title),
            ),
          ),
      ],
    );
  }

  _StickyHeaderState _currentStickyState() {
    final offset = widget.controller.hasClients
        ? widget.controller.offset
        : 0.0;
    if (offset <= 0) {
      return _StickyHeaderState(_sections.first.title, 0, visible: false);
    }
    var sectionStart = 0.0;
    for (final section in _sections) {
      final sectionHeight =
          _headerHeight + (section.items.length * _itemHeight);
      final nextSectionStart = sectionStart + sectionHeight;
      if (offset < nextSectionStart || section == _sections.last) {
        final distanceToNext = nextSectionStart - offset;
        final offsetY = distanceToNext < _headerHeight
            ? distanceToNext - _headerHeight
            : 0.0;
        return _StickyHeaderState(section.title, offsetY);
      }
      sectionStart = nextSectionStart;
    }
    return _StickyHeaderState(_sections.first.title, 0);
  }
}

class _ArticleGroupHeader extends StatelessWidget {
  const _ArticleGroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
      ),
    );
  }
}

class _StickyHeaderState {
  const _StickyHeaderState(this.title, this.offsetY, {this.visible = true});

  final String title;
  final double offsetY;
  final bool visible;
}

class _ArticleSection {
  const _ArticleSection(this.title, this.items);

  final String title;
  final List<_Article> items;
}

class _ArticleItemView extends StatelessWidget {
  const _ArticleItemView({required this.item});

  final _Article item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ArticleListState._itemHeight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              color: item.color,
              child: Image.asset(
                'assets/icons/ic_custom.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9F9F9F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0x11000000),
          shape: BoxShape.circle,
        ),
        child: Image.asset(asset, color: const Color(0xFF333333)),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0x11000000),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '$day',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE5E5E5),
      child: SizedBox(height: 0.5),
    );
  }
}

class _ArticleGroup {
  const _ArticleGroup(this.title, this.items);

  final String title;
  final List<_Article> items;
}

class _Article {
  const _Article(this.title, this.content, this.color);

  final String title;
  final String content;
  final Color color;
}

const _articleGroups = <_ArticleGroup>[
  _ArticleGroup('今日推荐', [
    _Article(
      '新西兰克马德克群岛发生5.7级地震 震源深度10千米',
      '#地震快讯#中国地震台网正式测定：12月04日08时08分在克马德克群岛发生5.7级地震，震源深度10千米。',
      Color(0xFFE8F2FF),
    ),
    _Article(
      '俄罗斯喊冤不当背锅侠 俄美陷入后真相旋涡',
      '俄罗斯近来连遭美国指责和西方国家连环出击，在你来我往的互掐中，真相似乎变得已不那么重要了。',
      Color(0xFFFFF0E2),
    ),
    _Article(
      '中企投资巴西获支持 英媒称巴西人感激保住饭碗',
      '里约热内卢附近的阿苏港在大宗商品热潮结束后仍蓬勃发展，成为当地经济关注焦点。',
      Color(0xFFEAF8EA),
    ),
  ]),
  _ArticleGroup('每周热点', [
    _Article(
      '2019年投产 电咖整车生产基地落户浙江绍兴',
      '广州车展上电咖发布首款电动汽车 EV10，新势力造车团队和生产基地同样引起关注。',
      Color(0xFFF2ECFF),
    ),
    _Article(
      '2017年进入尾声，苹果大笔押注的 ARkit 还好么？',
      '苹果把 AR 当做发展重点，新品硬件也围绕更好的增强现实效果进行了校准。',
      Color(0xFFEAF7F7),
    ),
    _Article(
      '亚马逊 CTO：我们要让人类成为机器人的中心',
      'AWS re:Invent 大会上，Werner Vogels 谈到信息民主化和下一代交互方式。',
      Color(0xFFFFF6D8),
    ),
  ]),
  _ArticleGroup('最高评论', [
    _Article(
      '美电视台记者因误报有关弗林新闻被停职四周',
      '美国 ABC 电视台记者因有关前国家安全顾问新闻报道中的失误，临时被停职。',
      Color(0xFFFFE8EE),
    ),
    _Article(
      '预计明年3月上市 曝全新奥迪 Q5L 无伪谍照',
      '轴距加长令后排空间有明显提升，国产全新一代奥迪 Q5L 预计明年上市。',
      Color(0xFFE8F0FF),
    ),
  ]),
];
