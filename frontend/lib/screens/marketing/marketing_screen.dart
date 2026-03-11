import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _tiktokTemplates = [
    {
      'id': '1',
      'title': 'Healthy Boer Goat for sale',
      'badge': 'Flash Sale',
      'badgeColor': const Color(0xFF13EC5B),
      'description': 'High conversion overlay • Upbeat music',
      'imageUrl': 'https://picsum.photos/seed/goat1/300/533.jpg',
    },
    {
      'id': '2',
      'title': 'New Stock Arrival Today',
      'badge': 'Daily Log',
      'badgeColor': const Color(0xFF13EC5B),
      'badgeBg': const Color(0xFF13EC5B).withOpacity(0.2),
      'description': 'Vlog style • ASMR sounds',
      'imageUrl': 'https://picsum.photos/seed/livestock1/300/533.jpg',
    },
    {
      'id': '3',
      'title': '3 Tips for Better Wool',
      'badge': 'Expert Tips',
      'badgeColor': Colors.blue,
      'description': 'Educational • Captions included',
      'imageUrl': 'https://picsum.photos/seed/sheep1/300/533.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return user == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      _buildHeroSection(),

                      // Tabs
                      _buildTabs(),

                      // Content area with fixed height so TabBarView doesn't expand indefinitely
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTikTokTemplates(),
                            _buildInstagramTemplates(),
                          ],
                        ),
                      ),

                      // Stats Section
                      _buildStatsSection(),
                    ],
                  ),
                ),
              );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 864) {
            // Desktop layout
            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://picsum.photos/seed/farm/400/300.jpg'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: const Color(0xFF13EC5B).withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: 'Boost Your '),
                            TextSpan(
                              text: 'Livestock Sales',
                              style: TextStyle(color: Color(0xFF13EC5B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create high-converting content for TikTok and Instagram in seconds. Select a template and start selling.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF13EC5B),
                                foregroundColor: const Color(0xFF102216),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'New Campaign',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF13EC5B).withOpacity(0.1),
                                foregroundColor: const Color(0xFF13EC5B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: const Color(0xFF13EC5B).withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'Tutorials',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout
            return Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://picsum.photos/seed/farm/400/200.jpg'),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: const Color(0xFF13EC5B).withOpacity(0.1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(text: 'Boost Your '),
                      TextSpan(
                        text: 'Livestock Sales',
                        style: TextStyle(color: Color(0xFF13EC5B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create high-converting content for TikTok and Instagram in seconds. Select a template and start selling.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13EC5B),
                        foregroundColor: const Color(0xFF102216),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: const Text(
                        'New Campaign',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF13EC5B).withOpacity(0.1),
                        foregroundColor: const Color(0xFF13EC5B),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: const Color(0xFF13EC5B).withOpacity(0.2),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: const Text(
                        'Tutorials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF13EC5B).withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF13EC5B),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF13EC5B),
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.video_library),
            text: 'TikTok Templates',
          ),
          Tab(
            icon: Icon(Icons.photo_library),
            text: 'Instagram Templates',
          ),
        ],
      ),
    );
  }

  Widget _buildTikTokTemplates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trending TikTok Styles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View all'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF13EC5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 9 / 16,
            ),
            itemCount: _tiktokTemplates.length,
            itemBuilder: (context, index) {
              final template = _tiktokTemplates[index];
              return _buildTemplateCard(template);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF13EC5B).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with overlay
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(template['imageUrl'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Content overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: template['badgeBg'] ?? (template['badgeColor'] as Color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template['badge'] as String,
                          style: TextStyle(
                            color: template['badgeBg'] != null 
                                ? template['badgeColor'] as Color 
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['description'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Button
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle),
                label: const Text('Open in TikTok'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramTemplates() {
    return const Center(
      child: Text(
        'Instagram templates coming soon...',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13EC5B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF13EC5B).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '12k+',
                label: 'Templates Used',
              ),
              _StatItem(
                value: '85%',
                label: 'Higher Sales',
              ),
              _StatItem(
                value: '2M',
                label: 'Total Views',
              ),
              _StatItem(
                value: '4.9',
                label: 'User Rating',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF13EC5B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
