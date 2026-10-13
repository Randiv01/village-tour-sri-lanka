import 'package:flutter/material.dart';
import '../../../models/contact_inquiry.dart';
import '../../../repositories/contact_inquiry_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

class AdminInquiryDialog extends StatefulWidget {
  final ContactInquiry? inquiry; // If null, create mode; otherwise edit mode

  const AdminInquiryDialog({super.key, this.inquiry});

  @override
  State<AdminInquiryDialog> createState() => _AdminInquiryDialogState();
}

class _AdminInquiryDialogState extends State<AdminInquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ContactInquiryRepository();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _messageController;
  late TextEditingController _adminNotesController;

  late String _status;
  bool _isSaving = false;

  final List<String> _statusOptions = [
    'pending',
    'in_progress',
    'resolved',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    final inq = widget.inquiry;
    _nameController = TextEditingController(text: inq?.name ?? '');
    _emailController = TextEditingController(text: inq?.email ?? '');
    _phoneController = TextEditingController(text: inq?.phoneNumber ?? '');
    _countryController = TextEditingController(text: inq?.country ?? 'Sri Lanka');
    _messageController = TextEditingController(text: inq?.message ?? '');
    _adminNotesController = TextEditingController(text: inq?.adminNotes ?? '');
    _status = inq?.status.toLowerCase() ?? 'pending';
    if (!_statusOptions.contains(_status)) {
      _status = 'pending';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _messageController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.inquiry == null) {
        // Create
        final newInquiry = ContactInquiry(
          id: '',
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          country: _countryController.text.trim().isNotEmpty
              ? _countryController.text.trim()
              : 'Sri Lanka',
          message: _messageController.text.trim(),
          status: _status,
          adminNotes: _adminNotesController.text.trim().isNotEmpty
              ? _adminNotesController.text.trim()
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repository.createInquiryByAdmin(newInquiry);
      } else {
        // Update
        final updatedInquiry = widget.inquiry!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          country: _countryController.text.trim(),
          message: _messageController.text.trim(),
          status: _status,
          adminNotes: _adminNotesController.text.trim().isNotEmpty
              ? _adminNotesController.text.trim()
              : null,
          updatedAt: DateTime.now(),
        );
        await _repository.updateInquiry(updatedInquiry);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.inquiry == null
                ? 'Inquiry added successfully'
                : 'Inquiry updated successfully',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save inquiry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'in_progress':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return AppColors.primary;
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.inquiry != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note : Icons.add_comment,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isEdit ? 'Inquiry Details & Edit' : 'Add New Inquiry',
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status selector
                        Text('Status', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statusOptions.map((opt) {
                            final isSelected = _status == opt;
                            final color = _getStatusColor(opt);
                            return ChoiceChip(
                              label: Text(
                                _formatStatusLabel(opt),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: color,
                              backgroundColor: color.withValues(alpha: 0.1),
                              side: BorderSide(
                                color: color.withValues(alpha: 0.4),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _status = opt;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Submitter name
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name *',
                          icon: Icons.person_outline,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Submitter email
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address *',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter email';
                            }
                            if (!val.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Phone and Country Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildTextField(
                                controller: _countryController,
                                label: 'Country',
                                icon: Icons.public_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Inquiry Message
                        _buildTextField(
                          controller: _messageController,
                          label: 'Inquiry Message *',
                          icon: Icons.message_outlined,
                          maxLines: 4,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter inquiry message';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Admin Internal Notes
                        _buildTextField(
                          controller: _adminNotesController,
                          label: 'Admin Internal Notes & Reply Log',
                          icon: Icons.assignment_outlined,
                          hintText: 'e.g., Contacted traveler via WhatsApp. Provided taxi rate.',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Create Inquiry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: AppColors.textSecondary)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
