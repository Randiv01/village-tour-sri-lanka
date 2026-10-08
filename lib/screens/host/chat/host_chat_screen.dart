import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../../../../services/cloudinary_service.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';


class HostChatScreen extends StatefulWidget {
  final String touristId;
  final String touristName;
  final String touristImage;
  final String touristLanguages;
  final String homestayId;
  final String homestayTitle;
  final String packagePrice;

  const HostChatScreen({
    super.key,
    required this.touristId,
    required this.touristName,
    required this.touristImage,
    required this.touristLanguages,
    required this.homestayId,
    required this.homestayTitle,
    required this.packagePrice,
  });

  @override
  State<HostChatScreen> createState() => _HostChatScreenState();
}

class _HostChatScreenState extends State<HostChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GoogleTranslator _translator = GoogleTranslator();
  
  String _sinhalaPreview = 'Ready';
  bool _isTranslating = false;
  String _chatId = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = '${widget.touristId}_${currentUserId}_${widget.homestayId}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageChanged(String text) async {
    if (text.isEmpty) {
      setState(() {
        _sinhalaPreview = 'Ready';
        _isTranslating = false;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translation = await _translator.translate(text, from: 'si', to: 'en');
      setState(() {
        _sinhalaPreview = translation.text;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _sinhalaPreview = 'Translation failed';
        _isTranslating = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    final translatedText = _sinhalaPreview == 'Ready' || _sinhalaPreview == 'Translation failed' ? text : _sinhalaPreview;

    _messageController.clear();
    setState(() {
      _sinhalaPreview = 'Ready';
    });

    final messageData = {
      'text': text,
      'translatedText': translatedText,
      'senderId': currentUserId,
      'receiverId': widget.touristId,
      'homestayId': widget.homestayId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };

    try {
      if (_editingMessageId != null) {
        await FirebaseFirestore.instance
            .collection('hostChats')
            .doc(_chatId)
            .collection('messages')
            .doc(_editingMessageId)
            .update({
          'text': text,
          'translatedText': translatedText,
          'timestamp': FieldValue.serverTimestamp(),
          'edited': true,
        });
        setState(() => _editingMessageId = null);
      } else {
        await FirebaseFirestore.instance
            .collection('hostChats')
            .doc(_chatId)
            .collection('messages')
            .add(messageData);
      }
          
      // Update chat metadata
      await FirebaseFirestore.instance.collection('hostChats').doc(_chatId).set({
        'touristId': widget.touristId,
        'hostId': currentUserId,
        'homestayId': widget.homestayId,
        'lastMessage': text,
        'lastTranslatedMessage': translatedText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${widget.touristId}': FieldValue.increment(1),
        'touristName': widget.touristName,
        'homestayTitle': widget.homestayTitle,
      }, SetOptions(merge: true));
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('hostChats')
        .doc(_chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  void _startEditing(String messageId, String currentText) {
    setState(() {
      _editingMessageId = messageId;
      _messageController.text = currentText;
      _onMessageChanged(currentText);
    });
  }

  Future<void> _pickFile() async {
    List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc'],
    );
    
    if (result.isNotEmpty && mounted) {
      final file = result.first;
      if (file.path == null) return;

      setState(() {
        _isTranslating = true;
      });

      try {
        final cloudinaryService = CloudinaryService();
        final uploadResult = await cloudinaryService.uploadImage(XFile(file.path!));

        if (uploadResult != null) {
          final imageUrl = uploadResult.secureUrl;
          final isImage = file.extension?.toLowerCase() == 'jpg' || file.extension?.toLowerCase() == 'png' || file.extension?.toLowerCase() == 'jpeg';

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return;

          final messageData = {
            'text': isImage ? '[Image Attached]' : '[File Attached: ${file.name}]',
            'translatedText': isImage ? '[Image Attached]' : '[File Attached: ${file.name}]',
            'imageUrl': isImage ? imageUrl : null,
            'fileUrl': !isImage ? imageUrl : null,
            'senderId': currentUserId,
            'receiverId': widget.touristId,
            'homestayId': widget.homestayId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          };

          await FirebaseFirestore.instance
              .collection('hostChats')
              .doc(_chatId)
              .collection('messages')
              .add(messageData);

          await FirebaseFirestore.instance.collection('hostChats').doc(_chatId).set({
            'touristId': widget.touristId,
            'hostId': currentUserId,
            'homestayId': widget.homestayId,
            'lastMessage': isImage ? '[Image Attached]' : '[File Attached: ${file.name}]',
            'lastTranslatedMessage': isImage ? '[Image Attached]' : '[File Attached: ${file.name}]',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCount_${widget.touristId}': FieldValue.increment(1),
            'touristName': widget.touristName,
            'homestayTitle': widget.homestayTitle,
          }, SetOptions(merge: true));

          _scrollToBottom();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File attached: ${file.name}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isTranslating = false;
          });
        }
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
              _onMessageChanged(val.recognizedWords);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.touristImage.isNotEmpty ? NetworkImage(widget.touristImage) : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.touristImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E6B52),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.touristName,
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD1B3)),
                        ),
                        child: Text(
                          'GUIDE',
                          style: AppTextStyles.caption.copyWith(color: const Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Speaks ${widget.touristLanguages}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPackageHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7F5),
                image: DecorationImage(
                  image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Subtle texture
                  opacity: 0.3,
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: _buildMessagesList(),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPackageHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, color: Color(0xFFC47F46), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.homestayTitle} • 21 Aug',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.packagePrice,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E6B52)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hostChats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data?.docs ?? [];
        
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Say Ayubowan!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index].data() as Map<String, dynamic>;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            final isMe = msg['senderId'] == currentUserId;
            
            DateTime time = DateTime.now();
            if (msg['timestamp'] != null) {
              time = (msg['timestamp'] as Timestamp).toDate();
            }
            final timeStr = DateFormat('h:mm a').format(time);

            return _buildMessageBubble(
              messageId: messages[index].id,
              isMe: isMe,
              text: msg['text'] ?? '',
              translatedText: msg['translatedText'] ?? '',
              timeStr: timeStr,
              imageUrl: msg['imageUrl'],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String messageId,
    required bool isMe,
    required String text,
    required String translatedText,
    required String timeStr,
    String? imageUrl,
  }) {
    // For the guide:
    // Outgoing (isMe): text is Sinhala, translatedText is English. So primary = text, secondary = translatedText.
    // Incoming (!isMe): text is English, translatedText is Sinhala. So primary = translatedText, secondary = text.
    final primaryText = isMe ? text : translatedText;
    final secondaryText = isMe ? translatedText : text;

    return GestureDetector(
      onLongPress: () {
        if (!isMe) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primaryDark),
                    title: Text('Edit Message', style: AppTextStyles.bodyMedium),
                    onTap: () {
                      Navigator.pop(context);
                      _startEditing(messageId, text);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Message', style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(messageId);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.border,
              child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF1E6B52) : const Color(0xFFFAFAF7),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (primaryText.isNotEmpty)
                        Text(
                          primaryText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isMe ? Colors.white : AppColors.primaryDark,
                            height: 1.5,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, color: isMe ? Colors.white24 : AppColors.border),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'English: ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isMe ? const Color(0xFFFFD1B3) : const Color(0xFFC47F46),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: secondaryText,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isMe ? Colors.white : AppColors.primaryDark,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$timeStr • ${isMe ? 'Delivered' : 'Translated from English'}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF1E6B52)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 20), // Balance the spacing
        ],
      ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AUTO-ASSIST',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Translate to English',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E6B52)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFC47F46)),
                const Spacer(),
                const Icon(Icons.translate, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'English Preview:',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isTranslating 
                    ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _sinhalaPreview,
                        style: AppTextStyles.caption.copyWith(color: const Color(0xFFC47F46), fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            onChanged: _onMessageChanged,
                            decoration: InputDecoration(
                              hintText: 'Type a message in Sinhala...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : AppColors.textSecondary),
                          onPressed: _listen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E6B52),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
