import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../models/gallery_image.dart';
import '../../../repositories/gallery_repository.dart';
import 'admin_add_edit_gallery_image_screen.dart';

class AdminManageGalleryScreen extends StatefulWidget {
  const AdminManageGalleryScreen({super.key});

  @override
  State<AdminManageGalleryScreen> createState() =>
      _AdminManageGalleryScreenState();
}

class _AdminManageGalleryScreenState extends State<AdminManageGalleryScreen> {
  final GalleryRepository _galleryRepository = GalleryRepository();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(GalleryImage image) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete "${image.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              await _galleryRepository.deleteImage(image.id);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Image deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openForm({GalleryImage? image}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddEditGalleryImageScreen(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            'Manage Gallery',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildTopBar(),
        Expanded(
          child: StreamBuilder<List<GalleryImage>>(
            stream: _galleryRepository.getAllImagesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              final allImages = snapshot.data ?? [];
              final images = allImages.where((img) {
                final query = _searchQuery.trim().toLowerCase();
                if (query.isNotEmpty) {
                  return img.title.toLowerCase().contains(query);
                }
                return true;
              }).toList();

              if (allImages.isEmpty) {
                return _buildDatabaseEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultCount(images.length),
                  Expanded(
                    child: images.isEmpty
                        ? _buildFilterEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              final image = images[index];
                              return _buildImageCard(image);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search images...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('+ Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCount(int count) {
    String text;
    if (count == 1) {
      text = '1 image found';
    } else {
      text = '$count images found';
    }
    if (_searchQuery.isEmpty) {
      text = count == 1 ? '1 image' : '$count images';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDatabaseEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No images yet', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          Text(
            'Add your first image to the gallery.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('+ Add Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No images match your search',
              style: AppTextStyles.sectionHeading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('We couldn\'t load images', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(GalleryImage image) {
    final bool isPublished =
        image.status == 'published' ||
        image.status == 'Published (Visible to Users)';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.background,
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title.isNotEmpty ? image.title : 'Untitled',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (image.description.isNotEmpty)
                    Text(
                      image.description,
                      style: AppTextStyles.bodySecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge(
                        isPublished ? 'Published' : 'Draft',
                        isPublished ? Icons.check : Icons.edit_note,
                        isPublished ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(image.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _openForm(image: image),
                            tooltip: 'Edit',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () => _confirmDelete(image),
                            tooltip: 'Delete',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
