class Client {
  final int? id;
  final String codeClient;
  final String raisonSociale;
  final String telephone;
  final String ville;

  Client({
    this.id,
    required this.codeClient,
    required this.raisonSociale,
    required this.telephone,
    required this.ville,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      codeClient: json['codeClient'],
      raisonSociale: json['raisonSociale'],
      telephone: json['telephone'],
      ville: json['ville'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeClient': codeClient,
      'raisonSociale': raisonSociale,
      'telephone': telephone,
      'ville': ville,
    };
  }

  Client copyWith({
    int? id,
    String? codeClient,
    String? raisonSociale,
    String? telephone,
    String? ville,
  }) {
    return Client(
      id: id ?? this.id,
      codeClient: codeClient ?? this.codeClient,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      telephone: telephone ?? this.telephone,
      ville: ville ?? this.ville,
    );
  }
}
