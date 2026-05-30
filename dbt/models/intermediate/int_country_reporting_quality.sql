with outbreaks as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

reporting_quality as (
    select
        country_name,

        -- outbreak counts (from rows that carry valid outbreak counts)
        sum(case when is_outbreak_count_row
            then new_outbreaks else 0 end)              as total_outbreaks,

        -- total detail rows (denominator for completeness metrics)
        countif(is_detail_row)                          as total_rows,

        -- completeness metrics (from detail rows only)
        countif(is_detail_row and has_case_count)       as rows_with_case_count,
        countif(is_detail_row and has_death_count)      as rows_with_death_count,
        countif(is_detail_row and has_vaccinated_count) as rows_with_vaccinated_count,

        -- completeness percentages
        round(
            countif(is_detail_row and has_case_count)
            / nullif(countif(is_detail_row), 0) * 100, 1
        )                                               as case_count_completeness_pct,
        round(
            countif(is_detail_row and has_death_count)
            / nullif(countif(is_detail_row), 0) * 100, 1
        )                                               as death_count_completeness_pct,
        round(
            countif(is_detail_row and has_vaccinated_count)
            / nullif(countif(is_detail_row), 0) * 100, 1
        )                                               as vaccinated_completeness_pct,

        -- composite quality score
        round(
            (
                countif(is_detail_row and has_case_count) +
                countif(is_detail_row and has_death_count) +
                countif(is_detail_row and has_vaccinated_count)
            ) / nullif(countif(is_detail_row) * 3, 0) * 100, 1
        )                                               as composite_quality_score

    from outbreaks
    group by 1
)

select * from reporting_quality