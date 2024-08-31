import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'AskAiScreen.dart';
import 'PdfViewerScreen.dart';
import 'PhotoViewerScreen.dart';

class BNPTemplateScreen extends StatelessWidget {
  final String name;
  final String url;
  final String storageLocation;
  const BNPTemplateScreen({
    super.key,
    required this.name,
    required this.url,
    required this.storageLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A74BD), Color(0xFF1A74BD)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/cuklogo.jpg',
                          width: 100, // Adjust the width as needed
                          height: 100, // Adjust the height as needed
                          fit: BoxFit
                              .cover, // Ensures the image covers the entire oval
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A74BD)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final Uri uri = Uri.parse(url);
                            final String lowerCaseUrl = url.toLowerCase();

                            if (lowerCaseUrl.contains('.pdf')) {
                              if (kIsWeb) {
                                // User is in a web environment
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              } else {
                                // User is not in a web environment
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
                                      url: url,
                                      storageLocation: storageLocation,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeOutCubic;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(tween);
                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
                              }
                            } else if (lowerCaseUrl.contains('.png') ||
                                lowerCaseUrl.contains('.jpeg') ||
                                lowerCaseUrl.contains('.jpg')) {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => PhotoViewerScreen(
                                    url: url,
                                    storageLocation: storageLocation,
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeOutCubic;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    var offsetAnimation = animation.drive(tween);
                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            } else {
                              // Handle other file types or default action
                              if (kIsWeb) {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              } else {
                                // Default action for non-web environment
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A74BD),
                          ),
                          child: const Text('Read'),
                        ),
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
                                'assets/images/AskAi.png',
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
