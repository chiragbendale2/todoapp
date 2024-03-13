class Task {
  late String id;
  late String owner;
  late String title;
  late String description;
  late List<dynamic> editors;

  Task({
    required this.id,
    required this.owner,
    required this.title,
    required this.description,
    required this.editors,
  });

  // Convert a Task object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'title': title,
      'description': description,
      'editors': editors,
    };
  }

  // Create a Task object from a Firestore document snapshot
  factory Task.fromSnapshot(Map<String, dynamic> snapshot) {
    return Task(
      id: snapshot['id'],
      owner: snapshot['owner'],
      title: snapshot['title'],
      description: snapshot['description'],
      editors: snapshot['editors'],
    );
  }
}
