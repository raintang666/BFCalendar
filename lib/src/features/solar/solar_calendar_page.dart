import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';
import 'solar_calendar_components.dart';

class SolarCalendarPage extends StatefulWidget {
  const SolarCalendarPage({super.key});

  @override
  State<SolarCalendarPage> createState() => _SolarCalendarPageState();
}

class _SolarCalendarPageState extends State<SolarCalendarPage> {
  static const int _minYear = 2004;
  static const int _maxYear = 2099;
  static const double _calendarItemHeight = 52;
  static const double _weekBarHeight = 40;
  static const _backgroundColor = SolarCalendarComponentBuilder.backgroundColor;
  static const _contentBackground = Color(0xFFF2F2F2);

  late final CalendarController _controller;
  late final CalendarInteractiveController _interactiveController;
  late final CalendarMonthYearController _monthYearController;
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = CalendarDateUtils.stripTime(DateTime.now());
    _controller =
        CalendarController(
            focusedDay: _today,
            minDate: DateTime(_minYear, 1, 1),
            maxDate: DateTime(_maxYear, 12, 31),
            markers: _buildMarkers(_today.year, _today.month),
          )
          ..setSelectionMode(CalendarSelectionMode.single)
          ..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth)
          ..setWeekStart(DateTime.sunday)
          ..setInterceptBlocked(false);
    _interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.horizontal,
    );
    _monthYearController = CalendarMonthYearController();
  }

  @override
  void dispose() {
    _monthYearController.dispose();
    _interactiveController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ColoredBox(
              color: _backgroundColor,
              child: SizedBox(height: MediaQuery.of(context).padding.top),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([
                _controller,
                _interactiveController,
                _monthYearController,
              ]),
              builder: (context, _) => _buildToolbar(),
            ),
            Expanded(
              child: CalendarMonthYearView(
                controller: _controller,
                interactionController: _interactiveController,
                monthYearController: _monthYearController,
                pageOrientation: CalendarPageOrientation.horizontal,
                componentBuilder: const SolarCalendarComponentBuilder(),
                calendarHeight: _calendarItemHeight,
                weekBarHeight: _weekBarHeight,
                monthHeaderHeight: 0,
                onFocusedDayChanged: (_) => _rebuildMarkersForFocusedMonth(),
                onMonthSelected: (_) => _rebuildMarkersForFocusedMonth(),
                onDaySelected: _handleDaySelected,
                contentBuilder: (context, scrollController, physics) {
                  return ColoredBox(
                    color: _contentBackground,
                    child: ListView.builder(
                      controller: scrollController,
                      physics: physics,
                      padding: EdgeInsets.zero,
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        return _SolarArticleItem(
                          article: _articles[index % _articles.length],
                        );
                      },
                    ),
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
    final selected = _controller.focusedDay;
    final isYearMode = _monthYearController.isYearMode;
    final lunar = CalendarDateUtils.isSameDay(selected, _today)
        ? '今日'
        : LunarService.metadataForDate(selected).lunarText;
    return ColoredBox(
      color: _backgroundColor,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTitleTap,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    isYearMode
                        ? '${_monthYearController.visibleYear}'
                        : '${selected.month}月${selected.day}日',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isYearMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 11,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selected.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            lunar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _jumpToToday,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 28,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${_today.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTitleTap() {
    if (!_interactiveController.isExpanded) {
      _interactiveController.expand();
      return;
    }
    _monthYearController.showYearMode();
  }

  void _handleDaySelected(DateTime day) {
    final previousMonth = DateTime(
      _controller.focusedDay.year,
      _controller.focusedDay.month,
    );
    _controller.selectDay(day);
    final currentMonth = DateTime(
      _controller.focusedDay.year,
      _controller.focusedDay.month,
    );
    if (previousMonth != currentMonth) {
      _rebuildMarkersForFocusedMonth();
    }
  }

  void _jumpToToday() {
    _monthYearController.hideYearMode();
    _controller.selectDay(_today);
    _controller.setMarkers(_buildMarkers(_today.year, _today.month));
  }

  void _rebuildMarkersForFocusedMonth() {
    _controller.setMarkers(
      _buildMarkers(_controller.focusedDay.year, _controller.focusedDay.month),
    );
  }

  Map<DateTime, List<CalendarMarker>> _buildMarkers(int year, int month) {
    const pointMarkers = [
      CalendarMarker(label: 'rightTop', color: Color(0xFFA8B015)),
      CalendarMarker(label: 'leftTop', color: Color(0xFF423CB0)),
      CalendarMarker(label: 'bottom', color: Color(0xFF643C8C)),
    ];
    final days = [3, 6, 9, 13, 14, 15, 18, 25, 27];
    return {for (final day in days) DateTime(year, month, day): pointMarkers};
  }
}

class _SolarArticle {
  const _SolarArticle({
    required this.title,
    required this.content,
    required this.imageUrl,
  });

  final String title;
  final String content;
  final String imageUrl;
}

class _SolarArticleItem extends StatelessWidget {
  const _SolarArticleItem({required this.article});

  final _SolarArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Image.network(
              article.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: Color(0xFFE1E1E1));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9F9F9F),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _articles = <_SolarArticle>[
  _SolarArticle(
    title: '新西兰克马德克群岛发生5.7级地震 震源深度10千米',
    content: '#地震快讯#中国地震台网正式测定：12月04日08时08分在克马德克群岛发生5.7级地震，震源深度10千米。',
    imageUrl:
        'https://nimg.ws.126.net/?url=http%3A%2F%2Fcms-bucket.ws.126.net%2F2024%2F0905%2F72f7c4eep00sjbxau001fc0009c0070c.png&thumbnail=140y88&quality=100&type=jpg',
  ),
  _SolarArticle(
    title: '俄罗斯喊冤不当"背锅侠" 俄美陷入"后真相"旋涡',
    content: '俄罗斯近来连遭美国指责和西方国家连环出击。一些国际舆论认为，俄罗斯成了背锅侠。',
    imageUrl:
        'https://nimg.ws.126.net/?url=http%3A%2F%2Fcms-bucket.ws.126.net%2F2024%2F0905%2F5301ee2dp00sjbwhf004jc0009c0070c.png&thumbnail=140y88&quality=100&type=jpg',
  ),
  _SolarArticle(
    title: '中企投资巴西获支持 英媒:巴西人感激"保住饭碗"',
    content: '参考消息网12月4日报道，里约热内卢附近的阿苏港曾被称为通往中国的公路。',
    imageUrl:
        'https://nimg.ws.126.net/?url=http%3A%2F%2Fcms-bucket.ws.126.net%2F2024%2F0905%2Feec545d5p00sjbjq90043c0009c0070c.png&thumbnail=140y88&quality=100&type=jpg',
  ),
  _SolarArticle(
    title: '美电视台记者因误报有关弗林新闻被停职四周',
    content: '据俄罗斯卫星网报道，美国ABC电视台记者因在相关新闻报道中的失误，临时被停职。',
    imageUrl:
        'https://nimg.ws.126.net/?url=http%3A%2F%2Fcms-bucket.ws.126.net%2F2024%2F0904%2Fe78186cap00sjamtw00f0c0009c0070c.png&thumbnail=140y88&quality=100&type=jpg',
  ),
  _SolarArticle(
    title: '预计明年3月上市 曝全新奥迪Q5L无伪谍照',
    content: '随着全新一代国产奥迪Q5L亮相，轴距加长令后排空间有着非常明显的提升。',
    imageUrl:
        'https://nimg.ws.126.net/?url=http%3A%2F%2Fcms-bucket.ws.126.net%2F2024%2F0904%2Fa93cad37p00sja1rr0024c000hs00a4c.png&thumbnail=140y88&quality=100&type=jpg',
  ),
];
