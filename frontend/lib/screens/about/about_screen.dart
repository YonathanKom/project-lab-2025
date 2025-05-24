import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        actions: const [
          ThemeToggle(),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Icon and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shopping List App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // App Description
          const Text(
            'About This App',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Shopping List App helps you organize your grocery shopping and household items efficiently. Create lists, share them with family members, and never forget an item again.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Features
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.list_alt, 'Create and manage shopping lists'),
          _buildFeatureItem(Icons.share, 'Share lists with family members'),
          _buildFeatureItem(Icons.check_circle, 'Track completed items'),
          _buildFeatureItem(Icons.history, 'View shopping history'),
          _buildFeatureItem(Icons.dark_mode, 'Light and dark theme support'),
          _buildFeatureItem(Icons.sync, 'Sync across devices'),

          const SizedBox(height: 24),

          // Developer Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Developer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Developed with Flutter'),
                  const SizedBox(height: 4),
                  const Text('© 2025 Shopping List App'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Open privacy policy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy Policy - Coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.privacy_tip),
                        label: const Text('Privacy Policy'),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Open terms of service
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Terms of Service - Coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.article),
                        label: const Text('Terms'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
