import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:async';
import 'dart:io' show Platform;

import '../../models/mockup/product_model.dart';
import '../../viewmodels/mockup_provider.dart';

class MockupResultScreen extends StatefulWidget {
  final String taskKey;
  final Product product;
  final Variant variant;

  const MockupResultScreen({
    super.key,
    required this.taskKey,
    required this.product,
    required this.variant,
  });

  @override
  State<MockupResultScreen> createState() => _MockupResultScreenState();
}

class _MockupResultScreenState extends State<MockupResultScreen> {
  Timer? _pollTimer;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Starts polling for mockup task status
  void _startPolling() {
    final mockupProvider = Provider.of<MockupProvider>(context, listen: false);

    // Poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isPolling) {
        timer.cancel();
        return;
      }

      await mockupProvider.getMockupTaskResult(widget.taskKey);

      if (mockupProvider.mockupResult != null) {
        final status = mockupProvider.mockupResult!['status'];
        if (status == 'completed' || status == 'failed') {
          setState(() {
            _isPolling = false;
          });
          timer.cancel();
        }
      }
    });

    // Initial fetch - delay until after first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mockupProvider.getMockupTaskResult(widget.taskKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Mockup'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          if (!_isPolling)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                _shareMockup();
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.green.shade900, // Dark green for top half
              Colors.grey.shade900,  // Dark grey for bottom half
            ],
          ),
        ),
        child: Consumer<MockupProvider>(
          builder: (context, provider, child) {
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error generating mockup',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.error!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final result = provider.mockupResult;
            if (result == null) {
              return _buildLoadingState();
            }

            final status = result['status'];

            if (status == 'pending' || status == 'processing') {
              return _buildLoadingState();
            }

            if (status == 'failed') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Mockup generation failed',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            // Status is completed
            final mockups = result['mockups'] as List?;
            if (mockups == null || mockups.isEmpty) {
              return Center(
                child: Text(
                  'No mockups generated',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              );
            }

            return _buildMockupGallery(mockups);
          },
        ),
      ),
    );
  }

  /// Builds the loading state UI
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Generating your mockup...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take a few moments',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the mockup gallery UI with generated images
  Widget _buildMockupGallery(List mockups) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mockup Generated!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${mockups.length} mockup${mockups.length > 1 ? 's' : ''} created',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Mockup Images
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: mockups.map((mockup) {
                // Try different possible URL fields
                String? mockupUrl = mockup['mockup_url'];
                if (mockupUrl == null &&
                    mockup['extra'] != null &&
                    (mockup['extra'] as List).isNotEmpty) {
                  final extra = mockup['extra'][0];
                  mockupUrl = extra['url'];
                }

                if (mockupUrl == null) {
                  // Fallback - create a placeholder for now
                  mockupUrl =
                      'https://via.placeholder.com/800x600/6C63FF/FFFFFF?text=Mockup+Generated';
                }

                final String displayName =
                    mockup['display_name'] ?? mockup['placement'] ?? 'Mockup';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: GestureDetector(
                            onTap: () => _showFullScreenPreview(
                              context,
                              mockupUrl!,
                              displayName,
                            ),
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: mockupUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  height: 400,
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 400,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.error, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Check if mockupUrl is not null before downloading
                                    if (mockupUrl != null) {
                                      _downloadMockupImage(mockupUrl, displayName);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Unable to download: Invalid image URL'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white, // White border
                                    ),
                                    foregroundColor: Colors.white, // White text
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Create Another Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.add, color: Colors.white), // White icon
              label: const Text('Create Another Mockup', style: TextStyle(color: Colors.white)), // White text
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6C63FF), // Purple background to match theme
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows full screen preview of mockup image
  void _showFullScreenPreview(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (BuildContext context) {
        return _FullScreenImageViewer(imageUrl: imageUrl, title: title);
      },
    );
  }

  /// Downloads the mockup image to device Download directory
  Future<void> _downloadMockupImage(String imageUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading: $fileName'),
        ),
      );
      
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied to save image'),
          ),
        );
        return;
      }
      
      // Download image data
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // Get the Download directory
        final directory = await getExternalStorageDirectory();
        String downloadPath;
        
        if (Platform.isAndroid) {
          // For Android, navigate to the Download directory
          downloadPath = '${directory!.path.split('/Android')[0]}/Download';
        } else {
          // For other platforms, use the documents directory
          final docDir = await getApplicationDocumentsDirectory();
          downloadPath = docDir.path;
        }
        
        // Create a file name
        final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '$downloadPath/${sanitizedFileName}_$timestamp.png';
        
        // Write image data to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to Downloads: $sanitizedFileName.png'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download image: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download image: $e'),
        ),
      );
    }
  }

  /// Shares the first mockup image
  Future<void> _shareMockup() async {
    try {
      final mockupProvider = Provider.of<MockupProvider>(context, listen: false);
      final result = mockupProvider.mockupResult;
      
      if (result != null && result['mockups'] != null && result['mockups'].isNotEmpty) {
        final mockups = result['mockups'] as List;
        final firstMockup = mockups.first;
        final imageUrl = firstMockup['mockup_url'] as String?;
        
        if (imageUrl != null) {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preparing image for sharing...'),
            ),
          );
          
          // Download image data
          final response = await http.get(Uri.parse(imageUrl));
          
          if (response.statusCode == 200) {
            // Create a temporary file
            final tempDir = await getTemporaryDirectory();
            final fileName = 'mockup_${DateTime.now().millisecondsSinceEpoch}.png';
            final filePath = '${tempDir.path}/$fileName';
            final file = File(filePath);
            
            // Write image data to file
            await file.writeAsBytes(response.bodyBytes);
            
            // Share the file with error handling
            try {
              final XFile xFile = XFile(filePath);
              await Share.shareXFiles(
                [xFile],
                text: 'Check out this awesome mockup I created!',
              );
            } catch (shareError) {
              // Fallback: copy URL to clipboard
              await Clipboard.setData(ClipboardData(text: imageUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing failed. Image URL copied to clipboard instead.'),
                  ),
                );
              }
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to download image for sharing'),
                ),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No image available to share'),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No mockup available to share'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share mockup: $e'),
          ),
        );
      }
    }
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageViewer({required this.imageUrl, required this.title});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  /// Zooms in the image viewer
  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(1.0, 5.0);
    _setZoom(newScale);
  }

  /// Zooms out the image viewer
  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(1.0, 5.0);
    _setZoom(newScale);
  }

  /// Sets the zoom level for the image viewer
  void _setZoom(double scale) {
    setState(() {
      _currentScale = scale;
      _transformationController.value = Matrix4.diagonal3Values(
        scale,
        scale,
        1.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.zoom_out), onPressed: _zoomOut),
            IconButton(icon: const Icon(Icons.zoom_in), onPressed: _zoomIn),
          ],
        ),
        body: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, size: 48, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
