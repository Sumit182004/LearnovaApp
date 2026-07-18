// google_profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GoogleProfilePage extends StatefulWidget {
  final User user;

  const GoogleProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<GoogleProfilePage> createState() =>
      _GoogleProfilePageState();
}

class _GoogleProfilePageState
    extends State<GoogleProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();

  bool isLoading = false;

  String selectedStandard = "class10";

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .set({
      "uid": widget.user.uid,
      "name": widget.user.displayName ?? "",
      "email": widget.user.email ?? "",
      "phone": phoneController.text.trim(),
      "standard": selectedStandard,
      "role": "student",
      "photoUrl": widget.user.photoURL ?? "",
      "assessmentCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      "/assessment",
      arguments: selectedStandard,
    );

    setState(() {
      isLoading = false;
    });
  }

  InputDecoration inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xff081062),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Container(
                width: 370,
                padding:
                const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
                child: Column(
                  children: [

                    CircleAvatar(
                      radius: 45,
                      backgroundImage:
                      NetworkImage(
                        widget.user.photoURL ??
                            "",
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      widget.user.displayName ??
                          "",
                      style:
                      const TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      widget.user.email ?? "",
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller:
                      phoneController,
                      keyboardType:
                      TextInputType.phone,
                      decoration:
                      inputDecoration(
                        "Phone Number",
                        Icons.phone,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Enter Phone Number";
                        }

                        if (value.length !=
                            10) {
                          return "Invalid Phone Number";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<
                        String>(
                      value:
                      selectedStandard,
                      decoration:
                      inputDecoration(
                        "Select Standard",
                        Icons.school,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                          "class10",
                          child: Text(
                              "Class 10"),
                        ),
                        DropdownMenuItem(
                          value:
                          "class12",
                          child: Text(
                              "Class 12"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStandard =
                          value!;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width:
                      double.infinity,
                      height: 55,
                      child:
                      ElevatedButton(
                        onPressed:
                        isLoading
                            ? null
                            : saveProfile,
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                              0xff081062),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors
                              .white,
                        )
                            : const Text(
                          "Continue",
                          style:
                          TextStyle(
                            color: Colors
                                .white,
                            fontSize:
                            18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}