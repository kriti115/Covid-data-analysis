-- Using two tables which were downloaded from: https://ourworldindata.org/covid-deaths 
-- 1. covid_deaths
-- 2. covid_vaccinations

-- View data:

Select *
From Portfolio..covid_deaths
where continent is not null
Order by 3,4

Select *
From Portfolio..covid_vaccinations
Order by 3,4

-- Select the columns we want to work with

Select Location, date, total_cases, new_cases, total_deaths, population
From Portfolio..covid_deaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths: % of ppl who died
-- Shows the likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio..covid_deaths
Where Location like '%nepal%'
Order by 1,2

-- Looking at the total cases vs the population
-- Shows what % of population got covid

Select Location, date, total_cases, population, (total_cases/Population)*100 as TotalPercentage
From Portfolio..covid_deaths
Where Location like '%nepal%'
Order by 1,2

-- Looking at countries with highest infection rate compared to population

Select Location, population, MAX(total_cases) as HighestInfectionRate, MAX((total_cases/Population))*100 as TotalPercentage
From Portfolio..covid_deaths
--Where Location like '%nepal%'
Group by Location, population
Order by 4 desc

-- Looking at how many people died
-- Showing the country with he highest death count per population

Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
where continent is not null
Group by Location
Order by TotalDeathCount desc

-- Continent

-- Shows Incorrect values
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
where continent is not null
Group by continent
Order by TotalDeathCount desc

-- Better values
Select location, max(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
where continent is null
Group by location
Order by TotalDeathCount desc

-- Global numbers

Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,  sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From Portfolio..covid_deaths
where continent is not null
-- Group by date
Order by 1,2

Select *
From Portfolio..covid_vaccinations
Order by 3,4

-- Looking at total population vs vaccinations: using simple method of total_vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (total_vaccinations/population)*100 as TotalVacc
From Portfolio..covid_deaths dea
Join Portfolio..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2

-- Looking at total population vs vaccinations: using advanced method of new_vaccinations using rolling count

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVacc
From Portfolio..covid_deaths dea
Join Portfolio..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- The newly created columns cannot be directly used: 
-- 1. use CTE 
-- 2. use Temp table

-- 1. CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVacc)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVacc
From Portfolio..covid_deaths dea
Join Portfolio..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (RollingPeopleVacc/population)*100
From PopvsVac

-- TEMP table

Drop table if exists #PercentPopulationVacc -- good if changes need to be made 
Create table #PercentPopulationVacc
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVacc numeric
)
Insert into #PercentPopulationVacc
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVacc
From Portfolio..covid_deaths dea
Join Portfolio..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null
-- order by 2,3
Select *, (RollingPeopleVacc/population)*100
From #PercentPopulationVacc

-- VIEWS to store data for visualizations

Create View PercentPopulationVaccination as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVacc
From Portfolio..covid_deaths dea
Join Portfolio..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
 where dea.continent is not null
 -- order by 2,3

 Select * 
 From PercentPopulationVacc


 -- Queries for Tableau Project
  -- #1
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio..covid_deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- #2
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- #3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio..covid_deaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- #4
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio..covid_deaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc