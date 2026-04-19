-----Base Session View (Foundation)
CREATE OR REPLACE VIEW vw_sessions_base AS
SELECT
    v.UserID0,
    v.Channel2          AS channel,
    from_utc_timestamp(v.RecordDate2, 'Africa/Johannesburg') AS session_ts,
    DATE(from_utc_timestamp(v.RecordDate2, 'Africa/Johannesburg')) AS session_date,
    HOUR(from_utc_timestamp(v.RecordDate2, 'Africa/Johannesburg')) AS session_hour
FROM `workspace`.`default`.`bright_tv_viewership` v;

-----Daily Viewership (Daily Sessions)
CREATE OR REPLACE VIEW vw_daily_viewership AS
SELECT
    session_date,
    COUNT(*) AS sessions
FROM vw_sessions_base
GROUP BY session_date
ORDER BY session_date;

---Time‑of‑Day Usage
CREATE OR REPLACE VIEW vw_hourly_usage AS
SELECT
    session_hour,
    COUNT(*) AS sessions
FROM vw_sessions_base
GROUP BY session_hour
ORDER BY session_hour;

----Top 10 Channels by Sessions
CREATE OR REPLACE VIEW vw_top_10_channels AS
SELECT
    channel,
    COUNT(*) AS sessions
FROM vw_sessions_base
GROUP BY channel
ORDER BY sessions DESC
LIMIT 10;

---Age Distribution
CREATE OR REPLACE VIEW vw_users_by_age AS
SELECT
    Age,
    COUNT(*) AS users
FROM `workspace`.`default`.`bright_tv_user_profiles`
GROUP BY Age;

---Race Distribution
CREATE OR REPLACE VIEW vw_users_by_race AS
SELECT
    Race,
    COUNT(*) AS users
FROM `workspace`.`default`.`bright_tv_user_profiles`
GROUP BY Race
ORDER BY users;

---Usage by Province
CREATE OR REPLACE VIEW vw_usage_by_province AS
SELECT
    p.Province,
    COUNT(*) AS sessions
FROM `workspace`.`default`.`vw_sessions_base` s
JOIN `workspace`.`default`.`bright_tv_user_profiles` p
  ON s.UserID0 = p.UserID
GROUP BY p.Province
ORDER BY sessions DESC;

---Low‑Usage Days Identification
CREATE OR REPLACE VIEW vw_daily_consumption_ranked AS
WITH daily_sessions AS (
    SELECT
        session_date,
        COUNT(*) AS sessions
    FROM vw_sessions_base
    GROUP BY session_date
)
SELECT
    session_date,
    sessions,
    percent_rank() OVER (ORDER BY sessions) AS usage_rank
FROM daily_sessions;

----Bottom 20% (Low‑Usage Days)
SELECT *
FROM vw_daily_consumption_ranked
WHERE usage_rank <= 0.2
ORDER BY session_date;

----Channels Performing on Low‑Usage Days
WITH low_days AS (
    SELECT session_date
    FROM vw_daily_consumption_ranked
    WHERE usage_rank <= 0.2
)
SELECT
    s.channel,
    COUNT(*) AS sessions
FROM vw_sessions_base s
JOIN low_days d
  ON s.session_date = d.session_date
GROUP BY s.channel
ORDER BY sessions DESC;

----Retention/Churn Definition – Behavioural
CREATE OR REPLACE VIEW vw_user_last_activity AS
SELECT
    UserID0,
    MAX(session_date) AS last_active_date
FROM vw_sessions_base
GROUP BY UserID0;
------------------
CREATE OR REPLACE VIEW vw_user_churn_status AS
SELECT
    UserID0,
    last_active_date,
    CASE
        WHEN datediff(current_date(), last_active_date) >= 30
             THEN 'Churned'
        ELSE 'Active'
    END AS churn_status
FROM vw_user_last_activity;
