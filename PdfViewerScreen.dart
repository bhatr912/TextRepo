import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'AskAiScreen.dart';

class PdfViewerScreen extends StatelessWidget {
  final String url;
  final String storageLocation;
  const PdfViewerScreen(
      {super.key, required this.url, required this.storageLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text('PDF Viewer',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400)),
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
      body: SfPdfViewer.network(
        url,
        initialZoomLevel: 1.0,
        enableDoubleTapZooming: true,
      ),
    );
  }
}
