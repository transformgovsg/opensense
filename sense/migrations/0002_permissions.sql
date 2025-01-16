-- Grant CONNECT on the database
GRANT CONNECT ON DATABASE data_copilot TO data_copilot;

-- Assuming the user needs access to the 'public' schema,
-- Adjust the schema name if a different schema should be used.
-- Grant USAGE on the schema
GRANT USAGE ON SCHEMA public TO data_copilot;

-- Grant SELECT, INSERT, UPDATE, DELETE on all tables in the 'public' schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO data_copilot;

-- To automatically grant privileges on new tables created in the future, you need to change the default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO data_copilot;