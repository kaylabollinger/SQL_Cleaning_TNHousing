/*
Data Cleaning in SQL Project
*/

-------------------------------------------------------------------------------------------------------------------------------------
/*
Create new table to be the cleaned version of the old table (to no overwrite or lose original data).
*/

CREATE TABLE TNHousing_clean 
	(UniqueID int,
     ParcelID nvarchar(255),
     LandUse nvarchar(255),
     PropertyAddress nvarchar(255),
     SaleDate date,
     SalePrice int,
     LegalReference nvarchar(255),
     SoldAsVacant nvarchar(255), -- will update type to nchar (1) later
     OwnerName nvarchar(255),
     OwnerAddress nvarchar(255),
     Acreage float,
     TaxDistrict nvarchar(255),
     LandValue int,
     BuildingValue int,
     TotalValue int,
     YearBuilt int,
     Bedrooms int,
     FullBath int,
     HalfBath int,
	 PRIMARY KEY (UniqueID)
	);

-------------------------------------------------------------------------------------------------------------------------------------
/*
Check total number of data points in original dataset--there should only be 56477.
*/

SELECT COUNT(*)
FROM dbo.TNHousing;
-- 1048575 rows--more than expected

-------------------------------------------------------------------------------------------------------------------------------------
/*
UniqueID
- no null values
- non-negative integer values
- unique identifier for each row, total of 56477 rows desired
*/

-- check NULL or negative values
SELECT COUNT(*)
FROM dbo.TNHousing
WHERE UniqueID IS NULL OR UniqueID < 0;
-- none

-- check for duplicates 
SELECT UniqueID, COUNT(*)
FROM dbo.TNHousing
GROUP BY UniqueID
HAVING COUNT(*) > 1;
-- 56477 unique UniqueID values (as expected)
-- check that indeed each UniqueID corresponds to a unique row
SELECT UniqueID, COUNT(*)
FROM dbo.TNHousing
GROUP BY [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
HAVING COUNT(*) > 1;
-- 56477 unique rows--indeed UniqueID = unique row

-- add only unique rows to clean table
WITH CTE_dup AS(
   SELECT *,
       RN = ROW_NUMBER()OVER(PARTITION BY UniqueID ORDER BY UniqueID)
   FROM dbo.TNHousing
)
INSERT INTO dbo.TNHousing_clean
SELECT [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
FROM CTE_dup 
WHERE RN = 1;

-------------------------------------------------------------------------------------------------------------------------------------
/*
ParcelID
- check for null values
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE ParcelID IS NULL;
-- no NULL values

-------------------------------------------------------------------------------------------------------------------------------------
/*
LandUse
- check for null values
- check distinct values for any irregularities
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE LandUse IS NULL;
-- no NULL values

SELECT DISTINCT(LandUse)
FROM dbo.TNHousing_clean;
-- no irregularities

-------------------------------------------------------------------------------------------------------------------------------------
/*
PropertyAddress
- no null values
- if null values, check if can be filled using ParcelID
- split address into Street and City
*/

-- check for NULL values
SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE PropertyAddress IS NULL;
-- resulted in: 29 NULL values

-- remove extra white spaces from address
UPDATE dbo.TNHousing_clean
SET PropertyAddress = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(PropertyAddress,' ','<>'),'><',''),'<>',' ')));
--

-- check to see if two different addresses can share the same ParcelID
SELECT sub.ParcelID, sub.PropertyAddress
FROM (
	SELECT ParcelID, PropertyAddress
	FROM dbo.TNHousing_clean
	WHERE ParcelID IN (
						SELECT ParcelID
						FROM dbo.TNHousing_clean
						GROUP BY ParcelID
						HAVING COUNT(*) > 1
						)
	) as sub
	GROUP BY sub.ParcelID, sub.PropertyAddress
	HAVING COUNT(*) = 1
ORDER BY ParcelID;
-- indeed they can, e.g. ParcelID = 033 16 0 131.00
-- cannot use ParcelID to fill in NULL values for PropertyAddress

-- split address into street and city
-- check streets
SELECT LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1)
FROM dbo.TNHousing_clean;
-- check cities
SELECT DISTINCT(RIGHT(PropertyAddress,LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress)-1))
FROM dbo.TNHousing_clean;
-- no irregularities in city names; also shows that indeed original format was "[STREET], [CITY]"
-- add new columns
ALTER TABLE dbo.TNHousing_clean
ADD PropertyAddress_Street nvarchar(255), PropertyAddress_City nvarchar(255);

UPDATE dbo.TNHousing_clean
SET PropertyAddress_Street = LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1),
	PropertyAddress_City = RIGHT(PropertyAddress,LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress)-1);

-------------------------------------------------------------------------------------------------------------------------------------
/*
SaleDate
-- remove time
*/

