import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/contact_inquiry.dart';
import '../../../repositories/contact_inquiry_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/email_service.dart';
import '../../../widgets/common/app_status_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

class AdminInquiryReplyDialog extends StatefulWidget {
  final ContactInquiry inquiry;

  const AdminInquiryReplyDialog({
    super.key,
    required this.inquiry,
  });

  @override
  State<AdminInquiryReplyDialog> createState() =>
      _AdminInquiryReplyDialogState();
}

class _AdminInquiryReplyDialogState extends State<AdminInquiryReplyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ContactInquiryRepository();

  late TextEditingController _replyController;
  late TextEditingController _adminNotesController;

  late String _status;
  bool _sendEmail = true;
  bool _sendNotification = true;
  bool _isSending = false;

  final List<String> _statusOptions = [
    'resolved',
    'in_progress',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(
      text: widget.inquiry.adminReply ?? '',
    );
    _adminNotesController = TextEditingController(
      text: widget.inquiry.adminNotes ?? '',
    );

    // Default to 'resolved' when replying unless already set to in_progress/closed
    final currentStatus = widget.inquiry.status.toLowerCase();
    if (currentStatus == 'closed') {
      _status = 'closed';
    } else if (currentStatus == 'in_progress') {
      _status = 'in_progress';
    } else {
      _status = 'resolved';
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  Future<void> _sendReply() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    final replyText = _replyController.text.trim();
    final notesText = _adminNotesController.text.trim();

    try {
      // 1. Update Inquiry in Firestore
      await _repository.replyToInquiry(
        widget.inquiry.id,
        replyText,
        newStatus: _status,
        adminNotes: notesText.isNotEmpty ? notesText : null,
      );

      // 2. Find Traveler User ID if not stored directly
      String? targetUserId = widget.inquiry.userId;
      if (targetUserId == null || targetUserId.isEmpty) {
        try {
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.inquiry.email.trim())
              .limit(1)
              .get();
          if (userQuery.docs.isNotEmpty) {
            targetUserId = userQuery.docs.first.id;
          }
        } catch (e) {
          debugPrint('Could not resolve user by email: $e');
        }
      }

      // 3. Send in-app notification if enabled & target user found
      if (_sendNotification && targetUserId != null && targetUserId.isNotEmpty) {
        try {
          await NotificationRepository().sendNotification(
            userId: targetUserId,
            title: 'Response to your inquiry',
            message: replyText,
            type: 'inquiry_reply',
            recipientRole: 'traveler',
            relatedId: widget.inquiry.id,
            metadata: {
              'inquiryId': widget.inquiry.id,
              'originalMessage': widget.inquiry.message,
              'replyMessage': replyText,
              'customerName': widget.inquiry.name,
              'repliedAt': DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          debugPrint('Error sending in-app notification: $e');
        }
      }

      // 4. Send Email notification if enabled
      if (_sendEmail && widget.inquiry.email.isNotEmpty) {
        try {
          await EmailService.notifyInquiryReply(
            toEmail: widget.inquiry.email.trim(),
            customerName: widget.inquiry.name,
            userMessage: widget.inquiry.message,
            adminReply: replyText,
          );
        } catch (e) {
          debugPrint('Error sending inquiry reply email: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);

      // 5. Show Success Dialog
      await AppStatusDialog.showSuccess(
        context: context,
        title: 'Reply Sent Successfully!',
        message:
            'Your reply has been sent to ${widget.inquiry.name}. They will receive an in-app notification and email.',
        buttonText: 'Done',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      await AppStatusDialog.showError(
        context: context,
        title: 'Failed to Send Reply',
        message: 'An error occurred while sending your reply: $e',
        buttonText: 'Try Again',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyReplied = widget.inquiry.adminReply != null &&
        widget.inquiry.adminReply!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
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
                          color: const Color(0xFF1E6B52).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          color: Color(0xFF1E6B52),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAlreadyReplied
                                ? 'Update Reply'
                                : 'Reply to Inquiry',
                            style: AppTextStyles.sectionHeading.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            'To: ${widget.inquiry.name}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Form & Details Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Inquiry Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customer Inquiry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(widget.inquiry.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.inquiry.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryDark.withValues(alpha: 0.95),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.inquiry.email,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (widget.inquiry.phoneNumber != null &&
                                      widget.inquiry.phoneNumber!.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.inquiry.phoneNumber!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Status Selection
                        Text(
                          'Update Status to',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
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
                              backgroundColor: color.withValues(alpha: 0.08),
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

                        // Reply Message field
                        Text(
                          'Reply Message to Traveler *',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _replyController,
                          maxLines: 4,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'Type your official response to the traveler...',
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
                                color: Color(0xFF1E6B52),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a reply message';
                            }
                            if (val.trim().length < 5) {
                              return 'Reply must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Admin Internal Notes field
                        Text(
                          'Internal Admin Notes (Optional)',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _adminNotesController,
                          maxLines: 2,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Discussed pricing over call. Assigned to host team.',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
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
                                color: Color(0xFF1E6B52),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Notification Toggles
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Send in-app notification to traveler',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Traveler will receive a real-time notification in their app',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          activeColor: const Color(0xFF1E6B52),
                          value: _sendNotification,
                          onChanged: (val) {
                            setState(() {
                              _sendNotification = val ?? true;
                            });
                          },
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Send email copy to ${widget.inquiry.email}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Traveler receives formatted response in their inbox',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          activeColor: const Color(0xFF1E6B52),
                          value: _sendEmail,
                          onChanged: (val) {
                            setState(() {
                              _sendEmail = val ?? true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSending ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendReply,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      isAlreadyReplied ? 'Update & Send' : 'Send Reply',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6B52),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
