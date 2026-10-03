import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../../../config/app_constants.dart';
import '../../../models/destination.dart';
import '../../../repositories/destination_repository.dart';
import '../../../services/cloudinary_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class _MediaItem {
  final DestinationImage? existingImage;
  final XFile? newFile;

  _MediaItem.existing(this.existingImage) : newFile = null;
  _MediaItem.newFile(this.newFile) : existingImage = null;
}

class DestinationFormScreen extends StatefulWidget {
  final Destination? destination;

  const DestinationFormScreen({super.key, this.destination});

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DestinationRepository();
  final _cloudinaryService = CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _orderController;

  final _nameFocus = FocusNode();
  final _shortDescFocus = FocusNode();
  final _descFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _latFocus = FocusNode();
  final _lngFocus = FocusNode();
  final _orderFocus = FocusNode();

  bool _isPopular = false;
  bool _isActive = true;
  List<_MediaItem> _mediaItems = [];
  bool _isSaving = false;
  bool _formIsDirty = false;
  String? _nameError;
  String? _uploadProgressText;

  int _shortDescLength = 0;
  int _descLength = 0;

  @override
  void initState() {
    super.initState();
    final dest = widget.destination;
    _nameController = TextEditingController(text: dest?.name ?? '');
    _shortDescController = TextEditingController(
      text: dest?.shortDescription ?? '',
    );
    _descController = TextEditingController(text: dest?.description ?? '');
    _locationController = TextEditingController(text: dest?.locationName ?? '');
    _latController = TextEditingController(
      text: dest?.latitude?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: dest?.longitude?.toString() ?? '',
    );
    _orderController = TextEditingController(
      text: dest?.displayOrder.toString() ?? '0',
    );

    _shortDescLength = _shortDescController.text.length;
    _descLength = _descController.text.length;

    void markDirty() {
      if (!_formIsDirty) {
        setState(() => _formIsDirty = true);
      }
    }

    _nameController.addListener(() {
      markDirty();
      if (_nameError != null) {
        setState(() => _nameError = null);
      }
    });

    _shortDescController.addListener(() {
      markDirty();
      setState(() => _shortDescLength = _shortDescController.text.length);
    });

    _descController.addListener(() {
      markDirty();
      setState(() => _descLength = _descController.text.length);
    });

    _locationController.addListener(markDirty);
    _latController.addListener(markDirty);
    _lngController.addListener(markDirty);
    _orderController.addListener(markDirty);

    _isPopular = dest?.isPopular ?? false;
    _isActive = dest?.isActive ?? true;

    if (dest != null && dest.images.isNotEmpty) {
      _mediaItems = dest.images.map((img) => _MediaItem.existing(img)).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _orderController.dispose();

    _nameFocus.dispose();
    _shortDescFocus.dispose();
    _descFocus.dispose();
    _locationFocus.dispose();
    _latFocus.dispose();
    _lngFocus.dispose();
    _orderFocus.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _pickImage() async {
    if (_mediaItems.length >= AppConstants.maxDestinationImages) {
      _showError(
        'Maximum ${AppConstants.maxDestinationImages} images reached.',
      );
      return;
    }

    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    int remainingSlots = AppConstants.maxDestinationImages - _mediaItems.length;
    if (images.length > remainingSlots) {
      _showError('You can add up to $remainingSlots more images.');
      return;
    }

    List<_MediaItem> validItems = [];

    for (var image in images) {
      final ext = image.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _showError(
          'This file type is not supported. Please use JPG, PNG or WebP.',
        );
        continue;
      }

      final length = await image.length();
      if (length > 5 * 1024 * 1024) {
        _showError('This image is too large. Maximum file size is 5 MB.');
        continue;
      }

      validItems.add(_MediaItem.newFile(image));
    }

    if (validItems.isNotEmpty) {
      setState(() {
        _mediaItems.addAll(validItems);
        _formIsDirty = true;
      });
    }
  }

  void _removeMedia(int index) {
    if (_mediaItems.length == 1) {
      _showError('At least one destination image is required.');
      return;
    }
    setState(() {
      _mediaItems.removeAt(index);
      _formIsDirty = true;
    });
  }

  void _setAsCover(int index) {
    if (index == 0) return;
    setState(() {
      final item = _mediaItems.removeAt(index);
      _mediaItems.insert(0, item);
      _formIsDirty = true;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Destination name is required.';
    }
    if (value.trim().length < 3 || value.trim().length > 80) {
      return 'Must be 3-80 characters.';
    }
    if (_nameError != null) {
      return _nameError;
    }
    return null;
  }

  String? _validateShortDesc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Short description is required.';
    }
    if (value.trim().length < 20 || value.trim().length > 180) {
      return 'Must be 20-180 characters.';
    }
    return null;
  }

