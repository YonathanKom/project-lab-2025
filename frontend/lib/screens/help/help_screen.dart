import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: const [
          ThemeToggle(),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'How do I create a shopping list?',
            'Navigate to the Shopping Lists screen and tap the + button to create a new list.',
          ),
          _buildFAQItem(
            'How do I add items to my list?',
            'Open a shopping list and tap the + button to add new items.',
          ),
          _buildFAQItem(
            'Can I share my lists with family members?',
            'Yes, you can invite family members to join your household and share lists.',
          ),
          _buildFAQItem(
            'How do I change the app theme?',
            'Use the theme toggle button in the app bar or go to Settings > Theme.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@shoppingapp.com'),
                  onTap: () {
                    // TODO: Implement email support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email support - Coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  onTap: () {
                    // TODO: Implement live chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Live chat - Coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Report a Bug'),
                  subtitle: const Text('Help us improve the app'),
                  onTap: () {
                    // TODO: Implement bug reporting
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bug reporting - Coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
