use july7;
commit;
select * from event;
select * from experiment;
--- Conversion Rate by Variant----
WITH experiment_results AS (
    SELECT
        a.variant,
        COUNT(DISTINCT a.user_id) AS total_users,
        COUNT(DISTINCT CASE
            WHEN e.event_type = 'purchase'
            THEN a.user_id
        END) AS converters,
        SUM(CASE
            WHEN e.event_type = 'purchase'
            THEN e.value
            ELSE 0
        END) AS total_revenue
    FROM experiment a
    LEFT JOIN event e
        ON a.user_id = e.user_id
       AND a.experiment_id = e.experiment_id
    WHERE a.experiment_id = 'checkout_redesign_v2'
    GROUP BY a.variant
)

SELECT
    variant,
    total_users,
    converters,
    ROUND(converters * 100.0 / total_users, 2) AS conversion_rate_pct,
    ROUND(total_revenue / total_users, 2) AS revenue_per_user
FROM experiment_results;

--- Sample Ratio Mismatch Check?---
SELECT
    variant,
    COUNT(*) AS users,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_total
FROM experiment
WHERE experiment_id = 'checkout_redesign_v2'
GROUP BY variant;
--- Device-wise Conversion Analysis---
WITH segment_results AS (
    SELECT
        a.variant,

        CASE
            WHEN e_first.device = 'mobile' THEN 'Mobile'
            WHEN e_first.device = 'desktop' THEN 'Desktop'
            ELSE 'Other'
        END AS device_segment,

        COUNT(DISTINCT a.user_id) AS users,

        COUNT(DISTINCT CASE
            WHEN ev.event_type = 'purchase'
            THEN a.user_id
        END) AS converters

    FROM experiment a

    LEFT JOIN event e_first
        ON a.user_id = e_first.user_id
       AND e_first.event_type = 'page_view'

    LEFT JOIN event ev
        ON a.user_id = ev.user_id
       AND ev.event_type = 'purchase'

    WHERE a.experiment_id = 'checkout_redesign_v2'

    GROUP BY a.variant, device_segment
)

SELECT
    device_segment,
    variant,
    users,
    converters,
    ROUND(converters * 100.0 / NULLIF(users, 0), 2) AS conversion_rate_pct
FROM segment_results
ORDER BY device_segment, variant;
--- Daily Conversion Trend (Novelty Effect)---
WITH daily_conversion AS (
    SELECT
        a.variant,
        DATE(a.assigned_at) AS day,

        COUNT(DISTINCT a.user_id) AS users,

        COUNT(DISTINCT CASE
            WHEN e.event_type = 'purchase'
            THEN a.user_id
        END) AS converters

    FROM experiment a

    LEFT JOIN event e
        ON a.user_id = e.user_id
       AND e.event_type = 'purchase'

    WHERE a.experiment_id = 'checkout_redesign_v2'

    GROUP BY
        a.variant,
        DATE(a.assigned_at)
)

SELECT
    day,
    variant,
    ROUND(converters * 100.0 / NULLIF(users, 0), 2)
        AS daily_conversion_rate
FROM daily_conversion
ORDER BY day, variant;