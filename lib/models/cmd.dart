// lib/models/cmd.dart
class Cmd {
  final String nCommand;
  final String? dateCmd;   // keep as String; UI parses if needed
  final String codeClient;
  final String raisonSocial; // maps "raison" or "raisonSocial"
  final String rep;
  final String ville;
  final String? dateExp;   // keep as String; UI parses if needed

  final double poids;
  final double mtht;
  final double mtttc;
  final double remise;

  // These are strings in your payload:
  final String soldee;     // "Soldée"/"Non soldée"
  final String etat;
  final String facturee;

  Cmd({
    required this.nCommand,
    required this.dateCmd,
    required this.codeClient,
    required this.raisonSocial,
    required this.rep,
    required this.ville,
    required this.dateExp,
    required this.poids,
    required this.mtht,
    required this.mtttc,
    required this.remise,
    required this.soldee,
    required this.etat,
    required this.facturee,
  });

  // --- helpers ---
  static String _s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString();

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString();
    final parsed = double.tryParse(s.replaceAll(',', '.'));
    return parsed ?? 0.0;
  }

  factory Cmd.fromJson(Map<String, dynamic> json) {
    return Cmd(
      nCommand: _s(json['nCommand'] ?? json['ncommand'] ?? json['nCommande']),
      dateCmd: _s(json['dateCmd'] ?? json['datecmd'] ?? json['dateCMD']),
      codeClient: _s(json['codeClient'] ?? json['codeclient']),
      raisonSocial: _s(json['raison'] ?? json['raisonSocial']),
      rep: _s(json['rep']),
      ville: _s(json['ville']),
      dateExp: _s(json['dateExp'] ?? json['dateexp']),
      poids: _d(json['poids']),
      mtht: _d(json['mtht']),
      mtttc: _d(json['mtttc']),
      remise: _d(json['remise']),
      soldee: _s(json['soldee']),
      etat: _s(json['etat']),
      facturee: _s(json['facturee']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nCommand': nCommand,
        'dateCmd': dateCmd,
        'codeClient': codeClient,
        'raison': raisonSocial,
        'rep': rep,
        'ville': ville,
        'dateExp': dateExp,
        'poids': poids,
        'mtht': mtht,
        'mtttc': mtttc,
        'remise': remise,
        'soldee': soldee,
        'etat': etat,
        'facturee': facturee,
      };
}
