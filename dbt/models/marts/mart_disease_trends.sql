with outbreaks as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

trends as (
    select
        -- time dimensions
        report_year,
        report_semester,

        -- geographic dimensions
        world_region,
        country_name,

        -- disease dimensions
        disease_short_name,
        disease_category,
        is_zoonotic,
        animal_category,

        -- measures
        sum(new_outbreaks)                          as total_outbreaks,
        sum(case_count)                             as total_cases,
        sum(death_count)                            as total_deaths,
        sum(killed_count)                           as total_killed,
        sum(vaccinated_count)                       as total_vaccinated,

        -- completeness metrics
        count(*)                                    as total_rows,
        countif(has_case_count)                     as rows_with_case_count,
        round(
            countif(has_case_count) / count(*) * 100, 1
        )                                           as case_count_completeness_pct

    from outbreaks
    where is_detail_row = true
    group by 1, 2, 3, 4, 5, 6, 7, 8
)

select * from trends