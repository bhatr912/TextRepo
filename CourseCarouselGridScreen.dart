import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'CourseCardScreen.dart';
import 'CourseDetailScreen.dart';

class CourseCarouselGrid extends ConsumerStatefulWidget {
  const CourseCarouselGrid({super.key});

  @override
  _CourseCarouselGridState createState() => _CourseCarouselGridState();
}

class _CourseCarouselGridState extends ConsumerState<CourseCarouselGrid> {
  List<String> courses = [];
  List<Map<String, String>> adImages = []; // To store ad images and URLs
  String? _selectedProgram;
  bool _isLoading = true;
  bool _showFAB = false; // To control the visibility of the FAB

  @override
  void initState() {
    super.initState();
    _loadSelectedProgram();
    _checkUserRole();
    _fetchAdImages(); // Fetch ad images from Firestore
  }

  Future<void> _loadSelectedProgram() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProgram = prefs.getString('selectedProgram') ?? 'Home';
      if (_selectedProgram != 'Home') {
        fetchCourses();
      } else {
        _isLoading = false; // No courses to load if Home is selected
      }
    });
  }

  Future<void> _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    if (email != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'Users').doc(email).get();
      if (userDoc.exists) {
        bool isEditor = userDoc.get('editor') ?? false;
        bool isAdmin = userDoc.get('admin') ?? false;
        setState(() {
          _showFAB = isEditor || isAdmin;
        });
      }
    }
  }

  Future<void> fetchCourses() async {
    if (_selectedProgram != null && _selectedProgram != 'Home') {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Programs')
          .doc(_selectedProgram!)
          .collection('Courses')
          .get();

      final List<String> fetchedCourses =
      querySnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        courses = fetchedCourses;
        _isLoading = false; // Data loading complete
      });
    }
  }

  Future<void> _fetchAdImages() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Ads').get();
    final List<Map<String, String>> fetchedAds = querySnapshot.docs.map((doc) {
      return {
        'imageUrl': doc.get('imageUrl') as String,
        'adUrl': doc.get('adUrl') as String,
      };
    }).toList();

    setState(() {
      adImages = fetchedAds;
    });
  }
  void _showAddCourseDialog(BuildContext context) {
    TextEditingController courseController = TextEditingController();
    bool isAdding = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Course'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      hintText: "Course Name",
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                    String courseName = courseController.text.trim();
                    if (courseName.isEmpty) {
                      setState(() {
                        errorText = "Can't add empty course";
                      });
                      return;
                    }

                    setState(() {
                      isAdding = true;
                      errorText = null;
                    });

                    await _addCourse(courseName);

                    setState(() {
                      isAdding = false;
                    });

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF2880BC),
                        content: Text('Course successfully added'),
                      ),
                    );

                    // Fetch courses again to update the list
                    await fetchCourses();
                  },
                  child: isAdding
                      ? const CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCourse(String courseName) async {
    final programCollection = FirebaseFirestore.instance.collection('Programs');
    final bTechDoc = programCollection.doc(_selectedProgram);
    final coursesCollection = bTechDoc.collection('Courses');
    final bTechSnapshot = await bTechDoc.get();
    if (!bTechSnapshot.exists) {
      await bTechDoc.set({});
    }

    // Check if the course already exists
    final courseDoc = coursesCollection.doc(courseName);
    final courseSnapshot = await courseDoc.get();
    if (!courseSnapshot.exists) {
      // Add course to 'Courses' collection if it doesn't exist
      await courseDoc.set({});
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final filteredCourses =
    courses.where((course) => course.toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      floatingActionButton: _showFAB
          ? FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          _showAddCourseDialog(context);
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth > 800;

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses available'),
            );
          }

          if (filteredCourses.isEmpty) {
            return const Center(
              child: Text('No match found'),
            );
          }

          if (isLargeScreen) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: constraints.maxHeight,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0,
                      initialPage: 0,
                      enableInfiniteScroll: true,
                      reverse: false,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration: const Duration(
                          milliseconds: 3000),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.vertical,
                    ),
                    items: adImages.map((ad) {
                      return Builder(
                        builder: (BuildContext context) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                _navigateToUrl(ad['adUrl']!);
                              },
                              child: Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 6.0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    ad['imageUrl']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            child: CourseCard(
                              courseName: filteredCourses[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => CourseDetailScreen(
                                      courseName: filteredCourses[index],
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(tween);
                                      return SlideTransition(position: offsetAnimation, child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          } else {
            const double itemWidth = 180;
            const double itemHeight = 110;
            final int crossAxisCount = (constraints.maxWidth / itemWidth)
                .floor();

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 150,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
                      initialPage: 0,
                      enableInfiniteScroll: true,
                      reverse: false,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration: const Duration(
                          milliseconds: 3000),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.horizontal,
                    ),
                    items: adImages.map((ad) {
                      return Builder(
                        builder: (BuildContext context) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                _navigateToUrl(ad['adUrl']!);
                              },
                              child: Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 6.0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    ad['imageUrl']!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 8),
                  child: Text(
                    'Courses',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2880BC)),
                  ),
                ),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: itemWidth / itemHeight,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredCourses.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        child: CourseCard(
                          courseName: filteredCourses[index],
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => CourseDetailScreen(
                                  courseName: filteredCourses[index],
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  var offsetAnimation = animation.drive(tween);
                                  return SlideTransition(position: offsetAnimation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
  void _navigateToUrl(String url) async {
    if (url.isNotEmpty) {
      Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    }
  }
}
