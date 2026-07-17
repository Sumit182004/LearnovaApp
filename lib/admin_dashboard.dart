import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

enum AdminPage {
  dashboard,
  syllabus,
  media,
  files,
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminPage currentPage = AdminPage.dashboard;

  final FirebaseStorage storage = FirebaseStorage.instance;

  String selectedClass = "Class 10";
  String selectedSubject = "Mathematics";

  bool isUploading = false;
  double uploadProgress = 0;

  List<Reference> uploadedFiles = [];
  bool isLoadingFiles = false;

  final Map<String, List<String>> subjectsByClass = {
    "Class 10": [
      "Mathematics",
      "Science",
      "English",
    ],
    "Class 12": [
      "Physics",
      "Chemistry",
      "Mathematics",
      "Biology",
    ],
  };

  List<String> get currentSubjects =>
      subjectsByClass[selectedClass] ?? [];

  void changeClass(String? value) {
    if (value == null) return;

    setState(() {
      selectedClass = value;

      if (!currentSubjects.contains(selectedSubject)) {
        selectedSubject = currentSubjects.first;
      }

      uploadedFiles.clear();
    });
  }

  void changeSubject(String? value) {
    if (value == null) return;

    setState(() {
      selectedSubject = value;
      uploadedFiles.clear();
    });
  }

  // ============================================================
  // UPLOAD JSON
  // ============================================================

