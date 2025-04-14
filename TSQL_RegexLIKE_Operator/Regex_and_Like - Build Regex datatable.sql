CREATE TABLE dbo.Employees (
    ID INT IDENTITY(101,1),
    [Name] VARCHAR(150),
    Email VARCHAR(320),
    Phone_Number VARCHAR(20)
);

INSERT INTO dbo.Employees ([Name], Email, Phone_Number) 
VALUES ('John Doe', 'john@contoso.com', '123-456-7890')
    , ('Alice Smith', 'alice@fabrikam.com', '234-567-8901')
    , ('Bob Johnson', 'bob@fabrikam.net','345-678-9012')
    , ('Eve Jones', 'eve@contoso.com', '456-789-0123')
    , ('Charlie Brown', 'charlie@contoso.co.in', '567-890-124');
