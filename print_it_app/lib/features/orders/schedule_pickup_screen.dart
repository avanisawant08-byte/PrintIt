import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // Generate the next 7 days for selection
  List<DateTime> get _availableDates {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
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
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isScheduled = orderState.pickupType == 'scheduled';
    final files = orderState.files;
    final totalDocs = files.length;
    final totalPrice = orderState.amountTotal;

    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF051424).withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8AEBFF)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Velocity',
          style: TextStyle(
            color: Color(0xFF8AEBFF),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Icon(
                isScheduled ? Icons.calendar_today : Icons.speed, 
                color: const Color(0xFF22D3EE), 
                size: 18
              ),
              const SizedBox(width: 6),
              Text(
                isScheduled ? 'SCHEDULED' : 'EXPRESS MODE',
                style: const TextStyle(
                  color: Color(0xFF8AEBFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
              children: [
                // Toggle Section
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2B3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(orderProvider.notifier).setPickupType('express');
                            ref.read(orderProvider.notifier).setPickupTime(null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isScheduled ? const Color(0xFF22D3EE) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: !isScheduled ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Express (Now)',
                                  style: TextStyle(
                                    color: !isScheduled ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(orderProvider.notifier).setPickupType('scheduled');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isScheduled ? const Color(0xFF22D3EE) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: isScheduled ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Scheduled',
                                  style: TextStyle(
                                    color: isScheduled ? const Color(0xFF005763) : const Color(0xFFBBC9CD),
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 32),

                if (!isScheduled) ...[
                  // Estimate Banner
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8AEBFF).withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22D3EE).withValues(alpha: _glowAnimation.value * 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
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
                                    color: const Color(0xFF8AEBFF).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.timer, color: Color(0xFF8AEBFF)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ESTIMATED READINESS',
                                      style: TextStyle(
                                        color: Color(0xFF8AEBFF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '5-10 Minutes',
                                      style: TextStyle(
                                        color: Color(0xFFD4E4FA),
                                        fontSize: 18,
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
                            )
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  // Scheduled Date and Time Picker
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF8AEBFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Horizontal Date Selector
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
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
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF22D3EE) : const Color(0xFF1E293B).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF22D3EE) : const Color(0xFF3C494C).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF005763) : const Color(0xFFD4E4FA),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('E').format(date),
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF005763).withValues(alpha: 0.8) : const Color(0xFFBBC9CD),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vertical Time Slot Selector
                  Column(
                    children: _availableTimeSlots.isEmpty 
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No slots available for this date.', style: TextStyle(color: Color(0xFFBBC9CD))),
                          )
                        ]
                      : _availableTimeSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedTimeSlot = slot;
                                });
                                String startTimeStr = slot.split(' to ')[0];
                                String periodStr = slot.split(' ')[3];
                                int hour = int.parse(startTimeStr.split(':')[0]);
                                int minute = int.parse(startTimeStr.split(':')[1]);
                                
                                if (periodStr == 'PM' && hour != 12) hour += 12;
                                if (periodStr == 'AM' && hour == 12) hour = 0;
                                
                                final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
                                ref.read(orderProvider.notifier).setPickupTime(dt);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF22D3EE) : const Color(0xFF3C494C).withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      slot,
                                      style: TextStyle(
                                        color: const Color(0xFFD4E4FA),
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF22D3EE) : const Color(0xFFBBC9CD),
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected 
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF22D3EE),
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
                  ),
                  const SizedBox(height: 32),
                ],

                // Pricing & Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PRICE',
                              style: TextStyle(
                                color: Color(0xFFBBC9CD),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3C494C).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUEUE STATUS',
                              style: TextStyle(
                                color: Color(0xFFBBC9CD),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF8AEBFF), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Low Traffic',
                                  style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'READY TO PRINT',
                      style: TextStyle(
                        color: Color(0xFFBBC9CD),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '$totalDocs Document${totalDocs == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF8AEBFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: files.map((fileEntry) {
                    final sizeMb = fileEntry.file.size / (1024 * 1024);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8AEBFF).withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8AEBFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description, color: Color(0xFF8AEBFF), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileEntry.file.name,
                                  style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sizeMb.toStringAsFixed(2)} MB • READY',
                                  style: const TextStyle(color: Color(0xFF859397), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check, color: Color(0xFF22D3EE), size: 20),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Fixed Bottom Action Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 16 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF051424).withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Total', style: TextStyle(color: Color(0xFFBBC9CD), fontSize: 12)),
                          Text('₹${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF8AEBFF), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22D3EE),
                            foregroundColor: const Color(0xFF005763),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: files.isEmpty ? null : () {
                            if (isScheduled && _selectedTimeSlot == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a time slot'),
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
                              Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
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
        // Create an offset wave effect
        double val = _glowAnimation.value + (index * 0.3);
        if (val > 1.0) val -= 1.0;
        
        return Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF8AEBFF).withValues(alpha: val),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }
    );
  }
}
