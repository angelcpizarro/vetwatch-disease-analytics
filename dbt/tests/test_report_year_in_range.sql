-- Fails if any year is outside the expected 2005-2024 range
select *
from {{ ref('stg_wahis__outbreaks') }}
where report_year < 2005 
   or report_year > 2024