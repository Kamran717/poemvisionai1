import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/profile/domain/models/membership_plan.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _isLoading = true;
  bool _isYearly = true; // Default to yearly subscription (better value)
  String? _errorMessage;
  String? _selectedPlanId;
  
  @override
  void initState() {
    super.initState();
    _loadPlans();
  }
  
  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadMembershipPlans();
      
      // Set current plan as selected
      if (profileProvider.currentPlan != null) {
        setState(() {
          _selectedPlanId = profileProvider.currentPlan!.id;
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading membership plans', e);
      setState(() {
        _errorMessage = 'Failed to load membership plans';
        _isLoading = false;
      });
    }
  }
  
  void _selectPlan(String planId) {
    setState(() {
      _selectedPlanId = planId;
    });
  }
  
  void _toggleBillingCycle() {
    setState(() {
      _isYearly = !_isYearly;
    });
  }
  
  Future<void> _processPurchase() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if user is selecting their current plan
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.profile?.membershipPlan == _selectedPlanId && 
        profileProvider.profile?.isMembershipActive == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have this plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // In a real app, we would handle payment processing here
    // For now, just show a dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan: ${_getPlanName(_selectedPlanId!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Billing: ${_isYearly ? 'Yearly' : 'Monthly'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${_getPlanPrice(_selectedPlanId!)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'In a production app, this would connect to a payment processor like Stripe or in-app purchases.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Simulate subscription
                await Future.delayed(const Duration(seconds: 2));
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Go back to profile screen
                  Navigator.pop(context);
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to process payment';
                });
              }
            },
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );
  }
  
  String _getPlanName(String planId) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final plan = profileProvider.availablePlans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => MembershipPlans.free,
    );
    
    return plan.name;
  }
  
  String _getPlanPrice(String planId) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final plan = profileProvider.availablePlans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => MembershipPlans.free,
    );
    
    return _isYearly 
        ? plan.yearlyPrice.toStringAsFixed(2) 
        : plan.monthlyPrice.toStringAsFixed(2);
  }
  
  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        final success = await profileProvider.cancelSubscription();
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully. You will have access until the end of your current billing period.'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = 'Failed to cancel subscription';
            _isLoading = false;
          });
        }
      } catch (e) {
        AppLogger.e('Error cancelling subscription', e);
        setState(() {
          _errorMessage = 'An error occurred while cancelling subscription';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Check for errors
        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load membership plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadPlans,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final plans = profileProvider.availablePlans;
        final userPlan = profileProvider.profile?.membershipPlan;
        final isActiveMember = profileProvider.profile?.isMembershipActive ?? false;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current subscription
              if (userPlan != null) ...[
                _buildCurrentSubscription(userPlan, isActiveMember, profileProvider),
                const SizedBox(height: 24),
              ],
              
              // Plans section
              const Text(
                'Choose a Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Toggle billing cycle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Monthly'),
                  Switch(
                    value: _isYearly,
                    onChanged: (value) => _toggleBillingCycle(),
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Text('Yearly'),
                  if (_isYearly)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save up to 16%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Plans list
              ...plans.map((plan) => _buildPlanCard(plan, userPlan)).toList(),
              
              const SizedBox(height: 24),
              
              // Subscribe button
              if (_selectedPlanId != null && 
                  (_selectedPlanId != userPlan || !isActiveMember))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processPurchase,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(
                      userPlan == 'free' || !isActiveMember
                          ? 'Subscribe Now'
                          : 'Change Plan',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              
              // Cancel subscription button
              if (userPlan != 'free' && isActiveMember) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelSubscription,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Additional information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Payment will be charged to your account at confirmation of purchase.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• You can manage your subscriptions in your account settings after purchase.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              // TODO: Open terms of service
                            },
                            child: const Text('Terms of Service'),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Open privacy policy
                            },
                            child: const Text('Privacy Policy'),
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
      },
    );
  }
  
  Widget _buildCurrentSubscription(
    String planId, 
    bool isActive, 
    ProfileProvider profileProvider
  ) {
    final plan = profileProvider.currentPlan;
    
    if (plan == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isActive && planId != 'free'
          ? AppTheme.primaryColor
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Plan: ${plan.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive && planId != 'free'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.star,
                  color: isActive && planId != 'free'
                      ? Colors.amber
                      : Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? planId == 'free'
                      ? 'Free plan with limited features'
                      : 'Active subscription'
                  : 'Subscription expired',
              style: TextStyle(
                color: isActive && planId != 'free'
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            if (planId != 'free' && profileProvider.profile?.membershipExpiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                isActive
                    ? 'Renews on ${_formatDate(profileProvider.profile!.membershipExpiresAt!)}'
                    : 'Expired on ${_formatDate(profileProvider.profile!.membershipExpiresAt!)}',
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard(MembershipPlan plan, String? userPlan) {
    final isSelected = _selectedPlanId == plan.id;
    final isUserPlan = userPlan == plan.id;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectPlan(plan.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Radio<String>(
                    value: plan.id,
                    groupValue: _selectedPlanId,
                    onChanged: (value) => _selectPlan(value!),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_isYearly ? plan.yearlyPrice.toStringAsFixed(2) : plan.monthlyPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isYearly ? '/year' : '/month',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_isYearly && plan.id != 'free') ...[
                    const SizedBox(width: 8),
                    Text(
                      '\$${plan.yearlyPricePerMonth.toStringAsFixed(2)}/mo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              if (_isYearly && plan.yearlyDiscountPercentage > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Save ${plan.yearlyDiscountPercentage.round()}% with annual billing',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...plan.features.map((feature) => _buildFeatureItem(feature)).toList(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(feature),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
