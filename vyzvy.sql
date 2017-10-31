select
           oznamenie.oznam_title,
           oznamenie.contracting_authority_name,
           oznamenie.druh_postupu,
           case when  oznamenie.druh_zakazky like 'Stavebné práce' then 'Práce' -- upravene podla oznameni otvorenych verejnych sutazi
            else oznamenie.druh_zakazky end druh_zakazky,
           case WHEN oznamenie.druh_obstaravatela like 'Iné (uveďte)' THEN upper(oznamenie.druh_obstaravatela_ine)
            else upper(oznamenie.druh_obstaravatela) -- upper case aby sa zjednotili rovnake hodnoty
             end druh_obstaravatela_clean,
           case WHEN vysledok.hlavna_cinnost like 'Iné (uveďte)' THEN upper(vysledok.hlavna_cinnost_ine)
            else upper(vysledok.hlavna_cinnost) -- upper case aby sa zjednotili rovnake hodnoty
            end hlavna_cinnost_clean,
           oznamenie.main_cpv_code,
           oznamenie.cpv_others,
           oznamenie.deli_sa_casti,
           oznamenie.varianty,
           oznamenie.typ_obdobie,
           case WHEN oznamenie.typ_obdobie like 'v dňoch (od zadania zákazky)' THEN cast(oznamenie.dlzka_zakazky as float) / 30
            else cast(oznamenie.dlzka_zakazky as float)
            end dlzka_zakazky_cleaned,
            case when oznamenie.kriteria_ponuk like 'Cena' then 'Najnižšia cena'
                  when oznamenie.kriteria_ponuk like 'Najnižšia cena' then oznamenie.kriteria_ponuk
                  else 'Iné' end kriteria_ponuk,  -- kriterium najnizsia cena alebo su do uvahy brane aj ine faktory, pripadne s kombinaciou ceny
           oznamenie.el_aukcia,
           oznamenie.predch_uverejnen_zakazky,
           cast(oznamenie.ziskanie_podkladov_deadline as date) ziskanie_podkladov_deadline,
           cast(oznamenie.ucast_deadline as date) ucast_deadline,
           cast(oznamenie.published_on as date) published_on,
           oznamenie.bude_sa_opakovat_zakazka,
           oznamenie.eu_fondy,
           cast(oznamenie.odoslanie_oznamenia as date) odoslanie_oznamenia,
           'Jedna hodnota' as typ_ceny_oznamenia, -- vsetky v jednotnej cene
           oznamenie.EstimatedPrice as EstimatedPriceCleaned, -- podla nazvu z oznameni
          oznamenie.nazov_typu_oznamenia,
           vysledok.nuts miesto_prac_zakazky,
           null as EstimatedPrice_From_Result, -- nestrukturovane data vo vyzvach
           vysledok.pocet_prijatych_ponuk,
           vysledok.pocet_prijatych_el_ponuk,
           vysledok.total_final_value_amount_clean,
           null as total_final_value_vat_included, -- nepouzivane pri vyzvach, vsetky ceny su uz uvadzane bez dph
           null as total_final_value_vat_rate, -- nepouzivane pri vyzvach, vsetky ceny su uz uvadzane bez dph
           null as total_final_value_amount_minus_vat,
            vysledok.total_final_value_amount_clean / oznamenie.EstimatedPrice AS price_ratio
  FROM (select n.contract_id   AS  oznam_contract_id,
                n.title as oznam_title,
                bi.published_on,
                nt.name as  nazov_typu_oznamenia,
  cast(unnest(xpath(
  '//DropDownList[@Title="Táto zákazka sa delí na časti"]/SelectListValue/@Title',
  body)) AS VARCHAR)               deli_sa_casti,

  cast(replace(replace(cast(unnest(xpath(
  '//ShortText[@FormComponentId="odhHodnZakazky"]/@Value|//ShortText[@Title="Hodnota/Od"]/@Value', -- potrebne pouzit AND kvoli roznym formatom
  body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) as
  EstimatedPrice -- vsetky ceny v mene EUR a cena su jednotne bez rozpatia
  ,

  cast(unnest(xpath(
  '//DropDownList[@Title ="Použije sa elektronická aukcia"]/SelectListValue/@Title|//DropDownList[@FormComponentId ="ddlyAukcia"]/SelectListValue/@Title',
  body)) AS VARCHAR)               el_aukcia, -- vypadnu 4 zakazky, kvoli zlemu formatu

  'výzva' as druh_postupu, -- informacia nie je v hlavicke

    cast(unnest(
    xpath(
    '//DropDownList[@FormComponentId="druhZakazky"]/SelectListValue/@Title',
    body)) AS VARCHAR)                  druh_zakazky,

    cast(unnest(xpath(
    '//SelectList[@FormComponentId="druhVO"]/SelectListValue/@Title',
     body)) AS VARCHAR)               druh_obstaravatela,

    CASE WHEN cast(xpath('//ShortText[@FormComponentId="inyDruhVO"]/@Value',body) as varchar) LIKE '{}' THEN NULL
    else cast(unnest(xpath('//ShortText[@FormComponentId="inyDruhVO"]/@Value',body)) as varchar)
    end druh_obstaravatela_ine,

    cast(unnest(xpath('//Cpv[@IsPrimary="true"]/@Code|//SelectList[@FormComponentId = "hlavnyCPV"]/SelectListValue/@Title', body))
    AS
    VARCHAR) as     main_cpv_code, -- vypadnu 4 zakazky kvoli zlemu formatu

    null as cpv_others, -- neuplne data

    CASE WHEN cast(xpath('//RadioButtonList[@FormComponentId="rpp_0-akceptaciaVariantov"]/SelectListValue/@Title',body) as varchar) LIKE '{}' THEN NULL
    else
    cast(unnest(xpath('//RadioButtonList[@FormComponentId="rpp_0-akceptaciaVariantov"]/SelectListValue/@Title', body))
    AS
    VARCHAR) end as     varianty,

    cast(unnest(xpath('//item/obstaravatel/text()', body))
    AS
    VARCHAR) contracting_authority_name,

    cast(unnest(xpath('//DropDownList[@Title="Obdobie"]/SelectListValue/@Title|//RadioButtonList[@Title="Obdobie"]/SelectListValue/@Title', body))
    AS
    VARCHAR) typ_obdobie,

    cast(cast(unnest(xpath(
    '//Part[@FormComponentId = "ptHodnota"]/ShortText/@Value|//Part[@FormComponentId = "ptHodnota2"]/ShortText/@Value|//ShortText[@FormComponentId = "rpp_0-vMesiacoch"]/@Value|//ShortText[@FormComponentId = "rpp_0-vDnoch"]/@Value',
    body)) AS VARCHAR) AS INTEGER)  dlzka_zakazky,

    CASE WHEN cast(xpath('//RadioButtonList[@FormComponentId = "rpp_0-kriteria"]/SelectListValue/@Title|//RadioButtonList[@FormComponentId = "PM12_KriteriaPonuk"]/SelectListValue/@Title',body) as varchar) LIKE '{"Nižšie uvedené kritéria"}' THEN
    cast(unnest(xpath(
  '//RadioButtonList[@Title = "Náklady/Cena"]/SelectListValue/@Title',
  body)) AS VARCHAR)
    else
    cast(unnest(xpath(
  '//RadioButtonList[@FormComponentId = "rpp_0-kriteria"]/SelectListValue/@Title|//RadioButtonList[@FormComponentId = "PM12_KriteriaPonuk"]/SelectListValue/@Title',
  body)) AS VARCHAR) end kriteria_ponuk,

    null as predch_uverejnen_zakazky,

    CASE WHEN cast(xpath('//Date[@FormComponentId = "dtLehota"]/@Value',body) as varchar) LIKE '{}' THEN NULL
    else
    cast(unnest(xpath('//Date[@FormComponentId = "dtLehota"]/@Value', body))
    AS
    VARCHAR) end as     ziskanie_podkladov_deadline,

    CASE WHEN cast(xpath('//Date[@FormComponentId = "dtDatumaCas1"]/@Value',body) as varchar) LIKE '{}' THEN NULL
    else
    cast(unnest(xpath('//Date[@FormComponentId = "dtDatumaCas1"]/@Value', body))
    AS
    VARCHAR) end as     ucast_deadline,

    null as bude_sa_opakovat_zakazka,

      cast(unnest(xpath(
  '//DropDownList[@FormComponentId = "ddlyesNo800"]/SelectListValue/@Title|//RadioButtonList[@FormComponentId = "rpp_0-fondyEU"]/SelectListValue/@Title',
  body)) AS VARCHAR)           eu_fondy,

      cast(cast(unnest(xpath(
  '//Date[@FormComponentId = "dtDatumOdoslaniaVyzvy"]/@Value|//Date[@FormComponentId = "datumOdoslania"]/@Value',
  body)) AS VARCHAR) as DATE)          odoslanie_oznamenia,




    body

           from vvo_sept.notices n
               JOIN vvo_sept.raw_notices rn ON n.raw_notice_id = rn.id
               --JOIN vvojul27.procedure_types pt ON pt.id = n.procedure_type_id
               JOIN vvo_sept.bulletin_issues bi ON bi.id = n.bulletin_issue_id
               JOIN vvo_sept.notice_types nt ON nt.id = n.notice_type_id
             WHERE nt.code IN ('WYP', 'WYT', 'WYS')) oznamenie

JOIN ( select
        result.title as result_title,
        result.contract_id as result_contract_id,
          cast(unnest(xpath(
        '(//MultiSelectList[@Type = "NUTS"]/MultiSelectListValue/@Code)[last()]',
          body)) AS VARCHAR)               nuts, -- extrahovane z vysledkov kvoli lepsiemu formatu. Tahana iba posledna hodnota v pripade,ze je ich viac napr. postupnost SK - SK01 ...
         cast(replace(replace(cast(unnest(xpath(
        '//Part[@Title="ODDIEL V: PRIDELENIE ZÁKAZKY"]/Repeater/RepeatingPart/Part[@FormComponentId = "rpp_0-partV_2"]/ShortText[@Title = "Hodnota (ktorá sa brala do úvahy)"]/@Value',
         body)) AS VARCHAR), ',', '.'), ' ', '') AS
         FLOAT) total_final_value_amount_clean, -- odpadnu verzie so sekciou o uzatvoreni zmluvy a VO, kde prislo k zmenam alebo sa nikto neprihlasil. Tiez par cien vo forme rozpatia.

        cast(unnest(xpath(
        '//Part[@Title="ODDIEL V: PRIDELENIE ZÁKAZKY"]/Repeater/RepeatingPart/Part[@FormComponentId = "rpp_0-partV_2"]/ShortText[@FormComponentId = "rpp_0-stDPH_menaHZ"]/@Value',
         body)) AS VARCHAR)               vysledok_dph,
        cast(unnest(xpath(
        '//Part[@Title="ODDIEL V: PRIDELENIE ZÁKAZKY"]/Repeater/RepeatingPart/Part[@FormComponentId = "rpp_0-partV_2"]/DropDownList[@FormComponentId = "rpp_0-celkovaHZ"]/SelectListValue/@Title',
         body)) AS VARCHAR)               vysledok_typ_hodnoty,
        cast(unnest(xpath(
        '//Part[@Title="ODDIEL V: PRIDELENIE ZÁKAZKY"]/Repeater/RepeatingPart/Part[@FormComponentId = "rpp_0-partV_2"]/DropDownList[@Title = "Mena"]/SelectListValue/@Title',
         body)) AS VARCHAR)               vysledok_mena,

         cast(replace(replace(cast(unnest(xpath(
        '//Part[@Title="ODDIEL V: PRIDELENIE ZÁKAZKY"]/Repeater/RepeatingPart/Part[@FormComponentId = "rpp_0-partV_2"]/ShortText[@Title = "Počet prijatých ponúk"]/@Value',
         body)) AS VARCHAR), ',', '.'), ' ', '') AS
         INTEGER) pocet_prijatych_ponuk,

         CASE WHEN cast(xpath('//ShortText[@Title = "Počet ponúk prijatých elektronicky"]/@Value',body) as varchar) LIKE '{}' THEN null
          else -- v mnohych vyzvach tato informacia nie je obsiahnuta, nie je jasne ci v pripade neuvedenia sa hodnota rovna 0 preto sa dosadzuje null
         cast(replace(replace(cast(unnest(xpath(
        '//ShortText[@Title = "Počet ponúk prijatých elektronicky"]/@Value',
         body)) AS VARCHAR), ',', '.'), ' ', '') AS
         INTEGER) end pocet_prijatych_el_ponuk,

       cast(unnest(xpath('//SelectList[@FormComponentId = "hlavnaCinnostVO"]/SelectListValue/@Title', body))
        AS
        VARCHAR) as  hlavna_cinnost, -- hlavna cinnost obstaravetla musi byt extrahovana z vysledku kedze v oznameniach sa prevazne nenachadza

        CASE WHEN cast(xpath('//ShortText[@FormComponentId = "inaHlavnaCinnostVO"]/@Value',body) as varchar) LIKE '{}' THEN NULL
        else
        cast(unnest(xpath('//ShortText[@FormComponentId = "inaHlavnaCinnostVO"]/@Value', body))
        AS
        VARCHAR) end  hlavna_cinnost_ine


from

          vvo_sept.raw_notices rn join vvo_sept.notices n ON n.raw_notice_id = rn.id
                    JOIN vvo_sept.result_notices result ON result.raw_notice_id = rn.id
                    JOIN vvo_sept.notice_types nt_r ON nt_r.id = n.notice_type_id
                    WHERE nt_r.code IN ('IPP', 'IPT', 'IPS') ) vysledok

        ON oznamenie.oznam_contract_id = vysledok.result_contract_id
where deli_sa_casti = 'Nie' --pracujeme iba so zakazkami ktore sa nedelia na casti kvoli zlozitej agregacii delitelnych zakazok
and (vysledok.total_final_value_amount_clean / oznamenie.EstimatedPrice) > 0.3 -- filter na price ratio - chyby v oznameniach a vysledkoch v cenach, pripadne ceny v inych jednotkach (pri elektrine, plyne.. )
AND (vysledok.total_final_value_amount_clean / oznamenie.EstimatedPrice < 2)
