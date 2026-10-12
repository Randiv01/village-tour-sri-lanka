import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../models/gallery_image.dart';
import '../../../repositories/gallery_repository.dart';
import '../../../services/cloudinary_service.dart';

class _GalleryMediaItem {
  final XFile? file;
  final String? networkUrl;
  final String? existingDocId;

  _GalleryMediaItem({
    this.file,
    this.networkUrl,
    this.existingDocId,
  });

  bool get isNetwork => networkUrl != null && file == null;
}

class AdminAddEditGalleryImageScreen extends StatefulWidget {
  final GalleryImage? image;
  const AdminAddEditGalleryImageScreen({super.key, this.image});

  @override
  State<AdminAddEditGalleryImageScreen> createState() =>
      _AdminAddEditGalleryImageScreenState();
}

class _AdminAddEditGalleryImageScreenState
    extends State<AdminAddEditGalleryImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  String _status = 'published';
  String _category = 'Surroundings & Views';
  DateTime? _imageDate;

  final List<_GalleryMediaItem> _mediaList = [];
  int _coverIndex = 0;
  bool _isLoading = false;
  String _uploadProgressText = '';
  bool _hasAttemptedSubmit = false;

  final GalleryRepository _galleryRepository = GalleryRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      _titleController.text = widget.image!.title;
      _descController.text = widget.image!.description;
      _locationController.text = widget.image!.location;
      _status = widget.image!.status;
      _category = widget.image!.category;
      _imageDate = widget.image!.imageDate;

      final existingUrls = widget.image!.imageUrls.isNotEmpty
          ? widget.image!.imageUrls
          : (widget.image!.imageUrl.isNotEmpty ? [widget.image!.imageUrl] : <String>[]);

      for (int i = 0; i < existingUrls.length; i++) {
        final url = existingUrls[i];
        _mediaList.add(
          _GalleryMediaItem(
            networkUrl: url,
            existingDocId: widget.image!.id,
          ),
        );
        if (url == widget.image!.imageUrl) {
          _coverIndex = i;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            _mediaList.add(_GalleryMediaItem(file: img));
          }
          if (_coverIndex >= _mediaList.length) {
            _coverIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaList.removeAt(index);
      if (_mediaList.isEmpty) {
        _coverIndex = 0;
      } else if (_coverIndex >= _mediaList.length) {
        _coverIndex = _mediaList.length - 1;
      } else if (_coverIndex == index) {
        _coverIndex = 0;
      } else if (_coverIndex > index) {
        _coverIndex--;
      }
    });
  }

  void _setAsCover(int index) {
    setState(() {
      _coverIndex = index;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image #${index + 1} set as Cover Photo'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_mediaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgressText = 'Preparing images...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uploaderId = user?.uid ?? 'unknown';

      // 1. Upload new files and build full URL list
      final List<String> finalUrls = [];
      for (int i = 0; i < _mediaList.length; i++) {
        final item = _mediaList[i];
        if (item.file != null) {
          setState(() {
            _uploadProgressText =
                'Uploading image ${i + 1} of ${_mediaList.length}...';
          });
          final result = await _cloudinaryService.uploadImage(item.file!);
          if (result != null) {
            finalUrls.add(result.secureUrl);
          } else {
            throw Exception('Image #${i + 1} failed to upload');
          }
        } else if (item.networkUrl != null && item.networkUrl!.isNotEmpty) {
          finalUrls.add(item.networkUrl!);
        }
      }

      if (finalUrls.isEmpty) {
        throw Exception('Please select at least one valid image');
      }

      // 2. Resolve cover URL
      final coverUrl = (_coverIndex >= 0 && _coverIndex < finalUrls.length)
          ? finalUrls[_coverIndex]
          : finalUrls.first;

      if (widget.image != null) {
        // Edit mode - Update the single gallery post with all images
        final updatedImage = widget.image!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          imageUrl: coverUrl,
          imageUrls: finalUrls,
          status: _status,
          category: _category,
          location: _locationController.text.trim(),
          imageDate: _imageDate,
          updatedAt: DateTime.now(),
        );

        await _galleryRepository.updateImage(updatedImage);
      } else {
        // Add mode - Create ONE single gallery post containing all images
        final newImage = GalleryImage(
          id: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          imageUrl: coverUrl,
          imageUrls: finalUrls,
          status: _status,
          category: _category,
          location: _locationController.text.trim(),
          imageDate: _imageDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          uploaderId: uploaderId,
          isCover: false,
        );
        await _galleryRepository.addImage(newImage);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.image != null
                  ? 'Gallery image updated successfully!'
                  : 'Added ${_mediaList.length} image(s) to gallery successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMediaThumbnail(_GalleryMediaItem item, int index) {
    final isCover = index == _coverIndex;

    ImageProvider imageProvider;
    if (item.file != null) {
      imageProvider = FileImage(File(item.file!.path));
    } else if (item.networkUrl != null && item.networkUrl!.isNotEmpty) {
      imageProvider = NetworkImage(item.networkUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/placeholder.jpg');
    }

    return Stack(
      children: [
        Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCover ? AppColors.primary : AppColors.border,
              width: isCover ? 2.5 : 1,
            ),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Cover Badge
        if (isCover)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 10),
                  SizedBox(width: 3),
                  Text(
                    'Cover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // "Set as Cover" button if not cover
        if (!isCover)
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: InkWell(
              onTap: () => _setAsCover(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Set Cover',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.6),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: AppColors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              '+ Add More',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.image != null;
    final hasImageError = _hasAttemptedSubmit && _mediaList.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Image' : 'Add Gallery Images'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _uploadProgressText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header for Photos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gallery Photos (${_mediaList.length})',
                          style: AppTextStyles.sectionHeading.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        if (_mediaList.isNotEmpty)
                          TextButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add More'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select multiple photos. Tap "Set Cover" on your favorite to make it the featured cover image.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Image Picker / Gallery Preview Box
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 130),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasImageError
                              ? AppColors.error
                              : AppColors.border,
                          width: hasImageError ? 1.5 : 1,
                        ),
                      ),
                      child: _mediaList.isNotEmpty
                          ? Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (int i = 0; i < _mediaList.length; i++)
                                  _buildMediaThumbnail(_mediaList[i], i),
                                _buildAddMoreButton(),
                              ],
                            )
                          : InkWell(
                              onTap: _pickImages,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 52,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Tap to select multiple images',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Supports JPG, PNG, WEBP',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    if (hasImageError) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Please select at least one image',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // Title with validation
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Sunrise Mist Over Ella Gap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a title for this image';
                        }
                        if (val.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add interesting details about the view...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        hintText: 'e.g. Ella, Uva Province',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category Dropdown with validation
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Surroundings & Views',
                          child: Text('Surroundings & Views'),
                        ),
                        DropdownMenuItem(
                          value: 'Homestay Spaces',
                          child: Text('Homestay Spaces'),
                        ),
                        DropdownMenuItem(
                          value: 'Activities',
                          child: Text('Activities'),
                        ),
                        DropdownMenuItem(
                          value: 'Food',
                          child: Text('Food'),
                        ),
                      ],
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _imageDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _imageDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _imageDate == null
                              ? 'Select Date'
                              : '${_imageDate!.year}-${_imageDate!.month.toString().padLeft(2, '0')}-${_imageDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.visibility_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published (Visible to Users)'),
                        ),
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Draft (Hidden)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.cloud_upload_outlined,
                            color: Colors.white),
                        label: Text(
                          isEditing
                              ? 'Save Changes'
                              : 'Upload ${_mediaList.length > 1 ? '${_mediaList.length} Images' : 'Image'}',
                          style: AppTextStyles.buttonText.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

