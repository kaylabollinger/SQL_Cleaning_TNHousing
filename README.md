# Data Cleaning in SQL: Tennessee Housing Data

This portfolio project is a practice in cleaning data using SQL. The dataset was taken from Alex the Analyst's ["Data Analyst Portfolio Project"](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx") series. While this work is my own, I am grateful for this series for being such a helpful guide.

*Notes on the data cleaning process:*

- To not alter the original data source, the cleaned data was put into a new table labeled "TNHousing_clean"--available in this repository.
- For some reason while importing the original dataset into Microsoft SQL Server SMS, rows in the dataset were duplicated many times. Only the unique rows are stored in the cleaned dataset.
- Alex the Analyst's guide for this project suggests using the attribute "ParcelID" to fill in missing/NULL values in the "PropertyAddress" column--the suggestion being that ParcelID is unique to each PropertyAddress. However, when I investigated this further I found that this was not the case (e.g., ParcelID 033 16 0 131.00 has two different addresses associated with it). This meant that there was no reliable way to find the missing addresses, and so the NULL values were not changed.
