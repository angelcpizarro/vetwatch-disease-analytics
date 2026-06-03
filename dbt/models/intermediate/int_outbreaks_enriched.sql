with outbreaks as (
    select * from {{ ref('stg_wahis__outbreaks') }}
),

disease_categories as (
    select * from {{ ref('disease_categories') }}
),

enriched as (
    select
        -- identifiers
        o.event_id,
        o.outbreak_id,

        -- time
        o.report_year,
        o.report_semester,

        -- geography
        o.world_region,
        o.country_name,
        o.administrative_division,

        -- disease (raw + enriched from seed)
        o.disease_name_raw,
        d.disease_short_name,
        d.disease_category,
        d.is_zoonotic,
        o.serotype,
        o.animal_category,
        o.species,

        -- quantitative fields
        o.new_outbreaks,
        o.case_count,
        o.death_count,
        o.killed_count,
        o.slaughtered_count,
        o.vaccinated_count,
        o.susceptible_count,
        o.measuring_units,

        -- classifies rows by source type: 'SMR' or 'IN_FUR'
        case
            when o.outbreak_id is null then 'SMR'
            else 'IN_FUR'
        end                                         as report_source,

        -- identifies detailed rows ('species' carrying a value, both 'SMR' and 'IN_FUR' level)
        case
            when o.species is null or o.species = ''
            then false
            else true
        end                                         as is_detail_row,

        -- keeps only the summary rows at 'SMR' level ('new_outbreaks' carrying a value)
        case
            when o.new_outbreaks is not null
             and o.new_outbreaks > 0
             and o.outbreak_id is null              -- SMR only
            then true
            else false
        end                                         as is_outbreak_count_row
    
    from outbreaks o
    left join disease_categories d
        on o.disease_name_raw = d.disease_name_raw
),

enriched_with_flags as (
    select
        *,
        -- completeness flags (detailed rows only)
        case
            when case_count is not null
             and is_detail_row = true
            then true else false
        end                                          as has_case_count,

        case
            when death_count is not null
             and is_detail_row = true
            then true else false
        end                                          as has_death_count,

        case
            when vaccinated_count is not null
             and is_detail_row = true
            then true else false
        end                                          as has_vaccinated_count
    from enriched
),

-- gets most common region per country to resolve inconsistencies 
-- (i.e. one country in more than one world region)
region_lookup as (
    select
        country_name,
        world_region,
        row_number() over (
            partition by country_name
            order by count(*) desc
        ) as rn
    from enriched_with_flags
    group by 1, 2
),

resolved_regions as (
    select country_name, world_region
    from region_lookup
    where rn = 1
),

final as (
    select
        e.* except(world_region),
        r.world_region
    from enriched_with_flags e
    left join resolved_regions r
        on e.country_name = r.country_name
)

select * from final
where disease_category != 'Apiary'