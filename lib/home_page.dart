import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:steel/developer_page.dart';
import 'package:steel/history_page.dart';
import 'package:steel/profile_page.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:developer' as devtools;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steel Check',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 39, 39, 39),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Define pages for bottom navigation.
  final List<Widget> _pages = const [
    HomePage(),
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(2, 255, 255, 255),
      // AppBar with hamburger drawer.
      appBar: AppBar(
        title: const Text(
          "Steel Check",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // DrawerHeader with logo and title.
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 65, 65, 65),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo.png", // Ensure this asset exists
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Steel Check",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Developer Team"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeveloperPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
      // Display the current page.
      body: _pages[_selectedIndex],
      // Replace BottomNavigationBar with CurvedNavigationBar.
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        color: Color.fromARGB(
            255, 255, 255, 255), // the color of the navigation bar
        buttonBackgroundColor: Color.fromARGB(
            255, 255, 255, 255), // the color of the active button
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: <Widget>[
          Image.asset(
            "assets/images/home.png", // Ensure these assets exist
            width: 24,
            height: 24,
          ),
          Image.asset(
            "assets/images/history_icon.png",
            width: 24,
            height: 24,
          ),
          Image.asset(
            "assets/images/profile.png",
            width: 24,
            height: 24,
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _cameraInitialization;
  String typeResult = '';
  String gradeResult = '';
  String uploadedImageUrl = '';
  File? capturedImage; // ✅ Store captured image

  late Interpreter _resnet;
  late Interpreter _typeModel;
  late Interpreter _gradeModel;

  List<String> typeLabels = [];
  List<String> gradeLabels = [];

  final cloudinary = CloudinaryPublic('ddonlymnx', 'steel09', cache: false);
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraInitialization = _initializeCamera();
    _loadLabels();
    _loadModels();
  }

  /// Initialize the back camera.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(backCamera, ResolutionPreset.medium);
    await _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
  }

    /// Load label files from assets.
    Future<void> _loadLabels() async {
      try {
        final typeTxt =
            await rootBundle.loadString('assets/models/type_labels.txt');
        final gradeTxt =
            await rootBundle.loadString('assets/models/grade_labels.txt');
        setState(() {
          typeLabels = typeTxt.split('\n').map((e) => e.trim()).toList();
          gradeLabels = gradeTxt.split('\n').map((e) => e.trim()).toList();
        });
      } catch (e) {
        devtools.log("❌ Failed to load labels: $e");
      }
    }

  /// Load the new models using the Interpreter API.
  Future<void> _loadModels() async {
    try {
      _resnet = await Interpreter.fromAsset(
          'assets/models/resnet_feature_extractor.tflite');
      _typeModel = await Interpreter.fromAsset(
          'assets/models/type_classifier_keras.tflite');
      _gradeModel = await Interpreter.fromAsset(
          'assets/models/grades_classifier_keras.tflite');
    } catch (e) {
      devtools.log("❌ Error loading models: $e");
    }
  }

  /// Capture an image using the camera, classify it, upload it, and save the results.
  Future<void> captureImage() async {
    if (!_cameraController.value.isInitialized) return;
    try {
      final XFile file = await _cameraController.takePicture();
      File imageFile = File(file.path);
      setState(() {
        capturedImage = imageFile; // ✅ Store captured image for preview
      });
      await classifyImage(imageFile);
    } catch (e) {
      devtools.log("❌ Error capturing image: $e");
    }
  }

  /// Classify the image using the new models.
  Future<void> classifyImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return;
      // Resize image to 224x224 as expected by the models.
      img.Image resized = img.copyResize(image, width: 224, height: 224);

      // Prepare input tensor with shape [1, 224, 224, 3]
      Float32List input = Float32List(1 * 224 * 224 * 3);
      int index = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          final r = img.getRed(pixel).toDouble();
          final g = img.getGreen(pixel).toDouble();
          final b = img.getBlue(pixel).toDouble();
          input[index++] = (b - 103.939); // B channel
          input[index++] = (g - 116.779); // G channel
          input[index++] = (r - 123.68); // R channel
        }
      }

      // Prepare output buffers.
      var resnetOutput = List.filled(2048, 0.0).reshape([1, 2048]);
      var typeOutput = List.filled(3, 0.0).reshape([1, 3]);
      var gradeOutput = List.filled(4, 0.0).reshape([1, 4]);

      // Run the ResNet feature extractor.
      _resnet.run(input.reshape([1, 224, 224, 3]), resnetOutput);

      // Run classifiers using the ResNet features.
      _typeModel.run(resnetOutput, typeOutput);
      _gradeModel.run(resnetOutput, gradeOutput);

      // Find the index with the highest probability for each classifier.
      int typeIndex = 0;
      double typeMax = -double.infinity;
      for (int i = 0; i < typeOutput[0].length; i++) {
        if (typeOutput[0][i] > typeMax) {
          typeMax = typeOutput[0][i];
          typeIndex = i;
        }
      }

      int gradeIndex = 0;
      double gradeMax = -double.infinity;
      for (int i = 0; i < gradeOutput[0].length; i++) {
        if (gradeOutput[0][i] > gradeMax) {
          gradeMax = gradeOutput[0][i];
          gradeIndex = i;
        }
      }

      setState(() {
        typeResult = typeLabels.isNotEmpty ? typeLabels[typeIndex] : "N/A";
        gradeResult = gradeLabels.isNotEmpty ? gradeLabels[gradeIndex] : "N/A";
      });

      // Upload the image after classification.
      await uploadImage(imageFile);
    } catch (e) {
      devtools.log("❌ Error during classification: $e");
    }
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    File imageFile = File(file.path);
    setState(() {
      capturedImage = imageFile;
    });
    await classifyImage(imageFile);
  }

  /// Upload image to Cloudinary.
  Future<void> uploadImage(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, folder: 'uploads'),
      );
      devtools.log("Uploaded image URL: ${response.secureUrl}");
      setState(() {
        uploadedImageUrl = response.secureUrl;
      });
    } catch (e) {
      devtools.log("Error uploading image: $e");
    }
  }

  /// Save image URL and classification results to Firebase Firestore.
  Future<void> saveToFirebase() async {
    devtools.log(
        "Before saving: uploadedImageUrl: $uploadedImageUrl, type: $typeResult, grade: $gradeResult");

    if (uploadedImageUrl.isEmpty || typeResult.isEmpty || gradeResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data incomplete, cannot save.")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated.")),
      );
      return;
    }

    final String userEmail = currentUser.email!;

    try {
      // Get the user's document reference from the 'users' collection using the user's email
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userEmail);

      // Save the data inside the user's document in Firestore
      await userDocRef.collection('history').add({
        'imageURL': uploadedImageUrl,
        'type': typeResult,
        'grade': gradeResult,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data saved successfully!")),
      );
      devtools.log("Data saved to Firestore successfully.");
    } catch (e) {
      devtools.log("Error saving data to Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save data.")),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _resnet.close();
    _typeModel.close();
    _gradeModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _cameraInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Camera Error: ${snapshot.error}"));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // Added instructional text here
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Text(
                    "Capture the Corrosion Closely for Better Accuracy",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: CameraPreview(_cameraController),
                ),
                if (capturedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        capturedImage!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Type: $typeResult",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Grade: $gradeResult",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: captureImage,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 7),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              elevation: 6,
                            ),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text("Capture"),
                          ),
                          ElevatedButton.icon(
                            onPressed: saveToFirebase,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 7),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              elevation: 6,
                            ),
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text("Save Data"),
                          ),
                          ElevatedButton.icon(
                            onPressed: pickImageFromGallery,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 7),
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              elevation: 6,
                            ),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text("Gallery"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
