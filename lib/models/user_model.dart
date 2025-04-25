class User {
  final String? id;
  final String email;
  final String username;
  final String name;
  final String password;
  final String contact;
  final String location;

  User({
    this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.password,
    required this.contact,
    required this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      name: json['name'],
      password: json['password'] ?? '',
      contact: json['contact'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'name': name,
      'password': password,
      'contact': contact,
      'location': location,
    };
  }
}
