--Overview of the Dataset
SELECT location,date, total_cases, new_cases, total_deaths,population
FROM PorfolioProject..CovidDeath$
Order by 1,2

--Total Cases VS Total Deaths
SELECT location, date, total_cases, total_deaths, 
    CASE 
        WHEN TRY_CONVERT(float, total_cases) = 0 THEN NULL
        ELSE (total_deaths / TRY_CONVERT(float, total_cases)) * 100 
    END as DeathPercentage
FROM PorfolioProject..CovidDeath$
Where location like '%China%'
ORDER BY 1, 2;

--Total Cases vs Population
SELECT location, date, population, total_cases,
    CASE 
        WHEN TRY_CONVERT(float, total_cases) = 0 THEN NULL
        ELSE (TRY_CONVERT(float, total_cases)/population) * 100 
    END as CasePercentage
FROM PorfolioProject..CovidDeath$
ORDER BY 1, 2;

--Courtries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentPopulationInfected
FROM PorfolioProject..CovidDeath$
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC ;

--Courtries with highest death rate compared to population
SELECT location, population, MAX(cast(total_deaths as int)) AS HighestdeathCount, (MAX(cast(total_deaths as int))/population)*100 as PercentPopulationDeath
FROM PorfolioProject..CovidDeath$
Where continent is not null
GROUP BY location,population
ORDER BY PercentPopulationDeath DESC ;

--Total population VS vaccinations
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.Date, dea.location) as AccumulatedVaccination
FROM PorfolioProject..CovidVaccin$ vac
JOIN PorfolioProject..CovidDeath$  dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--CTE- Accumulate Vaccination Rate
With PopvsVac (Continent, Location, Date, Population, New_vaccinations, AccumulatedVaccination)
AS (
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.Date, dea.location) as AccumulatedVaccination
FROM PorfolioProject..CovidVaccin$ vac
JOIN PorfolioProject..CovidDeath$  dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (AccumulatedVaccination/Population)*100 As AccuVaccRate
FROM PopvsVac
ORDER BY 1,2;

--Temp Table
DROP TABLE IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(225),
Location nvarchar(225),
Date datetime, 
Population numeric,
New_vaccinations numeric, 
AccumulatedVaccination numeric)

Insert into #PercentPopulationVaccinated
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.Date, dea.location) as AccumulatedVaccination
FROM PorfolioProject..CovidVaccin$ vac
JOIN PorfolioProject..CovidDeath$  dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (AccumulatedVaccination/Population)*100 As AccuVaccRate
FROM #PercentPopulationVaccinated
ORDER BY 1,2;


--Create View to store data for visualisation
Create View PercentPopulationVaccinate as
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.Date, dea.location) as AccumulatedVaccination
FROM PorfolioProject..CovidVaccin$ vac
JOIN PorfolioProject..CovidDeath$  dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL