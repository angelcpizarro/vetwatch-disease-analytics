with source as (
    select * from {{ source('wahis_raw', 'outbreaks') }}
),

renamed as (
    select
        -- identifiers
        cast(event_id as integer)               as event_id,
        cast(outbreak_id as integer)            as outbreak_id,

        -- time
        cast(year as integer)                   as report_year,
        TRIM(semester)                          as report_semester,

        -- geography
        TRIM(world_region)                      as world_region,
        TRIM(country)                           as country_name,
        TRIM(administrative_division)           as administrative_division,

        -- disease
        TRIM(disease)                           as disease_name_raw,
        TRIM(serotype_subtype_genotype)         as serotype,
        TRIM(animal_category)                   as animal_category,
        TRIM(species)                           as species,

        -- quantitative fields
        cast(new_outbreaks as integer)          as new_outbreaks,
        cast(cases as integer)                  as case_count,
        cast(deaths as integer)                 as death_count,
        cast(killed_and_disposed_of as integer) as killed_count,
        cast(slaughtered as integer)            as slaughtered_count,
        cast(vaccinated as integer)             as vaccinated_count,
        cast(susceptible as integer)            as susceptible_count,
        TRIM(measuring_units)                   as measuring_units

    from source
)

select * from renamed