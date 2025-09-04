-- Cleanup expired flow instances
DELETE FROM flow_instances WHERE expires_at < CURRENT_TIMESTAMP