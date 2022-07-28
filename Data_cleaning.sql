/*

Cleaning Data in SQL Queries

*/

Select *
From Portfolio.dbo.nashville_housing

-- Standardize Date Format

Select SaleDate, convert(Date, SaleDate)
From Portfolio.dbo.nashville_housing

-- Update should have worked but didn't so tried alter table
-- Update dbo.nashville_housing
-- Set SaleDateConverted = convert(Date, SaleDate)

-- Alter table did not work for some reason then worked again after trying diff things so not sure 
-- Use Portfolio
-- Go
alter table dbo.nashville_housing
Add SaleDateConverted Date;

Update nashville_housing
Set SaleDateConverted = convert(Date, SaleDate)

-- New column created for the updated date
Select SaleDateConverted, convert(Date, SaleDate)
From Portfolio.dbo.nashville_housing

-----------------------------------------------------------------------------------

--Populate Property Address data

-- See if the Property Address is null 
Select PropertyAddress
From Portfolio.dbo.nashville_housing
where PropertyAddress is null

-- See all the entries where the Property Address is null
Select *
From Portfolio.dbo.nashville_housing
-- where PropertyAddress is null
order by ParcelID

-- The ParcelID is same for one address so we will 'self join' the table to check and match the Property address with the 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From Portfolio.dbo.nashville_housing a 
JOIN Portfolio.dbo.nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
where a.PropertyAddress is null

-- Now we have an extra column which we will use to populate the 1st table 'a'
Update a 
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From Portfolio.dbo.nashville_housing a 
JOIN Portfolio.dbo.nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
where a.PropertyAddress is null

------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- 1. Using SUBSTRING and
-- 2. Using PARSENAME

-- 1. Using SUBSTRING
-------------------------------------------------------------------------------------------------
Select PropertyAddress
From Portfolio.dbo.nashville_housing

-- Getting only the Address that is before the ','

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address -- starts at 1 and goes till ','
-- CHARINDEX(',',PropertyAddress) -- CHARINDEX is not a string but a number so -1 removes the ',' from the table
From Portfolio.dbo.nashville_housing

-- Getting the city name that is after the ','
Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress), LEN(PropertyAddress)) as City -- strats at ',' and goes till the end i.e. length of the propertyaddress
From Portfolio.dbo.nashville_housing

-- Getting the city name that is after the ','
Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City -- strats at one step after ',' and goes till the end i.e. length of the propertyaddress
From Portfolio.dbo.nashville_housing

ALTER table dbo.nashville_housing
ADD PropertySplitAddress Nvarchar(255);

Update dbo.nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) 

ALTER table dbo.nashville_housing
ADD PropertySplitCity Nvarchar(255);

Update dbo.nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

Select *
From Portfolio.dbo.nashville_housing

-- 2. Using PARSENAME
-------------------------------------------------------------------------------------------------

Select OwnerAddress
From Portfolio.dbo.nashville_housing


Select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3) -- Also it does things backwards
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)-- Parsename works with periods '.' so we need to replace them with comma ','
From Portfolio.dbo.nashville_housing 

ALTER table dbo.nashville_housing
ADD OwnerSplitAddress Nvarchar(255);

Update dbo.nashville_housing
SET OwnerSplitAddress =PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER table dbo.nashville_housing
ADD OwnerSplitCity Nvarchar(255);

Update dbo.nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER table dbo.nashville_housing
ADD OwnerSplitState Nvarchar(255);

Update dbo.nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

Select *
From Portfolio.dbo.nashville_housing

-------------------------------------------------------------------------------------------------
 
 -- Change Y and N to Yes and No in 'Sold as Vacant' field
 
 Select Distinct(SoldAsVacant), count(SoldAsVacant)
 From Portfolio.dbo.nashville_housing
 group by SoldAsVacant
 order by 2

 -- Change 
 Select SoldAsVacant
 , CASE when SoldAsVacant='Y' Then 'Yes'
		when SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
		END
 From Portfolio.dbo.nashville_housing

 -- Update
 Update nashville_housing
 SET SoldAsVacant = CASE when SoldAsVacant='Y' Then 'Yes'
		when SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
		END

-------------------------------------------------------------------------------------------------

--Remove Duplicates: Data from database are usually not deleted
-- Need a way to identify duplicte rows: Rank, Order Rank, Row number

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, -- we need to partition by something that is same 
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				Order by 
					UniqueID
					) row_num
From Portfolio.dbo.nashville_housing
-- order by ParcelID
)
Select *
From RowNumCTE -- CTE, this query is querying off the table above that we created like a Temp Table
Where row_num > 1 -- These are all duplicates
Order by PropertyAddress

-- Now we delete them

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, -- we need to partition by something that is same 
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				Order by 
					UniqueID
					) row_num
From Portfolio.dbo.nashville_housing
-- order by ParcelID
)
DELETE
From RowNumCTE -- CTE, this query is querying off the table above that we created like a Temp Table
Where row_num > 1 -- These are all duplicates


sELECT *
From Portfolio.dbo.nashville_housing

-------------------------------------------------------------------------------------------------

-- Delete unused columns: is not done to raw data

sELECT *
From Portfolio.dbo.nashville_housing

Alter table Portfolio.dbo.nashville_housing
Drop column OwnerAddress, TaxDistrict, PropertyAddress

Alter table Portfolio.dbo.nashville_housing
Drop column SaleDate
