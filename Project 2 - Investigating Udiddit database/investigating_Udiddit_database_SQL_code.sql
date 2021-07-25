/* Proposed schema */

-- "users" table
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "username" VARCHAR(25) NOT NULL,
  "phone_number" VARCHAR(30),
  "time_created" TIMESTAMP,
  "last_login" TIMESTAMP,
  CONSTRAINT "not_empty_username" CHECK (LENGTH(TRIM("username")) > 0)
);

CREATE UNIQUE INDEX "lower_username" ON "users"(
  LOWER(TRIM("username")));
CREATE INDEX "reverse_phone_search" ON "users" (
  REGEXP_REPLACE("phone_number", '[^0-9]+', '', 'g'));


-- "topics" table
CREATE TABLE "topics" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(30) UNIQUE NOT NULL,
  "description" VARCHAR(500),
  "creator_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
  "time_created" TIMESTAMP,
  "time_updated" TIMESTAMP,
  CONSTRAINT "not_empty_name" CHECK (
    LENGTH(TRIM("name")) > 0)
);

CREATE INDEX "lower_topic_name" ON "topics" (
  LOWER("name") VARCHAR_PATTERN_OPS);


-- "posts" table
CREATE TABLE "posts" (
  "id" BIGSERIAL PRIMARY KEY,
  "title" VARCHAR(100) NOT NULL,
  "url" VARCHAR(2000) DEFAULT NULL,
  "text_content" TEXT DEFAULT NULL,
  "creator_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
  "topic_ref" INTEGER REFERENCES "topics" ("id") ON DELETE CASCADE,
  "time_created" TIMESTAMP,
  CONSTRAINT "not_empty_title" CHECK (LENGTH(TRIM("title")) > 0),
  CONSTRAINT "url_or_text" CHECK (
    (NULLIF("url",'') IS NULL OR NULLIF("text_content",'') IS NULL)
    AND NOT
    (NULLIF("url",'') IS NULL AND NULLIF("text_content",'') IS NULL))
);

CREATE INDEX "url_search" ON "posts" ("url" VARCHAR_PATTERN_OPS);


-- "comments" table
CREATE TABLE "comments" (
  "id" BIGSERIAL PRIMARY KEY,
  "text_content" TEXT NOT NULL,
  "creator_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
  "post_ref" INTEGER REFERENCES "posts" ("id") ON DELETE CASCADE,
  "parent_comment_id" INTEGER REFERENCES "comments" ("id")
    ON DELETE CASCADE,
  "time_created" TIMESTAMP,
  CONSTRAINT "not_empty_text_content" CHECK (
    LENGTH(TRIM("text_content")) > 0)
);


-- "votes" table
CREATE TABLE "votes" (
  "id" BIGSERIAL PRIMARY KEY,
  "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
  "post_ref" INTEGER REFERENCES "posts" ("id") ON DELETE CASCADE,
  "vote" SMALLINT NOT NULL,
  CONSTRAINT "one_vote_per_user" UNIQUE ("user_id", "comment_id"),
  CONSTRAINT "vote_value" CHECK ("vote" = 1 OR "vote" = -1)
);



/* Migrating data stored using the original schema to the database created with the proposed schema */

-- migrating data to "users" table
INSERT INTO "users" ("username")
SELECT DISTINCT username
FROM bad_comments
UNION
SELECT DISTINCT username
FROM bad_posts
UNION
SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(upvotes, ',')::VARCHAR
FROM bad_posts
UNION
SELECT DISTINCT REGEXP_SPLIT_TO_TABLE(downvotes, ',')::VARCHAR
FROM bad_posts;

-- migrating data to "topics" table
INSERT INTO "topics" ("name")
SELECT DISTINCT topic
FROM bad_posts;

-- migrating data to "posts" table
INSERT INTO "posts" (
  "id", "title", "url", "text_content", "creator_id", "topic_ref")
SELECT bp.id, LEFT(bp.title, 100), bp.url, bp.text_content,
  users.id, topics.id
FROM bad_posts bp
JOIN users
ON bp.username = users.username
JOIN topics
ON bp.topic = topics.name;

-- migrating data to "comments" table
INSERT INTO "comments" (
  "id", "text_content", "creator_id", "post_ref")
SELECT bc.id, bc.text_content, users.id, posts.id
FROM bad_comments bc
JOIN users
ON bc.username = users.username
JOIN posts
ON bc.post_id = posts.id;

-- migrating data to "votes" table
INSERT INTO "votes" ("user_id", "post_ref", "vote")
SELECT users.id, bp_up.id, 1 upvote
FROM (
  SELECT id , REGEXP_SPLIT_TO_TABLE(upvotes, ',') usernames
  FROM bad_posts) bp_up
JOIN users
ON users.username = bp_up.usernames;

INSERT INTO "votes" ("user_id", "post_ref", "vote")
SELECT users.id, bp_dw.id, 1 downvote
FROM (
  SELECT id , REGEXP_SPLIT_TO_TABLE(downvotes, ',') usernames
  FROM bad_posts) bp_dw
JOIN users
ON users.username = bp_dw.usernames;
