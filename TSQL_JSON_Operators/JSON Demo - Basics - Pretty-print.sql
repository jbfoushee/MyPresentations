CREATE TABLE #temp
  (ID int IDENTITY (1,1) NOT NULL
   , json_data nvarchar(4000) NOT NULL
  )

-- Sample data from https://microsoftedge.github.io/Demos/json-dummy-data/64KB.json

--This data has been pre-indented
INSERT INTO #temp (json_data)
VALUES
 ( '{
        "name": "Adeel Solangi",
        "language": "Sindhi",
        "id": "V59OF92YF627HFY0",
        "bio": "Donec lobortis eleifend condimentum. Cras dictum dolor lacinia lectus vehicula rutrum. Maecenas quis nisi nunc. Nam tristique feugiat est vitae mollis. Maecenas quis nisi nunc.",
        "version": 6.1
    }')
--This data has been deliberately un-indented
INSERT INTO #temp (json_data)
VALUES
 ( '{"name": "Afzal Ghaffar","language": "Sindhi","id": "ENTOCR13RSCLZ6KU","bio": "Aliquam sollicitudin ante ligula, eget malesuada nibh efficitur et. Pellentesque massa sem, scelerisque sit amet odio id, cursus tempor urna. Etiam congue dignissim volutpat. Vestibulum pharetra libero et velit gravida euismod.","version": 1.88 }'
 )

-- For each of the following queries, will every row return pretty-printed or not?
-- Try switching between "Results To Text," "Results To Grid" and "Results To File"
-- For "Results to Grid," copy the resulting table to Notepad

--Both rows in a dataset
SELECT * FROM #temp

--Isolating the row originally loaded pretty-printed
SELECT json_data 
FROM #temp
WHERE ID = (SELECT MIN(ID) FROM #temp)
FOR JSON AUTO

--Isolating the row originally loaded un-indented
SELECT json_data 
FROM #temp
WHERE ID = (SELECT MAX(ID) FROM #temp)
FOR JSON AUTO

--Selecting the row originally loaded pretty-printed (notice it came back indented)
SELECT JSON_QUERY(json_data, '$') AS [value]
FROM #temp
WHERE ID = (SELECT MIN(ID) FROM #temp)
FOR JSON AUTO

--Selecting the row originally loaded un-indented
SELECT JSON_QUERY(json_data, '$') AS [value]
FROM #temp
WHERE ID = (SELECT MAX(ID) FROM #temp)
FOR JSON AUTO

-- It seems it has a lot to do with how it was initially loaded!
-- But consider, this is merely a display issue and does not interfere
-- with the processing of the JSON object model

-- Now DROP the table and change the json_data datatype in line 3
-- from nvarchar to json. Now what happens?