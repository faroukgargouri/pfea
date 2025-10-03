
using System;
using System.Collections.Generic;
using System.Linq;
using System.Configuration;
using Microsoft.Data.SqlClient; // ✅ not System.Data.SqlClient
 // for AppSettings and ConnectionStrings

namespace TabletteNaoura.DTS.SQL
{
    public static class SqlScripts
    {
        // Example: read a simple appSetting
        public static string NomDossier =
#pragma warning disable CS8601 // Possible null reference assignment.
            System.Configuration.ConfigurationManager.AppSettings["NomDossier"];
#pragma warning restore CS8601 // Possible null reference assignment.

        // Example: read a connection string named "Base_Sage"
        public static string ConnexionSage =>
            System.Configuration.ConfigurationManager.ConnectionStrings["Base_Sage"].ConnectionString;

       
        public static string GetAllFactureNonRgl = @"SELECT  [AMTLOC_0] as MontantFac
      ,[BPR_0]  as 'CodeClient'
      ,[NUM_0]  AS 'NumFac'
      ,[INVDAT_0] as 'DateFac'
      ,cast ([SOLDE_0]  as decimal (12  , 3) )	as 'ResteReg'
      ,[DUDDAT_0] as 'Echeance'
      ,[INVREF_0] as 'NumCmd'
      ,[DATEDIF_0] as 'DiffDate'
      ,[SALFCY_0] as 'Site'
      ,[CPY_0]
      ,[BPINAM_0]
      ,[BPDADDLIG_0]
      ,[BPDADDLIG1_0]
      ,[BPDADDLIG2_0]
      ,[BPDCTY_0]
      ,[REP0_0]
      ,[REP1_0]
      ,[XAUTORISE_0]
      ,[NBCDE_0]
  FROM [" + NomDossier + @"].[ZFACIMPTAB]
  where (BPR_0=@CodeClient and [REP0_0]=@codeRep) or  (BPR_0=@CodeClient and [REP1_0]=@codeRep) ";
        public static string GetAllFactureNonRglSuperieurA5DT = @"SELECT[AMTLOC_0] as MontantFac
      ,[BPR_0]  as 'CodeClient'
      ,[NUM_0] AS 'NumFac'
      ,[INVDAT_0] as 'DateFac'
      ,cast([SOLDE_0]  as decimal (12  , 3) )	as 'ResteReg'
      ,[DUDDAT_0] as 'Echeance'
      ,[INVREF_0] as 'NumCmd'
      ,[DATEDIF_0] as 'DiffDate'
      ,[SALFCY_0] as 'Site'
      ,[CPY_0]
      ,[BPINAM_0]
      ,[BPDADDLIG_0]
      ,[BPDADDLIG1_0]
      ,[BPDADDLIG2_0]
      ,[BPDCTY_0]
      ,[REP0_0]
      ,[REP1_0]
      ,[XAUTORISE_0]
      ,[NBCDE_0]
        FROM [" + NomDossier + @"].[ZFACIMPTAB]
        where
       (BPR_0= 'MS005' and[REP0_0]= 'GMS' and[SOLDE_0]  > 5.000)
  or(BPR_0= 'MS005' and[REP1_0]= 'ALA' and[SOLDE_0]  > 5.000)";
        public static string GetDateDernierFacture = @"select max([INVDAT_0]) as 'DateArticle'	FROM [" + NomDossier + @"].[ZREFCLTART] where   [BPCINV_0]=@CodeClient";

        public static string GetDernierFacture = @"SELECT cast( [QTYSTU_0]	 as int )	   as 'QteArticle'
   	,  [INVDAT_0] as 'DateArticle'
      ,[ITMREF_0]			as	'CodeArticle'
      ,[BPCINV_0]			   as 'CodeClient'
      ,[ITMDES_0]			   as 'DesArticle'
      ,[BPRNAM_0]				as 'SecteurClient'
, cast ([AMTATILIN_0]  as decimal (12  , 3) )as 'PrixHT'
      , cast ([AMTNOTLIN_0] as decimal (12  , 3)) as 'PrixTTC'
      , cast ([NETPRI_0] as decimal (12  , 3)) as 'PrixU'
   FROM [" + NomDossier + @"].[ZREFCLTART]	   where  [BPCINV_0] 	 =@CodeClient  and  [INVDAT_0] =( select max([INVDAT_0])	  FROM [" + NomDossier + @"].[ZREFCLTART] where   [BPCINV_0]=@CodeClient)";
        public static string GetDateDernierFactureSommeHT = @"SELECT 
     cast( sum([AMTNOTLIN_0])   as decimal (12  , 3) ) as 'SommePrixHT'  FROM [" + NomDossier + @"].[ZREFCLTART]	   where  [BPCINV_0] 	 = @CodeClient and  [INVDAT_0] =( select max([INVDAT_0])	  FROM [" + NomDossier + @"].[ZREFCLTART] where   [BPCINV_0]=@CodeClient)";
        public static string GetDateDernierFactureSommeTTC = @"SELECT 
     cast( sum([AMTATILIN_0])   as decimal (12  , 3) ) as 'SommePrixTTC'   FROM [" + NomDossier + @"].[ZREFCLTART]	   where  [BPCINV_0] 	=@CodeClient and  [INVDAT_0] =( select max([INVDAT_0])	  FROM [" + NomDossier + @"].[ZREFCLTART] where   [BPCINV_0]=@CodeClient)";

