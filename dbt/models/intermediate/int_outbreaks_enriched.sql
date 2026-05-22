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

        -- derived fields
        case
            when o.outbreak_id is null then 'SMR'
            else 'IN_FUR'
        end                                         as report_source,

        case
            when o.species is null or o.species = ''
            then false
            else true
        end                                         as is_detail_row,

        case
            when o.case_count is not null
            then true else false
        end                                         as has_case_count,

        case
            when o.death_count is not null
            then true else false
        end                                         as has_death_count,

        case
            when o.vaccinated_count is not null
            then true else false
        end                                         as has_vaccinated_count

    from outbreaks o
    left join disease_categories d
        on o.disease_name_raw = d.disease_name_raw
)

select * from enriched