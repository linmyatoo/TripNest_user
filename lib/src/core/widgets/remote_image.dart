import 'package:flutter/material.dart';

/// A network image with consistent loading and error states.
///
/// The same `Image.network` + `errorBuilder` + `loadingBuilder` block was
/// copy-pasted across roughly eight widgets, each with slightly different
/// placeholders. This is the one implementation.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_not_supported,
    this.iconSize,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final image = (url == null || url!.isEmpty)
        ? _fallback()
        : Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          placeholderIcon,
          color: Colors.grey,
          size: iconSize ?? 24,
        ),
      ),
    );
  }
}
