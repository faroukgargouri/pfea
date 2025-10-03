// lib/models/derniere_facture.dart
class DerniereFacture {
  final int qteArticle;
  final String dateArticle;
  final String codeArticle;
  final String codeClient;
  final String desArticle;
  final String secteurClient;
  final double prixHT;
  final double prixTTC;
  final double prixU;

  DerniereFacture({
    required this.qteArticle,
    required this.dateArticle,
    required this.codeArticle,
    required this.codeClient,
    required this.desArticle,
    required this.secteurClient,
    required this.prixHT,
    required this.prixTTC,
    required this.prixU,
  });

  factory DerniereFacture.fromJson(Map<String, dynamic> json) {
    return DerniereFacture(
      qteArticle: (json['qteArticle'] as num).toInt(),
      dateArticle: json['dateArticle'] as String,
      codeArticle: json['codeArticle'] as String,
      codeClient: json['codeClient'] as String,
      desArticle: json['desArticle'] as String,
      secteurClient: json['secteurClient'] as String,
      prixHT: (json['prixHT'] as num).toDouble(),
      prixTTC: (json['prixTTC'] as num).toDouble(),
      prixU: (json['prixU'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qteArticle': qteArticle,
      'dateArticle': dateArticle,
      'codeArticle': codeArticle,
      'codeClient': codeClient,
      'desArticle': desArticle,
      'secteurClient': secteurClient,
      'prixHT': prixHT,
      'prixTTC': prixTTC,
      'prixU': prixU,
    };
  }
}