with outbreaks as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

trends as (
    select
        report_year,
        world_region,
        country_name,
        disease_short_name,
        disease_category,

        -- outbreak counts ('SMR' summary rows level)
        sum(case when is_outbreak_count_row 
            then new_outbreaks else 0 end)              as total_outbreaks,

        -- quantitative metrics (detailed rows level)
        sum(case when has_case_count 
            then case_count else null end)              as total_cases,
        sum(case when has_death_count 
            then death_count else null end)             as total_deaths,
        sum(case when has_vaccinated_count 
            then vaccinated_count else null end)        as total_vaccinated

    from outbreaks
    group by 1, 2, 3, 4, 5
)

select * from trends