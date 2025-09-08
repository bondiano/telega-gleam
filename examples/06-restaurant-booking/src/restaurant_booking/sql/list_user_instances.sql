-- List all flow instances for a user and chat
SELECT id, flow_name, user_id, chat_id, current_step, 
       state_data, scene_data, wait_token,
       EXTRACT(EPOCH FROM created_at)::INT as created_at,
       EXTRACT(EPOCH FROM updated_at)::INT as updated_at
FROM flow_instances 
WHERE user_id = $1 AND chat_id = $2