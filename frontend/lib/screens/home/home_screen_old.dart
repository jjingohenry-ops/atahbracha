import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Atahbracah'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeCard(user),

                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(context),

                      const SizedBox(height: 24),

                      // Dashboard Cards
                      _buildDashboardCards(),

                      const SizedBox(height: 24),

                      // Recent Activity
                      _buildRecentActivity(),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddOptions(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user.firstName}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.role,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.pets,
              label: 'Add Animal',
              color: Colors.blue,
              onTap: () => _navigateToAddAnimal(context),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.restaurant,
              label: 'Feed Log',
              color: Colors.orange,
              onTap: () => _navigateToFeedLog(context),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.medical_services,
              label: 'Health',
              color: Colors.red,
              onTap: () => _navigateToHealth(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              title: 'Total Animals',
              value: '24',
              icon: Icons.pets,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Active Tasks',
              value: '5',
              icon: Icons.task,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              title: 'Health Alerts',
              value: '2',
              icon: Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Feed Due',
              value: '8',
              icon: Icons.restaurant,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activities = [
                {'action': 'Cow #123 fed', 'time': '2 hours ago'},
                {'action': 'Health check completed', 'time': '4 hours ago'},
                {'action': 'New calf born', 'time': '1 day ago'},
              ];
              final activity = activities[index];

              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(activity['action']!),
                subtitle: Text(activity['time']!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to activity details
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAddOption(
                  icon: Icons.pets,
                  label: 'Animal',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAddAnimal(context);
                  },
                ),
                _buildAddOption(
                  icon: Icons.restaurant,
                  label: 'Feed Log',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToFeedLog(context);
                  },
                ),
                _buildAddOption(
                  icon: Icons.medical_services,
                  label: 'Treatment',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToHealth(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.green, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAnimal(BuildContext context) {
    // TODO: Navigate to add animal screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Animal - Coming Soon!')),
    );
  }

  void _navigateToFeedLog(BuildContext context) {
    // TODO: Navigate to feed log screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feed Log - Coming Soon!')),
    );
  }

  void _navigateToHealth(BuildContext context) {
    // TODO: Navigate to health screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health - Coming Soon!')),
    );
  }
}
