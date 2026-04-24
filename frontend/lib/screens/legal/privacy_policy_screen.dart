import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_PolicySection> _sections = [
    _PolicySection(
      title: '1. Introduction',
      body:
          'ATAHBRACHA ("App", "Platform", "We", "Us", "Our") is a global digital platform designed to support farmers and animal owners in livestock management, tracking, health monitoring, breeding, feeding schedules, reminders, and agricultural activities.\n\nATAHBRACHA is developed and operated from Kampala, Uganda, and is intended for worldwide use.\n\nBy using this App, users agree to the terms of this Privacy Policy and Legal Notice.',
    ),
    _PolicySection(
      title: '2. Company Information',
      body:
          'App Name: ATAHBRACHA\nDeveloper/Company Name: GRESSOVA GROUP OF COMPANIES\nLocation: Kampala, Uganda\nEmail: jjingohenry@gmail.com\nPhone: 0703755671 / 0767598926',
    ),
    _PolicySection(
      title: '3. Data We Collect',
      body:
          'A. Personal Information\n- Full Name\n- Email Address\n- Phone Number\n- Country / Location\n- Profile photo (optional)\n\nB. Farm & Livestock Data\n- Animal type (cattle, goats, poultry, etc.)\n- Animal identification records\n- Health records\n- Vaccination records\n- Breeding data\n- Feeding schedules\n- Treatment history\n- Reminders & notifications\n\nC. Device & Technical Data\n- Device model\n- Operating system\n- IP address\n- App usage statistics\n- Crash reports',
    ),
    _PolicySection(
      title: '4. How We Use Data',
      body:
          'We use collected data to provide livestock tracking services, send health and breeding reminders, improve app performance, provide customer support, prevent fraud or misuse, and comply with legal requirements.\n\nWe do not sell user data to third parties.',
    ),
    _PolicySection(
      title: '5. International Use',
      body:
          'ATAHBRACHA operates globally. By using this app, you consent to data processing in Uganda and other countries where our servers may be located.\n\nWe aim to comply with the Uganda Data Protection and Privacy Act, 2019, GDPR (for European users), Google Play Developer Policies, and international digital data standards.',
    ),
    _PolicySection(
      title: '6. Data Protection & Security',
      body:
          'We implement end-to-end encryption (where applicable), secure cloud storage, role-based access control, secure authentication systems, and regular system audits.\n\nHowever, no system is 100% secure, and users acknowledge this risk.',
    ),
    _PolicySection(
      title: '7. User Responsibilities',
      body:
          'Users agree to provide accurate information, not misuse the platform, not attempt hacking/reverse engineering/copying the system, and not upload illegal content.\n\nViolation may lead to account suspension or legal action.',
    ),
    _PolicySection(
      title: '8. Intellectual Property & Copyright',
      body:
          'All content within ATAHBRACHA including app design, logo, software code, algorithms, databases, features, branding, graphics, and written content is the exclusive intellectual property of GRESSOVA GROUP OF COMPANIES – ATAHBRACHA.\n\nProtected under Uganda Copyright and Neighbouring Rights Act, 2006, international copyright treaties, and WIPO conventions.\n\nUnauthorized reproduction, copying, distribution, reverse engineering, or commercial use is strictly prohibited and may result in legal prosecution.',
    ),
    _PolicySection(
      title: '9. Data Ownership',
      body:
          'Users retain ownership of their farm and livestock data.\n\nThe app retains rights to system analytics and anonymized aggregated data. ATAHBRACHA owns all platform infrastructure and software technology.',
    ),
    _PolicySection(
      title: '10. Limitation of Liability',
      body:
          'ATAHBRACHA is a management support tool. We are not responsible for loss of livestock, financial losses, incorrect data entered by users, or veterinary decisions made by users.\n\nUsers should consult licensed veterinarians or agricultural professionals before making critical decisions.',
    ),
    _PolicySection(
      title: '11. Third-Party Services',
      body:
          'The app may integrate with Google services, cloud storage providers, analytics providers, and payment processors.\n\nThese services have their own privacy policies.',
    ),
    _PolicySection(
      title: '12. Children\'s Policy',
      body: 'ATAHBRACHA is not intended for users under 18 without parental consent.',
    ),
    _PolicySection(
      title: '13. Policy Updates',
      body: 'We reserve the right to update this policy at any time. Users will be notified within the app.',
    ),
    _PolicySection(
      title: '14. Governing Law',
      body:
          'This agreement is governed by the laws of the Republic of Uganda. Disputes shall be handled in courts of Uganda unless otherwise required by international law.',
    ),
    _PolicySection(
      title: '15. Legal Protection Statement',
      body:
          'ATAHBRACHA is legally protected against software duplication, trademark infringement, brand imitation, data theft, and unauthorized commercial replication.\n\nLegal action may be pursued under Ugandan commercial law and international digital intellectual property law.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'ATAHBRACHA Privacy Policy & Legal Protection Document',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: 17 April 2026\nLast Updated: 17 April 2026',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final section in _sections) ...[
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(section.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;
}
