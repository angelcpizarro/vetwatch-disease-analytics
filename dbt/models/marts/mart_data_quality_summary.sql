with reporting_quality as (
    select * from {{ ref('int_country_reporting_quality') }}
)

select
    country_name,
    world_region,
    total_outbreaks,
    case_count_completeness_pct,
    death_count_completeness_pct,
    vaccinated_count_completeness_pct,
    composite_quality_score,
    case
        when composite_quality_score >= 70 then 'High'
        when composite_quality_score >= 40 then 'Medium'
        else 'Low'
    end                                     as quality_band
from reporting_quality