-- Database Project 5: Database Implementation 

--Q0 name of the database on the class server
-- Name: groceryStoreAnalysis_db
USE groceryStoreAnalysis_db



-- Q1  a list of CREATE TABLE statements 

CREATE TABLE ProductType 
(
    productTypeID INT PRIMARY KEY,
    Category NVARCHAR(50)
)


CREATE TABLE Brand (
    brand_name NVARCHAR(50) PRIMARY KEY,
    yearEstablished INT,
    parentcompany NVARCHAR(50),
    CountryOfOrigin NVARCHAR(50)
);


Create Table Certifications
(
    certification_id INT,
    certificationType NVARCHAR(30),
    certificationName NVARCHAR(100),
    PRIMARY KEY (certification_id)
);


Create Table groceryStore
(
    StoreName NVARCHAR(80),
    Location NVARCHAR(30),
    address NVARCHAR(100),
    HoursofOperation NVARCHAR(80)
    PRIMARY KEY (StoreName,Location)
)

CREATE TABLE Product (
    productid INT PRIMARY KEY,          
    name NVARCHAR(50) NOT NULL,        
    carbs FLOAT,                       
    protein FLOAT,                     
    sodium FLOAT,                     
    totalfat FLOAT,                   
    servingsize INT,                  
    calories INT,                               
    brand NVARCHAR(50),                
    categoryid INT, 
    Price FLOAT,                 
    FOREIGN KEY (brand) REFERENCES Brand(brand_name),
    FOREIGN KEY (categoryid) REFERENCES ProductType(productTypeID) 
);


CREATE TABLE Product_GroceryStores
(
    productid INT,                
    store_name NVARCHAR(80),
    store_location NVARCHAR(30),
    PRIMARY KEY (productid, store_name, store_location),
    FOREIGN KEY (productid) REFERENCES Product(productid), 
    FOREIGN KEY (store_name, store_location) REFERENCES GroceryStore(storeName, Location) 
)


CREATE TABLE ProductCertification
(
    ProductID INT,       
    CertificationID INT,
    PRIMARY KEY (ProductID, CertificationID),
    FOREIGN KEY (ProductID) REFERENCES Product(productid), 
    FOREIGN KEY (CertificationID) REFERENCES Certifications(certification_id) 
);



-- Q2: a list of 10 SQL statements using your schema, along with the English question



-- Q1
-- What are the top 5 dairy products with the highest carbohydrate content in per serving? 	
-- (Select Top Question) (Consumers)

SELECT TOP 5 p.brand, p.name, p.carbs, p.servingsize
FROM Product p, producttype pt
WHERE pt.productTypeID = p.categoryid
AND pt.category = 'dairy'
ORDER BY p.carbs DESC


-- Q2
-- What Brands have a low calories/diet beverage alternative to their other "regular beverage"?

SELECT  p.brand, p.name AS 'Regular Beverage', pr.name AS 'Diet / Low Calorie Beverage'
FROM product p, product pr
WHERE p.brand = pr.brand
AND p.calories >= 100  
AND pr.calories <50
AND p.categoryid = 1 AND pr.categoryid = 1
ORDER BY
    p.name;


-- Testing Option II


-- Pepsi & Coca Cola Products alternative 
SELECT  p.name AS 'Regular Beverage',pr.name AS 'Diet Beverage'
FROM Product p, Product pr
WHERE p.brand= pr.brand
    AND  p.name NOT LIKE '%Diet%'
    AND pr.name LIKE 'Diet%'
ORDER BY
    p.name;



--Q3
 -- Rank all protein products by its protein content within the meat category and order by price? 
-- (Ranking Question, check for protein products with highest protein content and cheapest) (Consumers)

SELECT  DENSE_RANK() OVER (PARTITION BY category ORDER BY  p.price ASC, protein DESC) AS ProteinRank, p.name, p.price, p.protein as protein_content
FROM product p, ProductType pt
WHERE p.categoryid = pt.productTypeID
AND pt.category = 'meat'
ORDER BY
    ProteinRank;


-- Q4
-- What is the most expensive snack product in each grocery store?
WITH RankedSnacks AS (
    SELECT 
        pg.store_name AS GroceryStore,
        p.name AS ProductName,
        p.Price,
        RANK() OVER (PARTITION BY pg.store_name ORDER BY p.Price DESC) AS PriceRank
    FROM 
        Product p, Product_GroceryStores pg, ProductType pt
    WHERE p.productid = pg.productid
    AND p.categoryid = pt.productTypeID
    AND pt.Category = 'Snacks'
)
SELECT 
    GroceryStore, 
    ProductName, 
    Price
FROM 
    RankedSnacks
WHERE 
    PriceRank = 1
ORDER BY 
    GroceryStore;