        public static string GetClientBanque = @"SELECT   [BPANUM_0] 'CodeClient'
      ,[BIDNUM_0] 'NCompte'
      ,[BIDNUMFLG_0] 'Priorite'
      ,[PAB1_0] 'Banque'
      FROM  [" + NomDossier + @"].[YBID] where  [BPANUM_0]=@CodeClient ";
        public static string QueryReferencementClient = @" SELECT [FCY_0] as 'Site'
      ,[REP_0] as 'Rep'
      ,[CLIENT_0]  as 'CodeClient'
,[BPCNAM_0] as 'RaisonSocial'
      ,[GAMME_0] as 'Gamme'
      ,[ITMREF_0] as 'CodeArticle' 
,[DES_0] as 'DesArticle'
      ,Cast([QTYCMD_0] as int) as 'QteCmd' 
      ,Cast([QTYP_0] as int) as 'QteVenduP' 
      ,Cast( [QTYA_0] as int ) as 'QteVenduA' 
  FROM [" + NomDossier + @"].[ZREFCLTITM]  where [CLIENT_0] =@CodeClient --and [FCY_0]=@Site";
        public static string QueryReferencementClientArticle = @" SELECT [FCY_0] as 'Site'
      ,[REP_0] as 'Rep'
      ,[CLIENT_0]  as 'CodeClient'
,[BPCNAM_0] as 'RaisonSocial'
      ,[GAMME_0] as 'Gamme'
      ,[ITMREF_0] as 'CodeArticle' 
,[DES_0] as 'DesArticle'
      ,Cast([QTYCMD_0] as int) as 'QteCmd' 
      ,Cast([QTYP_0] as int) as 'QteVenduP' 
      ,Cast( [QTYA_0] as int ) as 'QteVenduA' 
  FROM [" + NomDossier + @"].[ZREFCLTITM1]  where [CLIENT_0] =@CodeClient or [CLIENT_0]  is null --and [FCY_0]=@Site";
        public static string QueryGamme = @"select distinct [GAMME_0] as 'Gamme'   FROM [" + NomDossier + @"].[ZREFCLTITM] where [FCY_0]=@Site and [GAMME_0] != 'AVOIR FINANCIER'";

        public static string QueryArticleGamme = @"SELECT
 
      [ITMREF_0] as 'CodeArticle' 
,[DES_0] as 'DesArticle'
      ,Cast([QTYCMD_0] as int) as 'QteCmd' 
      ,Cast([QTYP_0] as int) as 'QteVenduP' 
      ,Cast( [QTYA_0] as int ) as 'QteVenduA' 
  FROM [" + NomDossier + @"].[ZREFCLTITM]  where [CLIENT_0] =@CodeClient and [GAMME_0] =@Gamme";
        public static string QueryArticleGammeNonVondu = @"SELECT
 
      [ITMREF_0] as 'CodeArticle' 
,[DES_0] as 'DesArticle'
      ,Cast([QTYCMD_0] as int) as 'QteCmd' 
      ,Cast([QTYP_0] as int) as 'QteVenduP' 
      ,Cast( [QTYA_0] as int ) as 'QteVenduA' 
  FROM [" + NomDossier + @"].[ZREFCLTITM1]  where  [CLIENT_0] is null and [GAMME_0] =@Gamme";
        public static string QueryReliquat = @"SELECT [BPCORD_0] as 'CodeClient'
      ,ORDDAT_0 as 'DateCMD'
      ,[SOHNUM_0]		  as 'Numcommande'
	   ,[ITMREF_0] as 'Refart'
      ,cast(([QTY_0])	as int)	   as 'Qtecommande'
      , cast (([DLVQTY_0])	as int )	 as 'Qtelivrée'
     
      
      ,[SALFCY_0]	  as 'Site'
     
