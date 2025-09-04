-- Get all bookings for a specific user
SELECT 
    b.id,
    b.booking_date::text,
    b.booking_time::text,
    b.guests,
    b.special_requests,
    b.status,
    b.confirmation_code,
    t.table_number,
    t.capacity,
    t.location,
    b.created_at
FROM bookings b
JOIN restaurant_tables t ON b.table_id = t.id
WHERE b.user_id = $1
ORDER BY b.booking_date DESC, b.booking_time DESC