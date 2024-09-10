--SQL Data fro Tableau Preparation--

--SQL have no linked with Tableau which can't import directly
--Therefore used Excel Sheet to develop Tableau Visulaization
--Excel sheet Prepartion for Query Below
--CTRL + SHIFT + C Copy to include the column name


--1.Global DeathPercentage Overall (2020-2024)

SELECT  SUM(new_cases) AS Total_case, SUM(CAST(new_deaths as int)) AS Total_death, SUM(CAST(new_deaths as int)) / NULLIF(SUM(new_cases),0) * 100 AS COVID_DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

--2. Yearly Global Death Percentage

WITH YrClassify (date, Yeardate, new_case, new_death)
AS
(
SELECT date, DATEPART(YEAR, date) AS Yeardate, SUM(new_cases) AS new_case, SUM(CAST(new_deaths as int)) AS new_death
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY date
--ORDER BY 1,2
)

SELECT date, Yeardate, new_case, SUM(CONVERT(DECIMAL(20,1),new_case)) OVER (Partition by Yeardate ORDER BY Yeardate, date) AS cases, new_death,
SUM(CONVERT(DECIMAL(20,1),new_death)) OVER (Partition by Yeardate ORDER BY Yeardate, date) AS deaths
FROM YrClassify
WHERE new_case is not NULL AND new_case != 0
AND new_death is not NULL AND new_death != 0
--ORDER By 1


--3. Classify by country upon Infected_Precentage_of_Population

SELECT location, population, MAX(total_cases) as higestinfectedcount, MAX(NULLIF(total_cases,0)/population)*100 AS Infected_percentofPopulation
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Infected_percentofPopulation DESC

--4.Total Death_Count by country

SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is NULL
--Where is NULL 
--(Classify by country part like Asia, Europe, North America)
GROUP BY location
ORDER BY TotalDeathCount DESC

--5. Infected Percentage Upon date

SELECT location, population, date, MAX(total_cases) as higestinfectedcount, MAX(NULLIF(total_cases,0)/population)*100 AS Infected_percentofPopulation
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population, date
ORDER BY Infected_percentofPopulation DESC