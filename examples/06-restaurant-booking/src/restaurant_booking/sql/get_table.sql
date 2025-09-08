-- Get table by ID
SELECT id, table_number, capacity, location, is_available 
FROM restaurant_tables 
WHERE id = $1