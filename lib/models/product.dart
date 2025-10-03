import '../data/api_config.dart';

class Product {
  final String id;
  final String itmref;
  final int tclcod;
  final String itmdes1;
  final int id_famillearticle;
  final int id_souscategorie;
  final double prix;
  final String DESIGNATIONCategorie;
  final String DesignationGamme;
  final String DesignationFamille;
  final String DesignationSousFamille;
  final String DesignationSKU;
  final String Quantity;

  /// 🔹 chemin relatif fourni par le backend (ex: "/products/PRD001.png")
  final String imageArticle;

  /// 🔹 construit l’URL complète selon apiBaseUrl défini dans api_config.dart
  String get fullImageUrl {
    if (imageArticle.isEmpty) return "";
    // éviter doublons de / si backend renvoie déjà "/products/..."
    return "$apiBaseUrl${imageArticle.startsWith("/") ? "" : "/"}$imageArticle";
  }

  const Product({
    required this.id,
    required this.itmref,
    required this.tclcod,
    required this.itmdes1,
    required this.id_famillearticle,
    required this.id_souscategorie,
    required this.prix,
    required this.DESIGNATIONCategorie,
    required this.DesignationGamme,
    required this.DesignationFamille,
    required this.DesignationSousFamille,
    required this.DesignationSKU,
    required this.Quantity,
    required this.imageArticle,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      itmref: (json['itmref'] ?? '').toString(),
      tclcod: _toInt(json['tclcod']),
      itmdes1: (json['itmdes1'] ?? '').toString(),
      id_famillearticle: _toInt(json['id_famillearticle']),
      id_souscategorie: _toInt(json['id_souscategorie']),
      prix: _toDouble(json['prix']),
      DESIGNATIONCategorie: (json['DESIGNATIONCategorie'] ?? '').toString(),
      DesignationGamme: (json['DesignationGamme'] ?? '').toString(),
      DesignationFamille: (json['DesignationFamille'] ?? '').toString(),
      DesignationSousFamille: (json['DesignationSousFamille'] ?? '').toString(),
      DesignationSKU: (json['DesignationSKU'] ?? '').toString(),
      Quantity: (json['Quantity'] ?? '').toString(),
      imageArticle: (json['imageArticle'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itmref': itmref,
        'tclcod': tclcod,
        'itmdes1': itmdes1,
        'id_famillearticle': id_famillearticle,
        'id_souscategorie': id_souscategorie,
        'prix': prix,
        'DESIGNATIONCategorie': DESIGNATIONCategorie,
        'DesignationGamme': DesignationGamme,
        'DesignationFamille': DesignationFamille,
        'DesignationSousFamille': DesignationSousFamille,
        'DesignationSKU': DesignationSKU,
        'Quantity': Quantity,
        'imageArticle': imageArticle,
      };

  Product copyWith({
    String? id,
    String? itmref,
    int? tclcod,
    String? itmdes1,
    int? id_famillearticle,
    int? id_souscategorie,
    double? prix,
    String? DESIGNATIONCategorie,
    String? DesignationGamme,
    String? DesignationFamille,
    String? DesignationSousFamille,
    String? DesignationSKU,
    String? Quantity,
    String? imageArticle,
  }) {
    return Product(
      id: id ?? this.id,
      itmref: itmref ?? this.itmref,
      tclcod: tclcod ?? this.tclcod,
      itmdes1: itmdes1 ?? this.itmdes1,
      id_famillearticle: id_famillearticle ?? this.id_famillearticle,
      id_souscategorie: id_souscategorie ?? this.id_souscategorie,
      prix: prix ?? this.prix,
      DESIGNATIONCategorie: DESIGNATIONCategorie ?? this.DESIGNATIONCategorie,
      DesignationGamme: DesignationGamme ?? this.DesignationGamme,
      DesignationFamille: DesignationFamille ?? this.DesignationFamille,
      DesignationSousFamille: DesignationSousFamille ?? this.DesignationSousFamille,
      DesignationSKU: DesignationSKU ?? this.DesignationSKU,
      Quantity: Quantity ?? this.Quantity,
      imageArticle: imageArticle ?? this.imageArticle,
    );
  }

  @override
  String toString() => 'Product($itmref • $itmdes1 • ${prix.toStringAsFixed(2)})';

  // --- helpers ---------------------------------------------------------------
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
