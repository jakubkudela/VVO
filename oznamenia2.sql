select
total_final_value_amount_minus_vat / EstimatedPriceCleaned AS price_ratio, *
from (

  SELECT
    oznamenie.oznam_title,
    oznamenie.contracting_authority_name,
    oznamenie.druh_postupu,
    oznamenie.druh_zakazky,
    CASE WHEN oznamenie.druh_obstaravatela LIKE 'Iné (uveďte)'
      THEN upper(oznamenie.druh_obstaravatela_ine)
    ELSE upper(oznamenie.druh_obstaravatela) -- upper case aby sa zjednotili rovnake hodnoty
    END                                         druh_obstaravatela_clean,
    CASE WHEN oznamenie.hlavna_cinnost LIKE 'Iné (uveďte)'
      THEN upper(oznamenie.hlavna_cinnost_ine)
    ELSE upper(oznamenie.hlavna_cinnost) -- upper case aby sa zjednotili rovnake hodnoty
    END                                         hlavna_cinnost_clean,
    oznamenie.main_cpv_code,
    oznamenie.cpv_others,
    oznamenie.deli_sa_casti,
    oznamenie.varianty,
    oznamenie.typ_obdobie,
    CASE WHEN oznamenie.typ_obdobie LIKE 'v dňoch (od zadania zákazky)'
      THEN cast(oznamenie.dlzka_zakazky_dni AS FLOAT) / 30
    ELSE cast(oznamenie.dlzka_zakazky_mesiace AS FLOAT)
    END                                         dlzka_zakazky_cleaned,
    CASE WHEN oznamenie.kriteria_ponuk LIKE 'Cena'
      THEN 'Najnižšia cena'
    WHEN oznamenie.kriteria_ponuk LIKE 'Najnižšia cena'
      THEN oznamenie.kriteria_ponuk
    ELSE 'Iné' END                              kriteria_ponuk,
    -- kriterium najnizsia cena alebo su do uvahy brane aj ine faktory, pripadne s kombinaciou ceny
    oznamenie.el_aukcia,
    oznamenie.predch_uverejnen_zakazky,
    oznamenie.ziskanie_podkladov_deadline AS    ziskanie_podkladov_deadline,
    cast(oznamenie.ucast_deadline AS DATE)      ucast_deadline,
    cast(oznamenie.publishedon AS DATE)        published_on,
    oznamenie.bude_sa_opakovat_zakazka,
    oznamenie.eu_fondy,
    cast(oznamenie.odoslanie_oznamenia AS DATE) odoslanie_oznamenia,
    oznamenie.typ_ceny_oznamenia,
    oznamenie.EstimatedPrice              AS    EstimatedPriceCleaned,
    oznamenie.nazov_typu_oznamenia,
    oznamenie.nuts_oznam                               miesto_prac_zakazky,
    -- vysledok.contract_sub_type,
    -- vysledok.gpa,
    vysledok.EstimatedPrice_From_Result,
    vysledok.pocet_prijatych_ponuk,
    vysledok.pocet_prijatych_el_ponuk,
    vysledok.total_final_value_amount_clean,
    vysledok.total_final_value_vat_included,
    vysledok.total_final_value_vat_rate,
    CASE WHEN vysledok.total_final_value_vat_included = TRUE
      THEN (1 - cast(vysledok.total_final_value_vat_rate AS FLOAT) / 100) * total_final_value_amount_clean
    ELSE total_final_value_amount_clean
    END                                   AS    total_final_value_amount_minus_vat


  FROM (
         SELECT

           CASE WHEN
             cast(xpath(
                      '(//ShortText[@FormComponentId="odhHodnZakazky"]/@Value|//ShortText[@Title ="Hodnota/Od"]/@Value)[1]',
                      body)
                  AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(replace(replace(cast(unnest(xpath(
                                                  '(//ShortText[@FormComponentId="odhHodnZakazky"]/@Value|//ShortText[@Title ="Hodnota/Od"]/@Value)[1]',
                                                  body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT)
           END                                              EstimatedPrice,

           cast(unnest(xpath(
                           '//Part[@Title="ODDIEL IV: POSTUP"]/DropDownList[@ Title ="Použije sa elektronická aukcia"]/SelectListValue/@Title',
                           body)) AS VARCHAR)               el_aukcia,

           cast(unnest(xpath(
                           '//DropDownList[@Title = "Táto zákazka sa delí na časti"]/SelectListValue/@Title',
                           body)) AS VARCHAR)               deli_sa_casti,
           pt.title                           AS            druh_postupu,
           cast(unnest(
                    xpath(
                        '(//DropDownList[@ Type ="druhZakazky"]/SelectListValue/@Title)[1]',
                        body)) AS VARCHAR)                  druh_zakazky,

           CASE WHEN cast(xpath('//SelectList[@Type ="druh_VO"]/SelectListValue/@Title', body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE cast(unnest(xpath('//SelectList[@Type ="druh_VO"]/SelectListValue/@Title', body)) AS VARCHAR)
           END                                              druh_obstaravatela,

           CASE WHEN cast(xpath(
                              '//ShortText[@Title="Iný verejný obstarávateľ"]/@Value|//ShortText[@Title="Iný verejný obstarávateľ (špecifikujte)"]/@Value',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE cast(unnest(xpath(
                                '//ShortText[@Title="Iný verejný obstarávateľ"]/@Value|//ShortText[@Title="Iný verejný obstarávateľ (špecifikujte)"]/@Value',
                                body)) AS VARCHAR)
           END                                              druh_obstaravatela_ine,

           CASE WHEN cast(xpath(
                              '(//MultiSelectList[@Title ="Hlavný predmet alebo predmety činnosti:"]/MultiSelectListValue/@Title)[1]|(//SelectList[@Type ="hlavnyPredmetCinnosti"]/SelectListValue/@Title)[1]',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE cast(unnest(xpath(
                                '(//MultiSelectList[@Title ="Hlavný predmet alebo predmety činnosti:"]/MultiSelectListValue/@Title)[1]|(//SelectList[@Type ="hlavnyPredmetCinnosti"]/SelectListValue/@Title)[1]',
                                body)) AS VARCHAR)
           END                                              hlavna_cinnost,

           CASE WHEN cast(xpath(
                              '//ShortText[@Title ="Iný predmet"]/@Value|//ShortText[@Title ="Iný predmet (špecifikujte)"]/@Value',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE cast(unnest(xpath(
                                '//ShortText[@Title ="Iný predmet"]/@Value|//ShortText[@Title ="Iný predmet (špecifikujte)"]/@Value',
                                body)) AS VARCHAR)
           END                                              hlavna_cinnost_ine,

           CASE WHEN
             cast(xpath(
                      '//SelectList[@FormComponentId ="hlavnyCPV"]/SelectListValue/@Title|//Cpv[@IsPrimary ="true"]/@Code',
                      body) AS
                  VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(unnest(xpath(
                             '//SelectList[@FormComponentId ="hlavnyCPV"]/SelectListValue/@Title|//Cpv[@IsPrimary ="true"]/@Code',
                             body))
                  AS
                  VARCHAR)
           END                                              main_cpv_code,

           NULL                               AS            cpv_others,

           cast(unnest(xpath(
                           '//RadioButtonList[@Title ="Budú sa akceptovať varianty"]/SelectListValue/@Title|//DropDownList[@Title ="Varianty sa budú prijímať"]/SelectListValue/@Title|//DropDownList[@Title ="Budú sa akceptovať varianty"]/SelectListValue/@Title',
                           body)) AS VARCHAR)               varianty,

           cast(unnest(xpath(
                           '//RadioButtonList[@Title = "Obdobie"]/SelectListValue/@Title',
                           body)) AS VARCHAR) AS            typ_obdobie,


           CASE WHEN cast(xpath(
                              '//ShortText[@Title="Trvanie v mesiacoch:"]/@Value|//ShortText[@FormComponentId="stHodnotaMesiac"]/@Value|//ShortText[@FormComponentId="stHodnota223"]/@Value',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(cast(unnest(xpath(
                                  '//ShortText[@Title="Trvanie v mesiacoch:"]/@Value|//ShortText[@FormComponentId="stHodnotaMesiac"]/@Value|//ShortText[@FormComponentId="stHodnota223"]/@Value',
                                  body)) AS VARCHAR) AS INTEGER)
           END                                              dlzka_zakazky_mesiace,
           CASE WHEN cast(xpath(
                              '//ShortText[@Title="Trvanie v dňoch:"]/@Value|//ShortText[@FormComponentId="stHodnotaDen"]/@Value',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(cast(unnest(xpath(
                                  '//ShortText[@Title="Trvanie v dňoch:"]/@Value|//ShortText[@FormComponentId="stHodnotaDen"]/@Value',
                                  body)) AS VARCHAR) AS INTEGER)
           END                                              dlzka_zakazky_dni,


           CASE WHEN cast(xpath(
                              '//RadioButtonList[@FormComponentId="ddlKriteriaPonuk"]/SelectListValue/@Title|//RadioButtonList[@Title="Náklady/Cena"]/SelectListValue/@Title',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(unnest(xpath(
                             '//RadioButtonList[@FormComponentId="ddlKriteriaPonuk"]/SelectListValue/@Title|//RadioButtonList[@Title="Náklady/Cena"]/SelectListValue/@Title',
                             body)) AS VARCHAR)
           END                                              kriteria_ponuk,

           NULL                               AS            predch_uverejnen_zakazky,
           --nestrukturovane informacie

           NULL                               AS            ziskanie_podkladov_deadline,
           --totozne s ucastou

           cast(cast(unnest(xpath(
                                '//Date[@FormComponentId = "lehotaPredkladanie"]/@Value|//Date[@FormComponentId = "dtLehotaNaPredkladaniePonuk"]/@Value',
                                body)) AS VARCHAR) AS DATE) ucast_deadline,

           CASE WHEN cast(xpath(
                              '//DropDownList[@Title = "Toto obstarávanie sa bude opakovať"]/SelectListValue/@Title',
                              body) AS VARCHAR) LIKE '{}'
             THEN NULL
           ELSE
             cast(unnest(xpath(
                             '//DropDownList[@Title = "Toto obstarávanie sa bude opakovať"]/SelectListValue/@Title',
                             body)) AS VARCHAR)
           END                                              bude_sa_opakovat_zakazka,

           cast(unnest(xpath(
                           '//RadioButtonList[@FormComponentId = "rpp_0-fondyEU"]/SelectListValue/@Title|//DropDownList[@FormComponentId = "ddlProgramFinancovanyZFondov"]/SelectListValue/@Title',
                           body)) AS VARCHAR)               eu_fondy,

           cast(cast(unnest(xpath(
                                '//Date[@FormComponentId = "datumOdoslania"]/@Value|//Date[@FormComponentId = "dtDatumOdoslaniaTohtoOznamenia"]/@Value',
                                body)) AS VARCHAR) AS DATE) odoslanie_oznamenia,

           'Jedna hodnota'                                  typ_ceny_oznamenia,
           --pri velkej vacsine dat neuvedene, predpoklad jednej hodnoty.


           cast(unnest(xpath(
                           '(//MultiSelectList[@Title = "Kód NUTS"]/MultiSelectListValue/@Title|//MultiSelectList[@Type = "NUTS"]/MultiSelectListValue/@Title)[1]',
                           body)) AS VARCHAR)                nuts_oznam,


           NULL                               AS            CenaDo_Oznamenia,

           n.contract_id                      AS            oznam_contract_id,
           pt.title                           AS            procedure_title,
           n.title                            AS            oznam_title,
           n.e_auction                        AS            oznam_e_auction,
           nt.name                            AS            nazov_typu_oznamenia,
           published_on as publishedon,
           *
         FROM vvo_sept.notices n
           JOIN (SELECT *
                 FROM vvo_sept.raw_notices) rn ON n.raw_notice_id = rn.id
           JOIN vvo_sept.procedure_types pt ON pt.id = n.procedure_type_id
           JOIN vvo_sept.bulletin_issues bi ON bi.id = n.bulletin_issue_id
           JOIN vvo_sept.notice_types nt ON nt.id = n.notice_type_id
         WHERE nt.code IN ('MST', 'MSS', 'MSP')
       ) oznamenie

    JOIN (
           SELECT
             result.contract_id AS result_contract_id,
             result.title       AS result_title,
             result.e_auction   AS result_e_auction,
             cast(cast(unnest(xpath(
                                  '//ShortText[@Title = "Počet prijatých ponúk:"]/@Value',
                                  body)) AS VARCHAR) AS
                  INTEGER)         pocet_prijatych_ponuk,
             -- vypadnu oznamenia, ktore neboli pridelene
             CASE WHEN cast(xpath(
                                '//RadioButtonList[@FormComponentId = "rpp_1-zakazkaKoncesiaPridelena"]/SelectListValue/@Title',
                                body) AS VARCHAR) LIKE '{}'
               THEN NULL
             ELSE cast(unnest(xpath(
                                  '//RadioButtonList[@FormComponentId = "rpp_1-zakazkaKoncesiaPridelena"]/SelectListValue/@Title',
                                  body)) AS VARCHAR)
             END                   deli_sa_casti_2,
             --Riesenie castych prikladov, kedy je v oznameni uvedene, ze sa nedeli na casti, ale vo vysledku sa deli.

             CASE WHEN
               cast(xpath('//ShortText[@Title = "Počet ponúk prijatých elektronicky:"]/@Value', body) AS VARCHAR) LIKE
               '{}'
               THEN NULL
             ELSE cast(cast(unnest(xpath('//ShortText[@Title = "Počet ponúk prijatých elektronicky:"]/@Value', body)) AS
                            VARCHAR) AS INTEGER)
             END                   pocet_prijatych_el_ponuk,

             CASE WHEN
               cast(xpath('//ShortText[@Title = "Pôvodná predpokladaná celková hodnota zákazky/časti:"]/@Value', body)
                    AS VARCHAR) LIKE '{}'
               THEN NULL
             ELSE cast(replace(replace(cast(unnest(xpath(
                                                       '//ShortText[@Title = "Pôvodná predpokladaná celková hodnota zákazky/časti:"]/@Value',
                                                       body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT)
             END                   EstimatedPrice_From_Result,

             CASE WHEN result.total_final_value_type LIKE 'Rozpätie hodnôt'
               THEN (total_final_value_lowest_offer + total_final_value_highest_offer) / 2
             ELSE total_final_value_amount
             END                   total_final_value_amount_clean,
             *
           FROM vvo_sept.notices n
             JOIN (SELECT *
                   FROM vvo_sept.raw_notices) rn ON n.raw_notice_id = rn.id
             JOIN vvo_sept.result_notices result ON result.raw_notice_id = rn.id
             JOIN vvo_sept.notice_types nt_r ON nt_r.id = n.notice_type_id
           WHERE nt_r.code IN ('VST', 'VSS', 'VSP')
         ) vysledok
      ON oznamenie.oznam_contract_id = vysledok.result_contract_id
  WHERE (published_on > '2016-02-01' -- po tomto datume sa zmenil format xml pre oznamenia, preto bol potrebny novy select
         AND deli_sa_casti = 'Nie'  --pracujeme iba so zakazkami ktore sa nedelia na casti kvoli zlozitej agregacii delitelnych zakazok
         AND deli_sa_casti_2 IS NULL  --parameter deli_sa_casti nedostacujuci sa na odfiltrovanie
         AND typ_obdobie IN ('v mesiacoch (od zadania zákazky)', 'v dňoch (od zadania zákazky)')
  )

) a
where (total_final_value_amount_minus_vat / EstimatedPriceCleaned) > 0.3 -- filter na price ratio - chyby v oznameniach a vysledkoch v cenach, pripadne ceny v inych jednotkach (pri elektrine, plyne.. )
        AND (total_final_value_amount_minus_vat / EstimatedPriceCleaned < 2);
