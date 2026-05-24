-- Fails if any new outbreak count is negative
select *
from {{ ref('stg_wahis__outbreaks') }}
where new_outbreaks < 0