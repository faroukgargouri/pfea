class Visite {
  final int? id;
  final String codeVisite;
  final String dateVisite;
  final String codeClient;
  final String raisonSociale;
  final String compteRendu;
  final int? userId;

  Visite({
    this.id,
    required this.codeVisite,
    required this.dateVisite,
    required this.codeClient,
    required this.raisonSociale,
    required this.compteRendu,
    this.userId,
  });

  factory Visite.fromJson(Map<String, dynamic> json) {
    return Visite(
      id: json['id'],
      codeVisite: json['codeVisite'],
      dateVisite: json['dateVisite'],
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
      'dateVisite': dateVisite,
      'codeClient': codeClient,
      'raisonSociale': raisonSociale,
      'compteRendu': compteRendu,
      'userId': userId,
    };
  }

  // ✅ copyWith pour modification sécurisée
  Visite copyWith({
    String? codeVisite,
    String? dateVisite,
    String? codeClient,
    String? raisonSociale,
    String? compteRendu,
    int? userId,
  }) {
    return Visite(
      id: id,
      codeVisite: codeVisite ?? this.codeVisite,
      dateVisite: dateVisite ?? this.dateVisite,
      codeClient: codeClient ?? this.codeClient,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      compteRendu: compteRendu ?? this.compteRendu,
      userId: userId ?? this.userId,
    );
  }
}
