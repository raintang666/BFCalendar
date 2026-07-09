import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../range/range_page.dart';
import 'demo_entries.dart';

class CalendarDemoPage extends StatefulWidget {
  const CalendarDemoPage({super.key});

  @override
  State<CalendarDemoPage> createState() => _CalendarDemoPageState();
}

class _CalendarDemoPageState extends State<CalendarDemoPage> {
  late final CalendarController _controller;
  final CalendarInteractiveController _interactiveController =
      CalendarInteractiveController();
  CalendarComponentStyle _componentStyle = CalendarComponentStyle.custom;
  bool _yearMode = false;
  int _yearPanelYear = DateTime.now().year;
  static const double _calendarRowHeight = 62;
  static const double _weekBarHeight = 46;
  static const double _monthHeaderHeight = 60;

  static const _moreActions = <String>[
    '周日为周起始',
    '周一为周起始',
    '周六为周起始',
    '更换选择模式：单选/默认',
    '热插拔更换周月视图',
    '月视图模式：全部显示',
    '月视图模式：仅当前月份',
    '月视图模式：自动填充',
  ];

  static const _funcActions = <String>[
    '展开日历布局',
    '收缩日历布局',
    '上一页',
    '下一页',
    '返回今天',
    '限制日期范围',
    '显示日期范围',
  ];

  @override
  void initState() {
    super.initState();
    final now = CalendarDateUtils.stripTime(DateTime.now());
    _controller = CalendarController(
      focusedDay: now,
      minDate: DateTime(1, 1, 1),
      maxDate: DateTime(9999, 12, 31),
      markers: _buildMarkers(now.year, now.month),
    );
    _controller.setWeekStart(DateTime.sunday);
    _yearPanelYear = now.year;
  }

  Map<DateTime, List<CalendarMarker>> _buildMarkers(int year, int month) {
    final specs = <(int, int, String)>[
      (1, 0xFF40DB25, '假'),
      (19, 0xFF40DB25, '码'),
      (26, 0xFF40DB25, '议'),
      (28, 0xFF40DB25, '码'),
    ];

    return {
      for (final spec in specs)
        DateTime(year, month, spec.$1): [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
        ],
    };
  }

  void _rebuildMarkersForFocusedMonth() {
    _controller.setMarkers(
      _buildMarkers(_controller.focusedDay.year, _controller.focusedDay.month),
    );
  }

