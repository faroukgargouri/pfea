class ReclamationArticle {
  final String codeArticle;
  final String nomArticle;
  final int quantite;
  final String? dateFabrication;
  final String? factureNo;
  final String? dateFacture;
  final double? montant;
  final String? observation;

  ReclamationArticle({
    required this.codeArticle,
    required this.nomArticle,
    required this.quantite,
    this.dateFabrication,
    this.factureNo,
    this.dateFacture,
    this.montant,
    this.observation,
  });

  factory ReclamationArticle.fromJson(Map<String, dynamic> json) {
    return ReclamationArticle(
      codeArticle: json['codeArticle'] ?? '',
      nomArticle: json['nomArticle'] ?? '',
      quantite: int.tryParse(json['quantite']?.toString() ?? '0') ?? 0, // ✅ conversion sûre
      dateFabrication: json['dateFabrication']?.toString(),
      factureNo: json['factureNo']?.toString(),
      dateFacture: json['dateFacture']?.toString(),
      montant: (json['montant'] != null)
          ? double.tryParse(json['montant'].toString())
          : null,
      observation: json['observation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeArticle': codeArticle,
      'nomArticle': nomArticle,
      'quantite': quantite,
      'dateFabrication': dateFabrication,
      'factureNo': factureNo,
      'dateFacture': dateFacture,
      'montant': montant,
      'observation': observation,
    };
  }
}
