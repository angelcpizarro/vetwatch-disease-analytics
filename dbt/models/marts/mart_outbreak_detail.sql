with detail as (
    select * from {{ ref('int_outbreaks_enriched') }}
),

final as (
    select
        -- identifiers
        event_id,
        outbreak_id,
        report_source,

        -- time
        report_year,
        report_semester,

        -- geography
        world_region,
        country_name,
        administrative_division,

        -- disease
        disease_name_raw,
        disease_short_name,
        disease_category,
        is_zoonotic,
        serotype,
        animal_category,
        species,

        -- quantitative fields
        new_outbreaks,
        case_count,
        death_count,
        killed_count,
        slaughtered_count,
        vaccinated_count,
        susceptible_count,
        measuring_units,

        -- completeness flags
        is_detail_row,
        has_case_count,
        has_death_count,
        has_vaccinated_count

    from detail
    where is_detail_row = true
)

select * from final