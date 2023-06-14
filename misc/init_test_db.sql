SELECT 'CREATE DATABASE test1'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'test1')\gexec

\connect test1

CREATE TABLE indexing_table(created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());
