CREATE DATABASE langfuse;
CREATE DATABASE metabase;
CREATE DATABASE senseadmin;

CREATE USER langfuse WITH PASSWORD 'xxx';
GRANT ALL PRIVILEGES ON DATABASE langfuse TO langfuse;
CREATE USER metabase WITH PASSWORD 'xxx';
GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase;
CREATE USER senseadmin WITH PASSWORD 'xxx';
GRANT ALL PRIVILEGES ON DATABASE senseadmin TO senseadmin;

\c langfuse
GRANT ALL ON SCHEMA public TO langfuse;
\c metabase
GRANT ALL ON SCHEMA public TO metabase;
\c senseadmin
GRANT ALL ON SCHEMA public TO senseadmin;