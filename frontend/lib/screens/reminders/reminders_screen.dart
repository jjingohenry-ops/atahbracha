import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/settings_provider.dart';
import 'new_reminder_sheet.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day; // active day

  @override
  void initState() {
    super.initState();
    // fetch initial reminders for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<RemindersProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      provider.fetchReminders(
        date: DateTime.now(),
        farmId: settingsProvider.activeFarmId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPaintBaselinesEnabled = false;
      debugPaintSizeEnabled = false;
      debugPaintPointersEnabled = false;
      debugPaintLayerBordersEnabled = false;
      debugRepaintRainbowEnabled = false;
      return true;
    }());

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          body: user == null
              ? const LoginScreen()
              : SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Compact calendar week view
                        _buildWeekCalendar(),

                        // Tasks Header
                        _buildTasksHeader(),

                        // Task List
                        Consumer<RemindersProvider>(
                          builder: (context, provider, _) {
                            if (provider.isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (provider.error != null) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[300]!),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 32),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Oops! Unable to Load Reminders',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        provider.error!,
                                        style: TextStyle(fontSize: 14, color: Colors.red[600]),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final settingsProvider =
                                              Provider.of<SettingsProvider>(context, listen: false);
                                          await provider.fetchReminders(
                                            date: provider.selectedDate,
                                            farmId: settingsProvider.activeFarmId,
                                          );
                                        },
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (provider.reminders.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.add_circle_outline,
                                      size: 48,
                                      color: Colors.grey[400]
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No reminders',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add reminder',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return _buildTaskList(provider.reminders);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 3,
            onTap: (index) {
              if (index == 3) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 3)),
                  );
                }
                return;
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen(initialTabIndex: index)),
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                label: 'Animals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu),
                label: 'More',
              ),
            ],
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
          ),
        );
      },
    );
  }

  Widget _buildWeekCalendar() {
    // simple horizontal week view for mobile
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Consumer<RemindersProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isActive = day == _selectedDay;
              final today = DateTime.now().day == day &&
                  DateTime.now().month == _currentMonth.month &&
                  DateTime.now().year == _currentMonth.year;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = day);
                    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                  provider.filterByDate(
                    DateTime(_currentMonth.year, _currentMonth.month, day),
                      farmId: settingsProvider.activeFarmId,
                  );
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF13EC5B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : today ? const Color(0xFF13EC5B) : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['S','M','T','W','T','F','S'][DateTime(_currentMonth.year,_currentMonth.month,day).weekday % 7],
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTasksHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Alarms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => NewReminderSheet(),
                        );
                      },
                      icon: const Icon(Icons.add_circle, size: 16),
                      label: const Text('New Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13EC5B),
                        foregroundColor: const Color(0xFF102216),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Alarms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => NewReminderSheet(),
                        );
                      },
                      icon: const Icon(Icons.add_circle, size: 16),
                      label: const Text('New Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13EC5B),
                        foregroundColor: const Color(0xFF102216),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = items[index];
        // parse backend reminder fields
        final dateStr = task['date'] as String?;
        DateTime? date;
        String timeStr = '';
        if (dateStr != null) {
          date = DateTime.parse(dateStr);
          final hour = date.hour > 12 ? date.hour - 12 : date.hour;
          final minute = date.minute.toString().padLeft(2, '0');
          final suffix = date.hour >= 12 ? 'PM' : 'AM';
          timeStr = '$hour:$minute $suffix';
        }
        final title = task['drugName'] as String? ?? 'Reminder';
        final location = task['dosage'] as String? ?? '';
        final isCompleted = date != null && date.isBefore(DateTime.now());
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Task Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF13EC5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Color(0xFF13EC5B),
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Task Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.grey[400] : const Color(0xFF102216),
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (timeStr.isNotEmpty || location.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  [timeStr, location].where((s) => s.isNotEmpty).join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          
                          // Urgent Badge
                          if (task['urgent'] == true)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C2D12),
                                ),
                              ),
                            ),
                          
                          // Note
                          if (task['note'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sticky_note_2,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      task['note'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
