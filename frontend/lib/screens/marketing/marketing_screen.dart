import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animals_provider.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(text: 'Kampala');
  final TextEditingController _contactController = TextEditingController();
  String _selectedChannel = 'WhatsApp';
  String? _selectedAnimalId;
  Map<String, dynamic>? _activeTemplate;
  String _generatedCaption = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnimalsProvider>(context, listen: false).fetchAnimals();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _generateDraft(Map<String, dynamic> animal, {Map<String, dynamic>? template}) {
    final name = (animal['name'] ?? 'this animal').toString();
    final type = (animal['type'] ?? 'livestock').toString().toUpperCase();
    final gender = (animal['gender'] ?? '').toString().toUpperCase();
    final age = (animal['age'] ?? '').toString();
    final weight = (animal['weight'] ?? '').toString();
    final notes = (animal['notes'] ?? '').toString();
    final activeTemplate = template ?? _activeTemplate;
    final price = _priceController.text.trim().isEmpty ? 'DM for price' : _priceController.text.trim();
    final location = _locationController.text.trim().isEmpty ? 'your area' : _locationController.text.trim();
    final contact = _contactController.text.trim().isEmpty ? 'Send a message for details' : _contactController.text.trim();

    final summaryBits = <String>[
      if (age.isNotEmpty) '$age months old',
      if (weight.isNotEmpty) '${weight}kg',
      if (gender.isNotEmpty) gender.toLowerCase(),
    ];
    final summary = summaryBits.isEmpty ? '' : ' (${summaryBits.join(', ')})';

    final defaultTone = _selectedChannel == 'TikTok'
        ? 'Quick farm update:'
        : _selectedChannel == 'Instagram'
            ? 'Featured livestock of the day:'
            : 'Available now:';
    final templateHook = (activeTemplate?['hook'] ?? '').toString().trim();
    final channelTone = templateHook.isNotEmpty ? templateHook : defaultTone;
    final templateCta = (activeTemplate?['cta'] ?? '').toString().trim();
    final templateHashtags = (activeTemplate?['hashtags'] ?? '').toString().trim();

    final draft = StringBuffer()
      ..writeln('$channelTone $name - $type$summary.')
      ..writeln('Location: $location')
      ..writeln('Price: $price')
      ..writeln('Why this one stands out: ${notes.isEmpty ? 'healthy and farm-raised with proper care.' : notes}')
      ..writeln('Contact: $contact');

    if (templateCta.isNotEmpty) {
      draft.writeln(templateCta);
    }

    draft
      ..writeln()
      ..writeln(templateHashtags.isNotEmpty
          ? '$templateHashtags #${type.toLowerCase()}'
          : '#Livestock #FarmSales #${type.toLowerCase()} #SmartLivestock');

    setState(() {
      _generatedCaption = draft.toString().trim();
    });
  }

  Future<void> _copyDraft() async {
    if (_generatedCaption.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _generatedCaption.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign draft copied to clipboard')),
    );
  }

  List<Map<String, dynamic>> _normalizedAnimals(List<dynamic> rawAnimals) {
    final normalized = <Map<String, dynamic>>[];
    for (final item in rawAnimals) {
      if (item is Map) {
        final asMap = <String, dynamic>{};
        item.forEach((key, value) {
          asMap[key.toString()] = value;
        });
        normalized.add(asMap);
      }
    }
    return normalized;
  }

  Map<String, dynamic>? _findAnimalById(List<Map<String, dynamic>> animals, String? animalId) {
    if (animalId == null) return null;
    for (final animal in animals) {
      if ((animal['id'] ?? '').toString() == animalId) {
        return animal;
      }
    }
    return null;
  }

  void _applyTemplate(Map<String, dynamic> template) {
    final animalsProvider = Provider.of<AnimalsProvider>(context, listen: false);
    final animals = _normalizedAnimals(animalsProvider.animals);

    setState(() {
      _selectedChannel = (template['platform'] ?? 'TikTok').toString();
      _activeTemplate = template;
      if (_selectedAnimalId == null && animals.isNotEmpty) {
        _selectedAnimalId = (animals.first['id'] ?? '').toString();
      }
    });

    final selectedAnimal = _findAnimalById(animals, _selectedAnimalId) ?? (animals.isNotEmpty ? animals.first : null);
    if (selectedAnimal != null) {
      _generateDraft(selectedAnimal, template: template);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template applied: ${(template['badge'] ?? 'TikTok style').toString()}')),
    );
  }

  Future<void> _openPlatformComposer(Map<String, dynamic> template) async {
    _applyTemplate(template);

    final platform = (template['platform'] ?? 'TikTok').toString();
    final text = _generatedCaption.trim();
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }

    final encoded = Uri.encodeComponent(text);
    final candidates = platform == 'Instagram'
        ? <String>[
            'instagram://camera',
            'https://www.instagram.com/create/select/',
          ]
        : <String>[
            'tiktok://upload?caption=$encoded',
            'https://www.tiktok.com/upload',
          ];

    bool opened = false;
    for (final url in candidates) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (opened) break;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? '$platform opened. Caption copied to clipboard for quick paste.'
              : 'Could not open $platform automatically. Caption copied to clipboard.',
        ),
      ),
    );
  }

  Future<void> _showMarketingHelpModal() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Tips'),
        content: const Text(
          'Use Template applies the style to your campaign draft.\n\n'
          'Use & Open opens TikTok/Instagram composer and copies the prepared caption so you can paste instantly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _tiktokTemplates = [
    {
      'id': '1',
      'platform': 'TikTok',
      'title': 'Premium Ankole Bull | High Weight, Ready For Breeding',
      'badge': 'Hot This Week',
      'badgeColor': const Color(0xFF13EC5B),
      'description': 'Use fast hook + close-up horns + proof of weight in first 4 seconds.',
      'hook': 'Farmers, if you want strong bloodline this season, watch this.',
      'cta': 'Comment "PRICE" and we will send full details on WhatsApp.',
      'duration': '18-25s',
      'hashtags': '#Ankole #LivestockSales #FarmBusiness',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': '2',
      'platform': 'TikTok',
      'title': 'New Goat Batch Arrival | Strong, Vaccinated, Farm Raised',
      'badge': 'Top Converting',
      'badgeColor': const Color(0xFF0EA5E9),
      'description': 'Show truck offload, health check, then buyer testimonials.',
      'hook': 'Fresh arrivals today. Strong goats with clean health records.',
      'cta': 'Tap follow and DM to reserve before stock runs out.',
      'duration': '15-22s',
      'hashtags': '#GoatFarming #FarmUpdate #RuralBusiness',
      'imageUrl': 'https://images.unsplash.com/photo-1494947665470-20322015e3a8?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': '3',
      'platform': 'TikTok',
      'title': '3 Feeding Tricks That Add Weight Faster (Without Waste)',
      'badge': 'Educational Winner',
      'badgeColor': const Color(0xFFF59E0B),
      'description': 'Educational format with before and after clips drives trust and leads.',
      'hook': 'If your herd is not gaining weight, change this today.',
      'cta': 'Save this video and share with another farmer.',
      'duration': '20-30s',
      'hashtags': '#FarmTips #CattleGrowth #AgriTok',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': '4',
      'platform': 'TikTok',
      'title': 'Before & After Weight Gain Showcase',
      'badge': 'Trust Builder',
      'badgeColor': const Color(0xFF8B5CF6),
      'description': 'Comparative clips with dates and feed changes increase buyer confidence.',
      'hook': 'See this 60-day transformation from our feed plan.',
      'cta': 'DM to get this animal or feeding plan details.',
      'duration': '18-24s',
      'hashtags': '#BeforeAfter #LivestockGrowth #FarmResults',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': '5',
      'platform': 'TikTok',
      'title': 'Buyer Testimonial + Animal Walkthrough',
      'badge': 'Social Proof',
      'badgeColor': const Color(0xFFEF4444),
      'description': 'Blend customer voice with clear visuals to improve inquiry quality.',
      'hook': 'Why farmers keep buying from our ranch.',
      'cta': 'Follow for weekly stock drops and direct pricing.',
      'duration': '22-30s',
      'hashtags': '#FarmReviews #CattleMarket #RanchLife',
      'imageUrl': 'https://images.unsplash.com/photo-1465447142348-e9952c393450?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  final List<Map<String, dynamic>> _instagramTemplates = [
    {
      'id': 'ig1',
      'platform': 'Instagram',
      'title': 'Premium Listing Carousel (5 Slides)',
      'badge': 'Top Reach',
      'badgeColor': Color(0xFFE1306C),
      'description': 'Slide flow: Hero image, weight, lineage, price, CTA.',
      'hook': 'Swipe to view this week\'s premium livestock listing.',
      'cta': 'Send us a DM with slide number to reserve.',
      'duration': 'Carousel',
      'hashtags': '#LivestockForSale #FarmBusiness #InstaFarm',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ig2',
      'platform': 'Instagram',
      'title': 'Reel: Farm Morning Routine',
      'badge': 'Engagement',
      'badgeColor': Color(0xFFF97316),
      'description': 'Routine content builds trust before sales pitches.',
      'hook': 'A real day on our farm before market starts.',
      'cta': 'Comment ROUTINE if you want our exact process.',
      'duration': '20-30s',
      'hashtags': '#FarmReels #FarmLife #AgriBusiness',
      'imageUrl': 'https://images.unsplash.com/photo-1494947665470-20322015e3a8?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ig3',
      'platform': 'Instagram',
      'title': 'Story Series: Stock Countdown',
      'badge': 'Fast Action',
      'badgeColor': Color(0xFF0EA5E9),
      'description': 'Three short stories with countdown sticker for urgency.',
      'hook': 'Only a few quality animals left this week.',
      'cta': 'Tap reply now to receive available stock list.',
      'duration': 'Story set',
      'hashtags': '#FarmStories #LimitedStock #LivestockMarket',
      'imageUrl': 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ig4',
      'platform': 'Instagram',
      'title': 'Educational Reel: Feed Ratio Breakdown',
      'badge': 'Authority',
      'badgeColor': Color(0xFF22C55E),
      'description': 'Educational content attracts serious buyers and keeps retention high.',
      'hook': 'The feed ratio we use for healthier, heavier livestock.',
      'cta': 'Save this reel and DM us if you want a custom plan.',
      'duration': '25-35s',
      'hashtags': '#FarmEducation #LivestockTips #AgriKnowledge',
      'imageUrl': 'https://images.unsplash.com/photo-1465447142348-e9952c393450?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final animalsProvider = Provider.of<AnimalsProvider>(context);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/marketing.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.08),
                  isDark ? BlendMode.darken : BlendMode.lighten,
                ),
              ),
            ),
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.06) : Colors.transparent,
              child: DefaultTextStyle.merge(
                style: const TextStyle(decoration: TextDecoration.none),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTabs(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTikTokTemplates(animalsProvider),
                            _buildInstagramTemplates(animalsProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignBuilder(AnimalsProvider animalsProvider, {bool compact = false}) {
    final animals = _normalizedAnimals(animalsProvider.animals);

    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF13EC5B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Builder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (animalsProvider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (animalsProvider.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB3B3)),
              ),
              child: Text(
                animalsProvider.error!,
                style: const TextStyle(color: Color(0xFF8A1F1F)),
              ),
            )
          else if (animals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FFF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7F3D3)),
              ),
              child: const Text(
                'No animals found yet. Add animals first, then create campaigns from real records.',
                style: TextStyle(color: Color(0xFF1C4D2A)),
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedAnimalId,
              hint: const Text('Select animal to market'),
              items: animals.map<DropdownMenuItem<String>>((animal) {
                final id = (animal['id'] ?? '').toString();
                final name = (animal['name'] ?? 'Unnamed').toString();
                final type = (animal['type'] ?? '').toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text('$name • $type'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAnimalId = value);
                if (value == null) return;
                Map<String, dynamic>? selected;
                for (final animal in animals) {
                  if ((animal['id'] ?? '').toString() == value) {
                    selected = animal;
                    break;
                  }
                }
                if (selected != null) {
                  _generateDraft(selected);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Asking price'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact details',
                hintText: 'Phone number or WhatsApp contact',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['WhatsApp', 'TikTok', 'Instagram'].map((channel) {
                final selected = channel == _selectedChannel;
                return ChoiceChip(
                  label: Text(channel),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedChannel = channel),
                  selectedColor: const Color(0xFF13EC5B),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedAnimalId == null
                        ? null
                        : () {
                            Map<String, dynamic>? selected;
                            for (final animal in animals) {
                              if ((animal['id'] ?? '').toString() == _selectedAnimalId) {
                                selected = animal;
                                break;
                              }
                            }
                            if (selected != null) {
                              _generateDraft(selected);
                            }
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Draft'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _generatedCaption.trim().isEmpty ? null : _copyDraft,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
            if (_generatedCaption.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE3EEE7)),
                ),
                child: Text(
                  _generatedCaption,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
            if (_activeTemplate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF13EC5B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Active template: ${(_activeTemplate!['title'] ?? '').toString()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
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
      child: Row(
        children: [
          Expanded(
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
          ),
          IconButton(
            tooltip: 'Template help',
            onPressed: _showMarketingHelpModal,
            icon: const Icon(Icons.help_outline, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTikTokTemplates(AnimalsProvider animalsProvider) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _tiktokTemplates.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCampaignBuilder(animalsProvider, compact: true);
        }

        final template = _tiktokTemplates[index - 1];
        return _buildTikTokBannerCard(template);
      },
    );
  }

  Widget _buildTikTokBannerCard(Map<String, dynamic> template) {
    final platform = (template['platform'] ?? 'TikTok').toString();
    final platformIcon = platform == 'Instagram' ? Icons.photo_camera : Icons.music_note;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
          SizedBox(
            height: 210,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(platformIcon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$platform Template',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallPill('Hook', template['hook'] as String),
                    _smallPill('Duration', template['duration'] as String),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template['cta'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  template['hashtags'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _applyTemplate(template),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Use Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13EC5B),
                          foregroundColor: const Color(0xFF102216),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openPlatformComposer(template),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Use & Open'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
  Widget _buildInstagramTemplates(AnimalsProvider animalsProvider) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _instagramTemplates.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCampaignBuilder(animalsProvider, compact: true);
        }

        final template = _instagramTemplates[index - 1];
        return _buildTikTokBannerCard(template);
      },
    );
  }

}
