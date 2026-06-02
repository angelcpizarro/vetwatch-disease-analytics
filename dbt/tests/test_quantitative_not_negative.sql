-- Fails if any quantitative count field has a negative value
-- Applies to new_outbreaks, cases, deaths, killed, slaughtered, vaccinated and susceptible

select *
from {{ ref('stg_wahis__outbreaks') }}
where new_outbreaks < 0
   or case_count < 0
   or death_count < 0
   or killed_count < 0
   or slaughtered_count < 0
   or vaccinated_count < 0
   or susceptible_count < 0