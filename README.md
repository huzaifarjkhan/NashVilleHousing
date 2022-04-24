# NashVilleHousing_
This project required an intensive data cleaning process. The client expected the data to be such cleaned that in future any analysis could be performed on it easily and effectively. For this purpose I used my extensive data cleaning checklist.  The changes made includes: 

**The data/information are being provided by taking explicit approval from the client**


1.  Standardizing Data: Sale Date was converted from Date Time format to Date format 
        
                      UPDATE PortfolioProject..NashvilleHousing 
                      SET    SaleDate = CAST(SaleDate AS Date) 

                      SELECT
                        *
                      FROM
                        PortfolioProject..NashvilleHousing

                      -- must use 'ALTER' statement to modify the table; 'UPDATE' is used for only updating data into the table

                      ALTER TABLE PortfolioProject..NashvilleHousing
                      ALTER COLUMN SaleDate Date
--------------------------------------------------------------------------------------------------------------------------

2.  NULLS in property Address were populated with the correct input using advance Self-Joins
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

3.  Breaking Property and Owner Addresses fields into Address, City and State columns for easier analysis  

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

--------------------------------------------------------------------------------------------------------------------------

4.  Standardized 'Yes, No, Y and N' inputs in 'Sold as Vacant' column to only 'Yes' and 'No' 

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
--------------------------------------------------------------------------------------------------------------------------

5.  Removed Duplicates  

                          WITH RowNumCTE AS(
                          Select *, 
                            ROW_NUMBER() OVER (Partition By ParcelID,     --Assuming that UniqueID is not available
                                            PropertyAddress,
                                            SaleDate,
                                            LegalReference,
                                            OwnerName
                                      Order By
                                            ParcelID) AS RowNumb -- This expression starts giving row number to each row in the table 
                                            --but restarts the number if given data is not same


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

--------------------------------------------------------------------------------------------------------------------------

**At the end of this ETL and Data wrangling process the client got extremely neat and 'ready to be analyzed' or 'stored for future use' data
**
