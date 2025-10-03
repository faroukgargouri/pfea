// File: Models/Entities.cs
using System;

namespace TabletteNaoura.Models
{
    // -----------------------
    // PRODUCTS (Articles)
    // -----------------------
    // Covers all SELECT aliases used in your SQL:
    //  id / Id, itmref / Name, itmdes1, Categorie, DESIGNATIONCategorie,
    //  Gamme, DesignationGamme, Famille/Famille1..5, DesignationFamille2..5,
    //  SousFamille, DesignationSousFamille, SKU, DesignationSKU,
    //  Marque, image, prix, etc.
    public class Article
    {
        // Common identifiers
        public string id { get; set; } = "";   // alias: "id"
        public string Id { get; set; } = "";   // alias: "Id" (some queries)
        public string itmref { get; set; } = "";   // ITMREF_0 alias
        public string Name { get; set; } = "";     // some queries alias ITMREF_0 as Name
        public string itmdes1 { get; set; } = "";  // ITMDES1_0 alias

        // Category / gamme
        public string? Categorie { get; set; }                 // TCLCOD_0
        public string? DESIGNATIONCategorie { get; set; }
        public string? Gamme { get; set; }                     // TSICOD_1
        public string? DesignationGamme { get; set; }

        // Family levels (various queries use these)
        public string? Famille { get; set; }                   // TSICOD_2 in GetAllFilters
        public string? DesignationFamille { get; set; }
        public string? Famille1 { get; set; }                  // TCLCOD_0 or TSICOD_1 depending on query
        public string? Famille2 { get; set; }                  // TSICOD_2
        public string? DesignationFamille2 { get; set; }
        public string? Famille3 { get; set; }                  // TSICOD_3
        public string? DesignationFamille3 { get; set; }
        public string? Famille4 { get; set; }                  // TSICOD_4
        public string? DesignationFamille4 { get; set; }
        public string? Famille5 { get; set; }                  // Z_TSI6_0
        public string? DesignationFamille5 { get; set; }

        // SousFamille + SKU
        public string? SousFamille { get; set; }               // TSICOD_3 (sometimes referred to as SousFamille)
        public string? DesignationSousFamille { get; set; }
        public string? SKU { get; set; }                       // TSICOD_4
        public string? DesignationSKU { get; set; }

        // Brand (in some queries: Z_MARQUE_0 Marque)
        public string? Marque { get; set; }

        // Media & price
        public string image { get; set; } = "";                // often ITMREF_0
        public decimal prix { get; set; }                      // computed in SQL
    }

    // -----------------------
    // FAMILIES / SUB-FAMILIES
    // -----------------------
    public class SousFamille
    {
        public string Code { get; set; } = "";
        public string Libelle { get; set; } = "";
    }

    public class SousFamille2
    {
        public string Code { get; set; } = "";
        public string Libelle { get; set; } = "";
    }

    public class FamilleArticle
    {
        public string Code { get; set; } = "";
        public string Libelle { get; set; } = "";
    }

    // -----------------------
    // CLIENTS
    // -----------------------
    // Matches aliases in SqlServiceClients.QuerySelect
    public class Client
    {
        public string bpcnum { get; set; } = "";     // T.BPRNUM_0
        public string bpcnam { get; set; } = "";     // concat(...) bpcnam
        public string? bpcnamFull { get; set; }      // optional, if you ever need full name separately

        public string? id_rep { get; set; }          // L.REP_0
        public string? id_rep1 { get; set; }         // L.REP_1
        public string? id_comm { get; set; }         // '' id_comm

        public string? Adresse_defaut { get; set; }  // D1.BPAADDLIG_0 + ' ' + D1.BPAADDLIG_1
        public string? Tel { get; set; }             // D.TEL_0
        public string? gouvernerat { get; set; }     // D.CTY_0

        public decimal? LongitudeClient { get; set; } // D.ZLONG_0
        public decimal? LatitudeClient  { get; set; } // D.ZLATIT_0

        public string? Email { get; set; }           // D.WEB_0
        public string? Site  { get; set; }           // CASE ... Site

        public string? Adresse_liv { get; set; }     // D.BPAADDLIG_0 + ' ' + D.BPAADDLIG_1
        public string? Regime_Taxe { get; set; }     // C.VACBPR_0
        public string? Condition_Payement { get; set; } // PTE.TEXTE_0

        public decimal? Encours_Autorise { get; set; } // C.OSTAUZ_0
        public string?  Control_Encours  { get; set; } // CASE C.OSTCTL_0 ...
        public decimal? Total_Encours    { get; set; } // ZENCOURS.MONTANT_0

        public string?  Matricule_Fiscale { get; set; } // T.EECNUM_0
        public string?  Famille_Client    { get; set; }  // STAT2.TEXTE_0

        public string?  RefCommandeClient  { get; set; } // Z.CUSORDREF_0
        public string?  DateCommandeClient { get; set; } // Z.ORDDAT_0 (string to avoid parsing issues)
        public string?  NCommande          { get; set; } // Z.SOHNUM_0

        public decimal? MtLigneHT  { get; set; }     // Z.ORDHT_0
        public decimal? MtLigneTTC { get; set; }     // Z.ORDTTC_0

        public decimal? CmdEncorsNonSoldeeNonLivree { get; set; } // subquery
    }
}
