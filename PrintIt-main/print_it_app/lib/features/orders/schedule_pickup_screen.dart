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

class _SchedulePickupScreenState extends ConsumerState<SchedulePickupScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
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

  // Generate available time slots based on the selected date
  List<String> get _availableTimeSlots {
    List<String> slots = [];
    DateTime now = DateTime.now();
    bool isToday = _selectedDate.day == now.day && _selectedDate.month == now.month && _selectedDate.year == now.year;

    for (int i = 9; i < 18; i++) {
      if (isToday && i <= now.hour) continue;
      String period1 = i >= 12 ? 'PM' : 'AM';
      int hour1 = i > 12 ? i - 12 : i;
      slots.add('$hour1:00 to $hour1:30 $period1');

      int nextHour = i + 1;
      String nextPeriod = nextHour >= 12 && nextHour < 24 ? 'PM' : 'AM';
      int displayNextHour = nextHour > 12 ? nextHour - 12 : nextHour;
      slots.add('$hour1:30 to $displayNextHour:00 $nextPeriod');
    }

    if (slots.isEmpty) {
      slots = [
        '5:00 to 5:30 PM',
        '5:30 to 6:00 PM',
        '6:00 to 6:30 PM',
      ];
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
                  ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                  : const Color(0xFFE0F7FA).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF22D3EE).withValues(alpha: isDark ? 0.3 : 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isScheduled ? Icons.calendar_today_outlined : Icons.bolt,
                  color: const Color(0xFF0891B2),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isScheduled ? 'SCHEDULED' : 'EXPRESS',
                  style: const TextStyle(
                    color: Color(0xFF0891B2),
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
                            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x1064748B),
                            blurRadius: 10,
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
                                  color: !isScheduled ? const Color(0xFF22D3EE) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: !isScheduled
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
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
                                          ? const Color(0xFF082F49)
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Express (Now)',
                                      style: TextStyle(
                                        color: !isScheduled
                                            ? const Color(0xFF082F49)
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
                                  color: isScheduled ? const Color(0xFF22D3EE) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isScheduled
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
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
                                          ? const Color(0xFF082F49)
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scheduled',
                                      style: TextStyle(
                                        color: isScheduled
                                            ? const Color(0xFF082F49)
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
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22D3EE).withValues(alpha: _glowAnimation.value * 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
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
                                        color: const Color(0xFFCFFAFE),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.4)),
                                      ),
                                      child: const Icon(Icons.timer_outlined, color: Color(0xFF0891B2), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ESTIMATED READINESS',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
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
                                    _buildPulsingBar(0),
                                    const SizedBox(width: 4),
                                    _buildPulsingBar(1),
                                    const SizedBox(width: 4),
                                    _buildPulsingBar(2),
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
                                      ? const Color(0xFF22D3EE)
                                      : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.72)),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF22D3EE)
                                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF22D3EE).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      )
                                    else
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.12) : const Color(0x0C64748B),
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
                                        color: isSelected ? const Color(0xFF082F49) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('E').format(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF082F49).withValues(alpha: 0.9)
                                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
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

                      // Time Slot Radio Cards matching Stitch
                      ..._availableTimeSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
                              try {
                                String startTimeStr = slot.split(' to ')[0];
                                String periodStr = slot.split(' ')[3];
                                int hour = int.parse(startTimeStr.split(':')[0]);
                                int minute = int.parse(startTimeStr.split(':')[1]);

                                if (periodStr == 'PM' && hour != 12) hour += 12;
                                if (periodStr == 'AM' && hour == 12) hour = 0;

                                final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
                                ref.read(orderProvider.notifier).setPickupTime(dt);
                              } catch (_) {}
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF06B6D4).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.92))
                                    : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.72)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF22D3EE)
                                      : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: const Color(0xFF22D3EE).withValues(alpha: 0.25),
                                      blurRadius: 12,
                                    )
                                  else
                                    BoxShadow(
                                      color: isDark ? Colors.black.withValues(alpha: 0.1) : const Color(0x0C64748B),
                                      blurRadius: 6,
                                    ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    slot,
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
                                        color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFCBD5E1),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF06B6D4),
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
                      }),
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
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x1064748B),
                                  blurRadius: 8,
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
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x1064748B),
                                  blurRadius: 8,
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
                                        color: Color(0xFF06B6D4),
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
                                ? const Color(0xFF0F172A).withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.12) : const Color(0x0C64748B),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFFAFE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFF0891B2), size: 20),
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
                              const Icon(Icons.check, color: Color(0xFF06B6D4), size: 20),
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
                        ? const Color(0xFF0A0F1D).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.88),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9),
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
                            backgroundColor: const Color(0xFF22D3EE),
                            foregroundColor: const Color(0xFF082F49),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
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

  Widget _buildPulsingBar(int index) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        double val = _glowAnimation.value + (index * 0.25);
        if (val > 1.0) val -= 1.0;

        return Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.3 + (val * 0.7)),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}
