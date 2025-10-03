class Reliquat {
  final String? codeClient;
  final String? numeroCommande;
  final String? dateCommande;
  final double? val_total;
  final String? refart;
  final double? qtecommande;
  final double? qtelivree;
  final double? solde;
  final double? valLigne;
  final String? desArt;
  final String? site;

  Reliquat({
    this.codeClient,
    this.numeroCommande,
    this.dateCommande,
    this.val_total,
    this.refart,
    this.qtecommande,
    this.qtelivree,
    this.solde,
    this.valLigne,
    this.desArt,
    this.site,
  });

  factory Reliquat.fromJson(Map<String, dynamic>? json) {
    try {
      // Validate input
      if (json == null || json is! Map<String, dynamic>) {
        print('Invalid JSON input for Reliquat: $json');
        return Reliquat(); // Return default instance if input is invalid
      }

      return Reliquat(
        codeClient: json['codeclient'] as String?,
        numeroCommande: json['numcommande'] as String?,
        dateCommande: json['dateCMD'] as String?,
        val_total: (json['val_total'] as num?)?.toDouble(),
        refart: json['refart'] as String?,
        qtecommande: (json['qtecommande'] as num?)?.toDouble(),
        qtelivree: (json['qtelivrée'] as num?)?.toDouble(),
        solde: (json['solde'] as num?)?.toDouble(),
        valLigne: (json['val_ligne'] as num?)?.toDouble(),
        desArt: json['desArt'] as String?,
        site: json['site'] as String?,
      );
    } catch (e) {
      print('Error parsing Reliquat from JSON: $e, Data: $json');
      return Reliquat(); // Return default instance on error
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'codeclient': codeClient,
      'numcommande': numeroCommande,
      'dateCMD': dateCommande,
      'val_total': val_total,
      'refart': refart,
      'qtecommande': qtecommande,
      'qtelivrée': qtelivree,
      'solde': solde,
      'val_ligne': valLigne,
      'desArt': desArt,
      'site': site,
    };
  }
}