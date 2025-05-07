// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;

// class SegmentationScreen extends StatefulWidget {
//   final File? filePath;

//   const SegmentationScreen(this.filePath, {super.key});

//   @override
//   State<SegmentationScreen> createState() => _SegmentationScreenState();
// }

// class _SegmentationScreenState extends State<SegmentationScreen>
//     with SingleTickerProviderStateMixin {
//   bool isProcessing = false;
//   String? classificationResult;
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   List<Rect> predefinedBoxes = [];

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );

//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );

//     _controller.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void generatePredefinedBoundingBoxes(Size imageSize) {
//     predefinedBoxes.clear();
//     int rows = 4;
//     int cols = 4;
//     double boxWidth = imageSize.width / cols;
//     double boxHeight = imageSize.height / rows;

//     for (int i = 0; i < rows; i++) {
//       for (int j = 0; j < cols; j++) {
//         predefinedBoxes.add(Rect.fromLTWH(
//           j * boxWidth,
//           i * boxHeight,
//           boxWidth,
//           boxHeight,
//         ));
//       }
//     }
//   }

//   void startSegmentation(Size imageSize) async {
//     setState(() {
//       isProcessing = true;
//       classificationResult = null;
//       generatePredefinedBoundingBoxes(imageSize);
//     });

//     _controller.forward();

//     await Future.delayed(const Duration(seconds: 3));

//     String classification = await detectColorAndClassify(widget.filePath!);

//     setState(() {
//       isProcessing = false;
//       classificationResult = classification;
//     });

//     _controller.reset();
//   }

//   void saveResult() {
//     print("Result saved: $classificationResult");
//   }

//   Future<String> detectColorAndClassify(File imageFile) async {
//     final image = img.decodeImage(await imageFile.readAsBytes());

//     if (image == null) {
//       return "Class A";
//     }

//     const brownMin = Color(0xFF8B4513);
//     const brownMax = Color(0xFFD2B48C);

//     bool hasBrown = false;

//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         int pixel = image.getPixel(x, y);
//         Color color = Color(pixel);

//         if (_isBrown(color, brownMin, brownMax)) {
//           hasBrown = true;
//           break;
//         }
//       }
//       if (hasBrown) break;
//     }

//     if (hasBrown) {
//       List<String> brownClasses = ["Class C", "Class D"];
//       return brownClasses[Random().nextInt(brownClasses.length)];
//     }

//     return "Class A";
//   }

//   bool _isBrown(Color color, Color min, Color max) {
//     return (color.red >= min.red &&
//         color.red <= max.red &&
//         color.green >= min.green &&
//         color.green <= max.green &&
//         color.blue >= min.blue &&
//         color.blue <= max.blue);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Image Segmentation"),
//         backgroundColor: Colors.grey[850],
//         shadowColor: Colors.black,
//         elevation: 10,
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 20),
//               if (widget.filePath != null)
//                 LayoutBuilder(
//                   builder: (context, constraints) {
//                     final imageSize = Size(
//                         constraints.maxWidth, constraints.maxWidth * 3 / 4);

//                     return Stack(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black54,
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(15),
//                             child: Image.file(
//                               widget.filePath!,
//                               width: constraints.maxWidth,
//                               height: constraints.maxWidth * 3 / 4,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         if (isProcessing || classificationResult != null)
//                           Positioned(
//                             top: 10,
//                             left: 10,
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withOpacity(0.5),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 isProcessing
//                                     ? "Processing..."
//                                     : "Corrosion Type: $classificationResult",
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         if (isProcessing)
//                           ...predefinedBoxes.map(
//                             (box) => Positioned(
//                               left: box.left,
//                               top: box.top,
//                               child: Container(
//                                 width: box.width * _animation.value,
//                                 height: box.height * _animation.value,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(
//                                     color: Colors.primaries[Random()
//                                         .nextInt(Colors.primaries.length)],
//                                     width: 2,
//                                   ),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     );
//                   },
//                 )
//               else
//                 const Text(
//                   "No image selected",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               const SizedBox(height: 20),
//               if (classificationResult != null)
//                 Text(
//                   "Corrosion Detected: $classificationResult",
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white70,
//                   ),
//                 ),
//               const SizedBox(height: 20),
//               if (isProcessing)
//                 const Column(
//                   children: [
//                     Text("Processing...",
//                         style: TextStyle(fontSize: 16, color: Colors.white70)),
//                     SizedBox(height: 16),
//                     CircularProgressIndicator(),
//                   ],
//                 ),
//               const SizedBox(height: 20),
//               if (!isProcessing && classificationResult == null)
//                 ElevatedButton(
//                   onPressed: () {
//                     final imageSize = MediaQuery.of(context).size;
//                     startSegmentation(imageSize);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                     backgroundColor: Colors.grey[800],
//                     foregroundColor: Colors.white,
//                     elevation: 10,
//                     shadowColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   child: const Text(
//                     "Start Segmentation",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 )
//               else if (classificationResult != null)
//                 ElevatedButton(
//                   onPressed: saveResult,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 30, vertical: 15),
//                     backgroundColor: Colors.grey[800],
//                     foregroundColor: Colors.white,
//                     elevation: 10,
//                     shadowColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   child: const Text(
//                     "Save Result",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//       backgroundColor: Colors.grey[900],
//     );
//   }
// }
