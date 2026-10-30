/* =====================================================================
   SOCIAL MEDIA (IG CLONE) — STUDENT ANSWER TEMPLATE
   ===================================================================== */

USE ig_clone;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1.
-- Are there any tables with duplicate or missing null values? If so, how
-- would you handle them?
-- 1). users — rows with NULL username
SELECT id, username, created_at
FROM users
WHERE username IS NULL;

-- 2). users — duplicate usernames
SELECT username, COUNT(*) AS count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- 3). photos — rows with NULL image_url / user_id / created_dat
SELECT id, image_url, user_id, created_dat
FROM photos
WHERE image_url IS NULL
OR user_id IS NULL
OR created_dat IS NULL;
   
-- 4). photos — duplicate (image_url, user_id) pairs
SELECT image_url, user_id, COUNT(*) AS count
FROM photos
GROUP BY image_url, user_id
HAVING COUNT(*) > 1;

-- 5). comments — rows with NULL comment_text / user_id / photo_id / created_at
SELECT id, comment_text, photo_id, user_id, created_at
FROM comments
WHERE comment_text IS NULL
OR user_id IS NULL
OR photo_id IS NULL
OR created_at IS NULL;

-- 6). comments — duplicate (comment_text, user_id, photo_id) triples
SELECT comment_text, user_id, photo_id, COUNT(*) AS count
FROM comments
GROUP BY comment_text, user_id, photo_id
HAVING COUNT(*) > 1;

-- 7). likes — rows with NULL user_id / photo_id / created_at
SELECT user_id, photo_id, created_at
FROM likes
WHERE user_id IS NULL
OR photo_id IS NULL
OR created_at IS NULL;

-- 8). likes — duplicate (user_id, photo_id) pairs
SELECT user_id, photo_id, COUNT(*) AS count
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- 9). follows — rows with NULL follower_id / followee_id / created_at
SELECT follower_id, followee_id, created_at
FROM follows
WHERE follower_id IS NULL
OR followee_id IS NULL
OR created_at IS NULL;

-- 10). follows — duplicate (follower_id, followee_id) pairs
SELECT follower_id, followee_id, COUNT(*) AS count
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;


-- O2.
-- What is the distribution of user activity levels (e.g., number of posts,
-- likes, comments) across the user base?
SELECT
    u.id AS user_id,
    u.username,
    (SELECT COUNT(*)
     FROM photos p
     WHERE p.user_id = u.id) AS total_posts,
    (SELECT COUNT(*)
     FROM likes l
     WHERE l.user_id = u.id) AS total_likes_given,
    (SELECT COUNT(*)
     FROM comments c
     WHERE c.user_id = u.id) AS total_comments_made
FROM users u
ORDER BY u.id;


-- O3.
-- Calculate the average number of tags per post (photo_tags and photos
-- tables).
SELECT ROUND(AVG(tags),2) AS avg_tags_per_post
FROM (SELECT p.id,COUNT(t.tag_id) AS tags
FROM photos p
LEFT JOIN photo_tags t ON p.id = t.photo_id GROUP BY p.id) AS num_tags;


-- O4.
-- Identify the top users with the highest engagement rates (likes, comments)
-- on their posts and rank them.
SELECT
    p.user_id AS user_id,
    u.username,
    COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS Total,
    RANK() OVER (ORDER BY COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) DESC) AS rnk
FROM photos p
JOIN likes l
    ON p.id = l.photo_id
JOIN comments c
    ON p.id = c.photo_id
JOIN users u
on u.id = p.user_id
GROUP BY p.user_id, u.username
ORDER BY rnk, user_id
LIMIT 25;


-- O5.
-- Which users have the highest number of followers and followings?
WITH CTE_FOllOWERS AS
( SELECT
        followee_id,
        COUNT(*) AS followers
    FROM follows
    GROUP BY followee_id),
CTE_FOLLOWING AS
(SELECT
	follower_id,
	COUNT(*) AS following
    FROM follows
    GROUP BY follower_id)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(f.followers, 0) AS followers,
    COALESCE(g.following, 0) AS following
FROM users u
LEFT JOIN CTE_FOLLOWERS f
    ON u.id = f.followee_id
LEFT JOIN CTE_FOLLOWING g
    ON u.id = g.follower_id
ORDER BY followers DESC, following DESC, u.id;


-- O6.
-- Calculate the average engagement rate (likes, comments) per post for each
-- user.
WITH CTE_LIKE_COUNT AS
(SELECT
	photo_id,
	COUNT(*) AS like_count
    FROM likes
    GROUP BY photo_id),
