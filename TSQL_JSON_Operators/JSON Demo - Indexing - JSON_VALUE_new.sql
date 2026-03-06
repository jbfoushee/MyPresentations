ALTER TABLE [Sales].[SalesOrderDetail]
  ADD jsonData json

UPDATE Sales.SalesOrderDetail
SET jsonData =
    JSON_OBJECT(
        'SalesOrderID': SalesOrderID,
        'SalesOrderDetailID': SalesOrderDetailID,
        'CarrierTrackingNumber': CarrierTrackingNumber,
        'OrderQty': OrderQty,
        'ProductID': ProductID,
        'SpecialOfferID': SpecialOfferID,
        'UnitPrice': UnitPrice,
        'UnitPriceDiscount': UnitPriceDiscount,
        'LineTotal': LineTotal,
        'rowguid': rowguid,
        'ModifiedDate': ModifiedDate
    )
WHERE jsonData IS NULL

SELECT TOP 10 * FROM [Sales].[SalesOrderDetail] ORDER BY NEWID()

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.CarrierTrackingNumber') = '1FA6-4616-B7'
-- We see a 100% Clustered Index Scan on the PK, and a subtree cost of : 11.236


CREATE JSON INDEX IXJ_SalesOrderDetail_JsonData
ON Sales.SalesOrderDetail(JsonData)
   FOR ('$')
   WITH (DATA_COMPRESSION=PAGE);

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.CarrierTrackingNumber') = '1FA6-4616-B7'
-- The subtree cost did not change (11.236)

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.CarrierTrackingNumber') = '1FA6-4616-B7'
  AND JSON_VALUE(jsonData,'$.OrderQty') = 1
-- The JSON index hit, and the subtree went down to 4.039

-- What if we focus the JSON index on the CarrierTrackingNumber ?
DROP INDEX IXJ_SalesOrderDetail_JsonData ON Sales.SalesOrderDetail
CREATE JSON INDEX IXJ_SalesOrderDetail_JsonData
ON Sales.SalesOrderDetail(JsonData)
   FOR ('$.CarrierTrackingNumber')
   WITH (DATA_COMPRESSION=PAGE);
-- It built a lot faster!

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.CarrierTrackingNumber') = '1FA6-4616-B7'
-- The subtree cost did not change (11.236)


DROP INDEX IXJ_SalesOrderDetail_JsonData ON Sales.SalesOrderDetail
CREATE JSON INDEX IXJ_SalesOrderDetail_JsonData
ON Sales.SalesOrderDetail(JsonData)
   FOR ('$')
   WITH (DATA_COMPRESSION=PAGE);


-- Let's add more data:

INSERT INTO Sales.SalesOrderDetail
(
    SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID,
    UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate
)
SELECT TOP (100000)
    soh.SalesOrderID,
    CONCAT(
        RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 9999 AS VARCHAR(4)), 4),
        '-',
        RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 999 AS VARCHAR(3)), 3),
        '-',
        RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 999 AS VARCHAR(3)), 3)
    ) AS CarrierTrackingNumber,
    ABS(CHECKSUM(NEWID())) % 5 + 1 AS OrderQty,
    p.ProductID,
    so.SpecialOfferID,
    p.ListPrice AS UnitPrice,
    CAST((ABS(CHECKSUM(NEWID())) % 20) / 100.0 AS DECIMAL(10,4)) AS UnitPriceDiscount,
    NEWID() AS rowguid,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365), GETDATE()) AS ModifiedDate
FROM Sales.SalesOrderHeader soh
JOIN Sales.SpecialOfferProduct sop
    ON 1 = 1
JOIN Production.Product p
    ON p.ProductID = sop.ProductID
JOIN Sales.SpecialOffer so
    ON so.SpecialOfferID = sop.SpecialOfferID
ORDER BY NEWID();


UPDATE Sales.SalesOrderDetail
SET jsonData =
    JSON_OBJECT(
        'SalesOrderID': SalesOrderID,
        'SalesOrderDetailID': SalesOrderDetailID,
        'CarrierTrackingNumber': CarrierTrackingNumber,
        'OrderQty': OrderQty,
        'ProductID': ProductID,
        'SpecialOfferID': SpecialOfferID,
        'UnitPrice': UnitPrice,
        'UnitPriceDiscount': UnitPriceDiscount,
        'LineTotal': LineTotal,
        'rowguid': rowguid,
        'ModifiedDate': ModifiedDate
    )
WHERE jsonData IS NULL


SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.CarrierTrackingNumber') = '1FA6-4616-B7'
-- The subtree cost did not change (11.236)

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.ProductID') = 812
-- The subtree cost did not change (11.236)

SELECT *
FROM [Sales].[SalesOrderDetail]
WHERE JSON_VALUE(jsonData,'$.OrderQty') = 15
-- The subtree cost did not change (11.236)