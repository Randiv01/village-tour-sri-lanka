import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/sign_in_screen.dart';
import '../../traveler/chat/traveler_host_chat_screen.dart';
import 'homestay_reviews_screen.dart';
class HomestayDetailsScreen extends StatefulWidget {
  final String homestayId;
  final Map<String, dynamic> homestayData;

  const HomestayDetailsScreen({
    super.key,
    required this.homestayId,
    required this.homestayData,
  });

  @override
  State<HomestayDetailsScreen> createState() => _HomestayDetailsScreenState();
}

class _HomestayDetailsScreenState extends State<HomestayDetailsScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  List<String> _images = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.homestayData['images'] != null) {
      _images = List<String>.from(widget.homestayData['images']);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentImageIndex < _images.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _buildImageCarousel(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLocationRow(),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTitle(),
                      const SizedBox(height: AppSpacing.md),
                      _buildPriceAndRatings(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTabsSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildOverviewText(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeaturePills(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildMockCalendar(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primaryDark),
            ),
          ),
          Column(
            children: [
              const Text(
                'VILLAGE SANCTUARY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Homestay Details',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.favorite_border, size: 16, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.share_outlined, size: 16, color: AppColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Stack(
        children: [
          // Images
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _images.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  )
                : Image.asset('assets/images/onboarding/onboarding_01.png', fit: BoxFit.cover, width: double.infinity),
          ),
          
          // Left Arrow
          if (_images.length > 1)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _prevImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          
          // Right Arrow
          if (_images.length > 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _nextImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),

          // Bottom Left Tag
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9E6541).withValues(alpha: 0.9), // brownish matching image
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Text('🌿', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Text('Organic Farm Hamlet', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Bottom Right Badge
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _images.isEmpty ? '0 / 0 Photos' : '${_currentImageIndex + 1} / ${_images.length} Photos',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    final location = widget.homestayData['location'] ?? 'Unknown Location';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_circle, size: 12, color: Colors.green),
              SizedBox(width: 4),
              Text('VERIFIED HOST', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final title = widget.homestayData['title'] ?? 'Unnamed Homestay';
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'PlayfairDisplay', // fallback if we don't have it, but standard bold will do
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryDark,
        height: 1.1,
      ),
    );
  }

  Widget _buildPriceAndRatings() {
    final price = widget.homestayData['pricePerNight']?.toString() ?? '0';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Icon(Icons.star, size: 16, color: Colors.orangeAccent),
        const SizedBox(width: 4),
        const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
        const SizedBox(width: 4),
        const Text('(32 reviews)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
        ),
        const Text(
          'Superhost',
          style: TextStyle(
            color: AppColors.textSecondary, 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
        const Spacer(),
        Text(
          'Rs. $price',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 2.0),
          child: Text(' / night', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    final tabs = ['Overview', 'Amenities', 'Reviews', 'Host'];
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                if (tabs[index] == 'Host') {
                  _handleMessageHost();
                } else if (tabs[index] == 'Reviews') {
                  _handleReviews();
                }
              },
              child: Column(
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isSelected)
                    Container(height: 3, width: 40, color: AppColors.primaryDark)
                  else
                    const SizedBox(height: 3),
                ],
              ),
            );
          }),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  Future<void> _handleMessageHost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          content: const Text('You need to be logged in to send a message to the host. Would you like to log in now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
      return;
    }

    final hostId = widget.homestayData['hostId'];
    if (hostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Host information not available.')));
      return;
    }

    try {
      final hostDoc = await FirebaseFirestore.instance.collection('users').doc(hostId).get();
      if (!hostDoc.exists) return;
      final hostInfo = hostDoc.data()!;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelerHostChatScreen(
            hostId: hostId,
            hostName: hostInfo['fullName'] ?? 'Host',
            hostImage: hostInfo['profileImage'] ?? hostInfo['profileImageUrl'] ?? '',
            hostLanguages: hostInfo['languages'] != null ? (hostInfo['languages'] as List).join(' & ') : 'English',
            homestayId: widget.homestayData['id'] ?? 'unknown_id',
            homestayTitle: widget.homestayData['title'] ?? 'Homestay',
            homestayPrice: 'Rs. ${widget.homestayData['pricePerNight'] ?? 0}/night',
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleReviews() async {
    final hostId = widget.homestayData['hostId'];
    String hostName = 'Host';
    if (hostId != null) {
      try {
        final hostDoc = await FirebaseFirestore.instance.collection('users').doc(hostId).get();
        if (hostDoc.exists) {
          hostName = hostDoc.data()?['fullName'] ?? 'Host';
        }
      } catch (e) {
        // ignore
      }
    }
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomestayReviewsScreen(
          homestayId: widget.homestayId,
          homestayTitle: widget.homestayData['title'] ?? 'Homestay',
          homestayLocation: widget.homestayData['location'] ?? 'Location',
          hostName: hostName,
        ),
      ),
    );
  }

  Widget _buildOverviewText() {
    final description = widget.homestayData['description'] ?? 'No description provided.';
    return Text(
      description,
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildFeaturePills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPill('🍛', 'Organic Buffet Included', const Color(0xFFFDF7E7), const Color(0xFF9E6541)),
        _buildPill('🛶', 'Lake Catamaran Tour', const Color(0xFFE8F6F3), const Color(0xFF0F7A6A)),
        _buildPill('🐂', 'Bullock Cart Ride', const Color(0xFFF3F3F3), const Color(0xFF555555)),
      ],
    );
  }

  Widget _buildPill(String emoji, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMockCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.chevron_left, size: 16, color: AppColors.textSecondary),
              ),
              const Text('AUGUST 2026', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: 1.1)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Mock days header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((day) => Text(day, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Mock dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['2', '3', '4', '5', '6', '7', '8']
                .map((date) => Text(date, style: const TextStyle(fontSize: 14, color: AppColors.border, fontWeight: FontWeight.w300)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
