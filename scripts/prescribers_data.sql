--1. 

--a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

--Bruce Pendley, NPI #1881634483 had the most amount of claims at 99,707

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT prescriber.npi, nppes_provider_last_org_name AS l_name, nppes_provider_first_name AS f_name, specialty_description, SUM(total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi, l_name, f_name, specialty_description
ORDER BY claim_count DESC

--2. 

--a. Which specialty had the most total number of claims (totaled over all drugs)?

--Family Practice had the most total number of claims at 9,752,347.

SELECT specialty_description AS specialty, SUM(total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY specialty
ORDER BY claim_count DESC

--b. Which specialty had the most total number of claims for opioids?

--Nurse Practitioner had the most total number of claims for opioids at 900,845.

SELECT specialty_description AS specialty, SUM(total_claim_count) AS claim_count, opioid_drug_flag
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag NOT LIKE 'N' 
OR long_acting_opioid_drug_flag NOT LIKE 'N'
GROUP BY specialty, opioid_drug_flag
ORDER BY claim_count DESC

--c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT 	
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
HAVING SUM(prescription.total_claim_count) IS NULL
ORDER BY prescriber.specialty_description;

--d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	
	SUM(total_claim_count) AS total_claims,
	
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
--order by specialty_description;
order by opioid_percentage desc

-- first CTE for total opioid claims
WITH claims AS 
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_claims
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	GROUP BY pr.specialty_description),
-- second CTE for total opioid claims
opioid AS
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_opioid
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag ='Y'
	GROUP BY pr.specialty_description)
--main query
SELECT
	claims.specialty_description,
	COALESCE(ROUND((opioid.total_opioid / claims.total_claims * 100),2),0) AS perc_opioid
FROM claims
LEFT JOIN opioid
USING(specialty_description)
ORDER BY perc_opioid DESC;

--3. 

--a. Which drug (generic_name) had the highest total drug cost?

--The drug Perfenidone had the highest total drug cost at 2,829,147.30
--OR
--The drug Insulin Glargine has the highest total cost at $104,264,066.35

SELECT prescription.drug_name, generic_name, total_drug_cost
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
ORDER BY total_drug_cost DESC

SELECT drug.generic_name, SUM(prescription.total_drug_cost) AS total_drug_cost
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY total_drug_cost DESC

--b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

--C1 Esterase Inhibitor had the highest total cost per day.

SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply), 2) AS total_cost_per_day
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY total_cost_per_day DESC;

--4. 

--a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' 
	END AS drug_type
FROM drug;

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

--More money was spent on opioids than were spent on antibiotics.

SELECT SUM(total_drug_cost)::MONEY AS total_drug_cost,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' 
	END AS drug_type
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY total_drug_cost DESC;


--5. 

--a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

--There are 42 CBSA's in Tennessee.

SELECT COUNT(*)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN'

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

--Largest: Nashville-Davidson_Murfreesboro_Franklin, TN: 1830410
--Smallest: Morristown, TN: 116352

SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
INNER JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC;

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

--The largest county not included in a CBSA is Sevier at 95,523

SELECT 
	population, county 
FROM population
LEFT JOIN fips_county
USING (fipscounty)
LEFT JOIN cbsa
USING (fipscounty)
WHERE cbsa.fipscounty IS NULL
ORDER BY population DESC;

--6. 

--a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
	drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	drug_name, total_claim_count, opioid_drug_flag
FROM prescription
LEFT JOIN drug 
USING (drug_name)
WHERE total_claim_count >= 3000

--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	drug_name, total_claim_count, opioid_drug_flag,
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name
FROM prescription 
LEFT JOIN drug 
USING (drug_name)
LEFT JOIN prescriber 
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000

SELECT drug_name, total_claim_count, CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS prescriber_name,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--7. 

--The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--a. First, create a list of ***all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT
	prescriber.npi, drug.drug_name
FROM prescriber 
CROSS JOIN drug 
WHERE prescriber.specialty_description iLike 'Pain Management'
	AND prescriber.nppes_provider_city iLike 'Nashville'
	AND drug.opioid_drug_flag = 'Y';
	

--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT
	prescriber.npi, drug.drug_name, SUM(prescription.total_claim_count) AS total_claim_count
FROM prescriber
CROSS JOIN drug 
LEFT JOIN prescription 
ON drug.drug_name = prescription.drug_name
WHERE prescriber.specialty_description iLike 'Pain Management'
	AND prescriber.nppes_provider_city iLike 'Nashville'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name
ORDER BY total_claim_count DESC

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name,
 COALESCE(prescription.total_claim_count,0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y';