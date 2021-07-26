/****** Object:  Table [dbo].[Geo_Cities]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_Cities]
(
    [CityID] [int] NOT NULL,
    [CityName] [nvarchar](50) NOT NULL,
    [StateProvinceID] [int] NOT NULL,
    [Location] [geography] NULL,
    [LatestRecordedPopulation] [bigint] NULL,
    [LastEditedBy] [int] NOT NULL,
    [ValidFrom] [datetime2](7) NOT NULL,
    [ValidTo] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[geo_cities1]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[geo_cities1]
as
    (select CityID as City_ID,
        CityName as City,
        StateProvinceID as Province,
        Location as Loc

    from dbo.Geo_Cities)



GO
/****** Object:  Table [dbo].[Geo_HurricaneCustomerDetails]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_HurricaneCustomerDetails]
(
    [CustomerId] [float] NULL,
    [FirstName] [nvarchar](255) NULL,
    [LastName] [nvarchar](255) NULL,
    [Gender] [nvarchar](255) NULL,
    [EmailId] [nvarchar](255) NULL,
    [ContactNo] [nvarchar](255) NULL,
    [BankName] [nvarchar](255) NULL,
    [LoanNo] [float] NULL,
    [LoanAmount] [float] NULL,
    [PayableAmount] [float] NULL,
    [InterestRate] [float] NULL,
    [TenureInYear] [float] NULL,
    [EMI] [float] NULL,
    [TotalEMI] [float] NULL,
    [EMIPaid] [float] NULL,
    [EMIRemaining] [float] NULL,
    [LoanStatus] [nvarchar](255) NULL,
    [CityID] [float] NULL,
    [HurricaneId] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Geo_HurricaneDetailsFlorida]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_HurricaneDetailsFlorida]
(
    [Id] [float] NULL,
    [Storm] [nvarchar](255) NULL,
    [SaffirSimpsonCategory] [float] NULL,
    [Date] [float] NULL,
    [Month] [float] NULL,
    [Year] [float] NULL,
    [LandfallIntensityInKnots] [float] NULL,
    [LandfallLocation] [nvarchar](255) NULL,
    [CityID] [int] NULL,
    [Location] [geography] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[RiskAreas]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[RiskAreas]
as
    (

    select
        max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory,
        h.CityId as CityId,
        h.LandFallLocation as CityName,
        h.[Location].Lat AS [Latitude],
        h.[Location].Long AS [Longitude],
        WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end)
        FROM [Geo_HurricaneCustomerDetails] c
        where c.CityID = h.CityId)
    from [Geo_HurricaneDetailsFlorida] h
    where h.Location IS NOT NULL
    group by h.CityID, h.LandFallLocation, h.[Location].Lat, h.[Location].Long

);

GO
/****** Object:  Table [dbo].[Geo_StateProvinces]    Script Date: 18-06-2021 18:10:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Geo_StateProvinces]
(
    [StateProvinceID] [int] NOT NULL,
    [StateProvinceCode] [nvarchar](5) NOT NULL,
    [StateProvinceName] [nvarchar](50) NOT NULL,
    [CountryID] [int] NOT NULL,
    [SalesTerritory] [nvarchar](50) NOT NULL,
    [Border] [geography] NULL,
    [LatestRecordedPopulation] [bigint] NULL,
    [LastEditedBy] [int] NOT NULL,
    [ValidFrom] [datetime2](7) NOT NULL,
    [ValidTo] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  StoredProcedure [dbo].[GetHurricaneDataFlorida]    Script Date: 26-07-2021 12:37:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Click2Cloud Team
-- Create Date: 16/06/2021
-- Description: Get Geojson data for Hurricane in Florida region
-- EXEC [dbo].[GetHurricaneDataFlorida]
-- =============================================
CREATE PROCEDURE [dbo].[GetHurricaneDataFlorida]
AS
BEGIN
	DECLARE @featureList nvarchar(max) =
	(
		SELECT * FROM
		(
			SELECT
				ROW_NUMBER() OVER (
					PARTITION BY T1.[CityID]
					ORDER BY T1.[SaffirSimpsonCategory] DESC
				) AS row_no,
				'Feature'									AS 'type',
				CAST(T1.[Id] AS VARCHAR)					AS 'properties.Id',
				T1.[Storm]									AS 'properties.Storm',
				CAST(T1.[SaffirSimpsonCategory] AS INT)		AS 'properties.SaffirSimpsonCategory',
				CAST(T1.[Date] AS INT)						AS 'properties.Date',
				CAST(T1.[Month] AS INT)						AS 'properties.Month',
				CAST(T1.[Year] AS INT)						AS 'properties.Year',
				CAST(T1.[LandfallIntensityInKnots] AS INT)	AS 'properties.LandfallIntensityInKnots',
				T1.[LandfallLocation]						AS 'properties.LandfallLocation',
				T1.[CityID]									AS 'properties.CityID',
				T2.[CustomerCount]							AS 'properties.CustomerCount',
				T1.[Location].STGeometryType()				AS 'geometry.type',
				JSON_QUERY('[' + CAST([Location].Long AS VARCHAR) + ', ' + CAST([Location].Lat AS VARCHAR) + ']') AS 'geometry.coordinates'
			FROM [dbo].[Geo_HurricaneDetailsFlorida] T1
			INNER JOIN
			(
				SELECT 
					COUNT(1) AS CustomerCount,
					CityID
				FROM [dbo].[Geo_HurricaneCustomerDetails]
				WHERE ([LoanStatus] = 'Defaulting' or [LoanStatus] = 'Ongoing') AND [BankName] = 'Woodgrove'
				GROUP BY CityID
			) T2
			ON T1.CityID = T2.CityID
		) DataResult
		WHERE DataResult.row_no = 1
		ORDER BY [properties.SaffirSimpsonCategory] DESC
		FOR JSON PATH
	);

	DECLARE @featureCollection nvarchar(max) = (
		SELECT 'FeatureCollection' AS 'type',
		JSON_QUERY(@featureList)   AS 'features'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	);

	SELECT @featureCollection AS data;

END;


/****** Object:  StoredProcedure [dbo].[GetGeospatialHurricaneDataFlorida]    Script Date: 26-07-2021 14:15:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Click2Cloud Team
-- Create Date: 16/06/2021
-- Description: Get Geojson data for Hurricane in Florida region
-- EXEC [dbo].[GetGeospatialHurricaneDataFlorida]
-- =============================================
ALTER PROCEDURE [dbo].[GetGeospatialHurricaneDataFlorida]
AS
BEGIN
	-- declare variables of type table for high risk, medium risk and low risk areas
	DECLARE @LowRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  
	DECLARE @MediumRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  
	DECLARE @HighRiskAreas TABLE (SaffirSimpsonCategory int, CityId int, CityName varchar(50), CityLocation geometry, WoodGroveCustomerCount int )  

	-- insert into temporary table named LowRiskAreas where SaffirSimpsonCategory is less than 3
	INSERT INTO @LowRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) < 3

	-- insert into temporary table named MediumRiskAreas where SaffirSimpsonCategory is less than 5 and greater than equal to 3
	INSERT INTO @MediumRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) < 5 and max(h.SaffirSimpsonCategory) >= 3

	-- insert into temporary table named HighRiskAreas where SaffirSimpsonCategory is greater than equal to 5 
	INSERT INTO @HighRiskAreas
	select 
		max(h.SaffirSimpsonCategory) as MaxSaffirSimpsonCategory, 
		h.CityId as CityId, 
		h.LandFallLocation as CityName, 
		GEOMETRY::STGeomFromText(h.Location.STAsText(), 4326) as CityLocation,
		WoodGroveCustomerCount = (SELECT sum(case when c.BankName = 'Woodgrove' and (c.LoanStatus = 'Defaulting' or c.LoanStatus = 'Ongoing') then 1 else 0 end) FROM [Geo_HurricaneCustomerDetails] c where c.CityID = h.CityId)
	from [Geo_HurricaneDetailsFlorida] h
	where h.Location IS NOT NULL
	group by h.CityID, h.LandFallLocation, h.Location.STAsText()
	having max(h.SaffirSimpsonCategory) >=5


	-- plot state boundary
	select GEOMETRY::STGeomFromText(sp.Border.ToString(),4326) as Location, '' as city_name, '' as woodgrove_customer_count from dbo.Geo_StateProvinces sp
	-- for florida
	where sp.StateProvinceCode = 'FL'

	-- high risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326).STBuffer(0.30) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @HighRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

	-- medium risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326).STBuffer(0.10) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @MediumRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

	-- low risk areas
	union all
	SELECT 
		GEOMETRY::STGeomFromText(c.Location.ToString(),4326) as Location, 
		m.CityName as city_name,
		m.WoodGroveCustomerCount as woodgrove_customer_count 
	FROM @LowRiskAreas m
	inner join dbo.Geo_Cities c
	on m.CityLocation.STIntersects(GEOMETRY::STGeomFromText(c.Location.ToString(),4326)) = 1
	where c.StateProvinceID = 10

END;
