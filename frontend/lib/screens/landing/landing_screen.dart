import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color _primary = Color(0xFF13EC25);
  static const Color _bg = Color(0xFFF8FAF8);
  static const Color _dark = Color(0xFF0A120B);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(isDesktop: isDesktop)),
            SliverToBoxAdapter(child: _HeroSection(isDesktop: isDesktop)),
            SliverToBoxAdapter(child: _PillarsSection()),
            SliverToBoxAdapter(child: _AppPreviewSection(isDesktop: isDesktop)),
            SliverToBoxAdapter(child: _FinalCtaSection()),
            SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/app_logo.jpg',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Atahbracha',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          if (isDesktop) ...[
            const Text('Features', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(width: 20),
            const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(width: 20),
            const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(width: 20),
          ],
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LandingScreen._primary,
              foregroundColor: LandingScreen._dark,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Wrap(
        runSpacing: 24,
        spacing: 24,
        children: [
          SizedBox(
            width: isDesktop ? 560 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: LandingScreen._primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '10k+ farmers growing stronger',
                    style: TextStyle(
                      color: Color(0xFF0C9E1A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manage Your Herd.\nGrow Your Wealth.',
                  style: TextStyle(
                    fontSize: 54,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The premium livestock intelligence platform for the modern African enterprise.',
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.black54,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/signup'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Start Free Trial'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LandingScreen._primary,
                        foregroundColor: LandingScreen._dark,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black.withOpacity(0.12), width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        shape: const StadiumBorder(),
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: isDesktop ? 460 : double.infinity,
            child: Stack(
              children: [
                Container(
                  height: 560,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=1200&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0x3313EC25),
                          child: Icon(Icons.trending_up, color: Color(0xFF0C9E1A)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HERD VALUATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45)),
                              Text('+24% Organic Growth', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = [
      const _PillarCard(
        icon: Icons.monitor_heart,
        title: 'Smart Tracking',
        body: 'Real-time monitoring for health, breeding cycles, and precision nutrition.',
      ),
      const _PillarCard(
        icon: Icons.rocket_launch,
        title: 'Direct Marketing',
        body: 'AI-assisted campaigns and digital catalogs to reach premium buyers faster.',
      ),
      const _PillarCard(
        icon: Icons.notifications_active,
        title: 'Early Warning',
        body: 'Predictive alerts for health anomalies and climate risks across your farms.',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text(
            'Our Three Pillars',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Engineered to transform your operation into a resilient, profitable enterprise.',
            style: TextStyle(color: Colors.black54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              if (isWide) {
                return Row(
                  children: cards
                      .map((card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: card,
                            ),
                          ))
                      .toList(),
                );
              }
              return Column(
                children: cards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: card,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LandingScreen._bg,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: LandingScreen._primary.withOpacity(0.2),
            child: Icon(icon, color: const Color(0xFF0C9E1A)),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.black54, height: 1.45)),
        ],
      ),
    );
  }
}

class _AppPreviewSection extends StatelessWidget {
  const _AppPreviewSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Wrap(
        spacing: 30,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 330,
            height: 630,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 36,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.short_text, color: Colors.black45),
                      CircleAvatar(
                        backgroundColor: Color(0x3313EC25),
                        child: Icon(Icons.person, color: Color(0xFF0C9E1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Atahbracha Mobile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1413EC25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ECOSYSTEM HEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45)),
                            Text('98% OPTIMAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0C9E1A))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: 0.98,
                            minHeight: 8,
                            backgroundColor: const Color(0x11000000),
                            color: LandingScreen._primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _AnimalPreviewCard(
                    name: 'Daisy #402',
                    note: 'Premium Angus',
                    good: true,
                  ),
                  const SizedBox(height: 10),
                  const _AnimalPreviewCard(
                    name: 'Bessy #119',
                    note: 'Due: 14 days',
                    good: false,
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(Icons.grid_view, color: Color(0xFF0C9E1A)),
                      Icon(Icons.analytics, color: Colors.black26),
                      Icon(Icons.chat_bubble, color: Colors.black26),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 520 : double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Entire Operation, Refined.',
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.1),
                ),
                SizedBox(height: 14),
                Text(
                  'Built for the field with edge intelligence: full offline operation and seamless sync when you reconnect.',
                  style: TextStyle(fontSize: 20, color: Colors.black54, height: 1.45),
                ),
                SizedBox(height: 22),
                _FeatureLine(
                  icon: Icons.cloud_off,
                  title: 'Offline-Native Design',
                  text: 'Capture and manage operations without cellular dependency.',
                ),
                SizedBox(height: 14),
                _FeatureLine(
                  icon: Icons.description,
                  title: 'Financial-Grade Reporting',
                  text: 'Generate lender-ready records and audit trails quickly.',
                ),
                SizedBox(height: 14),
                _FeatureLine(
                  icon: Icons.group,
                  title: 'Enterprise Permissions',
                  text: 'Delegate access with clear role boundaries across your team.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalPreviewCard extends StatelessWidget {
  const _AnimalPreviewCard({required this.name, required this.note, required this.good});

  final String name;
  final String note;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=500&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: good ? Colors.black45 : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Icon(good ? Icons.check_circle : Icons.medical_services, color: good ? const Color(0xFF0C9E1A) : Colors.orange),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: LandingScreen._primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0C9E1A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(color: Colors.black54, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Lead the New Agricultural Era?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Join the network of producers scaling with precision data and better market access.',
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LandingScreen._primary,
                  foregroundColor: LandingScreen._dark,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
                child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
                child: const Text('I Already Have An Account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        children: [
          Wrap(
            spacing: 28,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              Text('Management Suite', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
              Text('Marketplace', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
              Text('Pricing Plans', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
              Text('Knowledge Base', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 Atahbracha Intelligence Systems. All rights reserved.',
            style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}