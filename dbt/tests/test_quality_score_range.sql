-- Fails if composite quality score is outside 0-100
select *
from {{ ref('mart_country_summary') }}
where composite_quality_score < 0 
   or composite_quality_score > 100