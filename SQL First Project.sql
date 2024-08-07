SELECT *
FROM CovidDeaths
order by 3, 4

--Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1, 2

--Looking at Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location like '%lithuania%'
order by 1, 2

alter table CovidDeaths alter column total_cases DECIMAL(18, 2);
alter table CovidDeaths alter column total_deaths DECIMAL(9, 2);

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from CovidDeaths
where location like '%states%'
order by 1, 2

--Looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from CovidDeaths
--where location like '%states%'
group by location, population
order by PercentPopulationInfected desc

--Showing the countries with highest death count per population
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
--where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc

--Let's break things down by continent
--Showing continents with the highest death count per population
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
--where location like '%states%'
where continent is null
group by location
order by TotalDeathCount desc

alter table CovidDeaths alter column new_deaths DECIMAL(18, 2);

--GLOBAL NUMBERS
select date, SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as DECIMAL(18, 2)))/SUM(cast(new_cases as int))*100 as DeathPercentage
from CovidDeaths
--where location like '%states%'
where continent is not null
group by date
order by 1, 2

select SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as DECIMAL(18, 2)))/SUM(cast(new_cases as int))*100 as DeathPercentage
from CovidDeaths
--where location like '%states%'
where continent is not null
--group by date
order by 1, 2

--Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 2, 3

--USE CTE
with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	--order by 2, 3
)
select *, (convert(decimal(15,2), RollingPeopleVaccinated)/population)*100
from PopVsVac

--TEMP TABLE
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	--order by 2, 3

select *, (convert(decimal(15,2), RollingPeopleVaccinated)/population)*100
from #PercentPopulationVaccinated

--Create view to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null

select *
from PercentPopulationVaccinated