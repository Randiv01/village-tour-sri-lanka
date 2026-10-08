import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';

class HomestayReviewsScreen extends StatefulWidget {
  final String homestayId;
  final String homestayTitle;
  final String homestayLocation;
  final String hostName;

  const HomestayReviewsScreen({
    super.key,
    required this.homestayId,
    required this.homestayTitle,
    required this.homestayLocation,
    required this.hostName,
  });

  @override
  State<HomestayReviewsScreen> createState() => _HomestayReviewsScreenState();
}

class _HomestayReviewsScreenState extends State<HomestayReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Hospitality',
    'Organic Claypot',
    'Paddy Walk',
    'Lake Safari',
    'Clean Mudhouse',
  ];

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a review.')));
      return;
    }
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to submit a review.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data();

      final reviewData = {
        'userId': _currentUserId,
        'userName': userData?['fullName'] ?? 'Guest',
        'rating': _rating,
        'tags': _selectedTags,
        'reviewText': _reviewController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(widget.homestayId)
          .collection('reviews')
          .doc(_currentUserId) // User can only have one review per homestay
          .set(reviewData);

      if (!mounted) return;
      setState(() {
        _rating = 0;
        _selectedTags = [];
        _reviewController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteReview() async {
    if (_currentUserId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(widget.homestayId)
          .collection('reviews')
          .doc(_currentUserId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete review: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallRatingSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildWriteReviewSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildReviewList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              Text(
                'Guest Reviews & Ratings',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
              Text(
                '${widget.homestayTitle} · ${widget.homestayLocation}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.notifications_none, size: 16, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRatingSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D8C3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('128 verified guest reviews', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0D8C3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_user, size: 12, color: Color(0xFF1E6B52)),
                        SizedBox(width: 4),
                        Text('VERIFIED RURAL HOST', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRatingBar('Hospitality & Warmth', 5.0),
          _buildRatingBar('Authenticity & Culture', 4.9),
          _buildRatingBar('Claypot Food & Dining', 4.9),
          _buildRatingBar('Mudhouse Cleanliness', 4.8),
          _buildRatingBar('Value for Money', 4.9),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String title, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: rating / 5.0,
                    backgroundColor: const Color(0xFFE8F6F3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E6B52)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D8C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SHARE YOUR EXPERIENCE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E6B52), fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Support our local host family with your honest feedback', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7E7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0D8C3)),
                ),
                child: const Text('Rate\nHost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E6B52)), textAlign: TextAlign.center),
              )
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Overall Rating (Tap to score):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0D8C3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ...List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: index < _rating ? const Color(0xFF1E6B52) : Colors.white,
                        border: Border.all(color: index < _rating ? const Color(0xFF1E6B52) : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.star, color: index < _rating ? Colors.amber : AppColors.border, size: 20),
                    ),
                  );
                }),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF7E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _rating > 0 ? 'Good ($_rating.0)' : 'Rate',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9E6541), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('What went well? (Select multiple):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => _toggleTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E6B52) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF1E6B52) : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isSelected ? Icons.check : Icons.add, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(tag, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Detailed Feedback:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0D8C3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Share details of your own experience at this place...',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Add photos of your stay / meals (Max 5):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0D8C3), style: BorderStyle.solid), // Dashed normally, but solid for simplicity
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
                      SizedBox(height: 4),
                      Text('+ Add more photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                      Text('JPEG, PNG up to 10MB', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6B52),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Guest Review →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Guest Feedback', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E6B52))),
            Text('Sorted by: Most Relevant', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All (128)', true),
              _buildFilterChip('With Photos (42)', false),
              _buildFilterChip('Highest Rated', false),
              _buildFilterChip('Lowest Rated', false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('homestays')
              .doc(widget.homestayId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data?.docs ?? [];
            if (reviews.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No reviews yet. Be the first to review!'),
              ));
            }

            return Column(
              children: reviews.map((doc) => _buildReviewCard(doc)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E6B52) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF1E6B52) : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReviewCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMyReview = doc.id == _currentUserId;

    DateTime timestamp = DateTime.now();
    if (data['timestamp'] != null) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    }
    final formattedDate = DateFormat('MMM yyyy').format(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isMyReview ? const Color(0xFFFDF7E7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMyReview ? const Color(0xFFE0D8C3) : AppColors.border, width: isMyReview ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['userName'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                        const SizedBox(width: 4),
                        const Text('(Guest)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (isMyReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1E6B52), borderRadius: BorderRadius.circular(4)),
                            child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Stayed 2 nights · $formattedDate', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7E7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0D8C3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(data['rating']?.toString() ?? '5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                  if (isMyReview) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _deleteReview,
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                  ]
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${data['reviewText'] ?? ''}"',
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.primaryDark),
          ),
          if (data['hostResponse'] != null && data['hostResponse'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F7),
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Color(0xFF1E6B52), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 16, color: Color(0xFF1E6B52)),
                      const SizedBox(width: 4),
                      Text('Response from ${widget.hostName}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${data['hostResponse']}"',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