      ,cast( [SOLDE_0]  as int )		 as 'Solde'
     		,	  cast( [NETPRINOT_0]  as decimal (12  , 3) )    as 'Val_ligne'
    	
      ,   cast( [SOLDE_0]  as int )*	cast( [NETPRINOT_0]  as decimal (12  , 3) )			   as 'Val_total'
, [ITMDES1_0] as 'DesArt'
FROM [" + NomDossier + @"].[ZRELCDE]  where [BPCORD_0]=@CodeClient and  [SALFCY_0]=@Site 
--and  [ORDDAT_0] =( select max([ORDDAT_0])
--FROM [" + NomDossier + @"].[ZRELCDE]  where [BPCORD_0]=@CodeClient )	  order by 	 [SOHNUM_0] desc   ";
        public static string QueryDateCommande = @"select max(cast (([ORDDAT_0]) as date)	) as 'Datecommande' FROM [" + NomDossier + @"].[ZRELCDE]  where [BPCORD_0]=@CodeClient";

        public static string QueryModeReg = @"SELECT  [PAYTYP_0] as Code

       ,[DES_0] as Libelle

          ,[DES_0] as Designation

       ,[PAM_0] as CodeR

      ,[DENDEF_0]

  FROM  [" + NomDossier + @"].[YTRSREG]";

        public static string GetModeRegByCode = @"SELECT  [PAYTYP_0] as Code

       ,[DES_0] as Libelle

          ,[DES_0] as Designation

        ,[PAM_0] as CodeR

      ,[DENDEF_0]

  FROM  [" + NomDossier + @"].[YTRSREG] where PAYTYP_0=@Code";
        public static string getNumDerniereFacture = @"select 
        
        MAX(A.NUM_0) AS N_FACTURE
       
        from GRPCTM.SINVOICE A
        where A.NUM_0 = (select MAX(B.NUM_0) FROM GRPCTM.SINVOICE B
            WHERE B.BPR_0 = A.BPR_0 and B.BPR_0= @CodeClient
            )
        GROUP BY A.FCY_0, A.BPR_0, A.ACCDAT_0";

        public static string QueryArticleParSecteur = @" SELECT [FCY_0] as 'Site'
      ,[REP_0] as 'Représentant'
      ,[TSCOD_0] as 'Gouvernorat'
      ,[INTITULE_0] as 'Libelle_Gouvernorat'
      ,[GAMME_0] as 'Gamme'
      ,[ITMREF_0] as 'CodeArticle' 
      ,[DES_0] as 'DesArticle'
      ,CASE WHEN Isnumeric([QTYP_0]) = 1
       THEN CONVERT(DECIMAL(18,0),[QTYP_0]) 
       ELSE 0 END AS QteVenduP
      ,CASE WHEN Isnumeric([QTYA_0]) = 1
       THEN CONVERT(DECIMAL(18,0),[QTYA_0]) 
       ELSE 0 END AS 'QteVenduA'
  FROM  [" + NomDossier + @"].[ZARTVENTSEC]  where [INTITULE_0]=@gouvernorat ORDER BY [QTYP_0] DESC";

        public static string QueryFacNonRepTousClients = @"SELECT  [INVDAT_0]          as 'DateFac'
      ,[NUM_0] as 'NumFac'
      ,[REF_0] as 'NumCmd'
      ,[BPR_0]  as 'CodeClient'
, [BPCNAM_0] as 'Raison' 
      ,[BPDCTY_0] as 'Ville'
      ,[REP0_0] as 'Rep'
,[REP1_0] as 'Rep1'
	  , [TEL_0] as 'Tel'
      ,[PTE_0] as 'MdReg'
	  , [XAUTORISE_0] as 'Autorisation'
      ,[DATEDIF_0] as 'DiffDate'
      ,  cast ([TTC_0]  as decimal (12  , 3) )	as 'MTTTC'
      , cast ([HT_0]  as decimal (12  , 3) )  as 'MTHT'
      ,  cast ([MTREG_0]  as decimal (12  , 3) )    as 'MTRegle'
      , cast ([SOLFAC_0]  as decimal (12  , 3) )  as 'SoldeFacture'
      ,cast ([SOLCLT_0]  as decimal (12  , 3) )      as 'SoldeClient' 
         ,cast ([PORTEFEUILLE_0]  as decimal (12  , 3) )   as 'PortClient'
      , cast ([CMDNLIV_0]  as decimal (12  , 3) )      as 'CmdNliv'
      ,  cast ([ENCOURS_0]  as decimal (12  , 3) )    as 'Encours'
  FROM [" + NomDossier + @"].[ZFACIMPREP]  where  ([INVDAT_0]    >  @Date and  [REP0_0]=@Rep) or ([INVDAT_0]    >  @Date and  [REP1_0]=@Rep)";


