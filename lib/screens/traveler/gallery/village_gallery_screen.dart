import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../models/gallery_image.dart';
import '../../../repositories/gallery_repository.dart';

import 'package:share_plus/share_plus.dart';

import '../../../widgets/common/app_bottom_navigation.dart';
import '../main/traveler_main_screen.dart';
import '../../common/auth/auth_guard.dart';

class VillageGalleryScreen extends StatefulWidget {
  const VillageGalleryScreen({super.key});

  @override
  State<VillageGalleryScreen> createState() => _VillageGalleryScreenState();
}

class _VillageGalleryScreenState extends State<VillageGalleryScreen> {
  final GalleryRepository _galleryRepository = GalleryRepository();
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'All',
    'Surroundings & Views',
    'Homestay Spaces',
    'Activities',
    'Food',
  ];

  final PageController _pageController = PageController();
  int _currentHeroIndex = 0;

  Color _getColorForTag(String tag) {
    switch (tag) {
      case 'Surroundings & Views':
        return Colors.black.withValues(alpha: 0.6);
      case 'Homestay Spaces':
        return Colors.teal.shade700.withValues(alpha: 0.8);
      case 'Activities':
        return Colors.orange.shade800.withValues(alpha: 0.8);
      case 'Food':
        return Colors.brown.shade800.withValues(alpha: 0.8);
      default:
        return Colors.black.withValues(alpha: 0.6);
    }
  }

  void _openFullScreen(GalleryImage image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(image: image),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<GalleryImage>>(
          stream: _galleryRepository.getPublishedImagesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<GalleryImage> images = snapshot.data ?? [];
            if (_selectedFilterIndex > 0) {
              final selectedCategory = _filters[_selectedFilterIndex];
              images = images
                  .where((img) => img.category == selectedCategory)
                  .toList();
            }

            if (images.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No images in the gallery yet.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(images.length)),
                SliverToBoxAdapter(child: _buildFilters(images.length)),
                SliverToBoxAdapter(child: _buildHeroCarousel(images)),
                SliverToBoxAdapter(child: _buildSectionTitle()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.82,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildGridItem(images[index], index);
                    }, childCount: images.length),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) {
            // Already on explore/gallery
            return;
          }
          if (index == 2 || index == 3) {
            AuthGuard.requireAuth(
              context: context,
              onAuthenticated: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        TravelerMainScreen(initialIndex: index),
                  ),
                  (route) => false,
                );
              },
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => TravelerMainScreen(initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Gallery & Experiences',
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count authentic photos & stories',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: Icons.share_outlined,
            onTap: () {
              // ignore: deprecated_member_use
              Share.share(
                'Check out these amazing village experiences at Village Tour Sri Lanka!',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildFilters(int count) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          String label = _filters[index];
          if (index == 0) label = 'All ($count)';

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDark
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCarousel(List<GalleryImage> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 280,
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreen(images[index]),
                  child: Image.network(
                    images[index].imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[300]),
                  ),
                );
              },
            ),
          ),

          // Top Left Tag
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Location & Surroundings',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Expand
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _openFullScreen(images[_currentHeroIndex]),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Navigation Arrows
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_currentHeroIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_currentHeroIndex < images.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Tags
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentHeroIndex + 1} / ${images.length} • ${images[_currentHeroIndex].title.isNotEmpty ? images[_currentHeroIndex].title : 'Gallery Image'}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'COVER',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EXPLORE BY EXPERIENCE & LOCATION',
            style: AppTextStyles.caption.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Tap to inspect',
            style: AppTextStyles.caption.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(GalleryImage image, int index) {
    final String tag = image.category.isNotEmpty ? image.category : 'Location';
    final Color tagColor = _getColorForTag(tag);

    return GestureDetector(
      onTap: () => _openFullScreen(image),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title.isNotEmpty ? image.title : 'Gallery Moment',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    image.description.isNotEmpty
                        ? image.description
                        : 'Explore the beauty',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (image.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            image.location,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final GalleryImage image;

  const FullScreenImageViewer({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          if (image.title.isNotEmpty || image.description.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image.title.isNotEmpty)
                      Text(
                        image.title,
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    if (image.title.isNotEmpty && image.description.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    if (image.description.isNotEmpty)
                      Text(
                        image.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
