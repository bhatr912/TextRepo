import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';
class AdScreen extends StatefulWidget {
  final VoidCallback onAdComplete;

  const AdScreen({super.key, required this.onAdComplete});

  @override
  _AdScreenState createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> with TickerProviderStateMixin {
  List<Map<String, String>> ads = [];
  bool canSkip = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _timer;
  int _countdown = 6;
  int currentAdIndex = 0;
  late PageController _pageController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _loadRandomAds();
    _startSkipTimer();
    _initializeAnimation();
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadRandomAds() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Ads').get();
      if (snapshot.docs.isNotEmpty) {
        final random = math.Random();
        ads = snapshot.docs.map((doc) => {
          'imageUrl': doc['imageUrl'] as String,
          'adUrl': doc['adUrl'] as String,
        }).toList();
        ads.shuffle(random);
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ads: $e');
      }
    }
  }

  void _startSkipTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          canSkip = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _launchAdUrl(String? url) async {
    if (url != null) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  void _nextAd() {
    if (currentAdIndex < ads.length - 1) {
      _slideController.forward(from: 0.0).then((_) {
        setState(() {
          currentAdIndex++;
        });
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        _slideController.reverse();
      });
    }
  }

  void _previousAd() {
    if (currentAdIndex > 0) {
      _slideController.forward(from: 0.0).then((_) {
        setState(() {
          currentAdIndex--;
        });
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        _slideController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ads.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          // Ad Images
          PageView.builder(
            controller: _pageController,
            itemCount: ads.length,
            onPageChanged: (index) {
              setState(() {
                currentAdIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return FadeTransition(
                opacity: _animation,
                child: Image.network(
                  ads[index]['imageUrl']!,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skip button and timer
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: canSkip
                        ? ElevatedButton(
                      onPressed: () {
                        widget.onAdComplete();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('Skip Ad'),
                      ),
                    )
                        : CircularProgressIndicator(
                      value: (5 - _countdown) / 5,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                const Spacer(),
                // Ad content and CTA
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_slideController),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Special Promotion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click to explore exclusive offers and deals on our website!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _launchAdUrl(ads[currentAdIndex]['adUrl']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Visit Now',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Ad Navigation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: _previousAd,
                      ),

                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onPressed: _nextAd,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
