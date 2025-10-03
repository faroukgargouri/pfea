
class ReferencementClient {
  final String site;
  final String rep;
  final String codeClient;
  final String raisonSocial;
  final String gamme;
  final String codeArticle;
  final String desArticle;
  final int? qteCmd;
  final int qteVenduP;
  final int? qteVenduA;

  ReferencementClient({
    required this.site,
    required this.rep,
    required this.codeClient,
    required this.raisonSocial,
    required this.gamme,
    required this.codeArticle,
    required this.desArticle,
    this.qteCmd,
    required this.qteVenduP,
    this.qteVenduA,
  });

  factory ReferencementClient.fromJson(Map<String, dynamic> json) {
    return ReferencementClient(
      site: json['site'] as String,
      rep: json['rep'] as String,
      codeClient: json['codeClient'] as String,
      raisonSocial: json['raisonSocial'] as String,
      gamme: json['gamme'] as String,
      codeArticle: json['codeArticle'] as String,
      desArticle: json['desArticle'] as String,
      qteCmd: json['qteCmd'] as int?,
      qteVenduP: json['qteVenduP'] as int,
      qteVenduA: json['qteVenduA'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site': site,
      'rep': rep,
      'codeClient': codeClient,
      'raisonSocial': raisonSocial,
      'gamme': gamme,
      'codeArticle': codeArticle,
      'desArticle': desArticle,
      'qteCmd': qteCmd,
      'qteVenduP': qteVenduP,
      'qteVenduA': qteVenduA,
    };
  }
}
