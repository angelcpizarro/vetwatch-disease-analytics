-- Fails if any disease name doesn't match the seed file
-- Zero orphaned diseases expected after non-breaking space fix
select *
from {{ ref('int_outbreaks_enriched') }}
where disease_short_name is null