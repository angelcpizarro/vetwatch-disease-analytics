with source as (
    select * from {{ source('wahis_raw', 'outbreaks') }}
),

renamed as (
    select
        -- identifiers
        event_id,
        outbreak_id,

        -- time
        cast(year as integer)                       as report_year,
        semester                                    as report_semester,

        -- geography
        world_region,
        country                                     as country_name,
        administrative_division,

        -- disease
        disease                                     as disease_name_raw,
        serotype_subtype_genotype                   as serotype,
        animal_category,
        species,

        -- quantitative fields
        cast(new_outbreaks as integer)              as new_outbreaks,
        cast(cases as integer)                      as case_count,
        cast(deaths as integer)                     as death_count,
        cast(killed_and_disposed_of as integer)     as killed_count,
        cast(slaughtered as integer)                as slaughtered_count,
        cast(vaccinated as integer)                 as vaccinated_count,
        cast(susceptible as integer)                as susceptible_count,
        measuring_units

    from source
)

select * from renamed