import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const List<_TermsSection> _termsSections = [
    _TermsSection(
      title: '1. Acceptance of Terms',
      body:
          'By downloading, accessing, or using ATAHBRACHA (the App), you agree to be bound by these Terms & Conditions. If you do not agree, do not use the App.',
    ),
    _TermsSection(
      title: '2. Description of Service',
      body:
          'ATAHBRACHA is a digital livestock and farm management platform providing animal tracking, health and vaccination records, breeding and gestation reminders, feeding management, treatment logs, farm activity notifications, and agricultural productivity tools.\n\nThe App is intended for informational and farm management support purposes.',
    ),
    _TermsSection(
      title: '3. User Accounts',
      body:
          'Users agree to provide accurate information, keep login credentials confidential, and accept responsibility for all activity under their account.\n\nWe reserve the right to suspend accounts involved in fraud, hacking, or misuse.',
    ),
    _TermsSection(
      title: '4. Intellectual Property Rights',
      body:
          'All rights, title, and interest in ATAHBRACHA including source code, design architecture, branding, algorithms, data structure, logo, and content are owned exclusively by GRESSOVA GROUP OF COMPANIES.\n\nUnauthorized copying, reverse engineering, resale, or duplication is strictly prohibited.',
    ),
    _TermsSection(
      title: '5. License to Use',
      body:
          'We grant users a limited, non-transferable, non-exclusive license to use the App for personal or commercial farm management only.\n\nThis license does not allow selling the app, copying the system, extracting databases, or building competing products using our structure.',
    ),
    _TermsSection(
      title: '6. Limitation of Liability',
      body:
          'ATAHBRACHA is not liable for loss of animals, business losses, incorrect user input, or decisions based on app reminders.\n\nFarmers should consult professional veterinarians where necessary.',
    ),
    _TermsSection(
      title: '7. Termination',
      body:
          'We may terminate or suspend accounts that violate terms, attempt system interference, or engage in illegal activity.',
    ),
    _TermsSection(
      title: '8. Governing Law',
      body: 'These Terms are governed by the laws of the Republic of Uganda.',
    ),
  ];

  static const List<_TermsSection> _eulaSections = [
    _TermsSection(
      title: '1. License Grant',
      body: 'We grant you a revocable, non-exclusive, non-transferable license to use ATAHBRACHA.',
    ),
    _TermsSection(
      title: '2. Restrictions',
      body:
          'You may not modify or reverse engineer the App, copy source code, use the app to build competing software, remove copyright notices, or redistribute without written permission.',
    ),
    _TermsSection(
      title: '3. Ownership',
      body:
          'The App is licensed, not sold. All intellectual property remains the exclusive property of GRESSOVA GROUP OF COMPANIES.',
    ),
    _TermsSection(
      title: '4. Updates',
      body: 'We may release updates that modify features without prior notice.',
    ),
    _TermsSection(
      title: '5. Termination',
      body: 'Violation of this agreement results in automatic termination of license.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'ATAHBRACHA Terms & Conditions',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: 17 April 2026\nCompany Name: GRESSOVA GROUP OF COMPANIES\nLocation: Kampala, Uganda',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final section in _termsSections) ...[
              Text(section.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(section.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 14),
            ],
            const Divider(height: 32),
            Text(
              'End User License Agreement (EULA)',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final section in _eulaSections) ...[
              Text(section.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(section.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 14),
            ],
            const Divider(height: 32),
            Text(
              'Google Play Store Privacy Summary',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'ATAHBRACHA collects personal and farm-related data to provide livestock management services including health tracking, breeding reminders, feeding schedules, and treatment logs.\n\nWe do not sell personal data.\n\nData may be stored securely in cloud servers and processed in compliance with Ugandan and international data protection laws.\n\nUsers may request account deletion at any time.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;
}
