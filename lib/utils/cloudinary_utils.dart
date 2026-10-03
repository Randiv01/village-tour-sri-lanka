class CloudinaryUtils {
  static String getOptimizedUrl(
    String originalUrl, {
    int width = 600,
    int height = 400,
  }) {
    if (originalUrl.contains('res.cloudinary.com') &&
        originalUrl.contains('/upload/')) {
      final parts = originalUrl.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/w_$width,h_$height,c_fill,q_auto,f_auto/${parts[1]}';
      }
    }
    return originalUrl;
  }
}
