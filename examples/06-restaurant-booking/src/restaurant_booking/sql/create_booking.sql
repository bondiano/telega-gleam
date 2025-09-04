-- Create a new booking
INSERT INTO bookings 
  (user_id, table_id, booking_date, booking_time, guests, special_requests, confirmation_code, status)
VALUES ($1, $2, $3::date, $4::time, $5, $6, $7, 'confirmed')
RETURNING id, user_id, table_id, booking_date::text, booking_time::text, guests, special_requests, status, confirmation_code