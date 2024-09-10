--2020 - 2024 COVID 19 VACCINATED DASHBOARD

--1. Global Awareness on Vaccinations
-- SUM of all countries and nations & MAX numbers of ppl_vaccinated



--USE CTE

WITH Glob (location, Total_vaccinatedppl, Total_Fullyvaccinatedppl, Total_population, vaccinated_percentofPopulation)
AS 
(
SELECT vac.location, MAX(CONVERT(decimal(20,1), vac.people_vaccinated)) AS Total_vaccinatedppl, MAX(CONVERT(decimal(20,1), vac.people_fully_vaccinated)) AS Total_Fullyvaccinatedppl,
MAX(CONVERT(decimal(20,1), dea.population)) AS Total_population,
MAX(CONVERT(decimal(20,1), vac.people_fully_vaccinated)/dea.population)*100 AS vaccinated_percentofPopulation
FROM PortfolioProjects..CovidVaccinations vac
JOIN PortfolioProjects..CovidDeaths dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE vac.continent is NULL
AND vac.location NOT LIKE '%countries%' 
AND vac.location NOT LIKE '%world%' 
AND vac.location NOT LIKE '%union%' 
GROUP BY vac.location
)

SELECT SUM(Total_vaccinatedppl) AS Total_VaccinatedPPL, SUM(Total_Fullyvaccinatedppl) AS Total_FullyvaccinatedPPL, SUM(Total_population) AS Total_Population,
SUM(Total_vaccinatedppl)/SUM(Total_population) *100 AS Vaccianted_Percentage
FROM Glob

--2. Country Part Vaccinated Percentage

SELECT vac.location, MAX(CONVERT(decimal(20,1), vac.people_vaccinated)) AS Total_vaccinatedppl, MAX(CONVERT(decimal(20,1), vac.people_fully_vaccinated)) AS Total_Fullyvaccinatedppl,
MAX(CONVERT(decimal(20,1), dea.population)) AS Total_population,
MAX(CONVERT(decimal(20,1), vac.people_fully_vaccinated)/dea.population)*100 AS vaccinated_percentofPopulation
FROM PortfolioProjects..CovidVaccinations vac
JOIN PortfolioProjects..CovidDeaths dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE vac.continent is NULL
AND vac.location NOT LIKE '%countries%' 
AND vac.location NOT LIKE '%world%' 
AND vac.location NOT LIKE '%union%' 
GROUP BY vac.location

--3. Vaccinated amount and percentage of  country detail

SELECT vac.location, MAX(CONVERT(decimal(20,1), dea.population)) AS Population, MAX(CONVERT(decimal(20,1), vac.total_vaccinations)) AS Total_Vaccnations, 
MAX(CONVERT(decimal(20,1), vac.people_vaccinated)) AS PPL_Vaccinated, MAX(CONVERT(decimal(20,1), vac.people_fully_vaccinated)) AS PPL_FullyVaccinated, 
MAX(vac.people_fully_vaccinated/dea.population)*100  AS Vaccianted_Percent
FROM PortfolioProjects..CovidVaccinations vac
JOIN PortfolioProjects..CovidDeaths dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE vac.continent is not NULL
GROUP BY vac.location
ORDER BY Vaccianted_Percent DESC

--4. RollingVaccinated PPL 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(DECIMAL(20,1), vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
AND vac.location like '%state%'
--ORDER BY 2,3
)
SELECT *, RollingPeopleVaccinated/ population * 100
FROM PopvsVac

--Create temp table to remove Null to zero


DROP TABLE IF EXISTS #RollVaccinatedPPL
CREATE TABLE #RollVaccinatedPPL
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #RollVaccinatedPPL
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(DECIMAL(20,1), vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL

--AND vac.location like '%state%'
--ORDER BY 2,3

SELECT *, CONVERT(decimal(20,2), RollingPeopleVaccinated/ population * 100)  AS Vaccinated_Percentage
FROM #RollVaccinatedPPL

--Update NUll to zero

UPDATE #RollVaccinatedPPL
SET  new_vaccinations = ISNULL(new_vaccinations, 0)

UPDATE #RollVaccinatedPPL
SET  RollingPeopleVaccinated = ISNULL(RollingPeopleVaccinated, 0)

UPDATE #RollVaccinatedPPL
SET  Vaccinated = ISNULL(new_vaccinations, 0)


--5. Yearly Vaccinated

--USE CTE

WITH Glob_max (Yeardate, Total_Vac, Vac_fullPPL, Pop)
AS
(
SELECT DATEPART(YEAR, vac.date) AS Yeardate, vac.total_vaccinations AS Total_Vac, vac.people_fully_vaccinated AS Vac_fullPPL, dea.population AS Pop
FROM PortfolioProjects..CovidVaccinations vac
JOIN PortfolioProjects..CovidDeaths dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE vac.continent is NULL
AND vac.location LIKE '%World%'
)
SELECT Yeardate, MAX(Total_Vac) OVER (Partition by Yeardate Order by Yeardate) AS Total_Vaccinations,
MAX(Vac_fullPPL) OVER (Partition by Yeardate Order by Yeardate) AS Fully_VaccinatedPPL, 
MAX(Vac_fullPPL/Pop*100) OVER (Partition by Yeardate Order by Yeardate) AS Vaccinated_Percent
FROM Glob_max
--ORDER BY 1,2