  @override
  void dispose() {
    _interactiveController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FE),
      body: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF7F6FE),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              AnimatedBuilder(
                animation: _interactiveController,
                builder: (context, _) => _buildToolbar(),
              ),
              Visibility(
                visible: _yearMode,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Text(
                    '${_controller.focusedDay.year}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    CalendarInteractiveView(
                      controller: _controller,
                      interactionController: _interactiveController,
                      componentStyle: _componentStyle,
                      yearMode: _yearMode,
                      onFocusedDayChanged: (_) {
                        _rebuildMarkersForFocusedMonth();
                        setState(() {
                          _yearPanelYear = _controller.focusedDay.year;
                        });
                      },
                      onDaySelected: (day) {
                        if (_controller.isDisabled(day)) {
                          _showMessage('${_formatDate(day)}拦截不可点击');
                          return;
                        }
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
                        setState(() {
                          _yearPanelYear = _controller.focusedDay.year;
                        });
                        _showMessage(_calendarToastText(day));
                      },
                      calendarHeight: _calendarRowHeight,
                      weekBarHeight: _weekBarHeight,
                      monthHeaderHeight: _monthHeaderHeight,
                      contentBuilder: (context, scrollController, physics) {
                        return ListView.separated(
                          controller: scrollController,
                          physics: physics,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          itemCount: demoEntries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = demoEntries[index];
                            return _DemoCard(
                              entry: entry,
                              onTap: () => _handleDemoTap(entry),
                            );
                          },
                        );
                      },
                    ),
                    if (_yearMode)
                      _YearOverlay(
                        year: _yearPanelYear,
                        selectedMonth: _controller.focusedDay.month,
                        onPrevYear: () {
                          setState(() {
                            _yearPanelYear -= 1;
                          });
                        },
                        onNextYear: () {
                          setState(() {
                            _yearPanelYear += 1;
                          });
                        },
                        onMonthTap: (month) {
                          _controller.jumpToMonth(
                            DateTime(_yearPanelYear, month, 1),
                          );
                          _rebuildMarkersForFocusedMonth();
                          setState(() {
                            _yearMode = false;
                            _yearPanelYear = _controller.focusedDay.year;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final orientationAsset =
        _interactiveController.pageOrientation ==
            CalendarPageOrientation.horizontal
        ? 'assets/icons/ic_horizontal.png'
        : 'assets/icons/ic_vertical.png';
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 22),
          _SwitchView(
            checked: _yearMode,
            onChanged: (value) {
              setState(() {
                _yearMode = value;
                _yearPanelYear = _controller.focusedDay.year;
              });
            },
          ),
          const Spacer(),
          _ToolbarIconButton(
            asset: orientationAsset,
            onTap: () {
              if (_yearMode) {
                return;
              }
              _interactiveController.togglePageOrientation();
            },
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_expand_list.png',
            onTap: () {
              if (_yearMode) {
                return;
              }
              _interactiveController.toggleFullScreen();
            },
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_func.png',
            onTap: _showFuncDialog,
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_more.png',
            onTap: _showMoreDialog,
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  void _showMoreDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('动态更新'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 280,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _moreActions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_moreActions[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleMoreAction(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFuncDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('功能支持'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 280,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _funcActions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_funcActions[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleFuncAction(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleMoreAction(int which) {
    setState(() {
      switch (which) {
        case 0:
          _controller.setWeekStart(DateTime.sunday);
          break;
        case 1:
          _controller.setWeekStart(DateTime.monday);
          break;
        case 2:
          _controller.setWeekStart(DateTime.saturday);
          break;
        case 3:
          _controller.setSelectionMode(
            _controller.selectionMode == CalendarSelectionMode.single
                ? CalendarSelectionMode.range
                : CalendarSelectionMode.single,
          );
          break;
        case 4:
          _componentStyle = _componentStyle == CalendarComponentStyle.custom
              ? CalendarComponentStyle.meizu
              : CalendarComponentStyle.custom;
          _showMessage(
            _componentStyle == CalendarComponentStyle.meizu
                ? '已切换为魅族周月视图'
                : '已切换为自定义周月视图',
          );
          break;
        case 5:
          _controller.setMonthViewShowMode(MonthViewShowMode.allMonth);
          break;
        case 6:
          _controller.setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
          break;
        case 7:
          _controller.setMonthViewShowMode(MonthViewShowMode.fitMonth);
          break;
      }
    });
  }

  void _handleFuncAction(int which) {
    setState(() {
      switch (which) {
        case 0:
          _interactiveController.expand();
          break;
        case 1:
          _interactiveController.collapse();
          break;
        case 2:
          _controller.previousPage();
          _rebuildMarkersForFocusedMonth();
          _yearPanelYear = _controller.focusedDay.year;
          break;
        case 3:
          _controller.nextPage();
          _rebuildMarkersForFocusedMonth();
          _yearPanelYear = _controller.focusedDay.year;
          break;
        case 4:
          _controller.jumpToDay(CalendarDateUtils.stripTime(DateTime.now()));
          _rebuildMarkersForFocusedMonth();
          _yearPanelYear = _controller.focusedDay.year;
          break;
        case 5:
          _controller.setRange(2018, 7, 1, 2019, 11, 28);
          _rebuildMarkersForFocusedMonth();
          _yearPanelYear = _controller.focusedDay.year;
          break;
        case 6:
          _showMessage(_controller.rangeDescription);
          break;
      }
    });
  }

  String _calendarToastText(DateTime day) {
    return '新历${day.month}月${day.day}日';
  }

  String _formatDate(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _handleDemoTap(DemoEntry entry) {
    switch (entry.indexType) {
      case 8:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RangePage()));
        break;
      default:
        _showMessage('Demo ${entry.title} 待继续还原');
        break;
    }
  }
}

class _SwitchView extends StatelessWidget {
  const _SwitchView({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '月',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '年',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFD4D4D4), width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Image.asset(asset, color: const Color(0xFF333333)),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.entry, required this.onTap});

  final DemoEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 78,
            child: Row(
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(entry.iconAsset),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YearOverlay extends StatelessWidget {
  const _YearOverlay({
    required this.year,
    required this.selectedMonth,
    required this.onPrevYear,
    required this.onNextYear,
    required this.onMonthTap,
  });

  final int year;
  final int selectedMonth;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onMonthTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F6FE),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 22),
                _YearHeaderButton(text: '${year - 1}', onTap: onPrevYear),
                Expanded(
                  child: Center(
                    child: Text(
                      '$year',
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _YearHeaderButton(text: '${year + 1}', onTap: onNextYear),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected = month == selectedMonth;
                return GestureDetector(
                  onTap: () => onMonthTap(month),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: const Color(0xFF128C4B),
                              width: 1.2,
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month月',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                  mainAxisSpacing: 1,
                                  crossAxisSpacing: 1,
                                ),
                            itemCount: 14,
                            itemBuilder: (context, i) {
                              return Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
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
    );
  }
}

class _YearHeaderButton extends StatelessWidget {
  const _YearHeaderButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
      ),
    );
  }
}