  Future<void> uploadJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["json"],
    );

    if (result == null) return;

    final String? filePath = result.files.single.path;

    if (filePath == null) {
      showMessage("Unable to read selected file.");
      return;
    }

    final File file = File(filePath);
    final String fileName = result.files.single.name;

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    try {
      final Reference reference = storage.ref().child(
        "syllabus/$selectedClass/$selectedSubject/$fileName",
      );

      final UploadTask uploadTask = reference.putFile(
        file,
        SettableMetadata(
          contentType: "application/json",
        ),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) return;

        final int totalBytes = snapshot.totalBytes;

        if (totalBytes > 0) {
          setState(() {
            uploadProgress =
                snapshot.bytesTransferred / totalBytes;
          });
        }
      });

      await uploadTask;

      if (!mounted) return;

      setState(() {
        uploadProgress = 1;
      });

      showMessage(
        "JSON uploaded successfully.",
        color: Colors.green,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage(
        e.message ?? "JSON upload failed.",
        color: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "JSON upload failed: $e",
        color: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<void> uploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return;

    final String? filePath = result.files.single.path;

    if (filePath == null) {
      showMessage("Unable to read selected image.");
      return;
    }

    final File file = File(filePath);

    // Keep the real original filename and extension.
    final String fileName = result.files.single.name;

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    try {
      final Reference reference = storage.ref().child(
        "images/$selectedClass/$selectedSubject/$fileName",
      );

      final UploadTask uploadTask = reference.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) return;

        final int totalBytes = snapshot.totalBytes;

        if (totalBytes > 0) {
          setState(() {
            uploadProgress =
                snapshot.bytesTransferred / totalBytes;
          });
        }
      });

      await uploadTask;

      if (!mounted) return;

      setState(() {
        uploadProgress = 1;
      });

      showMessage(
        "Image uploaded successfully.",
        color: Colors.green,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage(
        e.message ?? "Image upload failed.",
        color: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Image upload failed: $e",
        color: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD SYLLABUS FILES
  // ============================================================

  Future<void> loadFiles() async {
    setState(() {
      isLoadingFiles = true;
      uploadedFiles.clear();
    });

    try {
      final Reference reference = storage.ref().child(
        "syllabus/$selectedClass/$selectedSubject",
      );

      final ListResult result = await reference.listAll();

      if (!mounted) return;

      setState(() {
        uploadedFiles = result.items;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage(
        e.message ?? "Unable to load files.",
        color: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Unable to load files: $e",
        color: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFiles = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE FILE
  // ============================================================

  Future<void> deleteFile(Reference fileReference) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete File"),
          content: Text(
            "Are you sure you want to delete ${fileReference.name}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await fileReference.delete();

      if (!mounted) return;

      showMessage(
        "File deleted successfully.",
        color: Colors.green,
      );

      await loadFiles();
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage(
        e.message ?? "Unable to delete file.",
        color: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Unable to delete file: $e",
        color: Colors.red,
      );
    }
  }

  // ============================================================
  // COMMON MESSAGE
  // ============================================================

  void showMessage(
      String message, {
        Color? color,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ============================================================
  // CLASS AND SUBJECT SELECTORS
  // ============================================================

  Widget selectors() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(
            labelText: "Select Class",
            border: OutlineInputBorder(),
          ),
          items: subjectsByClass.keys.map((className) {
            return DropdownMenuItem(
              value: className,
              child: Text(className),
            );
          }).toList(),
          onChanged: changeClass,
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: selectedSubject,
          decoration: const InputDecoration(
            labelText: "Select Subject",
            border: OutlineInputBorder(),
          ),
          items: currentSubjects.map((subject) {
            return DropdownMenuItem(
              value: subject,
              child: Text(subject),
            );
          }).toList(),
          onChanged: changeSubject,
        ),
      ],
    );
  }

  // ============================================================
  // UPLOAD PROGRESS
  // ============================================================

  Widget uploadProgressWidget() {
    if (!isUploading) {
      return const SizedBox.shrink();
    }

    final int percentage =
    (uploadProgress * 100).round();

    return Column(
      children: [
        const SizedBox(height: 25),

        LinearProgressIndicator(
          value: uploadProgress,
        ),

        const SizedBox(height: 10),

        Text(
          "$percentage%",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget dashboardPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Manage Learnova learning content from here.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          dashboardCard(
            icon: Icons.menu_book,
            title: "Manage Syllabus",
            description:
            "Upload chapter and syllabus JSON files.",
            onTap: () {
              setState(() {
                currentPage = AdminPage.syllabus;
              });
            },
          ),

          const SizedBox(height: 15),

          dashboardCard(
            icon: Icons.image,
            title: "Manage Media",
            description:
            "Upload images used in learning content.",
            onTap: () {
              setState(() {
                currentPage = AdminPage.media;
              });
            },
          ),

          const SizedBox(height: 15),

          dashboardCard(
            icon: Icons.folder,
            title: "Manage Files",
            description:
            "View and delete uploaded syllabus files.",
            onTap: () {
              setState(() {
                currentPage = AdminPage.files;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget dashboardCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 28,
          child: Icon(
            icon,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // MANAGE SYLLABUS
  // ============================================================

  Widget syllabusPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            "Manage Syllabus",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          selectors(),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed:
              isUploading ? null : uploadJson,
              icon: const Icon(
                Icons.upload_file,
              ),
              label: const Text(
                "Upload JSON File",
              ),
            ),
          ),

          uploadProgressWidget(),
        ],
      ),
    );
  }

  // ============================================================
  // MANAGE MEDIA
  // ============================================================

  Widget mediaPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            "Manage Media",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          selectors(),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed:
              isUploading ? null : uploadImage,
              icon: const Icon(
                Icons.image,
              ),
              label: const Text(
                "Upload Image",
              ),
            ),
          ),

          uploadProgressWidget(),
        ],
      ),
    );
  }

  // ============================================================
  // MANAGE FILES
  // ============================================================

  Widget filesPage() {
    return Column(
      children: [
        const Text(
          "Manage Files",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 25),

        selectors(),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed:
            isLoadingFiles ? null : loadFiles,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              "Load Files",
            ),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: isLoadingFiles
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : uploadedFiles.isEmpty
              ? const Center(
            child: Text(
              "No files loaded.",
            ),
          )
              : ListView.separated(
            itemCount:
            uploadedFiles.length,
            separatorBuilder:
                (context, index) {
              return const Divider();
            },
            itemBuilder:
                (context, index) {
              final Reference file =
              uploadedFiles[index];

              return ListTile(
                leading: const Icon(
                  Icons.description,
                ),
                title: Text(
                  file.name,
                ),
                subtitle: Text(
                  selectedSubject,
                ),
                trailing: IconButton(
                  tooltip: "Delete File",
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    deleteFile(file);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAGE SWITCHING
  // ============================================================

  Widget currentPageWidget() {
    switch (currentPage) {
      case AdminPage.dashboard:
        return dashboardPage();

      case AdminPage.syllabus:
        return syllabusPage();

      case AdminPage.media:
        return mediaPage();

      case AdminPage.files:
        return filesPage();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Learnova Admin",
        ),
      ),

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Align(
                  alignment:
                  Alignment.bottomLeft,
                  child: Text(
                    "Learnova Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.dashboard,
                ),
                title: const Text(
                  "Dashboard",
                ),
                selected: currentPage ==
                    AdminPage.dashboard,
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    currentPage =
                        AdminPage.dashboard;
                  });
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.menu_book,
                ),
                title: const Text(
                  "Manage Syllabus",
                ),
                selected: currentPage ==
                    AdminPage.syllabus,
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    currentPage =
                        AdminPage.syllabus;
                  });
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.image,
                ),
                title: const Text(
                  "Manage Media",
                ),
                selected: currentPage ==
                    AdminPage.media,
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    currentPage =
                        AdminPage.media;
                  });
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.folder,
                ),
                title: const Text(
                  "Manage Files",
                ),
                selected:
                currentPage == AdminPage.files,
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    currentPage =
                        AdminPage.files;
                  });

                  loadFiles();
                },
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: currentPageWidget(),
      ),
    );
  }
}