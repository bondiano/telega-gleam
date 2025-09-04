-- Get available tables for date, time and guest count
SELECT t.id, t.table_number, t.capacity, t.location, t.is_available
FROM restaurant_tables t
WHERE t.capacity >= $1
  AND t.is_available = true
  AND t.id NOT IN (
    SELECT table_id FROM bookings
    WHERE booking_date = $2::date
      AND booking_time = $3::time
      AND status != 'cancelled'
  )
ORDER BY t.capacity, t.table_number