
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
