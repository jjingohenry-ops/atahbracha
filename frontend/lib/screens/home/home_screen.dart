import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user.dart';
import '../animals/add_animal_modal.dart';
import '../animals/animals_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reminders/new_reminder_sheet.dart';
import '../marketing/marketing_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    if (authProvider.user != null) {
      await dashboardProvider.fetchDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header Section
                    Container(
                      color: const Color(0xFFF6F8F6).withOpacity(0.8),
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage('https://picsum.photos/seed/profile/40/40'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getTabTitle(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Welcome back, ${user?.firstName ?? 'Farmer'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.notifications),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Main Content - IndexedStack to switch between screens
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          const DashboardTab(),
                          const AnimalsScreen(),
                          const RemindersScreen(),
                          const MarketingScreen(),
                          const SettingsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: _selectedTabIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiChatScreen()),
                    );
                  },
                  backgroundColor: const Color(0xFF13EC5B),
                  foregroundColor: Colors.black87,
                  tooltip: 'AtahBracah AI',
                  child: const Icon(Icons.smart_toy_rounded),
                )
              : _selectedTabIndex == 1
                  ? FloatingActionButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddAnimalModal(),
                        );
                      },
                      backgroundColor: const Color(0xFF13EC5B),
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.add),
                    )
                  : _selectedTabIndex == 2
                      ? FloatingActionButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const NewReminderSheet(),
                            );
                          },
                          backgroundColor: const Color(0xFF13EC5B),
                          foregroundColor: Colors.black87,
                          child: const Icon(Icons.add),
                        )
                      : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  String _getTabTitle() {
    const titles = ['Dashboard', 'Animals', 'Reminders', 'Marketing', 'Settings'];
    return titles[_selectedTabIndex];
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
        // Reload dashboard data when switching to dashboard
        if (index == 0) {
          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
          dashboardProvider.fetchDashboardData();
        }
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
          icon: Icon(Icons.event_note),
          label: 'Reminders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign),
          label: 'Marketing',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }
}
