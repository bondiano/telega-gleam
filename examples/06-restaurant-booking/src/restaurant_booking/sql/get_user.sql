-- Get user by telegram_id and chat_id
SELECT id, telegram_id, chat_id, name, phone, email, created_at, updated_at 
FROM users 
WHERE telegram_id = $1 AND chat_id = $2