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

        -- outbreak counts (from rows that carry valid outbreak counts)
        sum(case when is_outbreak_count_row 
            then new_outbreaks else 0 end)              as total_outbreaks,

        -- quantitative metrics (from detail rows only)
        sum(case when is_detail_row 
            then case_count else null end)              as total_cases,
        sum(case when is_detail_row 
            then death_count else null end)             as total_deaths,
        sum(case when is_detail_row 
            then killed_count else null end)            as total_killed,
        sum(case when is_detail_row 
            then vaccinated_count else null end)        as total_vaccinated,

        -- completeness metrics (from detail rows only)
        countif(is_detail_row)                          as total_rows,
        countif(is_detail_row and has_case_count)       as rows_with_case_count,
        round(
            countif(is_detail_row and has_case_count)
            / nullif(countif(is_detail_row), 0) * 100, 1
        )                                               as case_count_completeness_pct


    from outbreaks
    group by 1, 2, 3, 4, 5, 6, 7, 8
)

select * from trends