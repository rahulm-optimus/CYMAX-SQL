--You need to create a stored procedure that accepts a JSON input, parses the data,
--and then inserts it into a table if the record doesn't already exist.
--If the record exists, it should update the existing record. 
--The JSON will contain a list of products, each having the following 
--properties: ProductID, ProductName, and Price.
--Table structure: You have a table named Products with the following columns:
--ProductID (INT) � Primary Key
--ProductName (VARCHAR)
--Price (DECIMAL)
--JSON Format Example:
--[
--  { "ProductID": 101, "ProductName": "Product A", "Price": 25.50 },
--  { "ProductID": 102, "ProductName": "Product B", "Price": 30.00 }
--]
 
--Task:
--Write a stored procedure named UpsertProducts that:
--Accepts a JSON array as input.
--Loops through each record in the JSON array.
--If the ProductID does not exist in the Products table, it inserts the record.
--If the ProductID exists, it updates the existing record with the new ProductName and Price.

CREATE TABLE tblProducts(
ProductID INT PRIMARY KEY,
ProductName VARCHAR(100),
Price DECIMAL(10,2),
)

INSERT INTO tblProducts (ProductID, ProductName, Price)
VALUES
(1, 'Laptop', 999.99),
(2, 'Smartphone', 499.50),
(3, 'Tablet', 299.99),
(4, 'Wireless Mouse', 29.99),
(5, 'Keyboard', 49.95);

-- Check table 
select * from tblProducts

-- Create the stored procedure
ALTER PROCEDURE spUpdateJsonData
    @jsonVar NVARCHAR(MAX) -- Corrected typo here
AS
BEGIN
    -- Check if the JSON input is valid
    IF (ISJSON(@jsonVar) = 1)
    BEGIN
        -- Declare a table variable to store parsed data from the JSON input
        DECLARE @ProductTableFromJSON TABLE (
            ProductID INT,
            ProductName VARCHAR(100),
            Price DECIMAL(10, 2)
        );

        -- Parse the JSON input and insert it into the table variable
        INSERT INTO @ProductTableFromJSON (ProductID, ProductName, Price)
         SELECT DISTINCT
            ProductID,
            ProductName,
            Price 
        FROM 
            OPENJSON(@jsonVar)
        WITH (
            ProductID INT,
            ProductName VARCHAR(255),
            Price DECIMAL(10, 2)
        );

        -- Perform the upsert operation using MERGE
        MERGE INTO tblProducts AS target
        USING @ProductTableFromJSON AS source
        ON target.ProductID = source.ProductID
        WHEN MATCHED THEN
            -- Update the existing product if ProductID matches
            UPDATE SET 
                target.ProductName = source.ProductName,
                target.Price = source.Price
        WHEN NOT MATCHED THEN
            -- Insert a new product if it doesn't exist in tblProducts
            INSERT (ProductID, ProductName, Price)
            VALUES (source.ProductID, source.ProductName, source.Price);

        -- Optional: Return the number of rows affected
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    ELSE
    BEGIN
        -- If the JSON is invalid, print an error message
        PRINT 'Invalid JSON input';
    END
END;

--Testing stored procedure

DECLARE @json NVARCHAR(MAX);

SET @json = '[ 
    { "ProductID": 101, "ProductName": "Product A", "Price": 25.50 },
	{ "ProductID": 101, "ProductName": "Product A", "Price": 25.50 }, 
    { "ProductID": 102, "ProductName": "Product B", "Price": 30.00 } 
]';

exec spUpdateJsonData  @json

select * from tblProducts







