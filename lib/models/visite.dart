class Visite {
  final int? id;
  final String codeVisite;
  final DateTime dateVisite;
  final String codeClient;
  final String raisonSociale;
  final String? compteRendu;
  final int userId;

  Visite({
    this.id,
    required this.codeVisite,
    required this.dateVisite,
    required this.codeClient,
    required this.raisonSociale,
    this.compteRendu,
    required this.userId,
  });

  // ✅ copyWith ajouté
  Visite copyWith({
    int? id,
    String? codeVisite,
    DateTime? dateVisite,
    String? codeClient,
    String? raisonSociale,
    String? compteRendu,
    int? userId,
  }) {
    return Visite(
      id: id ?? this.id,
      codeVisite: codeVisite ?? this.codeVisite,
      dateVisite: dateVisite ?? this.dateVisite,
      codeClient: codeClient ?? this.codeClient,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      compteRendu: compteRendu ?? this.compteRendu,
      userId: userId ?? this.userId,
    );
  }

  factory Visite.fromJson(Map<String, dynamic> json) {
    return Visite(
      id: json['id'],
      codeVisite: json['codeVisite'],
      dateVisite: DateTime.parse(json['dateVisite']),
      codeClient: json['codeClient'],
      raisonSociale: json['raisonSociale'],
      compteRendu: json['compteRendu'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeVisite': codeVisite,
      'dateVisite': dateVisite.toIso8601String(), // ✅ ISO8601 pour API .NET
      'codeClient': codeClient,
      'raisonSociale': raisonSociale,
      'compteRendu': compteRendu,
      'userId': userId,
    };
  }
}
