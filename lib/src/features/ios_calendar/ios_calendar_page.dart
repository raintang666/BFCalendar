import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lunar/calendar/Lunar.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import 'ios_calendar_components.dart';

class IOSCalendarPage extends StatefulWidget {
  const IOSCalendarPage({super.key});

  @override
  State<IOSCalendarPage> createState() => _IOSCalendarPageState();
}

class _IOSCalendarPageState extends State<IOSCalendarPage> {
  late final CalendarController _calendarController;
  late final CalendarInteractiveController _interactiveController;
  late final CalendarMonthYearController _monthYearController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _colorController = TextEditingController(
    text: '#FF0000',
  );
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _colorFocusNode = FocusNode();
  final List<_IOSEvent> _events = <_IOSEvent>[];
  bool _searchVisible = false;
  bool _addVisible = false;
  bool _canAdd = false;
  Color _pickedColor = const Color(0xFFFF0000);

  @override
  void initState() {
    super.initState();
    final now = CalendarDateUtils.stripTime(DateTime.now());
    _calendarController = CalendarController(
      focusedDay: now,
      minDate: DateTime(1),
      maxDate: DateTime(2099, 12, 31),
    )..setWeekStart(DateTime.sunday);
    _calendarController.setInterceptBlocked(false);
    _interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.vertical,
    );
    _monthYearController = CalendarMonthYearController();
    _titleController.addListener(_validateAddForm);
    _colorController.addListener(_handleColorTextChanged);
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _interactiveController.dispose();
    _monthYearController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _colorController.dispose();
    _searchFocusNode.dispose();
    _titleFocusNode.dispose();
    _colorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: !_addVisible && !_searchVisible,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_addVisible) {
          _closeAddLayout();
        } else if (_searchVisible) {
          _hideSearch();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              transformAlignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..translateByDouble(0.0, _addVisible ? 56.0 : 0.0, 0.0, 1.0)
                ..scaleByDouble(_addVisible ? 0.9 : 1.0, 1.0, 1.0, 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_addVisible ? 18 : 0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  _buildToolbar(),
                  Expanded(child: _buildCalendarBody()),
                  _buildBottomBar(bottomPadding),
                ],
              ),
            ),
            if (_searchVisible) _buildSearchOverlay(topPadding),
            _buildAddOverlay(topPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _calendarController,
        _interactiveController,
        _monthYearController,
      ]),
      builder: (context, _) {
        return SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 6),
              _IOSIconButton(
                icon: CupertinoIcons.chevron_left,
                onTap: _handleTitleTap,
                size: 32,
                iconSize: 26,
              ),
              GestureDetector(
                onTap: _handleTitleTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 52,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _toolbarTitle,
                      style: const TextStyle(
                        color: Color(0xFFFF0000),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _IOSIconButton(
                icon: _interactiveController.isCollapsed
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_up,
                onTap: () {
                  if (_monthYearController.isYearMode) {
                    return;
                  }
                  _interactiveController.isCollapsed
                      ? _interactiveController.expand()
                      : _interactiveController.collapse();
                },
                filled: _interactiveController.isCollapsed,
              ),
              const SizedBox(width: 18),
              _IOSIconButton(icon: CupertinoIcons.search, onTap: _showSearch),
              const SizedBox(width: 18),
              _IOSIconButton(icon: CupertinoIcons.add, onTap: _showAddLayout),
              const SizedBox(width: 18),
            ],
          ),
        );
      },
    );
  }

  String get _toolbarTitle {
    if (_monthYearController.isYearMode) {
      return '${_monthYearController.visibleYear}';
    }
    final selected = _calendarController.focusedDay;
    if (_interactiveController.isExpanded) {
      return '${selected.year}年';
    }
    return '${selected.year}年${selected.month}月';
  }

  Widget _buildCalendarBody() {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: CalendarMonthYearView(
        controller: _calendarController,
        interactionController: _interactiveController,
        monthYearController: _monthYearController,
        pageOrientation: CalendarPageOrientation.vertical,
        calendarHeight: 62,
        weekBarHeight: 28,
        monthHeaderHeight: 52,
        componentBuilder: const IOSCalendarComponentBuilder(),
        onDaySelected: (day) {
          _calendarController.selectDay(day);
          setState(() {});
        },
        onFocusedDayChanged: (_) => setState(() {}),
        onMonthSelected: (_) => setState(() {}),
        contentBuilder: (context, scrollController, physics) {
          return AnimatedBuilder(
            animation: _interactiveController,
            builder: (context, _) {
              return ListView.builder(
                controller: scrollController,
                physics: physics,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                itemCount: 25 + (_interactiveController.isCollapsed ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_interactiveController.isCollapsed && index == 0) {
                    return _DateDetailHeader(
                      day: _calendarController.focusedDay,
                    );
                  }
                  final hour =
                      index - (_interactiveController.isCollapsed ? 1 : 0);
                  return SizedBox(
                    height: 56,
                    child: CustomPaint(painter: _TimelineHourPainter(hour)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    return Container(
      height: 62 + bottomPadding,
      color: const Color(0xFFF9F9F9),
      child: Column(
        children: [
          Container(height: 0.5, color: const Color(0xFFC6C6C6)),
          SizedBox(
            height: 61.5,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BottomAction(text: '今天', onTap: _scrollToToday),
                ),
                const Center(child: _BottomAction(text: '日历')),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _BottomAction(text: '收件箱'),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(double topPadding) {
    return GestureDetector(
      onTap: _hideSearch,
      child: Container(
        color: const Color(0x80000000),
        child: Column(
          children: [
            Container(height: topPadding, color: Colors.white),
            Container(
              height: 66,
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 22),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: CupertinoTextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        placeholder: 'xxxx-xx-xx',
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color: Color(0xFFA6A6A6),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 10, right: 12),
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSubmitted: (_) => _submitSearch(),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: const Size(42, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: _hideSearch,
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Color(0xFFFF0000), fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const Expanded(child: SizedBox.expand()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOverlay(double topPadding) {
    return IgnorePointer(
      ignoring: !_addVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _addVisible ? 1 : 0,
        child: Container(
          color: const Color(0x80000000),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            offset: _addVisible ? Offset.zero : const Offset(0, 1),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding + 70),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Material(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildAddToolbar(),
                      const _DividerLine(),
                      const _SectionGap(height: 22),
                      const _DividerLine(),
                      _AddTextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        hint: '标题',
                        maxLength: 14,
                        bold: true,
                      ),
                      const _IndentedDividerLine(),
                      _AddTextField(
                        controller: _contentController,
                        hint: '内容',
                        maxLength: 28,
                        color: Color(0xFF666666),
                      ),
                      const _DividerLine(),
                      const _SectionGap(height: 38),
                      const _DividerLine(),
                      _InfoRow(label: '日期', value: _selectedDateText),
                      const _IndentedDividerLine(),
                      _ColorRow(
                        color: _pickedColor,
                        controller: _colorController,
                        focusNode: _colorFocusNode,
                      ),
                      const _DividerLine(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToolbar() {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          CupertinoButton(
            minimumSize: const Size(42, 42),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            onPressed: _closeAddLayout,
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFFFF0000), fontSize: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '新建日程',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          CupertinoButton(
            minimumSize: const Size(42, 42),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            onPressed: _canAdd ? _addEvent : null,
            child: Text(
              '添加',
              style: TextStyle(
                color: _canAdd
                    ? const Color(0xFF333333)
                    : const Color(0xFF9F9F9F),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _selectedDateText {
    final day = _calendarController.focusedDay;
    return '${day.year}年${_two(day.month)}月${_two(day.day)}日';
  }

  void _handleTitleTap() {
    if (!_interactiveController.isExpanded) {
      _interactiveController.expand();
      return;
    }
    if (_monthYearController.isYearMode) {
      return;
    }
    _monthYearController.showYearMode();
  }

  void _showSearch() {
    setState(() {
      _searchVisible = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _hideSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _searchVisible = false;
    });
  }

  void _submitSearch() {
    final parsed = _parseDate(_searchController.text.trim());
    if (parsed == null) {
      _showMessage('无效的输入');
      return;
    }
    _calendarController.selectDay(parsed);
    _hideSearch();
    setState(() {});
  }

  void _showAddLayout() {
    setState(() {
      _addVisible = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 360), () {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  void _closeAddLayout() {
    FocusScope.of(context).unfocus();
    setState(() {
      _addVisible = false;
    });
  }

  void _addEvent() {
    final color = _parseHexColor(_colorController.text.trim());
    if (color == null) {
      _showMessage('颜色格式错误');
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('标题不能为空');
      return;
    }
    final event = _IOSEvent(
      date: CalendarDateUtils.stripTime(_calendarController.focusedDay),
      title: title,
      content: _contentController.text.trim(),
      color: color,
    );
    setState(() {
      _events.add(event);
      _titleController.clear();
      _contentController.clear();
      _colorController.text = '#FF0000';
      _pickedColor = const Color(0xFFFF0000);
      _addVisible = false;
      _syncMarkers();
    });
  }

  void _scrollToToday() {
    _calendarController.selectDay(CalendarDateUtils.stripTime(DateTime.now()));
    setState(() {});
  }

  void _syncMarkers() {
    final markers = <DateTime, List<CalendarMarker>>{};
    for (final event in _events) {
      markers
          .putIfAbsent(event.date, () => <CalendarMarker>[])
          .add(CalendarMarker(label: event.title, color: event.color));
    }
    _calendarController.setMarkers(markers);
  }

  void _validateAddForm() {
    final next =
        _titleController.text.trim().isNotEmpty &&
        _parseHexColor(_colorController.text.trim()) != null;
    if (next != _canAdd) {
      setState(() {
        _canAdd = next;
      });
    }
  }

  void _handleColorTextChanged() {
    final color = _parseHexColor(_colorController.text.trim());
    if (color != null && color != _pickedColor) {
      setState(() {
        _pickedColor = color;
      });
    }
    _validateAddForm();
  }

  DateTime? _parseDate(String input) {
    final parts = input.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day ||
        year < 1 ||
        year > 2099) {
      return null;
    }
    return CalendarDateUtils.stripTime(candidate);
  }

  Color? _parseHexColor(String input) {
    final match = RegExp(r'^#[0-9a-fA-F]{6}$').firstMatch(input);
    if (match == null) {
      return null;
    }
    return Color(int.parse('FF${input.substring(1)}', radix: 16));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

class _DateDetailHeader extends StatelessWidget {
  const _DateDetailHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final lunar = Lunar.fromDate(day);
    return SizedBox(
      height: 32,
      child: Center(
        child: Text(
          '${day.year}年${day.month}月${day.day}日 ${_weekdayText(day)} '
          '${lunar.getYearInGanZhi()}年${lunar.getMonthInChinese()}月'
          '${lunar.getDayInChinese()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TimelineHourPainter extends CustomPainter {
  const _TimelineHourPainter(this.hour);

  final int hour;

  @override
  void paint(Canvas canvas, Size size) {
    const marginH = 16.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${_two(hour % 24)}:00',
        style: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(marginH, 8));
    final linePaint = Paint()
      ..color = const Color(0xFFCACACA)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final lineY = marginH / 1.6;
    canvas.drawLine(
      Offset(textPainter.width + marginH * 1.5, lineY),
      Offset(size.width - marginH, lineY),
      linePaint,
    );

    final now = DateTime.now();
    if (hour == now.hour) {
      final timePainter = TextPainter(
        text: TextSpan(
          text: '${_two(now.hour)}:${_two(now.minute)}',
          style: const TextStyle(
            color: Color(0xFFFF0000),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = marginH * 2;
      timePainter.paint(canvas, Offset(marginH * 1.5, y - 10));
      final redPaint = Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 1;
      final startX = textPainter.width + marginH * 1.5;
      canvas.drawLine(
        Offset(startX, y),
        Offset(size.width - marginH, y),
        redPaint,
      );
      canvas.drawCircle(Offset(startX + 6, y), 3, redPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineHourPainter oldDelegate) {
    return oldDelegate.hour != hour;
  }
}

class _IOSIconButton extends StatelessWidget {
  const _IOSIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 32,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size(size, size),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF0000) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: filled ? Colors.white : const Color(0xFFFF0000),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: const Size(62, 62),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFF0000),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AddTextField extends StatelessWidget {
  const _AddTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.maxLength,
    this.bold = false,
    this.color = const Color(0xFF333333),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int? maxLength;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: hint,
        maxLength: maxLength,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.color,
    required this.controller,
    required this.focusNode,
  });

  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              '标注颜色',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Container(width: 24, height: 24, color: color),
          SizedBox(
            width: 118,
            height: 42,
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 7,
              padding: const EdgeInsets.only(right: 22, left: 10),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: const Color(0xFFE6E6E6));
  }
}

class _IndentedDividerLine extends StatelessWidget {
  const _IndentedDividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 22),
      child: _DividerLine(),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: const Color(0xFFEFF0F5));
  }
}

class _IOSEvent {
  const _IOSEvent({
    required this.date,
    required this.title,
    required this.content,
    required this.color,
  });

  final DateTime date;
  final String title;
  final String content;
  final Color color;
}

String _two(int value) => value < 10 ? '0$value' : '$value';

String _weekdayText(DateTime day) {
  return switch (day.weekday) {
    DateTime.monday => '周一',
    DateTime.tuesday => '周二',
    DateTime.wednesday => '周三',
    DateTime.thursday => '周四',
    DateTime.friday => '周五',
    DateTime.saturday => '周六',
    _ => '周日',
  };
}
