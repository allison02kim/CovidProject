SELECT * 
FROM CovidProject..CovidVaccinations
WHERE continent <> ''


-- Select data we will use

SELECT 
	Location, date, total_cases, new_cases, total_deaths,
population
FROM CovidProject..CovidDeaths
WHERE continent <> ''
ORDER BY 1, CONVERT(DATE, date, 101)


--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract in your country
SELECT 
	Location, date, total_cases, total_deaths, 
	CASE
		WHEN total_cases>0 THEN(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 
		ELSE NULL
	END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
ORDER BY 1, CONVERT(DATE, date, 101)


--Looking at Total Cases vs Population
--Shows what percentage of the population got covid
SELECT 
	Location, date, total_cases, population, 
	CASE
		WHEN total_cases>0 THEN(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 
		ELSE NULL
	END AS ContractedPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
ORDER BY 1, CONVERT(DATE, date, 101)


--Looking at countries with highest infection rate compared to population
SELECT 
	Location, population, 
	MAX(CAST(total_cases AS FLOAT)) AS HigestInfectionCount, 
	(MAX(CAST(total_cases AS FLOAT))/(CAST(population AS FLOAT)))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


--Showing countries with highest death count per population
SELECT 
	Location, 
	MAX(CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population
ORDER BY TotalDeathCount desc


--Showing continents with highest death count per population
SELECT 
	continent, 
	MAX(CAST(total_deaths AS FLOAT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount desc


--GLOBAL NUMBERS

SELECT 
	 CONVERT(DATE, date, 101) as date, SUM(CAST(new_cases AS FLOAT)) AS total_new_cases, SUM(CAST(new_deaths AS FLOAT)) AS total_new_deaths,
	CASE
		WHEN SUM(CAST(new_cases AS FLOAT))>0 THEN (SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)))*100 
		ELSE NULL
	END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY date
HAVING (SUM(CAST(new_cases AS FLOAT)) > 0) 
ORDER BY date, total_new_cases

SELECT 
	SUM(CAST(new_cases AS FLOAT)) AS total_new_cases, SUM(CAST(new_deaths AS FLOAT)) AS total_new_deaths,
	CASE
		WHEN SUM(CAST(new_cases AS FLOAT))>0 THEN (SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)))*100 
		ELSE NULL
	END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
--GROUP BY date
ORDER BY 1, 2


--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 101) as date, population, CAST(vac.new_vaccinations AS FLOAT) as new_vacc,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.location order by CONVERT(DATE, dea.date, 101)) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''
order by 2, 3


SELECT 
	 dea.location, CONVERT(DATE, dea.date, 101) as date,  CAST(vac.total_vaccinations AS FLOAT) as new_vacc, CAST(dea.new_cases AS FLOAT) as new_cases
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''
order by 1, 2

--cte
With PopvsVac (Continent, Location, Date, Population, new_vacc, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 101) as date, population, CAST(vac.new_vaccinations AS FLOAT) as new_vacc,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.location order by CONVERT(DATE, dea.date, 101)) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--temp table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
new_vacc numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS FLOAT) as new_vacc,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.location order by CONVERT(DATE, dea.date, 101)) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating views to store for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS FLOAT) as new_vacc,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.location order by CONVERT(DATE, dea.date, 101)) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''

Create View DeathPercentageByCountry as
SELECT 
	Location, date, total_cases, total_deaths, 
	CASE
		WHEN total_cases>0 THEN(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 
		ELSE NULL
	END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
--ORDER BY 1, CONVERT(DATE, date, 101)


Create View HighestInfectionRate as
SELECT 
	Location, population, 
	MAX(CAST(total_cases AS FLOAT)) AS HigestInfectionCount, 
	(MAX(CAST(total_cases AS FLOAT))/(CAST(population AS FLOAT)))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


Create View GloabalDeathPercentage as
SELECT 
	 CONVERT(DATE, date, 101) as date, SUM(CAST(new_cases AS FLOAT)) AS total_new_cases, SUM(CAST(new_deaths AS FLOAT)) AS total_new_deaths,
	CASE
		WHEN SUM(CAST(new_cases AS FLOAT))>0 THEN (SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)))*100 
		ELSE NULL
	END AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ''
GROUP BY date
HAVING (SUM(CAST(new_cases AS FLOAT)) > 0) 



Create View PeopleVaccByCountry as
SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 101) as date, population, CAST(vac.new_vaccinations AS FLOAT) as new_vacc,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.location order by CONVERT(DATE, dea.date, 101)) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''



Create View VaccvsCases as
SELECT 
	 dea.location, CONVERT(DATE, dea.date, 101) as date,  CAST(vac.total_vaccinations AS FLOAT) as new_vacc, CAST(dea.new_cases AS FLOAT) as new_cases
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	on dea.location =vac.location
	and dea.date=vac.date
WHERE dea.continent <> ''