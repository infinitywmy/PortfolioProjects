--SQL Data Cleaning on Nashville Housing Data

SELECT *
FROM PorfolioProject..[Nashville Housing$]

--1. Standize Data Format SaleDate

SELECT SaleDate, CONVERT(DATE,SaleDate)
FROM PorfolioProject..[Nashville Housing$]

ALTER TABLE [Nashville Housing$]
ADD SaleDateConverted Date;

UPDATE [Nashville Housing$]
SET SaleDateConverted = CONVERT(DATE,SaleDate)

--2.Populate Property Address Data

SELECT ParcelID,PropertyAddress
FROM PorfolioProject..[Nashville Housing$]

SELECT a.[UniqueID ],a.ParcelID,a.PropertyAddress,b.[UniqueID ],b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PorfolioProject..[Nashville Housing$] a
JOIN PorfolioProject..[Nashville Housing$] b
ON a.ParcelID=b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PorfolioProject..[Nashville Housing$] a
JOIN PorfolioProject..[Nashville Housing$] b
ON a.ParcelID=b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]

--3. Breakout Address into Individual Columns
--3.1 Break PropertyAddress using Substring

SELECT
SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM PorfolioProject..[Nashville Housing$] 

ALTER TABLE [Nashville Housing$]
ADD PropertySplitAddress Nvarchar(255);

UPDATE [Nashville Housing$]
SET PropertySplitAddress = SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE [Nashville Housing$]
ADD PropertySplitCity Nvarchar(255);

UPDATE [Nashville Housing$]
SET PropertySplitCity = SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

--3.2 Break OwnerAddress using parsename

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3), --PARESENAME Position is reverse, different from Substring position
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PorfolioProject..[Nashville Housing$] 
WHERE OwnerAddress is not null;

ALTER TABLE [Nashville Housing$]
ADD OwnerSplitAddress Nvarchar(255);

UPDATE [Nashville Housing$]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE [Nashville Housing$]
ADD OwnerSplitCity Nvarchar(255);

UPDATE [Nashville Housing$]
SET OwnerSplitCity =PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE [Nashville Housing$]
ADD OwnerSplitState Nvarchar(255);

UPDATE [Nashville Housing$]
SET OwnerSplitState =PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--4. Change Y and N to Yes and No in SoldAsVacant Column

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' Then 'Yes'
WHEN SoldAsVacant = 'N' Then 'No'
ELSE SoldAsVacant
END
FROM PorfolioProject..[Nashville Housing$]

UPDATE [Nashville Housing$]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' Then 'Yes'
WHEN SoldAsVacant = 'N' Then 'No'
ELSE SoldAsVacant
END
FROM PorfolioProject..[Nashville Housing$]

SELECT DISTINCT(SoldAsVacant)
FROM PorfolioProject..[Nashville Housing$]

--5. Remove Duplicate Data Entry BY using Window Function Row_Number

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID,PropertyAddress,SaleDate,SalePrice,LegalReference
ORDER BY UniqueID ) row_num
FROM PorfolioProject..[Nashville Housing$])

DELETE
FROM RowNumCTE
Where row_num >1;


--6. Delete Unused Columns

ALTER TABLE PorfolioProject..[Nashville Housing$]
DROP COLUMN OwnerAddress,PropertyAddress,SaleDate,TaxDistrict  -- dropping columns does not delete the data within those columns but becomes inaccessible.
