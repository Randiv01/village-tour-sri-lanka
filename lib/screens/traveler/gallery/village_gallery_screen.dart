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
  late final Stream<List<GalleryImage>> _publishedImagesStream;

  @override
  void initState() {
    super.initState();
    _publishedImagesStream = _galleryRepository.getPublishedImagesStream();
  }

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
          stream: _publishedImagesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<GalleryImage> allImages = snapshot.data ?? [];
            if (allImages.isEmpty) {
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

            List<GalleryImage> images = allImages;
            if (_selectedFilterIndex > 0) {
              final selectedCategory = _filters[_selectedFilterIndex];
              images = allImages
                  .where((img) => img.category == selectedCategory)
                  .toList();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(allImages.length)),
                SliverToBoxAdapter(child: _buildFilters(allImages)),
                if (images.isNotEmpty) ...[
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
                ] else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.filter_none,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No photos in "${_filters[_selectedFilterIndex]}" yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildFilters(List<GalleryImage> allImages) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          final categoryName = _filters[index];
          final int count = index == 0
              ? allImages.length
              : allImages.where((img) => img.category == categoryName).length;
          final String label = '$categoryName ($count)';

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                  _currentHeroIndex = 0;
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
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

    final int heroIndex =
        (_currentHeroIndex >= 0 && _currentHeroIndex < images.length)
            ? _currentHeroIndex
            : 0;
    final GalleryImage currentHeroImage = images[heroIndex];

    return Container(
      height: 280,
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
              onTap: () => _openFullScreen(currentHeroImage),
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

          // Navigation Arrows (bounded so they don't block horizontal swipes)
          Positioned(
            left: 16,
            top: 122,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                if (heroIndex > 0) {
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 122,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                if (heroIndex < images.length - 1) {
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 24,
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
                      '${heroIndex + 1} / ${images.length} • ${currentHeroImage.title.isNotEmpty ? currentHeroImage.title : 'Gallery Image'}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (currentHeroImage.isCover ||
                    (heroIndex == 0 &&
                        !images.any((img) => img.isCover))) ...[
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
                  if (image.imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.collections_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${image.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

class FullScreenImageViewer extends StatefulWidget {
  final GalleryImage image;

  const FullScreenImageViewer({super.key, required this.image});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final List<String> _urls;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _urls = widget.image.imageUrls.isNotEmpty
        ? widget.image.imageUrls
        : (widget.image.imageUrl.isNotEmpty ? [widget.image.imageUrl] : []);

    int initialPage = 0;
    if (widget.image.imageUrl.isNotEmpty) {
      final foundIndex = _urls.indexOf(widget.image.imageUrl);
      if (foundIndex != -1) {
        initialPage = foundIndex;
      }
    }
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _urls.length > 1
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_urls.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: _urls.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, idx) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      _urls[idx],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 64,
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
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_urls.length > 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _urls.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentIndex == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentIndex == i
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
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
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
