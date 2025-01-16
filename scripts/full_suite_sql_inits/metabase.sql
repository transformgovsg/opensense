CREATE DATABASE metabase;
CREATE USER metabase_user WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase_user;

\c metabase
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO metabase_user;
GRANT CREATE ON SCHEMA public TO metabase_user;