-- test conversion
SELECT SaleDate, CONVERT(date,SaleDate)
FROM dbo.TNHousing_clean;

UPDATE dbo.TNHousing_clean
SET SaleDate = CONVERT(date,SaleDate);

-------------------------------------------------------------------------------------------------------------------------------------
/*
SalePrice
- non-negative values
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE SalePrice < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
LegalReference
-- none
*/
-------------------------------------------------------------------------------------------------------------------------------------
/*
SoldAsVacant
-- check for irregularities
*/

SELECT DISTINCT(SoldAsVacant)
FROM dbo.TNHousing_clean;
-- mix of "Y/N" and "Yes/No" convention

-- convert to "Y/N" convention
UPDATE dbo.TNHousing_clean
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Yes' THEN 'Y'
		WHEN SoldAsVacant = 'No' THEN 'N'
		ELSE SoldAsVacant
		END;

-- alter column type to indicate single character description
ALTER TABLE dbo.TNHousing_clean
ALTER COLUMN SoldAsVacant nchar(1);

-------------------------------------------------------------------------------------------------------------------------------------
/*
OwnerName
- remove extra whitespace
*/

UPDATE dbo.TNHousing_clean
SET OwnerName = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(OwnerName,' ','<>'),'><',''),'<>',' ')));

-------------------------------------------------------------------------------------------------------------------------------------
/*
OwnerAddress
- remove extra whitespace
- split into Street, City, and State
*/

UPDATE dbo.TNHousing_clean
SET OwnerAddress = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(OwnerAddress,' ','<>'),'><',''),'<>',' ')));

-- split address into street, city, and state
-- check streets
SELECT LEFT(OwnerAddress,CHARINDEX(',',OwnerAddress)-1)
FROM dbo.TNHousing_clean;
-- check cities
SELECT DISTINCT(RIGHT(OwnerAddress,LEN(OwnerAddress)-CHARINDEX(',',OwnerAddress)-1))
FROM dbo.TNHousing_clean;
-- no irregularities
-- this also includes state info--will temporarily store as "_City", then remove state

-- add new columns
ALTER TABLE dbo.TNHousing_clean
ADD OwnerAddress_Street nvarchar(255), OwnerAddress_City nvarchar(255);

UPDATE dbo.TNHousing_clean
SET OwnerAddress_Street = LEFT(OwnerAddress,CHARINDEX(',',OwnerAddress)-1),
	OwnerAddress_City = RIGHT(OwnerAddress,LEN(OwnerAddress)-CHARINDEX(',',OwnerAddress)-1);

-- fix OwnerAddress_City and add State column
-- check cities
SELECT DISTINCT(LEFT(OwnerAddress_City,CHARINDEX(',',OwnerAddress_City)-1))
FROM dbo.TNHousing_clean;
-- check states
SELECT DISTINCT(RIGHT(OwnerAddress_City,LEN(OwnerAddress_City)-CHARINDEX(',',OwnerAddress_City)-1))
FROM dbo.TNHousing_clean;

-- add new columns
ALTER TABLE dbo.TNHousing_clean
ADD OwnerAddress_State nvarchar(255);

UPDATE dbo.TNHousing_clean
SET OwnerAddress_City = LEFT(OwnerAddress_City,CHARINDEX(',',OwnerAddress_City)-1),
	OwnerAddress_State = RIGHT(OwnerAddress_City,LEN(OwnerAddress_City)-CHARINDEX(',',OwnerAddress_City)-1);

-------------------------------------------------------------------------------------------------------------------------------------
/*
Acreage
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE Acreage < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
TaxDistrict
- check for irregularities
*/

SELECT DISTINCT(TaxDistrict)
FROM dbo.TNHousing_clean;
-- no irregularities

-- remove extra whitespace (if any)
UPDATE dbo.TNHousing_clean
SET TaxDistrict = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(TaxDistrict,' ','<>'),'><',''),'<>',' ')));

-------------------------------------------------------------------------------------------------------------------------------------
/*
LandValue
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE LandValue < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
BuildingValue
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE BuildingValue < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
TotalValue
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE TotalValue < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
YearBuilt
- nonnegative
- 4 digits
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE YearBuilt < 0;
-- no negative values

SELECT DISTINCT(LEN(YearBuilt))
FROM dbo.TNHousing_clean;
-- only 4 digits

-------------------------------------------------------------------------------------------------------------------------------------
/*
Bedrooms
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE Bedrooms < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
FullBath
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE FullBath < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
HalfBath
- nonnegative
*/

SELECT COUNT(*)
FROM dbo.TNHousing_clean
WHERE HalfBath < 0;
-- no negative values

-------------------------------------------------------------------------------------------------------------------------------------
/*
Final Check
*/

SELECT *
FROM dbo.TNHousing_clean;