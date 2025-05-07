import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  final List<Map<String, String>> developers = const [
    {
      'name': 'Darlene Mae Dimaunahan',
      'course': 'Electronics Engineering Student',
      'image': 'assets/images/dar.jpg'
    },
    {
      'name': 'Maria Fetrice Esguerra',
      'course': 'Electronics Engineering Student',
      'image': 'assets/images/fet.jpg'
    },
    {
      'name': 'Joyce Myca Espiritu',
      'course': 'Electronics Engineering Student',
      'image': 'assets/images/jm.jpg'
    },
    {
      'name': 'Kim Cinderell Pestijo',
      'course': 'Electronics Engineering Student',
      'image': 'assets/images/kc.jpg'
    },
    {
      'name': 'Catherine Jane Pumeda',
      'course': 'Electronics Engineering Student',
      'image': 'assets/images/cat.jpg'
    },
    {
      'name': 'Steel Check',
      'course': 'Machine Learning',
      'image': 'assets/images/logo.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/about.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: developers.length,
        itemBuilder: (context, index) =>
            DeveloperCard(developer: developers[index]),
      ),
    );
  }
}

class DeveloperCard extends StatefulWidget {
  final Map<String, String> developer;
  const DeveloperCard({super.key, required this.developer});

  @override
  State<DeveloperCard> createState() => _DeveloperCardState();
}

class _DeveloperCardState extends State<DeveloperCard> {
  bool get isEditable => widget.developer['name'] == 'Steel Check';
  late TextEditingController visionController, missionController;

  @override
  void initState() {
    super.initState();
    visionController = TextEditingController();
    missionController = TextEditingController();
    if (isEditable) _loadDeveloperData();
  }

  Future<void> _loadDeveloperData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection("developer")
          .doc(widget.developer['name'])
          .get();
      if (doc.exists) {
        var data = doc.data();
        if (mounted) {
          setState(() {
            visionController.text = data?['vision'] ?? "No vision set.";
            missionController.text = data?['mission'] ?? "No mission set.";
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  @override
  void dispose() {
    visionController.dispose();
    missionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: AssetImage(widget.developer['image']!),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.developer['name']!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.developer['course']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (isEditable) ...[
                    const SizedBox(height: 4),
                    Text("Vision:",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(visionController.text,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text("Mission:",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(missionController.text,
                        style: const TextStyle(fontSize: 12)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
