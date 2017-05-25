

SELECT  nt.code, nt.name, count(nt.code)

        FROM vvo.notices n
         JOIN (SELECT *
               FROM vvo.raw_notices
               WHERE zovo_type = 'NM03') rn ON n.raw_notice_id = rn.id
         JOIN vvo.result_notices result ON result.raw_notice_id = rn.id join vvo.notice_types nt on nt.id = result.notice_type_id

group by nt.code, nt.name
order by count(nt.code) desc

select * from vvo.notice_types
where code like 'V%'


SELECT  nt.code, nt.name, count(nt.code)

FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
    JOIN vvo.procedure_types pt ON pt.id = n.procedure_type_id
    JOIN vvo.bulletin_issues bi ON bi.id = n.bulletin_issue_id join vvo.notice_types nt on nt.id = n.notice_type_id

group by nt.code, nt.name
order by count(nt.code) desc




select ep,total_final_value_amount_minus_vat/ep as price_ratio, *  from (

select oznamenie.oznam_tit, oznamenie.published_on, oznamenie.nt_code, oznamenie.nt_name, vysledok.nt_code, vysledok.nt_name, oznamenie.EstimatedPrice as ep, EstPriceResult as estres,
CASE WHEN vysledok.total_final_value_vat_included = TRUE
   THEN (1 - cast(vysledok.total_final_value_vat_rate AS FLOAT) / 100) * total_final_value_amount
  ELSE total_final_value_amount
  END AS        total_final_value_amount_minus_vat,  * from (
SELECT
 n.contract_id                                                                          AS oznam_contract_id,
    pt.title                                                                               AS procedure_title,
    n.title                                                                                AS oznam_tit,
    n.e_auction                                                                            AS oznam_e_auction,
    nt.code as nt_code,
    nt.name as nt_name,
    cast(replace(replace(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@CssClass="NoBr PDF_beginline"]/@Value',
                                                                            body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS EstimatedPrice,

     cast(unnest(xpath(
                    '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@Title="Táto zákazka sa delí na časti"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        deli_sa_casti,
    *
   FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
    JOIN vvo.procedure_types pt ON pt.id = n.procedure_type_id
    JOIN vvo.bulletin_issues bi ON bi.id = n.bulletin_issue_id
    join vvo.notice_types nt on nt.id = n.notice_type_id
    where nt.code in ('MST','MSS','MSP')
    ) oznamenie

         join

 ( SELECT
         result.contract_id AS                               result_contract_id,
         result.title       AS                               result_title,
         result.e_auction   AS                               result_e_auction,
         ntt.code as nt_code,
    ntt.name as nt_name,

    cast(replace(replace(cast(unnest(xpath('//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater/RepeatingPart/ShortText[@ FormComponentId = "rpp_0-MN03_zmluvaPredpokladanaHodnota"]/@Value',body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS EstPriceResult,
 *
        FROM vvo.notices n
         JOIN (SELECT *
               FROM vvo.raw_notices
               WHERE zovo_type = 'NM03') rn ON n.raw_notice_id = rn.id
         JOIN vvo.result_notices result ON result.raw_notice_id = rn.id join vvo.notice_types nt on nt.id = n.notice_type_id
        join vvo.notice_types ntt on ntt.id = n.notice_type_id
        where nt.code in ('VST','VSS','VSP')
       ) vysledok

   ON oznamenie.oznam_contract_id = vysledok.result_contract_id
   order by oznamenie.oznam_tit, oznamenie.published_on

) a
where deli_sa_casti = 'Nie' and ep <> estres
order by price_ratio asc













 SELECT

     --cast(unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@ FormComponentId ="ddlRozpatie66"]/SelectListValue/@Title',body)) AS VARCHAR) typ_ceny_oznamenia,
    case WHEN cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title="Do"]/@Value',body) as varchar) like '{}' THEN NULL
    else unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title="Do"]/@Value',body))
 end CenaDo_Oznamenia
   FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
    JOIN vvo.procedure_types pt ON pt.id = n.procedure_type_id
    JOIN vvo.bulletin_issues bi ON bi.id = n.bulletin_issue_id
    join vvo.notice_types nt on nt.id = n.notice_type_id
    where nt.code in ('MST','MSS','MSP')






select count(*) from (

  SELECT
    result.contract_id AS result_contract_id,
    result.title       AS result_title,
    result.e_auction   AS result_e_auction,
        cast(cast(unnest(xpath(
                              '//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater[@FormComponentId ="rpZmluva"]/RepeatingPart[@FormComponentId ="rpp_0-partZmluva"]/ShortText[@Title = "Počet prijatých ponúk"]/@Value',
                              body)) AS VARCHAR) AS INTEGER) pocet_prijatych_ponuk,
         cast(cast(unnest(xpath(
                              '//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater[@FormComponentId ="rpZmluva"]/RepeatingPart[@FormComponentId ="rpp_0-partZmluva"]/ShortText[@Title = "Počet ponúk prijatých elektronickou cestou"]/@Value',
                              body)) AS VARCHAR) AS INTEGER) pocet_prijatych_el_ponuk,

        cast(replace(replace(cast(unnest(xpath('//Part[@Title="ODDIEL V: ZADANIE ZÁKAZKY"]/Repeater/RepeatingPart/ShortText[@ FormComponentId = "rpp_0-MN03_zmluvaPredpokladanaHodnota"]/@Value',body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS EstimatedPrice_From_Result,

        case WHEN result.total_final_value_type like 'Rozpätie hodnôt' THEN (total_final_value_lowest_offer+total_final_value_highest_offer)/2
           else total_final_value_amount
             end total_final_value_amount_clean ,
          *
  FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM03') rn ON n.raw_notice_id = rn.id
    JOIN vvo.result_notices result ON result.raw_notice_id = rn.id
    JOIN vvo.notice_types nt_r ON nt_r.id = n.notice_type_id
  WHERE nt_r.code IN ('VST', 'VSS', 'VSP')

) a


select count(*) from (

  SELECT
    -- v niektorych oznameniach nie je uvedena cena alebo ak sa deli na castiach tak su tieto ceny uvedene inde
    case WHEN cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title ="Hodnota/Od"]/@Value',body) as varchar) like '{}' THEN NULL
      else
    cast(replace(replace(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title ="Hodnota/Od"]/@Value',
                                         body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT)
      end  EstimatedPrice,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL IV: POSTUP"]/DropDownList[@ Title ="Použije sa elektronická aukcia"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        el_aukcia,
    cast(unnest(xpath(
                    '//Part[@Title="HLAVIČKA FORMULÁRA"]/RadioButtonList[@ Title ="Druh postupu"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        druh_postupu,
    cast(unnest(
             xpath('//Part[@Title="HLAVIČKA FORMULÁRA"]/DropDownList[@ Title ="Druh zákazky"]/SelectListValue/@Title',
                   body)) AS VARCHAR)                                                         druh_zakazky,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/SelectList[@Type ="druh_VO"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        druh_obstaravatela,
    -- v pripade ze ma oznamenie viacero hlavnych cinnosti je ako hlavna vybrana prva z nich, cca 100 pripadov.
    cast(unnest(xpath(
                    '(//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/MultiSelectList[@Type ="hlavnyPredmetCinnosti"]/MultiSelectListValue/@Title)[1]',
                    body)) AS VARCHAR)                                                        hlavna_cinnost,

    case WHEN cast(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[@IsPrimary = "true"]/@Code', body) as varchar) like '{}' THEN NULL
    else
    cast(unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[@IsPrimary = "true"]/@Code', body)) AS
         VARCHAR)
    end main_cpv_code,
    /*cast(unnest(xpath(
                    '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@Title="Táto zákazka sa delí na časti"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        deli_sa_casti,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@Title="Varianty sa budú prijímať"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        varianty,
    cast(cast(unnest(xpath(
                         '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@FormComponentId="stHodnotaMesiac"]/@Value',
                         body)) AS VARCHAR) AS INTEGER)                                       dlzka_zakazky_mesiace,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL IV: POSTUP"]/RadioButtonList[@ Type ="NM02_KriteriaPonuk"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        kriteria_ponuk,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL IV: POSTUP"]/DropDownList[@FormComponentId ="ddlPredchadzaujuceOznamenie"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        predch_uverejnen_zakazky,
    cast(cast(unnest(xpath(
                         '//Part[@Title="ODDIEL IV: POSTUP"]/Part[@FormComponentId ="ptPodmienkyZiskavaniaSutaznychPodkladov"]/Date/@Value',
                         body)) AS VARCHAR) AS
         DATE)                                                                                ziskanie_podkladov_deadline,
    cast(cast(unnest(xpath(
                         '//Part[@Title="ODDIEL IV: POSTUP"]/Date[@FormComponentId ="dtLehotaNaPredkladaniePonuk"]/@Value',
                         body)) AS VARCHAR) AS DATE)                                          ucast_deadline,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/DropDownList[@Title ="Toto obstarávanie sa bude opakovať"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        bude_sa_opakovat_zakazka,
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/DropDownList[@ FormComponentId ="ddlProgramFinancovanyZFondov"]/SelectListValue/@Title',
                    body)) AS VARCHAR)                                                        eu_fondy,
    cast(cast(unnest(xpath(
                         '//Part[@Title="ODDIEL VI: DOPLNKOVÉ INFORMÁCIE"]/Date[@FormComponentId ="dtDatumOdoslaniaTohtoOznamenia"]/@Value',
                         body)) AS VARCHAR) AS DATE)                                          odoslanie_oznamenia,

     cast(unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/DropDownList[@ FormComponentId ="ddlRozpatie66"]/SelectListValue/@Title',body)) AS VARCHAR) typ_ceny_oznamenia,

     cast(replace(replace(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@Title="Do"]/@Value',
                                         body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS CenaDo_Oznamenia, */
    n.contract_id AS oznam_contract_id,
    pt.title      AS procedure_title,
    n.title       AS oznam_title,
    n.e_auction   AS oznam_e_auction,
    *
  FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
    JOIN vvo.procedure_types pt ON pt.id = n.procedure_type_id
    JOIN vvo.bulletin_issues bi ON bi.id = n.bulletin_issue_id
    JOIN vvo.notice_types nt ON nt.id = n.notice_type_id
  WHERE nt.code IN ('MST', 'MSS', 'MSP')
) b




select *

  FROM vvo.notices n
    JOIN (SELECT *
          FROM vvo.raw_notices
          WHERE zovo_type = 'NM02') rn ON n.raw_notice_id = rn.id
    JOIN vvo.procedure_types pt ON pt.id = n.procedure_type_id
    JOIN vvo.bulletin_issues bi ON bi.id = n.bulletin_issue_id
    JOIN vvo.notice_types nt ON nt.id = n.notice_type_id
where n.title = 'Pravdepodobné environmentálne záťaže - prieskum na vybraných lokalitách Slovenskej republiky'


