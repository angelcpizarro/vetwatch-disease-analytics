-- Fails if any boolean flag contains an unexpected value (not true or false)
select *
from {{ ref('int_outbreaks_enriched') }}
where is_detail_row is null
   or is_outbreak_count_row is null
   or has_case_count is null
   or has_death_count is null
   or has_vaccinated_count is null