CTE_COMMENT_COUNT AS
(SELECT
	photo_id,
	COUNT(*) AS comment_count
    FROM comments
    GROUP BY photo_id
)
SELECT
    u.id AS id,
    u.username,
    AVG(COALESCE(l.like_count, 0) + COALESCE(c.comment_count, 0)) AS avg_engagement
FROM users u
JOIN photos p
    ON u.id = p.user_id
LEFT JOIN CTE_LIKE_COUNT l
ON p.id = l.photo_id
LEFT JOIN CTE_COMMENT_COUNT c
    ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY avg_engagement DESC;


-- O7.
-- Get the list of users who have never liked any post (users and likes
-- tables)
SELECT
    u.id,
    u.username
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.user_id = u.id
)
ORDER BY u.id;


-- O8.
-- How can you leverage user-generated content (posts, hashtags, photo tags)
-- to create more personalized and engaging ad campaigns?
SELECT t.tag_name, COUNT(*) AS usage_count
FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY usage_count DESC
LIMIT 10;

-- Also, to run targeted ads, we analyze users most frequently used tags from their posts.

WITH user_tags AS (
  SELECT p.user_id, t.tag_name, COUNT(*) AS tag_count
  FROM photos p
  JOIN photo_tags pt ON p.id = pt.photo_id
  JOIN tags t ON pt.tag_id = t.id
  GROUP BY p.user_id, t.tag_name
),
ranked_tags AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY tag_count DESC) AS rn
  FROM user_tags
)
SELECT user_id, tag_name, tag_count
FROM ranked_tags
WHERE rn = 1;



-- O9.
-- Are there any correlations between user activity levels and specific
-- content types (e.g., photos, videos, reels)? How can this information
-- guide content creation and curation strategies?
WITH CTE_PHOTO_LIKES AS (
    SELECT
        p.id AS photo_id,
        p.user_id,
        COUNT(DISTINCT l.user_id) AS likes_count
    FROM photos p
    LEFT JOIN likes l
        ON p.id = l.photo_id
    GROUP BY
        p.id,
        p.user_id
),

CTE_PHOTO_COMMENTS AS (
    SELECT
        p.id AS photo_id,
        p.user_id,
        COUNT(DISTINCT c.id) AS comments_count
    FROM photos p
    LEFT JOIN comments c
        ON p.id = c.photo_id
    GROUP BY
        p.id,
        p.user_id
),

CTE_PHOTO_ENGAGEMENT AS (
    SELECT
        pl.photo_id,
        pl.user_id,
        COALESCE(pl.likes_count, 0)
            + COALESCE(pc.comments_count, 0) AS total_engagement
    FROM CTE_PHOTO_LIKES pl
    LEFT JOIN CTE_PHOTO_COMMENTS pc
        ON pl.photo_id = pc.photo_id
),

CTE_PHOTO_TAGS AS (
    SELECT
        pe.photo_id,
        pe.user_id,
        pe.total_engagement,
        t.tag_name
    FROM CTE_PHOTO_ENGAGEMENT pe
    JOIN photo_tags pt
        ON pe.photo_id = pt.photo_id
    JOIN tags t
        ON pt.tag_id = t.id
)

SELECT
    tag_name AS content_type,
    COUNT(DISTINCT photo_id) AS total_photos,
    COUNT(DISTINCT user_id) AS active_users,
    AVG(total_engagement) AS avg_engagement_per_photo
FROM CTE_PHOTO_TAGS
GROUP BY tag_name
ORDER BY avg_engagement_per_photo DESC;


