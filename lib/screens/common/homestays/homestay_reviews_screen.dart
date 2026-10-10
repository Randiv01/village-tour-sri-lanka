import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/cloudinary_service.dart';

class HomestayReviewsScreen extends StatefulWidget {
  final String homestayId;
  final String homestayTitle;
  final String homestayLocation;
  final String hostName;
  final bool isEmbedded;

  const HomestayReviewsScreen({
    super.key,
    required this.homestayId,
    required this.homestayTitle,
    required this.homestayLocation,
    required this.hostName,
    this.isEmbedded = false,
  });

  @override
  State<HomestayReviewsScreen> createState() => _HomestayReviewsScreenState();
}

class _HomestayReviewsScreenState extends State<HomestayReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  List<String> _selectedTags = [];
  bool _isSubmitting = false;
  List<XFile> _selectedPhotos = [];
  List<String> _existingPhotoUrls = [];
  String _selectedFilter = 'All';

  final List<String> _availableTags = [
    'Hospitality',
    'Organic Claypot',
    'Paddy Walk',
    'Lake Safari',
    'Clean Mudhouse',
  ];

  String? _currentUserId;
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _scrollController.dispose();
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

  Future<void> _pickPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      if (_selectedPhotos.length + _existingPhotoUrls.length + images.length > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 photos allowed.')));
        return;
      }
      setState(() {
        _selectedPhotos.addAll(images);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }
  
  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
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

      // Upload photos
      List<String> finalPhotoUrls = List.from(_existingPhotoUrls);
      if (_selectedPhotos.isNotEmpty) {
        final cloudinaryService = CloudinaryService();
        for (var photo in _selectedPhotos) {
          final result = await cloudinaryService.uploadImage(photo);
          if (result != null) {
            finalPhotoUrls.add(result.secureUrl);
          }
        }
      }

      final reviewData = {
        'travelerId': _currentUserId,
        'homestayId': widget.homestayId,
        'userName': userData?['fullName'] ?? 'Guest',
        'rating': _rating,
        'tags': _selectedTags,
        'reviewText': _reviewController.text,
        'images': finalPhotoUrls,
        'timestamp': FieldValue.serverTimestamp(), // Always update timestamp on edit
      };

      await FirebaseFirestore.instance
          .collection('homestay_reviews')
          .doc('${widget.homestayId}_$_currentUserId') // User can only have one review per homestay
          .set(reviewData, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _rating = 0;
        _selectedTags = [];
        _reviewController.clear();
        _selectedPhotos = [];
        _existingPhotoUrls = [];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Review updated successfully!' : 'Review submitted successfully!')));
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
          .collection('homestay_reviews')
          .doc('${widget.homestayId}_$_currentUserId')
          .delete();
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _rating = 0;
        _selectedTags = [];
        _reviewController.clear();
        _selectedPhotos = [];
        _existingPhotoUrls = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete review: $e')));
    }
  }

  void _editReview(Map<String, dynamic> data) {
    setState(() {
      _isEditing = true;
      _rating = data['rating'] ?? 0;
      _selectedTags = List<String>.from(data['tags'] ?? []);
      _reviewController.text = data['reviewText'] ?? '';
      _existingPhotoUrls = List<String>.from(data['images'] ?? []);
      _selectedPhotos = [];
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamBuilder = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('homestay_reviews')
          .where('homestayId', isEqualTo: widget.homestayId)
          .snapshots(),
      builder: (context, snapshot) {
        final reviews = snapshot.data?.docs ?? [];
        return SingleChildScrollView(
          controller: widget.isEmbedded ? null : _scrollController,
          physics: widget.isEmbedded ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.all(widget.isEmbedded ? 0 : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallRatingSection(reviews),
              const SizedBox(height: AppSpacing.lg),
              _buildWriteReviewSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildReviewList(reviews),
            ],
          ),
        );
      }
    );

    if (widget.isEmbedded) {
      return streamBuilder;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: streamBuilder),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          currentIndex: 1, // Assume Explore is selected since we're viewing a homestay
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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

  Widget _buildOverallRatingSection(List<QueryDocumentSnapshot> reviews) {
    int totalReviews = reviews.length;
    double averageRating = 0;
    
    if (totalReviews > 0) {
      double sum = 0;
      for (var doc in reviews) {
        final data = doc.data() as Map<String, dynamic>;
        sum += (data['rating'] ?? 0).toDouble();
      }
      averageRating = sum / totalReviews;
    }

    // Mock category scores for demonstration based on overall average, bounded
    double baseScore = averageRating > 0 ? averageRating : 5.0;
    double hospitality = baseScore > 4.9 ? 5.0 : baseScore + 0.1;
    double authenticity = baseScore;
    double food = baseScore;
    double cleanliness = baseScore > 1 ? baseScore - 0.1 : baseScore;
    double value = baseScore;

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
                      Text(
                        totalReviews > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) => Icon(Icons.star, color: index < averageRating.round() ? Colors.amber : AppColors.border, size: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$totalReviews verified guest reviews', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
          _buildRatingBar('Hospitality & Warmth', hospitality > 5.0 ? 5.0 : hospitality),
          _buildRatingBar('Authenticity & Culture', authenticity),
          _buildRatingBar('Claypot Food & Dining', food),
          _buildRatingBar('Mudhouse Cleanliness', cleanliness),
          _buildRatingBar('Value for Money', value),
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
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
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
          if (_existingPhotoUrls.isNotEmpty || _selectedPhotos.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingPhotoUrls.asMap().entries.map((entry) => _buildPhotoPreview(
                        url: entry.value,
                        onRemove: () => _removeExistingPhoto(entry.key),
                      )),
                  ..._selectedPhotos.asMap().entries.map((entry) => _buildPhotoPreview(
                        file: entry.value,
                        onRemove: () => _removePhoto(entry.key),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_existingPhotoUrls.length + _selectedPhotos.length < 5)
            GestureDetector(
              onTap: _pickPhotos,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0D8C3), style: BorderStyle.solid),
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
            ),
          const SizedBox(height: AppSpacing.lg),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _rating = 0;
                  _selectedTags = [];
                  _reviewController.clear();
                  _selectedPhotos = [];
                  _existingPhotoUrls = [];
                });
              },
              child: const Center(child: Text('Cancel Edit', style: TextStyle(color: Colors.red))),
            ),
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
                  : Text(_isEditing ? 'Update Guest Review →' : 'Submit Guest Review →', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview({String? url, XFile? file, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url != null 
              ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover)
              : Image.file(File(file!.path), width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<QueryDocumentSnapshot> allReviews) {
    int photoReviewsCount = allReviews.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final images = data['images'] as List<dynamic>? ?? [];
      return images.isNotEmpty;
    }).length;

    List<QueryDocumentSnapshot> filteredReviews = List.from(allReviews);
    
    // Default sort by timestamp descending
    filteredReviews.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['timestamp'] as Timestamp?;
      final bTime = bData['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    if (_selectedFilter == 'With Photos') {
      filteredReviews = filteredReviews.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final images = data['images'] as List<dynamic>? ?? [];
        return images.isNotEmpty;
      }).toList();
    } else if (_selectedFilter == 'Highest Rated') {
      filteredReviews.sort((a, b) {
        final aRating = (a.data() as Map<String, dynamic>)['rating'] ?? 0;
        final bRating = (b.data() as Map<String, dynamic>)['rating'] ?? 0;
        return bRating.compareTo(aRating);
      });
    } else if (_selectedFilter == 'Lowest Rated') {
      filteredReviews.sort((a, b) {
        final aRating = (a.data() as Map<String, dynamic>)['rating'] ?? 0;
        final bRating = (b.data() as Map<String, dynamic>)['rating'] ?? 0;
        return aRating.compareTo(bRating);
      });
    }

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
              _buildFilterChip('All (${allReviews.length})', 'All'),
              _buildFilterChip('With Photos ($photoReviewsCount)', 'With Photos'),
              _buildFilterChip('Highest Rated', 'Highest Rated'),
              _buildFilterChip('Lowest Rated', 'Lowest Rated'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredReviews.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No reviews found for this filter.'),
          ))
        else
          Column(
            children: filteredReviews.map((doc) => _buildReviewCard(doc)).toList(),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    bool isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildReviewCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMyReview = data['travelerId'] == _currentUserId;

    DateTime timestamp = DateTime.now();
    if (data['timestamp'] != null) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    }
    final formattedDate = DateFormat('MMM yyyy').format(timestamp);
    
    final images = data['images'] as List<dynamic>? ?? [];

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
                      onTap: () => _editReview(data),
                      child: const Icon(Icons.edit_outlined, color: Color(0xFF1E6B52), size: 20),
                    ),
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
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(images[index], width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
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
