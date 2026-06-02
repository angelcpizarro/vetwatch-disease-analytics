with reporting_quality as (
    select * from {{ ref('int_country_reporting_quality') }}
),

-- gets most common region per country to resolve inconsistencies 
-- (i.e. one country in more than one world region)
country_regions as (
    select
        country_name,
        world_region,
        count(*) as region_count,
        row_number() over (
            partition by country_name 
            order by count(*) desc
        ) as rn
    from {{ ref('int_outbreaks_enriched') }}
    group by 1, 2
),

final_regions as (
    select country_name, world_region
    from country_regions
    where rn = 1
),

summary as (
    select
        r.country_name,
        f.world_region,
        r.total_outbreaks,
        r.case_count_completeness_pct,
        r.death_count_completeness_pct,
        r.vaccinated_count_completeness_pct,
        r.composite_quality_score,
        case
            when r.composite_quality_score >= 70 then 'High'
            when r.composite_quality_score >= 40 then 'Medium'
            else 'Low'
        end                                     as quality_band
    from reporting_quality r
    left join final_regions f
        on r.country_name = f.country_name
)

select * from summary