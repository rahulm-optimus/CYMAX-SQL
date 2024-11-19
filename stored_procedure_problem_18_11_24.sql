--You are tasked with creating a stored procedure that accepts a list of 
--customer IDs and updates the Status column in the Customers table.
--The new status should be set to 'Inactive' for the customers whose IDs are provided in the list.
--Additionally, if any customer is already marked as 'Inactive', the procedure should skip that 
--record and log a message stating, "Customer already inactive."
--Requirements:
--The stored procedure should handle a comma-separated list of customer IDs.
--For each customer ID, it should check if the Status is 'Inactive' before attempting to update it.
--Log the customer ID and a message if the status is skipped.
--Return the number of records updated.


DECLARE @STRING NVARCHAR(MAX) = N'1,2,3';

--Table initilaization
CREATE TABLE tblCustomers(
CustomerID INT PRIMARY KEY,
Name NVARCHAR(50),
Status NVARCHAR(50)
)

--Inserting into tblCustomers
INSERT INTO tblCustomers (CustomerID, Name, Status)
VALUES
(1, 'John Doe', 'Active'),
(2, 'Jane Smith', 'Inactive'),
(3, 'Michael Brown', 'Active'),
(4, 'Emily Davis', 'Pending'),
(5, 'David Wilson', 'Active');

--Truncating to check the sp
TRUNCATE TABLE tblCustomers;

SELECT * FROM tblCustomers

--Creating stored procedure
ALTER PROC spUpdateCustomersStatus (
    @customerIDs NVARCHAR(MAX),
    @status VARCHAR(50)
)
AS
BEGIN
    -- Declare a table variable to store parsed Customer IDs
    DECLARE @tblCustomerID TABLE (CustomerID INT);

    -- Insert Customer IDs into the table variable after splitting the input string
    INSERT INTO @tblCustomerID 
    SELECT CAST(TRIM(value) AS INT) AS CustomerID
    FROM STRING_SPLIT(@customerIDs, ',');

    -- Count the number of parsed IDs
    DECLARE @idCount INT;
    SET @idCount = (SELECT COUNT(*) FROM @tblCustomerID);

    -- Check if there are any IDs to process
    IF (@idCount > 0)
    BEGIN
        -- Perform the merge operation
        MERGE INTO tblCustomers AS target
        USING @tblCustomerID AS source
        ON target.CustomerID = source.CustomerID
        WHEN MATCHED AND target.Status <> 'Inactive' THEN
            UPDATE SET 
                target.Status = @status ;
         -- After the merge, check if no rows were matched
		 -- Can not add print directly into merge 
        IF (NOT EXISTS (SELECT 1 FROM tblCustomers WHERE CustomerID IN (SELECT CustomerID FROM @tblCustomerID)))
        BEGIN
            PRINT 'No match found.';
        END
		--Reflect the changes
		select @@rowcount as 'Total rows affected'
		select * from tblCustomers
    END
    ELSE
    BEGIN
        PRINT 'No valid customer IDs provided.'
    END
END;

--Testing 
SELECT * FROM tblCustomers

EXEC spUpdateCustomersStatus  @customerIDs='1,2,3',@status='Inactive'

