SELECT * FROM Person.PersonOrders_JSON
WHERE JSON_VALUE([CustomerJson], '$.json_expert') = Convert(bit, 1)

SELECT * FROM Person.PersonOrders_JSON
WHERE JSON_PATH_EXISTS([CustomerJson], '$.json_expert') = 1

SELECT * FROM Person.PersonOrders_JSON
WHERE JSON_VALUE([CustomerJson], '$.json_expert') IN (Convert(bit, 1), Convert(bit, 0))

