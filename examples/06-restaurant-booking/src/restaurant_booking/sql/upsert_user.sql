-- Create or update a user
INSERT INTO users (telegram_id, chat_id, name, phone, email)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (telegram_id) DO UPDATE SET
  chat_id = EXCLUDED.chat_id,
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email,
  updated_at = CURRENT_TIMESTAMP
RETURNING id, telegram_id, chat_id, name, phone, email