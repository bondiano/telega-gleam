-- Create or update user in database
INSERT INTO users (telegram_id, chat_id, name, phone, email, updated_at)
VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
ON CONFLICT (telegram_id)
DO UPDATE SET 
  chat_id = EXCLUDED.chat_id,
  name = EXCLUDED.name, 
  phone = EXCLUDED.phone, 
  email = EXCLUDED.email, 
  updated_at = CURRENT_TIMESTAMP
RETURNING id, telegram_id, chat_id, name, phone, email, created_at, updated_at