import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    blueGray.withOpacity(0.2),
                    yellow.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: yellow, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 64,
                    color: yellow,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock Premium Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access all poem types and advanced features',
                    style: TextStyle(
                      fontSize: 16,
                      color: sageGreen.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pricing section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: sageGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sageGreen.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Premium Membership',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: yellow,
                        ),
                      ),
                      const Text(
                        '1.99',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: yellow,
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 16,
                          color: sageGreen.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime',
                    style: TextStyle(
                      fontSize: 14,
                      color: sageGreen.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Features section
            const Text(
              'Premium Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Feature list
            _buildFeatureItem(
              icon: Icons.palette,
              title: 'All Poem Types',
              description: 'Access to 90+ premium poem types including famous poets, music styles, and special occasions',
              color: blueGray,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.auto_awesome,
              title: 'Advanced AI Models',
              description: 'Use cutting-edge AI for more creative and personalized poems',
              color: yellow,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.download,
              title: 'HD Downloads',
              description: 'Download your poems in high-quality formats for printing and sharing',
              color: sageGreen,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.favorite,
              title: 'Unlimited Creations',
              description: 'Create as many poems as you want without any limits',
              color: blueGray,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.support,
              title: 'Priority Support',
              description: 'Get faster help and support whenever you need it',
              color: yellow,
            ),
            const SizedBox(height: 32),

            // Upgrade button
            ElevatedButton(
              onPressed: _showUpgradeDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: yellow,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Terms and conditions
            Text(
              'By subscribing, you agree to our Terms & Conditions. Your subscription will automatically renew monthly until cancelled.',
              style: TextStyle(
                fontSize: 12,
                color: sageGreen.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // FAQ section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFAQItem(
              question: 'When will I be charged?',
              answer: 'Your card will be charged immediately upon subscribing. Subsequent charges will occur monthly on the same date.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'Can I cancel my subscription?',
              answer: 'Yes, you can cancel your subscription anytime from your profile page. Your Premium benefits will continue until the end of your current billing period.',
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: 'What payment methods do you accept?',
              answer: 'We accept all major credit cards including Visa, Mastercard, American Express, and Discover.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    // Theme colors
    const Color sageGreen = Color(0xFFC8C7B9);

    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: sageGreen.withOpacity(0.9),
            ),
          ),
        ),
      ],
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
    );
  }

  void _showUpgradeDialog() {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Upgrade to Premium',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: yellow,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment integration is currently being set up.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Premium features will be available soon!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(color: blueGray),
              ),
            ),
          ],
        );
      },
    );
  }
}