        public static string QueryCmdRep = @"SELECT  [COMMANDE_0] as 'NCommand'
      ,[ORDDAT_0] as 'DateCmd' 
      ,[CLIENT_0] as 'CodeClient'
      ,[BPCNAM_0] as 'Raison'
      ,[REF_0] as  'RefCdCl'
      ,[VILLE_0] as 'Ville'
      ,[REP0_0] as 'Rep' 
      ,[SHIDAT_0] as 'DateExp'
      
, cast ([POIDS_0]   as decimal (12  , 3) )  as 'Poids'
  , cast ([HT_0]  as decimal (12  , 3) )  as 'MTHT'
, cast ([TTC_0] as decimal (12  , 3) )  as 'MTTTC'
     , cast ([REMISE_0] as decimal (12  , 3) )  as 'Remise'
    
      ,[SOLDEE_0] as 'Soldee'
      ,[ETAT_0] as 'Etat' 
      ,[FACTUREE_0] as 'Facturee' 
  FROM [" + NomDossier + @"].[ZCMDCLT]  where   [ORDDAT_0] >@date and  [REP0_0]=@Rep and [FACTUREE_0] = 'Non facturée'";

        public static string GetProductByGamme = @"SELECT 
  
     I.ITMREF_0   CodeArticle
	,I.ITMDES1_0  DesArticle
	--, I.TSICOD_1	GAMME
	, (Select ATEXTRA.TEXTE_0 from GRPCTM.ATEXTRA ATEXTRA where I.TSICOD_1=ATEXTRA.IDENT2_0
 AND  ATEXTRA.CODFIC_0='ATABDIV' AND ATEXTRA.LANGUE_0='FRA' AND ATEXTRA.ZONE_0='LNGDES' AND ATEXTRA.IDENT1_0='21') AS Gamme
FROM GRPCTM.ITMMASTER  I 
INNER JOIN GRPCTM.SPRICLIST T ON I.ITMREF_0 = T.PLICRI1_0 

AND cast(T.PLISTRDAT_0 as date) <= cast(GETDATE () as date)
AND cast(T.PLIENDDAT_0 as date) >= cast(GETDATE () as date)  
AND T.PLI_0 = 'TL10' 
 WHERE I.TCLCOD_0 <> ' '
AND I.ITMSTA_0 = 1  -- actif
AND I.XTABLETTE_0 = 2  -- tablette
AND I.TCLCOD_0 IN ('BON', 'GSS', 'CHA', 'GAS','PAK')
And  (Select ATEXTRA.TEXTE_0 from GRPCTM.ATEXTRA ATEXTRA where I.TSICOD_1=ATEXTRA.IDENT2_0 AND  ATEXTRA.CODFIC_0='ATABDIV' AND ATEXTRA.LANGUE_0='FRA' AND ATEXTRA.ZONE_0='LNGDES' AND ATEXTRA.IDENT1_0='21')=@Gamme";

        public static string GetAllSageCommande = @" 

       SELECT 
       [REFERENCE_0]    AS Reference
      ,[DATE_COMMAND_0] AS Date_commande
      ,[DATE_LIVRAIS_0] AS Date_Livraison
      ,[TOTALHT_0]      AS Total
      --,[TOTALTTC_0]     AS Total
      ,[CODE_CLIENT_0]  AS Code_Client
      ,[NOM_CLIENT_0]   AS Nom_Client
      ,[ADR_CLIENT_0]   AS Adresse_Client
      ,[CODE_REP_0]     AS Code_Rep
      ,[NOM_REP_0]      AS Nom_Rep
	  ,(Case [STATUTCMD_0]  
      when   'Validée' then 1
	  when 'Annulée' then 2 
	  when 'Livrée' then 3
	  when 'Retournée' then 5
	  else 4
	  end ) as StatutCommande
      FROM [" + NomDossier + @"].[YSTACMD] where cast(DATE_COMMAND_0 as date)  > '2023-11-01'
";

