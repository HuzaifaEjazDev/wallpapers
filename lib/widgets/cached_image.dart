import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    required this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  static final Map<String, Uint8List> _cache = {};
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    // Check if image is already cached
    if (_cache.containsKey(widget.imageUrl)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200 && mounted) {
        _cache[widget.imageUrl] = response.bodyBytes;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If image is cached, display it immediately
    if (_cache.containsKey(widget.imageUrl)) {
      Widget image = Image.memory(
        _cache[widget.imageUrl]!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
      
      if (widget.borderRadius != BorderRadius.zero) {
        image = ClipRRect(
          borderRadius: widget.borderRadius,
          child: image,
        );
      }
      
      return image;
    }

    // Show error state
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }

    // Show loading state
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white38,
          strokeWidth: 2,
        ),
      ),
    );
  }
}