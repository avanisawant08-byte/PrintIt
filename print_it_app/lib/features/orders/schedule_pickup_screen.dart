import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/ambient_background.dart';
import 'order_provider.dart';

class SchedulePickupScreen extends ConsumerStatefulWidget {
  const SchedulePickupScreen({super.key});

  @override
  ConsumerState<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _TimeSlotItem {
  final String display;
  final DateTime dateTime;

  const _TimeSlotItem({required this.display, required this.dateTime});
}

class _SchedulePickupScreenState extends ConsumerState<SchedulePickupScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  String? _selectedTimeSlot;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    final orderNotifier = ref.read(orderProvider.notifier);
    if (ref.read(orderProvider).files.isEmpty) {
      orderNotifier.addDemoFileIfEmpty();
    }
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Smart default date selection: if today has no remaining slots, default to tomorrow!
    final now = DateTime.now();
    final todaySlots = _getTimeSlotsForDate(now);
    if (todaySlots.isEmpty) {
      _selectedDate = now.add(const Duration(days: 1));
    } else {
      _selectedDate = now;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // Generate the next 10 days for selection
  List<DateTime> get _availableDates {
    return List.generate(10, (index) => DateTime.now().add(Duration(days: index)));
  }

  // Generate available time slots based on the selected date (strictly future-only for today)
  List<_TimeSlotItem> _getTimeSlotsForDate(DateTime date) {
    final List<_TimeSlotItem> slots = [];
    final DateTime now = DateTime.now();
    final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    // Minimum buffer: at least 20 minutes from now for same-day preparation
    final DateTime minSlotTime = now.add(const Duration(minutes: 20));

    // Shop hours: 9:00 AM (09:00) to 9:00 PM (21:00)
    for (int hour = 9; hour < 21; hour++) {
      for (int minute in [0, 30]) {
        final slotStart = DateTime(date.year, date.month, date.day, hour, minute);
        final slotEnd = slotStart.add(const Duration(minutes: 30));

        // Skip any slot that has already started or is within the buffer on today
        if (isToday && slotStart.isBefore(minSlotTime)) {
          continue;
        }

        final startPeriod = slotStart.hour >= 12 ? 'PM' : 'AM';
        final endPeriod = slotEnd.hour >= 12 ? 'PM' : 'AM';
        final startDisplayHour = slotStart.hour > 12 ? slotStart.hour - 12 : (slotStart.hour == 0 ? 12 : slotStart.hour);
        final endDisplayHour = slotEnd.hour > 12 ? slotEnd.hour - 12 : (slotEnd.hour == 0 ? 12 : slotEnd.hour);
        final startMinuteStr = slotStart.minute.toString().padLeft(2, '0');
        final endMinuteStr = slotEnd.minute.toString().padLeft(2, '0');

        final String display;
        if (startPeriod == endPeriod) {
          display = '$startDisplayHour:$startMinuteStr to $endDisplayHour:$endMinuteStr $startPeriod';
        } else {
          display = '$startDisplayHour:$startMinuteStr $startPeriod to $endDisplayHour:$endMinuteStr $endPeriod';
        }

        slots.add(_TimeSlotItem(display: display, dateTime: slotStart));
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isScheduled = orderState.pickupType == 'scheduled';
    final files = orderState.files;
    final totalDocs = files.length;
    final totalPrice = orderState.amountTotal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Modes',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                  : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                    : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isScheduled ? Icons.calendar_today_outlined : Icons.bolt,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isScheduled ? 'SCHEDULED' : 'EXPRESS',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                  children: [
                    // Mode Selector Pill Tabs matching Stitch
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF121929).withValues(alpha: 0.90)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.50)
                              : Colors.white.withValues(alpha: 0.75),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Express Tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ref.read(orderProvider.notifier).setPickupType('express');
                                ref.read(orderProvider.notifier).setPickupTime(null);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isScheduled ? const Color(0xFF0284C7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: !isScheduled
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bolt,
                                      color: !isScheduled
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Express (Now)',
                                      style: TextStyle(
                                        color: !isScheduled
                                            ? Colors.white
                                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)),
                                        fontSize: 13,
                                        fontWeight: !isScheduled ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Scheduled Tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ref.read(orderProvider.notifier).setPickupType('scheduled');
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isScheduled ? const Color(0xFF0284C7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isScheduled
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: isScheduled
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scheduled',
                                      style: TextStyle(
                                        color: isScheduled
                                            ? Colors.white
                                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)),
                                        fontSize: 13,
                                        fontWeight: isScheduled ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!isScheduled) ...[
                      // Express Mode: Estimated Readiness Card
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF121929).withValues(alpha: 0.90)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155).withValues(alpha: 0.50)
                                    : Colors.white.withValues(alpha: 0.75),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: _glowAnimation.value * 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                            : const Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.timer_outlined,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ESTIMATED READINESS',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '5-10 Minutes',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildPulsingBar(0, isDark),
                                    const SizedBox(width: 4),
                                    _buildPulsingBar(1, isDark),
                                    const SizedBox(width: 4),
                                    _buildPulsingBar(2, isDark),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Scheduled Mode: Month Label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Horizontal Date Carousel matching Stitch
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableDates.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final date = _availableDates[index];
                            final isSelected = _selectedDate.day == date.day &&
                                _selectedDate.month == date.month &&
                                _selectedDate.year == date.year;
                            final now = DateTime.now();
                            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                            final dateSlots = _getTimeSlotsForDate(date);
                            final isClosed = isToday && dateSlots.isEmpty;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedTimeSlot = null;
                                  ref.read(orderProvider.notifier).setPickupTime(null);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 58,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0284C7)
                                      : (isDark ? const Color(0xFF121929).withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.88)),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : (isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75)),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      )
                                    else
                                      BoxShadow(
                                        color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                        blurRadius: 8,
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isClosed
                                                ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                                : (isDark ? Colors.white : const Color(0xFF0F172A))),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isToday && isClosed ? 'Closed' : DateFormat('E').format(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : (isClosed
                                                ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.8) : const Color(0xFFDC2626))
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                        fontSize: 11,
                                        fontWeight: isClosed ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Available Pickup Slots Label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'AVAILABLE PICKUP SLOTS',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      // Time Slot Radio Cards (Filtered strictly for future slots)
                      Builder(
                        builder: (context) {
                          final currentSlots = _getTimeSlotsForDate(_selectedDate);

                          if (currentSlots.isEmpty) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF121929).withValues(alpha: 0.90)
                                    : Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.nightlight_round,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Shop Closed For Today',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'All pickup slots for today have ended. The shop reopens tomorrow morning at 9:00 AM.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final tomorrow = DateTime.now().add(const Duration(days: 1));
                                      setState(() {
                                        _selectedDate = tomorrow;
                                        _selectedTimeSlot = null;
                                        ref.read(orderProvider.notifier).setPickupTime(null);
                                      });
                                    },
                                    icon: const Icon(Icons.calendar_today_rounded, size: 15),
                                    label: Text(
                                      'Select Tomorrow (${DateFormat('d MMM').format(DateTime.now().add(const Duration(days: 1)))})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: currentSlots.map((slotItem) {
                              final isSelected = _selectedTimeSlot == slotItem.display;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTimeSlot = slotItem.display;
                                    });
                                    ref.read(orderProvider.notifier).setPickupTime(slotItem.dateTime);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0284C7)
                                          : (isDark ? const Color(0xFF121929).withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.88)),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0284C7)
                                            : (isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75)),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          )
                                        else
                                          BoxShadow(
                                            color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                            blurRadius: 8,
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          slotItem.display,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Center(
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF0284C7),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Metrics Cards: Total Price & Queue Status
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF121929).withValues(alpha: 0.90)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL PRICE',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF121929).withValues(alpha: 0.90)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QUEUE STATUS',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Low Traffic',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Ready To Print Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'READY TO PRINT',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '$totalDocs Document${totalDocs == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: files.map((fileEntry) {
                        final sizeMb = fileEntry.file.size / (1024 * 1024);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121929).withValues(alpha: 0.90)
                                : Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.75),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0C4A6E).withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileEntry.file.name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${sizeMb.toStringAsFixed(2)} MB • READY',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.check_circle_rounded,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Bar matching Stitch
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0F1D).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Total',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '₹${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          ),
                          onPressed: files.isEmpty
                              ? null
                              : () {
                                  if (isScheduled && _selectedTimeSlot == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select a pickup time slot'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } else {
                                    context.push('/payment');
                                  }
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Proceed to Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
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
    );
  }

  Widget _buildPulsingBar(int index, bool isDark) {
    final barColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        double val = _glowAnimation.value + (index * 0.25);
        if (val > 1.0) val -= 1.0;

        return Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.3 + (val * 0.7)),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}