  String? _validateDesc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full description is required.';
    }
    if (value.trim().length < 50 || value.trim().length > 2000) {
      return 'Must be 50-2000 characters.';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location name is required.';
    }
    if (value.trim().length < 2 || value.trim().length > 100) {
      return 'Must be 2-100 characters.';
    }
    return null;
  }

  String? _validateLat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required.';
    }
    final val = double.tryParse(value);
    if (val == null) {
      return 'Invalid decimal number.';
    }
    if (val < -90 || val > 90) {
      return 'Must be -90 to 90.';
    }
    return null;
  }

  String? _validateLng(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required.';
    }
    final val = double.tryParse(value);
    if (val == null) {
      return 'Invalid decimal number.';
    }
    if (val < -180 || val > 180) {
      return 'Must be -180 to 180.';
    }
    return null;
  }

  String? _validateOrder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display order is required.';
    }
    final val = int.tryParse(value);
    if (val == null || val < 1 || val > 999) {
      return 'Must be whole number (1-999).';
    }
    return null;
  }

  void _focusFirstError() {
    if (_validateName(_nameController.text) != null) {
      _nameFocus.requestFocus();
    } else if (_validateShortDesc(_shortDescController.text) != null) {
      _shortDescFocus.requestFocus();
    } else if (_validateDesc(_descController.text) != null) {
      _descFocus.requestFocus();
    } else if (_validateLocation(_locationController.text) != null) {
      _locationFocus.requestFocus();
    } else if (_validateLat(_latController.text) != null) {
      _latFocus.requestFocus();
    } else if (_validateLng(_lngController.text) != null) {
      _lngFocus.requestFocus();
    } else if (_validateOrder(_orderController.text) != null) {
      _orderFocus.requestFocus();
    }
  }

  Future<void> _save() async {
    setState(() => _nameError = null);

    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    if (_mediaItems.isEmpty) {
      _showError('At least one destination image is required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exists = await _repository.checkNameExists(
        _nameController.text.trim(),
        excludeId: widget.destination?.id,
      );
      if (exists) {
        setState(() {
          _nameError = 'A destination with this name already exists.';
          _isSaving = false;
        });
        _formKey.currentState!.validate();
        _nameFocus.requestFocus();
        return;
      }

      List<DestinationImage> finalImages = [];
      int uploadedCount = 0;
      int totalToUpload = _mediaItems
          .where((item) => item.newFile != null)
          .length;

      for (var item in _mediaItems) {
        if (item.existingImage != null) {
          finalImages.add(item.existingImage!);
        } else if (item.newFile != null) {
          try {
            if (totalToUpload > 1) {
              setState(
                () => _uploadProgressText =
                    'Uploading images...\n$uploadedCount of $totalToUpload uploaded',
              );
            } else {
              setState(() => _uploadProgressText = 'Uploading image...');
            }

            final uploadedResult = await _cloudinaryService.uploadImage(
              item.newFile!,
            );
            if (uploadedResult == null) {
              throw Exception('Cloudinary upload returned null');
            }
            finalImages.add(
              DestinationImage(
                url: uploadedResult.secureUrl,
                publicId: uploadedResult.publicId,
              ),
            );
            uploadedCount++;
          } catch (e) {
            debugPrint('Cloudinary upload error: $e');
            _showError('We couldn\'t upload this image. Please try again.');
            setState(() {
              _isSaving = false;
              _uploadProgressText = null;
            });
            return;
          }
        }
      }

      final now = DateTime.now();

      final destinationData = Destination(
        id: widget.destination?.id ?? '',
        name: _nameController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        description: _descController.text.trim(),
        locationName: _locationController.text.trim(),
        latitude: double.tryParse(_latController.text),
        longitude: double.tryParse(_lngController.text),
        images: finalImages,
        isPopular: _isPopular,
        isActive: _isActive,
        displayOrder: int.tryParse(_orderController.text) ?? 0,
        createdAt: widget.destination?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.destination == null) {
        await _repository.createDestination(destinationData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destination created successfully.')),
          );
        }
      } else {
        await _repository.updateDestination(destinationData);
        if (mounted) {
          String msg = 'Destination updated successfully.';
          if (uploadedCount > 0) {
            msg =
                'Destination updated successfully. $uploadedCount images saved.';
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }

      _formIsDirty = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      _showError('Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('Unknown error: $e');
      _showError('We couldn\'t save the destination. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadProgressText = null;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_formIsDirty) {
      return true;
    }
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You have unsaved changes'),
        content: const Text('Do you want to stay or discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.destination != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: Text(
          isEditing ? 'Edit Destination' : 'Add Destination',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: PopScope(
        canPop: !_formIsDirty && !_isSaving,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          if (_isSaving) {
            return;
          }
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: AppSpacing.sm),
                _buildTextField(
                  'Destination Name *',
                  _nameController,
                  validator: _validateName,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(
                  'Short Description *',
                  _shortDescController,
                  validator: _validateShortDesc,
                  focusNode: _shortDescFocus,
                  maxLines: 2,
                  currentLength: _shortDescLength,
                  maxLength: 180,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(
                  'Full Description *',
                  _descController,
                  validator: _validateDesc,
                  focusNode: _descFocus,
                  maxLines: 5,
                  currentLength: _descLength,
                  maxLength: 2000,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildSectionTitle('Location'),
                const SizedBox(height: AppSpacing.sm),
                _buildTextField(
                  'Location Name *',
                  _locationController,
                  validator: _validateLocation,
                  focusNode: _locationFocus,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Latitude *',
                        _latController,
                        isNumeric: true,
                        validator: _validateLat,
                        focusNode: _latFocus,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTextField(
                        'Longitude *',
                        _lngController,
                        isNumeric: true,
                        validator: _validateLng,
                        focusNode: _lngFocus,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildSectionTitle('Media'),
                const SizedBox(height: AppSpacing.sm),
                _buildImagePicker(),
                const SizedBox(height: AppSpacing.lg),

                _buildSectionTitle('Settings'),
                const SizedBox(height: AppSpacing.sm),
                _buildTextField(
                  'Display Order *',
                  _orderController,
                  isNumeric: true,
                  validator: _validateOrder,
                  focusNode: _orderFocus,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Mark as Popular',
                    style: AppTextStyles.bodyMedium,
                  ),
                  activeThumbColor: AppColors.primary,
                  value: _isPopular,
                  onChanged: (val) {
                    setState(() {
                      _isPopular = val;
                      _formIsDirty = true;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active (Visible to Travelers)',
                    style: AppTextStyles.bodyMedium,
                  ),
                  activeThumbColor: AppColors.primary,
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                      _formIsDirty = true;
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _uploadProgressText ??
                                      (isEditing
                                          ? 'Saving changes...'
                                          : 'Creating destination...'),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Destination',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionHeading.copyWith(
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumeric = false,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    int? currentLength,
    int? maxLength,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        errorMaxLines: 3,
        counterText: maxLength != null
            ? '${currentLength ?? 0} / $maxLength'
            : null,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Destination Images', style: AppTextStyles.bodyMedium),
            Text(
              '${_mediaItems.length} / ${AppConstants.maxDestinationImages} images',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...List.generate(_mediaItems.length, (index) {
              final item = _mediaItems[index];
              return _buildThumbnail(item, index);
            }),
            if (_mediaItems.length < AppConstants.maxDestinationImages)
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      Text('Add Image', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(_MediaItem item, int index) {
    final isCover = index == 0;
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCover
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            image: DecorationImage(
              image: item.newFile != null
                  ? FileImage(File(item.newFile!.path)) as ImageProvider
                  : NetworkImage(item.existingImage!.url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isCover)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ),
        ),
        if (!isCover)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: InkWell(
              onTap: () => _setAsCover(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Set Cover',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
