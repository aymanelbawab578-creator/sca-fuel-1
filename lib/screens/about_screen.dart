import 'package:flutter/material.dart';

import '../widgets/sca_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final mutedTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      appBar: ScaAppBar(
        title: 'حول البرنامج',
        showBack: true,
        showMenu: false,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 42, color: Theme.of(context).primaryColor),
                          const SizedBox(height: 8),
                          Text('SCA', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCA Fleet Management',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'الإصدار:\nVersion 1.3',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedTextColor, height: 1.5),
            ),
            const SizedBox(height: 24),
            _AboutSection(
              title: 'تم تطوير البرنامج بواسطة:',
              body: 'Ayman elbawab',
              cardColor: cardColor,
              borderColor: borderColor,
              mutedTextColor: mutedTextColor,
            ),
            const SizedBox(height: 16),
            _AboutSection(
              title: 'مساعدو التطوير بالذكاء الاصطناعي:',
              bulletItems: const [
                'GitHub Copilot',
                'ChatGPT',
                'Gemini',
              ],
              cardColor: cardColor,
              borderColor: borderColor,
              mutedTextColor: mutedTextColor,
            ),
            const SizedBox(height: 16),
            _AboutSection(
              title: 'التقنيات المستخدمة:',
              bulletItems: const [
                'Flutter',
                'Supabase',
                'PostgreSQL',
              ],
              cardColor: cardColor,
              borderColor: borderColor,
              mutedTextColor: mutedTextColor,
            ),
            const SizedBox(height: 16),
            _AboutSection(
              title: 'مميزات النظام:',
              bulletItems: const [
                'Offline First',
                'Automatic Cloud Synchronization',
                'Fleet Management',
                'Fuel Tracking',
                'Reports & Analytics',
              ],
              cardColor: cardColor,
              borderColor: borderColor,
              mutedTextColor: mutedTextColor,
            ),
            const SizedBox(height: 16),
            _AboutSection(
              title: 'حقوق الملكية:',
              body: '© 2026 Ayman elbawab\nAll Rights Reserved',
              cardColor: cardColor,
              borderColor: borderColor,
              mutedTextColor: mutedTextColor,
            ),
          ],
        ),
            ),
          ),
        ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final String? body;
  final List<String>? bulletItems;
  final Color cardColor;
  final Color borderColor;
  final Color mutedTextColor;

  const _AboutSection({
    required this.title,
    this.body,
    this.bulletItems,
    required this.cardColor,
    required this.borderColor,
    required this.mutedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (body != null)
            Text(
              body!,
              style: TextStyle(color: mutedTextColor, height: 1.6),
            )
          else if (bulletItems != null)
            ...bulletItems!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item, style: TextStyle(color: mutedTextColor))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
