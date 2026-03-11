import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F8F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F8F6),
            body: Center(child: Text('Error: ${provider.error}')),
          );
        }
        final stats = provider.stats ?? {};
        final aiInsights = provider.aiInsights ?? {};
        final alerts = provider.alerts ?? [];
        final recentActivity = provider.recentActivity ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(title: 'Total Animals', value: stats['totalAnimals']?.toString() ?? '-'),
                  _StatCard(title: 'Pregnant', value: stats['pregnant']?.toString() ?? '-'),
                  _StatCard(title: 'Sick', value: stats['sick']?.toString() ?? '-'),
                  _StatCard(title: 'Upcoming', value: stats['upcomingTasks']?.toString() ?? '-'),
                ],
              ),
              const SizedBox(height: 24),
              // AI Insights
              if (aiInsights['message'] != null)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(child: Text(aiInsights['message'])),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Alerts
              Text('Urgent Alerts', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final alert = alerts[i];
                    return Card(
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (alert['count'] != null) Text('${alert['count']} ${alert['label'] ?? ''}'),
                            if (alert['next'] != null) Text('Next: ${alert['next']}'),
                            if (alert['label'] != null && alert['count'] == null) Text(alert['label']),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Recent Activity
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...recentActivity.map<Widget>((activity) => Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle),
                  title: Text(activity['activity'] ?? ''),
                  subtitle: Text(activity['animal']?['name'] ?? ''),
                  trailing: Text(activity['time']?.toString().substring(0, 16) ?? ''),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
