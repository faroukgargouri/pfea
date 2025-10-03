class listefactures {
  final DateTime? dateFac;      // dateFac
  final String numFac;          // numFac
  final String numCmd;          // numCmd
  final String codeClient;      // codeClient
  final String raison;          // raison
  final String ville;           // ville
  final String rep;             // rep
  final String rep1;            // rep1
  final String tel;             // tel
  final String mdReg;           // mdReg
  final String autorisation;    // autorisation
  final int diffDate;           // diffDate

  final double mtttc;           // mtttc
  final double mtHt;            // mtHt
  final double mtRegle;         // mtRegle
  final double soldeFacture;    // soldeFacture
  final double soldeClient;     // soldeClient
  final double portClient;      // portClient
  final double cmdNliv;         // cmdNliv
  final double encours;         // encours

  const listefactures({
    required this.dateFac,
    required this.numFac,
    required this.numCmd,
    required this.codeClient,
    required this.raison,
    required this.ville,
    required this.rep,
    required this.rep1,
    required this.tel,
    required this.mdReg,
    required this.autorisation,
    required this.diffDate,
    required this.mtttc,
    required this.mtHt,
    required this.mtRegle,
    required this.soldeFacture,
    required this.soldeClient,
    required this.portClient,
    required this.cmdNliv,
    required this.encours,
  });

  // ---- JSON Helpers ----
  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory listefactures.fromJson(Map<String, dynamic> json) {
    return listefactures(
      dateFac: json['dateFac'] != null ? DateTime.tryParse(json['dateFac'].toString()) : null,
      numFac: json['numFac']?.toString() ?? '',
      numCmd: json['numCmd']?.toString() ?? '',
      codeClient: json['codeClient']?.toString() ?? '',
      raison: json['raison']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      rep: json['rep']?.toString() ?? '',
      rep1: json['rep1']?.toString() ?? '',
      tel: json['tel']?.toString() ?? '',
      mdReg: json['mdReg']?.toString() ?? '',
      autorisation: json['autorisation']?.toString() ?? '',
      diffDate: int.tryParse(json['diffDate']?.toString() ?? '0') ?? 0,
      mtttc: _asDouble(json['mtttc']),
      mtHt: _asDouble(json['mtht']),
      mtRegle: _asDouble(json['mtRegle']),
      soldeFacture: _asDouble(json['soldeFacture']),
      soldeClient: _asDouble(json['soldeClient']),
      portClient: _asDouble(json['portClient']),
      cmdNliv: _asDouble(json['cmdNliv']),
      encours: _asDouble(json['encours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateFac': dateFac?.toIso8601String(),
      'numFac': numFac,
      'numCmd': numCmd,
      'codeClient': codeClient,
      'raison': raison,
      'ville': ville,
      'rep': rep,
      'rep1': rep1,
      'tel': tel,
      'mdReg': mdReg,
      'autorisation': autorisation,
      'diffDate': diffDate,
      'mtttc': mtttc,
      'mtHt': mtHt,
      'mtRegle': mtRegle,
      'soldeFacture': soldeFacture,
      'soldeClient': soldeClient,
      'portClient': portClient,
      'cmdNliv': cmdNliv,
      'encours': encours,
    };
  }
}
