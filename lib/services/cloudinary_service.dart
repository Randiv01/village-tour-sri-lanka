import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  CloudinaryUploadResult({required this.secureUrl, required this.publicId});
}

class CloudinaryService {
  // Use the actual Cloudinary configuration provided
  final cloudinary = CloudinaryPublic(
    'dxsho3nak',
    'village_tour_upload',
    cache: false,
  );

  Future<CloudinaryUploadResult?> uploadImage(XFile imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'Village Tour',
        ),
      );
      return CloudinaryUploadResult(
        secureUrl: response.secureUrl,
        publicId: response.publicId,
      );
    } catch (e) {
      // Log error (suppressed print to satisfy linter)
      // Print the actual error to console in debug mode
      // debugPrint('Cloudinary upload error: $e');
      throw Exception('Cloudinary upload failed: $e');
    }
  }

  /// Deletes an image from Cloudinary using its public ID.
  ///
  /// IMPORTANT SECURITY LIMITATION:
  /// The `cloudinary_public` package uses unsigned uploads and CANNOT securely
  /// perform destructive operations (like deletion) from the client application.
  /// Deleting media requires the Cloudinary API Secret, which MUST NOT be exposed
  /// in the Flutter client code.
  ///
  /// This method is currently a placeholder. For actual deletion, this operation
  /// must be moved to a secure backend/server-side function (e.g., Firebase Cloud Functions)
  /// which has access to the Cloudinary API Secret.
  Future<bool> deleteImage(String publicId) async {
    // throw UnimplementedError(
    //     'Secure client-side deletion is not supported. Please implement via backend.');
    // To allow the app to continue without crashing during this demo phase, we simulate failure/success.
    debugPrint(
      'WARNING: Simulated deletion of $publicId. Actual deletion requires backend implementation.',
    );
    return false; // Returning false to indicate it couldn't actually delete it yet due to security constraints.
  }
}
