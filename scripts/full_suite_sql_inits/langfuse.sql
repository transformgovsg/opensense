CREATE DATABASE "langfuse";
CREATE USER langfuse_user WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE langfuse TO langfuse_user;

\c langfuse
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO langfuse_user;
GRANT ALL ON SCHEMA public TO langfuse_user;