CREATE DATABASE sense_admin;
CREATE USER sense_admin_user WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE sense_admin TO sense_admin_user;

\c sense_admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sense_admin_user;
GRANT CREATE ON SCHEMA public TO sense_admin_user;