-- O10.
-- Calculate the total number of likes, comments, and photo tags for each
-- user.
WITH CTE_TOTAL_LIKES AS (
    SELECT
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
CTE_TOTAL_COMMENTS AS (
    SELECT
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
),
CTE_TOTAL_TAGS AS (
    SELECT
        p.user_id,
        COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt
        ON p.id = pt.photo_id
    GROUP BY p.user_id
)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(t.total_tags, 0) AS total_tags
FROM users u
LEFT JOIN CTE_TOTAL_LIKES l
    ON u.id = l.user_id
LEFT JOIN CTE_TOTAL_COMMENTS c
    ON u.id = c.user_id
LEFT JOIN CTE_TOTAL_TAGS t
    ON u.id = t.user_id
ORDER BY u.id;


-- O11.
-- Rank users based on their total engagement (likes, comments, shares) over a
-- month.
WITH CTE_LIKES AS (
    SELECT
        p.user_id,
        YEAR(p.created_dat) AS year,
        MONTH(p.created_dat) AS month,
        COUNT(l.user_id) AS likes_received
    FROM photos p
    LEFT JOIN likes l
        ON p.id = l.photo_id
    WHERE p.created_dat IS NOT NULL
    GROUP BY
        p.user_id,
        YEAR(p.created_dat),
        MONTH(p.created_dat)
),
CTE_COMMENTS AS (
    SELECT
        p.user_id,
        YEAR(p.created_dat) AS year,
        MONTH(p.created_dat) AS month,
        COUNT(c.id) AS comments_received
    FROM photos p
    LEFT JOIN comments c
        ON p.id = c.photo_id
    WHERE p.created_dat IS NOT NULL
    GROUP BY
        p.user_id,
        YEAR(p.created_dat),
        MONTH(p.created_dat)
),
CTE_ENGAGEMENT AS (
    SELECT
        u.id AS user_id,
        u.username,
        l.year,
        l.month,
        COALESCE(l.likes_received, 0)
          + COALESCE(c.comments_received, 0) AS total_engagement
    FROM CTE_LIKES l
    JOIN users u
        ON u.id = l.user_id
    LEFT JOIN CTE_COMMENTS c
        ON c.user_id = l.user_id
       AND c.year = l.year
       AND c.month = l.month
)
SELECT
    user_id,
    username,
    year,
    month,
    total_engagement,
    DENSE_RANK() OVER (
        PARTITION BY year, month
        ORDER BY total_engagement DESC
    ) AS engagement_rank
FROM CTE_ENGAGEMENT
ORDER BY year, month, engagement_rank, user_id;


-- O12.
-- Retrieve the hashtags that have been used in posts with the highest average
-- number of likes. Use a CTE to calculate the average likes for each
-- hashtag first.
WITH CTE_HASHTAG_STATS AS (
    SELECT
        t.id AS tag_id,
        t.tag_name,
        COUNT(DISTINCT pt.photo_id) AS total_photos,
        COUNT(l.user_id) AS total_likes,
        (COUNT(l.user_id) * 1.0 / COUNT(DISTINCT pt.photo_id)) AS avg_likes_per_photo
    FROM tags t
    JOIN photo_tags pt
        ON t.id = pt.tag_id
    LEFT JOIN likes l
        ON pt.photo_id = l.photo_id
    GROUP BY
        t.id,
        t.tag_name
)
SELECT
    tag_id,
    tag_name,
    avg_likes_per_photo,
    total_likes,
    total_photos
FROM CTE_HASHTAG_STATS
ORDER BY avg_likes_per_photo DESC, tag_id
LIMIT 10;


-- O13.
-- Retrieve the users who have started following someone after being followed
-- by that person.
WITH CTE_FOLLOWING AS (
    SELECT
        follower_id,
        followee_id,
        created_at
    FROM follows
)
SELECT DISTINCT
    u.id,
    u.username
FROM users u
JOIN CTE_FOLLOWING f1
    ON u.id = f1.follower_id
JOIN CTE_FOLLOWING f2
    ON f1.followee_id = f2.follower_id
   AND f1.follower_id = f2.followee_id
WHERE f1.created_at > f2.created_at
ORDER BY u.id;



/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1.
-- Based on user engagement and activity levels, which users would you
-- consider the most loyal or valuable? How would you reward or incentivize
-- these users?
WITH CTE_POSTS AS (
    SELECT
        user_id,
        COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),
CTE_LIKES_RECEIVED AS (
    SELECT
        p.user_id,
        COUNT(*) AS likes_received
    FROM photos p
    JOIN likes l
        ON p.id = l.photo_id
    GROUP BY p.user_id
),
CTE_COMMENTS_RECEIVED AS (
    SELECT
        p.user_id,
        COUNT(*) AS comments_received
    FROM photos p
    JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id
),
CTE_LIKES_GIVEN AS (
    SELECT
        user_id,
        COUNT(*) AS likes_given
    FROM likes
    GROUP BY user_id
),
CTE_COMMENTS_MADE AS (
    SELECT
        user_id,
        COUNT(*) AS comments_made
    FROM comments
    GROUP BY user_id
),
CTE_USER_ACTIVITY AS (
    SELECT
        u.id AS user_id,
        u.username,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(lr.likes_received, 0) AS likes_received,
        COALESCE(cr.comments_received, 0) AS comments_received,
        COALESCE(lg.likes_given, 0) AS likes_given,
        COALESCE(cm.comments_made, 0) AS comments_made,
        (COALESCE(lr.likes_received, 0) + COALESCE(cr.comments_received, 0)) AS engagement_received,
        (COALESCE(lg.likes_given, 0) + COALESCE(cm.comments_made, 0)) AS engagement_given
    FROM users u
    LEFT JOIN CTE_POSTS p
        ON u.id = p.user_id
    LEFT JOIN CTE_LIKES_RECEIVED lr
        ON u.id = lr.user_id
    LEFT JOIN CTE_COMMENTS_RECEIVED cr
        ON u.id = cr.user_id
    LEFT JOIN CTE_LIKES_GIVEN lg
        ON u.id = lg.user_id
    LEFT JOIN CTE_COMMENTS_MADE cm
        ON u.id = cm.user_id
)
SELECT
    *,
    (engagement_received + engagement_given) AS total_activity_score,
    DENSE_RANK() OVER(ORDER BY engagement_received + engagement_given DESC) AS user_rank
FROM CTE_USER_ACTIVITY;


-- S2.
-- For inactive users, what strategies would you recommend to re-engage them
-- and encourage them to start posting or engaging again?
WITH CTE_USER_ACTIVITY AS 
(SELECT
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS photos_posted,
        COUNT(DISTINCT l.photo_id) AS likes_given,
        COUNT(DISTINCT c.id) AS comments_made
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON u.id = l.user_id
    LEFT JOIN comments c
        ON u.id = c.user_id
    GROUP BY u.id, u.username
)
SELECT
    user_id,
    username,
    photos_posted,
    likes_given,
    comments_made,
    CASE
        WHEN photos_posted = 0 AND likes_given = 0 AND comments_made = 0 THEN 'Totally Inactive'
        WHEN photos_posted = 0 THEN 'Does Not Post But Engages'
        WHEN likes_given = 0 AND comments_made = 0 THEN 'Posts But Does Not Engage'
        ELSE 'Fully Active User'
    END AS activity_status
FROM CTE_USER_ACTIVITY ;


-- S3.
-- Which hashtags or content topics have the highest engagement rates? How can
-- this information guide content strategy and ad campaigns?

WITH CTE_HASHTAG_ENGAGEMENT AS (
    SELECT
        t.id AS tag_id,
        t.tag_name,
        COUNT(DISTINCT pt.photo_id) AS total_photos,
        COUNT(l.user_id) AS total_likes,
        ROUND(COUNT(l.user_id) * 1.0 / COALESCE(COUNT(DISTINCT pt.photo_id), 0),2) AS avg_likes_per_photo
    FROM tags t
    JOIN photo_tags pt
        ON t.id = pt.tag_id
    LEFT JOIN likes l
        ON pt.photo_id = l.photo_id
    GROUP BY
        t.id,
        t.tag_name
)
SELECT
    tag_id,
    tag_name,
    avg_likes_per_photo,
    total_likes,
    total_photos
FROM CTE_HASHTAG_ENGAGEMENT
ORDER BY avg_likes_per_photo DESC, total_photos DESC
LIMIT 10;


-- S4.
-- Are there any patterns or trends in user engagement based on demographics
-- (age, location, gender) or posting times? How can these insights inform
-- targeted marketing campaigns?
WITH CTE_TOTAL_LIKES AS (
    SELECT
        photo_id,
        COUNT(*) AS total_likes
    FROM likes
    GROUP BY photo_id
),

CTE_TOTAL_COMMENTS AS (
    SELECT
        photo_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY photo_id
)

SELECT
    DATE_FORMAT(p.created_dat, '%H') AS hour_of_day,
    DAYNAME(p.created_dat) AS day_of_week,
    COUNT(p.id) AS total_posts,
    COALESCE(SUM(tl.total_likes), 0) AS total_likes,
    COALESCE(SUM(tc.total_comments), 0) AS total_comments,
    ROUND(
        (
            COALESCE(SUM(tl.total_likes), 0)
            + COALESCE(SUM(tc.total_comments), 0)
        ) / COUNT(p.id),
        2
    ) AS average_engagement
FROM photos p
LEFT JOIN CTE_TOTAL_LIKES tl
    ON p.id = tl.photo_id
LEFT JOIN CTE_TOTAL_COMMENTS tc
    ON p.id = tc.photo_id
GROUP BY
    DATE_FORMAT(p.created_dat, '%H'),
    DAYNAME(p.created_dat)
ORDER BY average_engagement DESC;

-- S5.
-- Based on follower counts and engagement rates, which users would be ideal
-- candidates for influencer marketing campaigns? How would you approach
-- and collaborate with these influencers?
WITH CTE_FOLLOWERS AS (
    SELECT
        followee_id AS user_id,
        COUNT(*) AS follower_count
    FROM follows
    GROUP BY followee_id
),
CTE_POST_ENGAGEMENT AS (
    SELECT
        p.user_id,
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS likes_received,
        COUNT(DISTINCT c.id) AS comments_received
    FROM photos p
    LEFT JOIN likes l
        ON p.id = l.photo_id
    LEFT JOIN comments c
        ON p.id = c.photo_id
    GROUP BY p.user_id, p.id
),
CTE_USER_ENGAGEMENT AS (
    SELECT
        user_id,
        COUNT(*) AS total_posts,
        SUM(likes_received) AS total_likes,
        SUM(comments_received) AS total_comments,
        ROUND(
            AVG(likes_received + comments_received), 2
        ) AS avg_engagement_per_post
    FROM CTE_POST_ENGAGEMENT
    GROUP BY user_id
),
CTE_INFLUENCER_SCORE AS (
    SELECT
        u.id AS user_id,
        u.username,
        COALESCE(f.follower_count, 0) AS follower_count,
        COALESCE(e.total_posts, 0) AS total_posts,
        COALESCE(e.total_likes, 0) AS total_likes,
        COALESCE(e.total_comments, 0) AS total_comments,
        COALESCE(e.avg_engagement_per_post, 0)
            AS avg_engagement_per_post
    FROM users u
    LEFT JOIN CTE_FOLLOWERS f
        ON u.id = f.user_id
    LEFT JOIN CTE_USER_ENGAGEMENT e
        ON u.id = e.user_id
)
SELECT
    *,
    DENSE_RANK() OVER (
        ORDER BY follower_count DESC,
                 avg_engagement_per_post DESC
    ) AS influencer_rank
FROM CTE_INFLUENCER_SCORE
WHERE total_posts > 0
ORDER BY influencer_rank, user_id
LIMIT 10;


-- S6.
-- Based on user behavior and engagement data, how would you segment the user
-- base for targeted marketing campaigns or personalized recommendations?
WITH CTE_POSTS AS (
    SELECT
        user_id,
        COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),
CTE_LIKES AS (
    SELECT
        user_id,
        COUNT(*) AS likes_given
    FROM likes
    GROUP BY user_id
),
CTE_COMMENTS AS (
    SELECT
        user_id,
        COUNT(*) AS comments_made
    FROM comments
    GROUP BY user_id
),
CTE_FOLLOWERS AS (
    SELECT
        followee_id AS user_id,
        COUNT(*) AS follower_count
    FROM follows
    GROUP BY followee_id
),
CTE_USER_ACTIVITY AS (
    SELECT
        u.id AS user_id,
        u.username,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(l.likes_given, 0) AS likes_given,
        COALESCE(c.comments_made, 0) AS comments_made,
        COALESCE(f.follower_count, 0) AS follower_count
    FROM users u
    LEFT JOIN CTE_POSTS p
        ON u.id = p.user_id
    LEFT JOIN CTE_LIKES l
        ON u.id = l.user_id
    LEFT JOIN CTE_COMMENTS c
        ON u.id = c.user_id
    LEFT JOIN CTE_FOLLOWERS f
        ON u.id = f.user_id
)
SELECT
    user_id,
    username,
    total_posts,
    likes_given,
    comments_made,
    follower_count,
    CASE
        WHEN total_posts = 0 AND likes_given = 0 AND comments_made = 0 THEN 'Inactive Users'
        WHEN total_posts >= 5 AND likes_given + comments_made >= 10 THEN 'Highly Active Users'
        WHEN total_posts > 0 AND likes_given + comments_made = 0 THEN 'Content Creators'
        WHEN likes_given + comments_made > 0 AND total_posts = 0 THEN 'Engaged Viewers'
        ELSE 'Moderately Active Users'
    END AS user_segment
FROM CTE_USER_ACTIVITY
ORDER BY user_id;


-- S7.
-- If data on ad campaigns (impressions, clicks, conversions) is available,
-- how would you measure their effectiveness and optimize future campaigns?



-- S8.
-- How can you use user activity data to identify potential brand ambassadors
-- or advocates who could help promote Instagram's initiatives or events?



-- S9.
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?



-- S10.
-- Assuming there's a "User_Interactions" table tracking user engagements, how
-- can you update the "Engagement_Type" column to change all instances of
-- "Like" to "Heart" to align with Instagram's terminology?
UPDATE User_Interactions 
SET Engagement_Type = 'Heart' 
WHERE Engagement_Type = 'Like';



/* ===================================== END OF FILE ===================================== */
