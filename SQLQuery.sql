



SELECT
	*
FROM
	PortfolioProject..NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

UPDATE PortfolioProject..NashvilleHousing 
SET    SaleDate = CAST(SaleDate AS Date) 

SELECT
	*
FROM
	PortfolioProject..NashvilleHousing

-- must use 'ALTER' statement to modify the table; 'UPDATE' is used for only updating data into the table

ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate Date

SELECT
	*
FROM
	PortfolioProject..NashvilleHousing


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
SELECT
	*
FROM
	PortfolioProject..NashvilleHousing
--WHERE
--	PropertyAddress is NULL
ORDER BY 
	ParcelID


-- PropertyAddress is NULL at many places. However, on a closer view it was noted that same ParcelID has same PropertyAddress


-- To obtain values for values for  NULLs from the same column, using Self Join
SELECT
	a.[UniqueID ], b.[UniqueID ], a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress
FROM
	PortfolioProject..NashvilleHousing a
	JOIN
	PortfolioProject..NashvilleHousing b
	ON
		a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE
	a.PropertyAddress is NULL

ORDER BY 
	a.ParcelID

-- Updating NULL data points

UPDATE a
SET 
	a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress) -- can use ISNULL() as well
FROM
	PortfolioProject..NashvilleHousing a
	JOIN
	PortfolioProject..NashvilleHousing b
	ON
		a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


-- PropertyAddress Breaking
SELECT
	PropertyAddress--, ParcelID, SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) 

FROM
	PortfolioProject..NashvilleHousing
-- Accidentally modifeied PropertyAddress table without extracting city from it
UPDATE
	PortfolioProject..NashvilleHousing
SET
	PropertyAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) 


--Reuploaded the Original dataset to extract PropertyCity from there
-- *Nulls of PropertyAddress is removed from this dataset using above method

--SEPERATING COLUMNS FOR Address and City
ALTER TABLE 
		PortfolioProject..NashvilleHousing
ADD PropertyCity varchar(255)


-- Populating PropertyCity 
UPDATE 
	a
SET 
	a.PropertyCity = SUBSTRING(b.PropertyAddress, CHARINDEX(',',b.PropertyAddress)+1, LEN(b.PropertyAddress))
FROM
	PortfolioProject..NashvilleHousing a
	JOIN 
	[PortfolioProject].[dbo].[OriginalNashvilleHousing] b
	ON 
		a.[UniqueID ] = b.[UniqueID ]

SELECT
	*
FROM
	PortfolioProject..NashvilleHousing

-- PropertyAddress Breaking
-- PARSENAME looks for '.' 'period' and breaks string into column 
SELECT
	PARSENAME(REPLACE(OwnerAddress,',','.'),3) OwnerSplitAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'),2)OwnerCity,
	PARSENAME(REPLACE(OwnerAddress,',','.'),1) OwnerState
FROM
	PortfolioProject..NashvilleHousing

-- It could have been done using SUBSTRING but would have been lengthy
ALTER TABLE
	PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), 
	OwnerCity NVARCHAR(255), 
	OwnerState NVARCHAR(255)


UPDATE
	PortfolioProject..NashvilleHousing
SET
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerCity		  = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerState		  = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

ALTER TABLE 
	PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress

SELECT
	*
FROM
	PortfolioProject..NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM
	PortfolioProject..NashvilleHousing
Group By
	SoldAsVacant
Order By 2
	
--Testing to change 'Y' and 'N' values to 'Yes' and 'No'

SELECT
	CASE
		WHEN 
			SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN
			SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant

	END AS SoldAsVacant
FROM
	PortfolioProject..NashvilleHousing


-- Updating Y and N to Yes and No

UPDATE
	PortfolioProject..NashvilleHousing
SET
	SoldAsVacant =
	(CASE
		WHEN 
			SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN
			SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END )



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (Partition By ParcelID,     --Assuming that UniqueID is not available
									PropertyAddress,
									SaleDate,
									LegalReference,
									OwnerName
						Order By
									ParcelID) AS RowNumb -- This expression starts giving row number to each row in the table but restarts the number if given data is not same


FROM
	PortfolioProject..NashvilleHousing
--WHERE
--	RowNumb > 1 -- Cant use Where in query where Window function is used such as OVER. Hence, using CTE
)
--SELECT *
--FROM
--	RowNumCTE
--Where RowNumb > 1

DELETE 
FROM
	RowNumCTE
Where RowNumb > 1

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















