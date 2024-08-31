import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'AskAiScreen.dart';
class PhotoViewerScreen extends StatelessWidget {
  final String url;
  final String storageLocation;
  const PhotoViewerScreen(
      {super.key, required this.url, required this.storageLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1A74BD),
        title: const Text(
          'Photo Viewer',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: 'Ask AI',
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => AskAIScreen(
                        storageLocation: storageLocation,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var curve = Curves.easeInOut;
                        var tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                        var fadeAnimation = animation.drive(tween);
                        var scaleAnimation = Tween(begin: 0.95, end: 1.0)
                            .chain(CurveTween(curve: curve))
                            .animate(animation);

                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: ScaleTransition(
                            scale: scaleAnimation,
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/AskAiWhite.png',
                  width: 82,
                  height: 82,
                ),
              ),
            ),
          )

        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(
          color: Colors.white,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text('Failed to load image.'),
        ),
      ),
    );
  }
}
