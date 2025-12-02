import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_course_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final pages = [
      CoursesListPage(userId: user.uid),
      MyEnrollmentsPage(userId: user.uid),
      const AddCoursePage(),
    ];
    final titles = ['All Courses', 'My Enrollments', 'Add Course'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'My Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Course',
          ),
        ],
      ),
    );
  }
}

class CoursesListPage extends StatelessWidget {
  final String userId;
  const CoursesListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final coursesRef = FirebaseFirestore.instance.collection('courses');
    final enrollmentsRef = FirebaseFirestore.instance.collection('enrollments');

    return StreamBuilder<QuerySnapshot>(
      stream: coursesRef.orderBy('title').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No courses found.'));
        }

        final courses = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseId = course.id;
            final title = course['title'] as String? ?? 'Untitled';
            final description = course['description'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(title),
                subtitle: Text(description),
                trailing: StreamBuilder<QuerySnapshot>(
                  stream: enrollmentsRef
                      .where('userId', isEqualTo: userId)
                      .where('courseId', isEqualTo: courseId)
                      .snapshots(),
                  builder: (context, enrollSnap) {
                    final alreadyEnrolled =
                        enrollSnap.hasData && enrollSnap.data!.docs.isNotEmpty;

                    return ElevatedButton(
                      onPressed: alreadyEnrolled
                          ? null
                          : () async {
                              await enrollmentsRef.add({
                                'userId': userId,
                                'courseId': courseId,
                                'enrolledAt': FieldValue.serverTimestamp(),
                              });
                            },
                      child: Text(
                        alreadyEnrolled ? 'Enrolled' : 'Enroll',
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MyEnrollmentsPage extends StatelessWidget {
  final String userId;
  const MyEnrollmentsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final enrollmentsRef = FirebaseFirestore.instance.collection('enrollments');
    final coursesRef = FirebaseFirestore.instance.collection('courses');

    return StreamBuilder<QuerySnapshot>(
      stream: enrollmentsRef.where('userId', isEqualTo: userId).snapshots(),
      builder: (context, enrollSnap) {
        if (enrollSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!enrollSnap.hasData || enrollSnap.data!.docs.isEmpty) {
          return const Center(
            child: Text('You are not enrolled in any course.'),
          );
        }

        final enrollmentDocs = enrollSnap.data!.docs;
        final courseIds =
            enrollmentDocs.map((e) => e['courseId'] as String).toList();

        return FutureBuilder<QuerySnapshot>(
          future:
              coursesRef.where(FieldPath.documentId, whereIn: courseIds).get(),
          builder: (context, courseSnap) {
            if (courseSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!courseSnap.hasData || courseSnap.data!.docs.isEmpty) {
              return const Center(child: Text('No course data found.'));
            }

            final courses = courseSnap.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(course['title'] ?? 'Untitled'),
                    subtitle: Text(course['description'] ?? ''),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
