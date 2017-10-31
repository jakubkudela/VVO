SELECT
    *,total_final_value_amount_minus_vat / EstimatedPriceCleaned AS price_ratio
  FROM (

         SELECT
           -- oznamenie.body,
           oznamenie.oznam_title,
           oznamenie.contracting_authority_name,
           oznamenie.druh_postupu,
           oznamenie.druh_zakazky,
           case WHEN oznamenie.druh_obstaravatela like 'Iné (uveďte)' THEN upper(oznamenie.druh_obstaravatela_ine)
            else upper(oznamenie.druh_obstaravatela) -- upper case aby sa zjednotili rovnake hodnoty
             end druh_obstaravatela_clean,
           case WHEN oznamenie.hlavna_cinnost like 'Iné (uveďte)' THEN upper(oznamenie.hlavna_cinnost_ine)
            else upper(oznamenie.hlavna_cinnost) -- upper case aby sa zjednotili rovnake hodnoty
            end hlavna_cinnost_clean,
           oznamenie.main_cpv_code,
           oznamenie.cpv_others,
           oznamenie.deli_sa_casti,
           oznamenie.varianty,
           oznamenie.typ_obdobie,
           case WHEN oznamenie.typ_obdobie like 'v dňoch (od zadania zákazky)' THEN cast(oznamenie.dlzka_zakazky_dni as float) / 30
            else cast(oznamenie.dlzka_zakazky_mesiace as float)
            end dlzka_zakazky_cleaned,
           case when oznamenie.kriteria_ponuk like 'Najnižšia cena' then oznamenie.kriteria_ponuk
             else 'Iné' end kriteria_ponuk, -- kriterium najnizsia cena alebo su do uvahy brane aj ine faktory, pripadne s kombinaciou ceny
           oznamenie.el_aukcia,
           oznamenie.predch_uverejnen_zakazky,
           cast(oznamenie.ziskanie_podkladov_deadline as date) ziskanie_podkladov_deadline,
           cast(oznamenie.ucast_deadline as date) ucast_deadline,
           cast(oznamenie.published_on as date) published_on,
           oznamenie.bude_sa_opakovat_zakazka,
           oznamenie.eu_fondy,
           cast(oznamenie.odoslanie_oznamenia as date) odoslanie_oznamenia,
           oznamenie.typ_ceny_oznamenia,
           CASE WHEN oznamenie.typ_ceny_oznamenia LIKE 'Rozpätie hodnôt'
             THEN (oznamenie.EstimatedPrice + oznamenie.CenaDo_Oznamenia) / 2
           ELSE oznamenie.EstimatedPrice
d
           oznamenie.nazov_typu_oznamenia,
           vysledok.nuts miesto_prac_zakazky,
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
           END AS        total_final_value_amount_minus_vat
         FROM
           (
             SELECT
               -- v niektorych oznameniach nie je uvedena cena alebo ak sa deli na castiach tak su tieto ceny uvedene inde
               CASE WHEN
                 cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title ="Hodnota/Od"]/@Value', body)
                      AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(replace(replace(cast(unnest(xpath(
                                                      '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title ="Hodnota/Od"]/@Value',
                                                      body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT)
               END                                              EstimatedPrice,
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL IV: POSTUP"]/DropDownList[@ Title ="Použije sa elektronická aukcia"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               el_aukcia,
               cast(unnest(xpath(
                               '//Part[@Title="HLAVIČKA FORMULÁRA"]/RadioButtonList[@ Title ="Druh postupu"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               druh_postupu,
               cast(unnest(
                        xpath(
                            '//Part[@Title="HLAVIČKA FORMULÁRA"]/DropDownList[@ Title ="Druh zákazky"]/SelectListValue/@Title',
                            body)) AS VARCHAR)                  druh_zakazky,
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/SelectList[@Type ="druh_VO"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               druh_obstaravatela,

               CASE WHEN cast(xpath('//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/ShortText[@Title ="Iný verejný obstarávateľ"]/@Value',body) as varchar) LIKE '{}' THEN NULL
                 else cast(unnest(xpath('//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/ShortText[@Title ="Iný verejný obstarávateľ"]/@Value',body)) as varchar)
                   end druh_obstaravatela_ine,
               -- v pripade ze ma oznamenie viacero hlavnych cinnosti je ako hlavna vybrana prva z nich, cca 100 pripadov.
               cast(unnest(xpath(
                               '(//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/MultiSelectList[@Type ="hlavnyPredmetCinnosti"]/MultiSelectListValue/@Title)[1]',
                               body)) AS VARCHAR)               hlavna_cinnost,


                CASE WHEN cast(xpath('//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/ShortText[@Title ="Iný predmet"]/@Value',body) as varchar) LIKE '{}' THEN NULL
                else
               cast(unnest(xpath('//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/ShortText[@Title ="Iný predmet"]/@Value',body)) AS VARCHAR)
                end hlavna_cinnost_ine,

               CASE WHEN
                 cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[@IsPrimary = "true"]/@Code', body) AS
                      VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[@IsPrimary = "true"]/@Code', body))
                      AS
                      VARCHAR)
               END                                              main_cpv_code,

               CASE WHEN cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[not(@IsPrimary="true")]/@Code',body) as varchar) LIKE '{}' THEN NULL
                 else cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[not(@IsPrimary="true")]/@Code',body) as varchar)
                end cpv_others,

               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@Title="Táto zákazka sa delí na časti"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               deli_sa_casti,
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@Title="Varianty sa budú prijímať"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               varianty,

               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/RadioButtonList[@Title ="Obdobie"]/SelectListValue/@Title',
                               body)) AS VARCHAR) AS            typ_obdobie,

               CASE WHEN cast(xpath(
                                  '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@FormComponentId="stHodnotaMesiac"]/@Value',
                                  body) AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(cast(unnest(xpath(
                                      '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@FormComponentId="stHodnotaMesiac"]/@Value',
                                      body)) AS VARCHAR) AS INTEGER)
               END                                              dlzka_zakazky_mesiace,
               CASE WHEN cast(xpath(
                                  '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@ FormComponentId ="stHodnotaDen"]/@Value',
                                  body) AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(cast(unnest(xpath(
                                      '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@ FormComponentId ="stHodnotaDen"]/@Value',
                                      body)) AS VARCHAR) AS INTEGER)
               END                                              dlzka_zakazky_dni,
               -- pre typ obdobia v dnoch > , este ostava dokoncit typ obdobia lehoty uskutočnenia
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL IV: POSTUP"]/RadioButtonList[@ Type ="NM02_KriteriaPonuk"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               kriteria_ponuk,
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL IV: POSTUP"]/DropDownList[@FormComponentId ="ddlPredchadzaujuceOznamenie"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               predch_uverejnen_zakazky,

               -- case pretoze vynechava par

               CASE WHEN cast(xpath(
                                  '//Part[@Title="ODDIEL IV: POSTUP"]/Part[@FormComponentId ="ptPodmienkyZiskavaniaSutaznychPodkladov"]/Date/@Value',
                                  body) AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE cast(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL IV: POSTUP"]/Part[@FormComponentId ="ptPodmienkyZiskavaniaSutaznychPodkladov"]/Date/@Value',
                                         body)) AS VARCHAR) AS
                         DATE)
               END                                              ziskanie_podkladov_deadline,
               cast(cast(unnest(xpath(
                                    '//Part[@Title="ODDIEL IV: POSTUP"]/Date[@FormComponentId ="dtLehotaNaPredkladaniePonuk"]/@Value',
                                    body)) AS VARCHAR) AS DATE) ucast_deadline,
               -- potreby case pretoze bude_sa_opakovat_zakazka dropne okolo 800 riadkov. V mnohych oznameniach taketo pole nie je.
               CASE WHEN cast(xpath(
                                  '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/DropDownList[@Title ="Toto obstarávanie sa bude opakovať"]/SelectListValue/@Title',
                                  body) AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(unnest(xpath(
                                 '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/DropDownList[@Title ="Toto obstarávanie sa bude opakovať"]/SelectListValue/@Title',
                                 body)) AS VARCHAR)
               END                                              bude_sa_opakovat_zakazka,
               cast(unnest(xpath(
                               '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/DropDownList[@ FormComponentId ="ddlProgramFinancovanyZFondov"]/SelectListValue/@Title',
                               body)) AS VARCHAR)               eu_fondy,
               cast(cast(unnest(xpath(
                                    '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/Date[@FormComponentId ="dtDatumOdoslaniaTohtoOznamenia"]/@Value',
                                    body)) AS VARCHAR) AS DATE) odoslanie_oznamenia,

               -- dropne len par zaznamov
               CASE WHEN cast(xpath(
                                  '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@ FormComponentId ="ddlRozpatie66"]/SelectListValue/@Title',
                                  body) AS VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(unnest(xpath(
                                 '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@ FormComponentId ="ddlRozpatie66"]/SelectListValue/@Title',
                                 body)) AS VARCHAR)
               END                                              typ_ceny_oznamenia,

               CASE WHEN
                 cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title="Do"]/@Value', body) AS
                      VARCHAR) LIKE '{}'
                 THEN NULL
               ELSE
                 cast(replace(replace(cast(unnest(xpath(
                                                      '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title="Do"]/@Value',
                                                      body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT)
               END                                              CenaDo_Oznamenia,
               n.contract_id                      AS            oznam_contract_id,
               pt.title                           AS            procedure_title,
               n.title                            AS            oznam_title,
               n.e_auction                        AS            oznam_e_auction,
               nt.name                            AS            nazov_typu_oznamenia,
               *
             FROM vvo_sept.notices n
               JOIN (SELECT *
                     FROM vvo_sept.raw_notices
                     WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
               JOIN vvo_sept.procedure_types pt ON pt.id = n.procedure_type_id
               JOIN vvo_sept.bulletin_issues bi ON bi.id = n.bulletin_issue_id
               JOIN vvo_sept.notice_types nt ON nt.id = n.notice_type_id
             WHERE nt.code IN ('MST', 'MSS', 'MSP')
           ) oznamenie -- ponechany nazov oznamenia, jedna sa vska o typ vyzvy

           JOIN (
                  SELECT
                    result.contract_id AS result_contract_id,
                    result.title       AS result_title,
                    result.e_auction   AS result_e_auction,
                    cast(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater[@FormComponentId ="rpZmluva"]/RepeatingPart[@FormComponentId ="rpp_0-partZmluva"]/ShortText[@Title = "Počet prijatých ponúk"]/@Value',
                                         body)) AS VARCHAR) AS
                         INTEGER)         pocet_prijatych_ponuk,
                    cast(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater[@FormComponentId ="rpZmluva"]/RepeatingPart[@FormComponentId ="rpp_0-partZmluva"]/ShortText[@Title = "Počet ponúk prijatých elektronickou cestou"]/@Value',
                                         body)) AS VARCHAR) AS
                         INTEGER)         pocet_prijatych_el_ponuk,

                    cast(replace(replace(cast(unnest(xpath(
                                                         '//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater/RepeatingPart/ShortText[@ FormComponentId = "rpp_0-MN03_zmluvaPredpokladanaHodnota"]/@Value',
                                                         body)) AS VARCHAR), ',', '.'), ' ', '') AS
                         FLOAT)        AS EstimatedPrice_From_Result,

                    CASE WHEN result.total_final_value_type LIKE 'Rozpätie hodnôt'
                      THEN (total_final_value_lowest_offer + total_final_value_highest_offer) / 2
                    ELSE total_final_value_amount
                    END                   total_final_value_amount_clean,
                    *
                  FROM vvo_sept.notices n
                    JOIN (SELECT *
                          FROM vvo_sept.raw_notices
                          WHERE zovo_type = 'NM03') rn ON n.raw_notice_id = rn.id
                    JOIN vvo_sept.result_notices result ON result.raw_notice_id = rn.id
                    JOIN vvo_sept.notice_types nt_r ON nt_r.id = n.notice_type_id
                  WHERE nt_r.code IN ('VST', 'VSS', 'VSP')
                ) vysledok

             ON oznamenie.oznam_contract_id = vysledok.result_contract_id

       ) a
  WHERE deli_sa_casti = 'Nie' --pracujeme iba so zakazkami ktore sa nedelia na casti kvoli zlozitej agregacii delitelnych zakazok
  -- odfiltruje chyby, vysledky v inych jednotkach a pod.
        AND cast(EstimatedPriceCleaned as varchar) like case
          WHEN typ_ceny_oznamenia LIKE 'Jedna hodnota'
          THEN
            cast(EstimatedPrice_From_Result as varchar)
          ELSE '%' end
    -- filter na price ratio - chyby v oznameniach a vysledkoch v cenach, pripadne ceny v inych jednotkach (pri elektrine, plyne.. )
        AND (total_final_value_amount_minus_vat / EstimatedPriceCleaned) > 0.3
        AND (total_final_value_amount_minus_vat / EstimatedPriceCleaned < 2);
