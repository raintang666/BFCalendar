import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';
import '../../calendar/calendar_controller.dart';
import '../../calendar/calendar_models.dart';
import '../../calendar/calendar_view.dart';
import '../../calendar/date_utils_ext.dart';

class RangePage extends StatefulWidget {
  const RangePage({super.key});

  @override
  State<RangePage> createState() => _RangePageState();
}

class _RangePageState extends State<RangePage> {
  static const _weekLabels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  static const _lineColor = Color(0xFFE7E7E7);
  static const _contentBackground = Color(0xFFF2F2F2);

  late final CalendarController _controller;
  double _calendarItemHeight = 46;

  @override
  void initState() {
    super.initState();
    final today = CalendarDateUtils.stripTime(DateTime.now());
    _controller =
        CalendarController(
            focusedDay: today,
            minDate: DateTime(2004, 1, 1),
            maxDate: DateTime(9999, 12, 31),
          )
          ..setSelectionMode(CalendarSelectionMode.range)
          ..setMonthViewShowMode(MonthViewShowMode.allMonth)
          ..setInterceptBlocked(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            _buildToolbar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalendarView(
                      controller: _controller,
                      pageOrientation: CalendarPageOrientation.horizontal,
                      componentBuilder: const RangeCalendarComponentBuilder(),
                      calendarHeight: _calendarItemHeight,
                      weekBarHeight: 40,
                      monthHeaderHeight: 0,
                      handleDaySelection: true,
                      onDaySelected: (_) {},
                      onSelectOutOfRange: _handleSelectOutOfRange,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: _lineColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final start = _controller.rangeSelection.start;
                          final end = _controller.rangeSelection.end;
                          return Row(
                            children: [
                              Expanded(
                                child: _DateInfoColumn(
                                  label: start == null
                                      ? '开始日期'
                                      : _weekdayLabel(start),
                                  value: start == null
                                      ? ''
                                      : _monthDayLabel(start),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 76,
                                color: _lineColor,
                              ),
                              Expanded(
                                child: _DateInfoColumn(
                                  label: end == null
                                      ? '结束日期'
                                      : _weekdayLabel(end),
                                  value: end == null ? '' : _monthDayLabel(end),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: _lineColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'min range = ${_controller.minSelectRange}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'max range = ${_controller.maxSelectRange}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Material(
                color: _contentBackground,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _handleCommit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        '提交',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildToolbar() {
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '范围选择',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _ToolbarIcon(
            asset: 'assets/icons/ic_clear.png',
            padding: const EdgeInsets.all(7),
            marginRight: 12,
            onTap: _handleClear,
          ),
          _ToolbarIcon(
            asset: 'assets/icons/ic_reduce.png',
            padding: const EdgeInsets.all(6),
            marginRight: 12,
            onTap: _handleReduce,
          ),
          _ToolbarIcon(
            asset: 'assets/icons/ic_increase.png',
            padding: const EdgeInsets.all(8),
            marginRight: 16,
            onTap: _handleIncrease,
          ),
        ],
      ),
    );
  }

  void _handleClear() {
    _controller.clearSelection();
  }

  void _handleReduce() {
    setState(() {
      _calendarItemHeight = (_calendarItemHeight - 8).clamp(46, 90).toDouble();
    });
  }

  void _handleIncrease() {
    setState(() {
      _calendarItemHeight = (_calendarItemHeight + 8).clamp(46, 90).toDouble();
    });
  }

  void _handleSelectOutOfRange(
    DateTime day,
    CalendarRangeLimitViolation violation,
  ) {
    final message = violation == CalendarRangeLimitViolation.belowMinRange
        ? '${_fullDateLabel(day)} 小于最小选择范围'
        : '${_fullDateLabel(day)} 超过最大选择范围';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _handleCommit() {
    final dates = _controller.selectedRangeDates;
    if (dates.isEmpty) {
      return;
    }
    final start = dates.first;
    final end = dates.last;
    final message =
        '选择了${dates.length}个日期: ${_fullDateLabel(start)} —— ${_fullDateLabel(end)}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  String _weekdayLabel(DateTime date) {
    return _weekLabels[date.weekday % 7];
  }

  String _monthDayLabel(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  String _fullDateLabel(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateInfoColumn extends StatelessWidget {
  const _DateInfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else
          const SizedBox(height: 37),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.asset,
    required this.padding,
    required this.onTap,
    required this.marginRight,
  });

  final String asset;
  final EdgeInsets padding;
  final VoidCallback onTap;
  final double marginRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: marginRight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: padding,
              child: Image.asset(asset, color: const Color(0xFF333333)),
            ),
          ),
        ),
      ),
    );
  }
}