        public static string GetSageCommandeBYReference = @" 

       SELECT 
       [REFERENCE_0]    AS Reference
      ,[DATE_COMMAND_0] AS Date_commande
      ,[DATE_LIVRAIS_0] AS Date_Livraison
      ,[TOTALHT_0]      AS Total
      --,[TOTALTTC_0]     AS Total
      ,[CODE_CLIENT_0]  AS Code_Client
      ,[NOM_CLIENT_0]   AS Nom_Client
      ,[ADR_CLIENT_0]   AS Adresse_Client
      ,[CODE_REP_0]     AS Code_Rep
      ,[NOM_REP_0]      AS Nom_Rep
      ,[STATUTCMD_0]    AS StatutCommandeString
      FROM [" + NomDossier + @"].[YSTACMD]  where REFERENCE_0=@Reference ";

        public static string GetAllSageLigneCommandeBYReference = @"
          SELECT
       [REFERENCE_0]    AS Reference
       ,[REF_PRODUIT_0] as itmref
      ,[NOM_PRODUIT_0] as itmdes1
      ,[QUANTITE_0] as Quantity
      ,[PRIXUHT_0] as prix
      ,(Case [STATUTCMD_0]  
      when   'Validée' then 1
	  when 'Annulée' then 2 
	  when 'Livrée' then 3
	  when 'Retournée' then 5
	  else 4
	  end ) as StatutCommande
      FROM [" + NomDossier + @"].[YSTACMD] where REFERENCE_0=@Reference  ";
        public static string GetAllEtatPreavisImpayes = @" 
SELECT  
    [YDATP_0] AS DatePreavis,
    [AGENCE_0] AS Agence,
    CASE 
        WHEN [PAYTYP_0] = 'CTRT' THEN 'Traite'
        ELSE 'Chéque'
    END AS TypePaiement,
    [CHQNUM_0] AS NumCheque,
    [NUM_0] AS NumReg,
    [MONTANT_0] AS Montant,
    [BPC_0] AS CodeClient,
    [NAME_0] AS NomClient,
    [YDATAP_0] AS DateAnnulationPreavis,
    [YDATIMP_0] AS DateImpaye,
    [YDATRIMP_0] AS DateRecuperationImpaye,
    [SOCIETE_0] AS Societe,
    [SITE_0] AS Site,
    [STATUT_0] AS Status,
    [REP1_0] AS REP1,
    [REP2_0] AS REP2
FROM GRPCTM.[YPREAVIS]

  WHERE REP1_0=@Rep OR REP2_0 =@Rep
  order by [YDATP_0],[AGENCE_0],[NUM_0] asc ";
        public static string GetListedesChequesParClient = @" 
SELECT  [BPR_0] as CodeClient
      ,[BPANAM_0] as RaisonSocial
      ,[NUM_0] as NumReg
      ,[ACCDAT_0] as Date
      ,[DUDDAT_0] as DateEcheance
      ,[CHQNUM_0] as NumCheq
      ,[CHQBAN_0] As Agence
      ,[REF_0] As Reference
      ,[DES_0] as Libelle
      ,[P1_0] AS Portefeuille1
      ,[P2_0] AS Portefeuille2
      ,[P3_0] AS Portefeuille3
      ,[IMPAYEE_0] as Impayee
      ,[REP1_0] AS REP1
      ,[REP2_0] AS REP2
  FROM [" + NomDossier + @"].[YLISCHQ]
    WHERE REP1_0=@Rep OR REP2_0 =@Rep  
  
";
        public static string ListedeschequesParClientChoisi = @" 
SELECT  [BPR_0] as CodeClient
      ,[BPANAM_0] as RaisonSocial
      ,[NUM_0] as NumReg
      ,[ACCDAT_0] as Date
      ,[DUDDAT_0] as DateEcheance
      ,[CHQNUM_0] as NumCheq
      ,[CHQBAN_0] As Agence
      ,[REF_0] As Reference
      ,[DES_0] as Libelle
      ,[P1_0] AS Portefeuille1
      ,[P2_0] AS Portefeuille2
      ,[P3_0] AS Portefeuille3
      ,[IMPAYEE_0] as Impayee
      ,[REP1_0] AS REP1
      ,[REP2_0] AS REP2
  FROM [" + NomDossier + @"].[YLISCHQ]
    WHERE( REP1_0=@Rep OR REP2_0 =@Rep  ) and BPR_0=@CodeClient
  
";
    }
}