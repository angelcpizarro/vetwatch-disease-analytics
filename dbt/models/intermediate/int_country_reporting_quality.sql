with outbreaks as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

reporting_quality as (
    select
        country_name,

        -- outbreak counts ('SMR' summary rows level)
        sum(case when is_outbreak_count_row
            then new_outbreaks else 0 end)              as total_outbreaks,

        -- total detailed rows (denominator for completeness metrics)
        countif(is_detail_row)                          as total_detailed_rows,

        -- completeness metrics (detailed rows level)
        countif(has_case_count)                         as rows_with_case_count,
        countif(has_death_count)                        as rows_with_death_count,
        countif(has_vaccinated_count)                   as rows_with_vaccinated_count
    
    from outbreaks
    group by 1
),

completed_reporting_quality as (
        select *,
        
        -- completeness percentages
        round(
            (rows_with_case_count)
            / nullif(total_detailed_rows, 0) * 100, 1
        )                                               as case_count_completeness_pct,
        round(
            (rows_with_death_count)
            / nullif(total_detailed_rows, 0) * 100, 1
        )                                               as death_count_completeness_pct,
        round(
            (rows_with_vaccinated_count)
            / nullif(total_detailed_rows, 0) * 100, 1
        )                                               as vaccinated_count_completeness_pct,

        -- composite quality score (%)
        round(
            (
                rows_with_case_count +
                rows_with_death_count +
                rows_with_vaccinated_count
            ) / nullif(total_detailed_rows * 3, 0) * 100, 1
        )                                               as composite_quality_score

    from reporting_quality
)

select * from completed_reporting_quality