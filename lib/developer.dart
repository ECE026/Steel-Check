class Developer {
  final String id;
  final String name;
  final String course;
  final String image;
  
  Developer({
    required this.id,
    required this.name,
    required this.course,
    required this.image,
  });
  
  // You can add a factory constructor to create a Developer from a Map if needed.
  factory Developer.fromMap(Map<String, String> map) {
    return Developer(
      id: map['id']!,
      name: map['name']!,
      course: map['course']!,
      image: map['image']!,
    );
  }
}
