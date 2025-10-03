class Representant {
  final int id;
  final String codeSage;
  final String fullName;
  final String email;
    final String? site;
  final String? password;

  Representant({
    required this.id,
    required this.codeSage,
    required this.fullName,
    required this.email,
    required this.site,
    this.password,
  });

  factory Representant.fromJson(Map<String, dynamic> json) {
    return Representant(
      id: json['id'] ?? 0,
      codeSage: json['codeSage'] ?? json['code_Sage'] ?? '', 
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      site: json ['site']?? '',
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeSage': codeSage, 
      'fullName': fullName,
      'email': email,
      'password': password,
      'site' : site,
    };
  }
}