--Q5 -- What is the average sodium content in all snacks within the two major stores QFC & Safeway? (Q5)
SELECT 
    pg.store_name AS GroceryStore,
    1.0 *AVG(p.sodium)  AS AvgSodiumContent
FROM 
    Product p, Product_GroceryStores pg, ProductType pt
WHERE p.productid = pg.productid
AND p.categoryid = pt.productTypeID
AND pt.Category = 'Snacks'
AND pg.store_name IN ('QFC', 'Safeway')
GROUP BY 
    pg.store_name
ORDER BY
    AvgSodiumContent DESC;


-- Q6 --Which certifications appear most frequently across all snack products?
SELECT
    c.certificationName AS Certification,
    COUNT(pc.CertificationID) AS Frequency
FROM 
    Product p, ProductCertification pc, Certifications c, ProductType pt 
WHERE p.productid = pc.ProductID
AND pc.CertificationID = c.certification_id
AND p.categoryid = pt.productTypeID
AND pt.Category = 'Snacks'
GROUP BY 
    c.certificationName
ORDER BY 
    Frequency DESC;


--Q7 -- What are the average totalfat & calorie content for each Frozen Food company 
SELECT 
    b.parentcompany AS Company,
    pt.Category AS ProductCategory,
    AVG(p.totalfat) AS AVGTotalFat,
    AVG(p.calories) AS AvgCalorieContent
FROM 
    Product p, Brand b, ProductType pt
WHERE p.brand = b.brand_name
AND p.categoryid = pt.productTypeID
AND  pt.category = 'Frozen Foods'
GROUP BY 
    b.parentcompany, pt.Category
ORDER BY 
    ProductCategory, AVGTotalFat DESC, AvgCalorieContent DESC



--Q8 -- Which grocery store offers the lowest average price for frozen foods? (scenario -- College Student looking for cheap frozen food)  -- Learn to Round to stop multi digits for price
WITH LowCalorieFrozen AS (
    SELECT gs.StoreName, p.price
    FROM Product p, ProductType pt, Product_GroceryStores pgs, GroceryStore gs
    WHERE p.categoryid = pt.productTypeID
    AND  p.productid = pgs.productid
    AND pgs.store_name = gs.StoreName
    AND pt.Category = 'Frozen Foods'
),
average_prices AS (
    SELECT StoreName, ROUND(AVG(price), 2) AS avg_price
    FROM LowCalorieFrozen
    GROUP BY StoreName
),
lowestStorePrice AS (
    SELECT StoreName, avg_price
    FROM average_prices
    WHERE avg_price =
     (SELECT MIN(avg_price)
      FROM average_prices)
)
SELECT *
FROM lowestStorePrice;


--Q9 
-- What are the  options for consumers looking for products with less than 100 calories, under $10 


SELECT P.name AS ProductName,  P.calories AS Calories, P.price AS Price,  C.certificationName AS Certification
FROM Product P, ProductCertification PC, Certifications C,
   (
       SELECT PC.ProductID
       FROM ProductCertification PC
       GROUP BY PC.ProductID
       HAVING COUNT(PC.CertificationID) >= 2
   ) AS FilteredProducts
WHERE P.productid = FilteredProducts.ProductID
AND P.productid = PC.ProductID
AND PC.CertificationID = C.certification_id
AND P.calories < 100
AND P.price < 10
ORDER BY P.name, C.certificationName;


-- Q10 -- "What is the cheapest snack product and what is the price of the product?"
WITH snacks as 
(
SELECT p.name, p.price
FROM Product p, ProductType pt
WHERE p.categoryid = pt.productTypeID
AND pt.category = 'Snacks'
), minprice as (
SELECT min(price) minprice FROM snacks
)
SELECT name, price
FROM snacks, minprice m
WHERE price = m.minprice


-- Q11 -- What is the cheapest & most expensive organic certified product available for consumers to purchase at a grocery store?

WITH organicProducts AS (
    SELECT p.name, p.price
    FROM Product p, ProductCertification pc,  certifications c
    WHERE p.productid = pc.ProductID
    AND pc.CertificationID = c.certification_id
    AND c.certificationName = 'Organic Certified'
),
MinMaxPrice AS (
    SELECT MIN(price) AS minPrice, Max(price) AS maxPrice
    FROM organicProducts
)
SELECT p.name, p.price
FROM organicProducts p, MinMaxPrice m
WHERE p.price = m.minprice
OR p.price = m.maxPrice;


-- Q12 What are brands that supply products in multiple different categories? (grocery management)
SELECT b.brand_name
FROM brand b, Product p, ProductType pt
WHERE b.brand_name = p.brand
AND p.categoryid = pt.productTypeID
GROUP BY b.brand_name
HAVING COUNT(DISTINCT pt.Category) > 1


-- Q3 the 3-5 demo queries 
-- (Applied in the sql statements above  + can be found in document Project Meeting Notes Google Doc)







