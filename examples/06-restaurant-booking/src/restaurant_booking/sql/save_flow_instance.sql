-- Save or update a flow instance
INSERT INTO flow_instances 
  (id, flow_name, user_id, chat_id, current_step, state_data, scene_data, wait_token)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (id) DO UPDATE SET
  current_step = EXCLUDED.current_step,
  state_data = EXCLUDED.state_data,
  scene_data = EXCLUDED.scene_data,
  wait_token = EXCLUDED.wait_token,
  updated_at = CURRENT_TIMESTAMP