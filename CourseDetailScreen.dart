import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studifyy/Screens/AddBNPScreen.dart';
import 'package:studifyy/Screens/AdminScreen.dart';
import '../main.dart';
import 'BNPScreen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseName;
  const CourseDetailScreen({super.key, required this.courseName});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  bool isEditor = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    if (email != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(email).get();
      if (userDoc.exists) {
        setState(() {
          isEditor = userDoc.get('editor') ?? false;
          isAdmin = userDoc.get('admin') ?? false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // This removes the default back button
        backgroundColor: const Color(0xFF1A74BD),
        title: ValueListenableBuilder<bool>(
          valueListenable: _isSearching,
          builder: (context, isSearching, child) {
            return isSearching
                ? TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(color: Color(0xFF2880BC)),
                    ),
                    style: const TextStyle(color: Color(0xFF2880BC)),
                    autofocus: true,
                    onChanged: (query) {
                      ref.read(searchQueryProvider.notifier).state = query;
                    },
                  )
                : Row(
                    children: [
                      MouseRegion(
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
                      const SizedBox(
                        width: 16,
                      ),
                      Text(widget.courseName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  );
          },
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isSearching,
            builder: (context, isSearching, child) {
              return Row(
                children: [
                  /*
                  if ((isEditor || isAdmin) &&
                      MediaQuery.of(context).size.width <= 800)
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddBNPScreen(
                              selectedCourse: widget.courseName,
                            ),
                          ),
                        );
                      },
                    ),
                   */
                  IconButton(
                    icon: Icon(isSearching ? Icons.close : Icons.search,
                        color: Colors.white),
                    onPressed: () {
                      _isSearching.value = !_isSearching.value;
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                ],
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2880BC), Color(0xFF2880BC)],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            return Row(
              children: [
                NavigationRail(
                  minWidth: 120,
                  selectedIndex: _tabController.index,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _tabController.index = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: const IconThemeData(color: Color(0xFF2880BC)),
                  selectedLabelTextStyle: const TextStyle(fontSize: 16, color: Color(0xFF2880BC)),
                  unselectedLabelTextStyle: const TextStyle(fontSize: 16, color: Color(0xFF2880BC)),
                  indicatorColor: const Color(0xFF2880BC), // Set the indicator color to blue
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.book),
                      selectedIcon: Icon(Icons.book),
                      label: Padding(
                        padding: EdgeInsets.only(bottom: 32.0),
                        child: Text('Books'),
                      ),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.note),
                      selectedIcon: Icon(Icons.note),
                      label: Padding(
                        padding: EdgeInsets.only(bottom: 32.0),
                        child: Text('Notes'),
                      ),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.description),
                      selectedIcon: Icon(Icons.description),
                      label: Padding(
                        padding: EdgeInsets.only(bottom: 32.0),
                        child: Text('Papers'),
                      ),
                    ),
                    if (isEditor)
                      const NavigationRailDestination(
                        icon: Icon(Icons.add),
                        selectedIcon: Icon(Icons.add),
                        label: Padding(
                          padding: EdgeInsets.only(bottom: 32.0),
                          child: Text('Add'),
                        ),
                      ),
                    if (isEditor && isAdmin)
                      const NavigationRailDestination(
                        icon: Icon(Icons.admin_panel_settings),
                        selectedIcon: Icon(Icons.admin_panel_settings),
                        label: Padding(
                          padding: EdgeInsets.only(bottom: 32.0),
                          child: Text('Admin'),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BNPScreen(type: 'Books', courseName: widget.courseName),
                      BNPScreen(type: 'Notes', courseName: widget.courseName),
                      BNPScreen(type: 'Papers', courseName: widget.courseName),
                      if (isEditor)
                        AddBNPScreen(selectedCourse: widget.courseName),
                      if (isEditor && isAdmin)
                        AdminScreen(courseName: widget.courseName),
                    ],
                  ),
                ),
              ],
            );

          } else {
            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor:
                      const Color(0xFF2880BC), // Text color of the selected tab
                  unselectedLabelColor: const Color(
                      0xFF2880BC), // Text color of the unselected tabs
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16), // Bold text for selected tab
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16), // Bold text for unselected tabs
                  tabs: const [
                    Tab(text: 'Books'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Papers'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BNPScreen(type: 'Books', courseName: widget.courseName),
                      BNPScreen(type: 'Notes', courseName: widget.courseName),
                      BNPScreen(type: 'Papers', courseName: widget.courseName),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
