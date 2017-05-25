-- pocet notices - 61520
-- pocet result notices 23143
--select total_final_value_amount, total_estimated_value_amount from vvo.result_notices r join vvo.notice_types nt on r.notice_type_id = nt.id

--TODO:
-- vyriesit predbeznu cenu dph/bez dph.
--novy pocet 41218

select * from vvo.contract_awards ca join vvo.result_notices rn on ca.result_notice_id = rn.id  join vvo.raw_notices raw on rn.raw_notice_id = raw.id join vvo.notices n on n.raw_notice_id = raw.id join vvo.notice_types nt on rn.notice_type_id = nt.id join vvo.bulletin_issues bi on bi.id = rn.bulletin_issue_id
where ca.title = 'I/77 Bardejov, juhozápadný obchvat'
--ca.id = 13

select estimated_value_amount,final_value_amount, * from vvo.contract_awards
where final_value_amount > estimated_value_amount


select * from vvo.result_notice_main_cpvs

select * from vvo.result_notice_lot_main_cpvs

select * from vvo.contract_awards ca join vvo.result_notices rn on ca.result_notice_id = rn.id
where ca.title = 'I/77 Bardejov, juhozápadný obchvat'

--unnest(xpath('content/Part[@Title=''ODDIEL II: PREDMET ZÁKAZKY'']/', body))
--http://stackoverflow.com/questions/4835891/extract-value-of-attribute-node-via-xpath

--cast(unnest(xpath('//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/ShortText[@ Title ="Iný verejný obstarávateľ"]/@Value',body)) na ine druhy ver. obstaravania

select total_final_value_amount_minus_vat/EstimatedPriceCleaned as price_ratio, * from (

 SELECT
  -- oznamenie.body,
  oznamenie.oznam_title,
  oznamenie.contracting_authority_name,
  oznamenie.EstimatedPrice,
  oznamenie.druh_postupu,
  oznamenie.druh_zakazky,
  oznamenie.druh_obstaravatela,
  oznamenie.hlavna_cinnost,
  oznamenie.main_cpv_code,
  oznamenie.deli_sa_casti,
  oznamenie.varianty,
  oznamenie.dlzka_zakazky_mesiace,
  oznamenie.kriteria_ponuk,
  oznamenie.el_aukcia,
  oznamenie.predch_uverejnen_zakazky,
  oznamenie.ziskanie_podkladov_deadline,
  oznamenie.ucast_deadline,
  oznamenie.published_on,
  oznamenie.bude_sa_opakovat_zakazka,
  oznamenie.eu_fondy,
  oznamenie.odoslanie_oznamenia,
  oznamenie.typ_ceny_oznamenia,
  oznamenie.CenaDo_Oznamenia,
  case WHEN oznamenie.typ_ceny_oznamenia like 'Rozpätie hodnôt' THEN (oznamenie.EstimatedPrice + oznamenie.CenaDo_Oznamenia)/2
   else oznamenie.EstimatedPrice
   end EstimatedPriceCleaned,
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
    cast(replace(replace(cast(unnest(xpath(
                                         '//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/ShortText[@CssClass="NoBr PDF_beginline"]/@Value',
                                         body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS EstimatedPrice,
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
    cast(unnest(xpath(
                    '//Part[@Title="ODDIEL I: VEREJNÝ OBSTARÁVATEĽ"]/MultiSelectList[@Type ="hlavnyPredmetCinnosti"]/MultiSelectListValue/@Title',
                    body)) AS VARCHAR)                                                        hlavna_cinnost,
    cast(unnest(xpath('//Part[@Title="ODDIEL II: PREDMET ZÁKAZKY"]/Cpv[@IsPrimary = "true"]/@Code', body)) AS
         VARCHAR)                                                                             main_cpv_code,
    cast(unnest(xpath(
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
                                         body)) AS VARCHAR), ',', '.'), ' ', '') AS FLOAT) AS CenaDo_Oznamenia,
    n.contract_id                                                                          AS oznam_contract_id,
    pt.title                                                                               AS procedure_title,
    n.title                                                                                AS oznam_title,
    n.e_auction                                                                            AS oznam_e_auction,
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

  JOIN (
        SELECT
         result.contract_id AS                               result_contract_id,
         result.title       AS                               result_title,
         result.e_auction   AS                               result_e_auction,
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
          join vvo.notice_types nt_r on nt_r.id = n.notice_type_id
          where nt_r.code in ('VST','VSS','VSP')
       ) vysledok

   ON oznamenie.oznam_contract_id = vysledok.result_contract_id

) a
--where deli_sa_casti = 'Nie' and EstimatedPriceCleaned = EstimatedPrice_From_Result
order by total_final_value_amount_minus_vat/EstimatedPriceCleaned asc






select count(*) from (
  select * from vvo.notices n  join (select * from vvo.raw_notices where zovo_type = 'NM02')  rn on n.raw_notice_id = rn.id join vvo.procedure_types pt on pt.id = n.procedure_type_id join vvo.bulletin_issues bi on bi.id = n.bulletin_issue_id

)a









