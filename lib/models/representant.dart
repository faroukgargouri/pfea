class Representant {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String codeSage;
  final String role;

  Representant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.codeSage,
    required this.role,
  });

  factory Representant.fromJson(Map<String, dynamic> json) {
    // 👇 Vérifie que le champ id est bien un int, sinon lance une erreur claire
    if (json['id'] == null) {
      throw FormatException("Le champ 'id' est requis et ne peut pas être null.");
    }

    return Representant(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      codeSage: json['codeSage'] ?? '',
      role: json['role'] ?? 'Représentant',
    );
  }
}
