with outbreaks as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

reporting_quality as (
    select
        country_name,
        world_region,

        -- volume metrics
        count(*)                                        as total_rows,
        sum(new_outbreaks)                              as total_outbreaks,

        -- completeness metrics
        countif(has_case_count)                         as rows_with_case_count,
        countif(has_death_count)                        as rows_with_death_count,
        countif(has_vaccinated_count)                   as rows_with_vaccinated_count,

        -- completeness percentages
        round(
            countif(has_case_count) / count(*) * 100, 1
        )                                               as case_count_completeness_pct,
        round(
            countif(has_death_count) / count(*) * 100, 1
        )                                               as death_count_completeness_pct,
        round(
            countif(has_vaccinated_count) / count(*) * 100, 1
        )                                               as vaccinated_completeness_pct,

        -- Average of three completeness metrics)
        round(
            (
                countif(has_case_count) +
                countif(has_death_count) +
                countif(has_vaccinated_count)
            ) / (count(*) * 3) * 100, 1
        )                                               as composite_quality_score

    from outbreaks
    group by 1, 2
)

select * from reporting_quality