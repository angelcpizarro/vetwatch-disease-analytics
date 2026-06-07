# Analytical Findings

## Table of Contents

1. [Overview](#overview)
2. [Disease Trends](#disease-trends)
3. [Geographic Breakdown](#geographic-breakdown)
4. [Data Quality](#data-quality)
5. [Limitations](#limitations)

---

## Overview

This document records the analytical findings from the VetWatch dashboard, based on 20 years of WAHIS quantitative data (2005–2024). Findings are presented per analytical question and include specific data points, observations, and known limitations.

Note: Apiary diseases are excluded from all quantitative analysis due to incompatibility of units — see [Limitations](#limitations) for details.

For a summary of findings, see the [README](../README.md).

---

## Disease Trends

*Which diseases and disease categories show the highest outbreak reporting, and how has that changed over 20 years?*

### Livestock dominates outbreak reporting

Livestock diseases account for 48.9% of all reported outbreaks across 2005–2024, making it by far the largest category. This reflects the large number of distinct livestock diseases tracked by WAHIS, their global prevalence, and the strong economic impact that reporting outbreaks affecting commercially farmed animals can have.

The top 5 most reported diseases are dominated by livestock and multi-species diseases:

1. Livestock: Brucellosis (abortus) — 297,400
2. Multi-species: Echinococcus granulosus — 271,100
3. Livestock: Bovine TB — 253,200
4. Multi-species: Rabies — 240,900
5. Livestock: FMD — 221,700

### Foot-and-mouth disease (FMD) (2022)

A sudden increase in FMD outbreaks is observed in 2022. Exploring the origin of this increase using the **Geographic Breakdown** page, reveals most of the outbreaks from Indonesia. This is consistent with peer-reviewed papers:

> In 2022, a severe foot-and-mouth disease (FMD) outbreak swept across Indonesia, ending the country's FMD-free status which it had maintained since 1990. The highly contagious viral strain spread rapidly through Indonesian cattle and livestock populations, heavily impacting beef feedlots.

**Reference: Prama Rangga et al. (2025) — Preventive Veterinary Medicine. Volume 246, 106739**

### Echinococcus granulosus peak of outbreaks in Chile (2019-2021)

Chile's Echinococcus granulosus reporting shows a dramatic pattern — zero cases from 2014–2017, a sudden surge peaking at 105,394 in 2020, then returning to zero by 2023. This is inconsistent with the biology of an endemic parasitic disease and likely reflects a change in Chile's reporting methodology rather than a genuine disease emergence. High outbreak counts should always be interpreted cautiously without additional context.

### COVID-19 impact on reporting (2020)

A dip in reporting is visible across most categories in 2020, consistent with COVID-19 disrupting global veterinary surveillance infrastructure and reporting workflows. 

Multi-species diseases show a different pattern — the expected 2020 dip is masked by the simultaneous peak of Echinococcus granulosus reporting in Chile (see Echinococcus granulosus section above).

### Disease category classification methodology

Disease names in WAHIS use long formal nomenclature — 161 distinct diseases were grouped into 8 clinically meaningful categories (Livestock, Multi-species, Avian, Swine, Equine, Aquatic, Wildlife) using a manually curated seed file. Categories reflect the primary animal domain of each disease, not every species it can infect. See `docs/data_exploration_notes.md` for the full classification methodology note.

---

## Geographic Breakdown

*How are reported outbreaks distributed globally across regions and countries?*

### Americas lead outbreak reporting

The Americas (1.1m outbreaks) has reported the most outbreaks followed by Europe (998.6k outbreaks) and Asia (967.6k outbreaks), which represents over 74% of all reported outbreaks across 2005–2024. Middle East follows at 655.7k.

### Iran leads globally

Iran reports the highest outbreak count of any individual country (435.7k), followed by China (340.0k) and Chile (310.5k). Iran's disease categories dominating outbreaks are Livestock (59%) and Avian (36.7%) with no dramatic peak over the 20 years. Whether high outbreak counts reflect genuine disease pressure or strong reporting infrastructure cannot be determined from reporting data alone — see the Data Quality section for completeness analysis.

### Geographic distribution is broadly global

No single region dominates overwhelmingly. The map shows outbreaks reported across all continents, with notable concentration in parts of Asia and the Americas.

---

## Data Quality

*Which countries and regions show the highest data completeness, and what does that reveal about the reliability of global disease reporting?*

### Global average completeness

The global average composite quality score is 71.50%, calculated as the average of three completeness metrics (cases, deaths, and vaccination status) across all countries.

### Middle East and Africa lead on data quality

The Middle East achieves the highest average composite quality score (78.6%) followed by Africa (78.5%), despite not being the regions with the most reported outbreaks. This directly demonstrates that outbreak volume and reporting quality are not correlated.

### Vaccination reporting is the weakest metric globally

Of the three completeness metrics, vaccination reporting is consistently the lowest (51.2% globally), compared to case reporting (87.8%) and death reporting (75.5%). This likely reflects a combination of reporting gaps and the fact that not all diseases have available vaccines.

### American and European countries score below the global average

American and European countries score below the global average — 68.8% and 64.4% respectively. This likely reflects the wider variety of diseases reported in these regions, including many where vaccination data is not routinely collected, rather than poor surveillance quality.

### Notable outliers

Puerto Rico is the only country with a composite quality score of 0% — reporting one outbreak event (IN/FUR source) with no quantitative data at all. Wallis and Futuna Island, Antarctica and Vanuatu also reported 0 outbreaks but in this case they have >0% composite quality score — Vanuatu scoring 100%. 

### Countries with High data quality

114 out of 201 reporting countries (56.7%) achieve a High quality band (composite score ≥ 70%). 

Vanuatu (0 outbreaks), San Marino (11 outbreaks), St. Lucia (1 outbreak), and Samoa (2 outbreaks) scoring 100%. These scores should be interpreted cautiously given the very low outbreak counts. However, Sudan has the 5th highest composite score of 99.2% with 3,601 outbreaks followed by Somalia (98.3%; 11,707 outbreaks). 

---

## Limitations

### Apiary diseases excluded

Apiary diseases (Varroosis, American foulbrood, Small hive beetle etc.) are excluded from all quantitative analysis. The `new_outbreaks` field for bee diseases records hive counts rather than distinct outbreak events, making them incomparable with animal disease outbreak counts. Apiary diseases account for a significant proportion of records and their inclusion would distort all outbreak count aggregations.

See problems_and_solutions.md file for more details.

### Outbreak counts reflect reporting, not disease burden

The data measures what was reported to WAHIS — not the true prevalence or burden of disease. Countries with strong veterinary surveillance infrastructure may report more outbreaks than countries with higher actual disease pressure but weaker reporting systems. The data cannot distinguish between these two explanations.

### Disease category classifications are manually curated

The `disease_categories` seed file was created using veterinary clinical knowledge and is not sourced from an official reference database. The `is_zoonotic` field in particular reflects understanding at time of creation (May 2026) and may require updating as scientific consensus evolves.

### Region inconsistencies in source data

20 countries (predominantly Middle Eastern and North African) appear under more than one world region in the source data. The most common region per country was selected to resolve this.