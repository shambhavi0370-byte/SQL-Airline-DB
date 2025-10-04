-- Q1: Total number of bookings per month

SELECT 
    DATE_TRUNC('month', book_date) AS month,
    COUNT(*) AS total_bookings
FROM bookings
GROUP BY 1
ORDER BY 1;

-- Q2: Top 10 most frequent flight routes

SELECT 
    departure_airport,
    arrival_airport,
    COUNT(*) AS total_flights
FROM flights
GROUP BY departure_airport, arrival_airport
ORDER BY total_flights DESC
LIMIT 10;

-- Q3: Average arrival delay (minutes) by route - Top 10

-- Delay = actual_arrival - scheduled_arrival

SELECT
  f.departure_airport,
  f.arrival_airport,
  ROUND(AVG(EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0), 2) AS avg_arrival_delay_mins,
  COUNT(*) AS flights_count
FROM flights f
WHERE f.actual_arrival IS NOT NULL
GROUP BY f.departure_airport, f.arrival_airport
HAVING COUNT(*) >= 5              -- optional: ensure enough flights per route
ORDER BY avg_arrival_delay_mins DESC
LIMIT 10;

-- Q4B: Revenue by route and fare class (Top 10)

SELECT 
  f.departure_airport,
  f.arrival_airport,
  tf.fare_conditions AS class,
  ROUND(SUM(tf.amount), 2) AS total_revenue
FROM ticket_flights tf
JOIN flights f ON f.flight_id = tf.flight_id
GROUP BY f.departure_airport, f.arrival_airport, tf.fare_conditions
ORDER BY total_revenue DESC
LIMIT 10;

-- Q5: Load factor (occupancy) by fare class

SELECT 
  tf.fare_conditions AS class,
  ROUND(COUNT(bp.boarding_no)::decimal / NULLIF(COUNT(s.seat_no), 0), 2) AS load_factor
FROM ticket_flights tf
JOIN flights f ON f.flight_id = tf.flight_id
LEFT JOIN boarding_passes bp ON bp.ticket_no = tf.ticket_no AND bp.flight_id = tf.flight_id
JOIN seats s ON s.aircraft_code = f.aircraft_code AND s.fare_conditions = tf.fare_conditions
GROUP BY tf.fare_conditions
ORDER BY load_factor DESC;

-- Q6: On-time arrival rate (<= 15 mins late) by route - Top 10

SELECT
  f.departure_airport,
  f.arrival_airport,
  ROUND(
    100.0 * AVG(
      CASE
        WHEN f.actual_arrival IS NOT NULL
             AND EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival)) / 60.0 <= 15
        THEN 1 ELSE 0
      END
    )
  , 2) AS on_time_pct,
  COUNT(*) AS flights_count
FROM flights f
WHERE f.actual_arrival IS NOT NULL
GROUP BY f.departure_airport, f.arrival_airport
HAVING COUNT(*) >= 5   -- ensure enough samples
ORDER BY on_time_pct DESC, flights_count DESC
LIMIT 10;

-- Q7 (by booking): Spend per booking reference

SELECT
  t.book_ref,
  ROUND(SUM(tf.amount), 2) AS booking_spend
FROM tickets t
JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no
GROUP BY t.book_ref
ORDER BY booking_spend DESC
LIMIT 10;

-- Q8: Top 10 most profitable routes by ticket revenue

SELECT 
  f.departure_airport,
  f.arrival_airport,
  ROUND(SUM(tf.amount), 2) AS total_revenue
FROM ticket_flights tf
JOIN flights f ON tf.flight_id = f.flight_id
GROUP BY f.departure_airport, f.arrival_airport
ORDER BY total_revenue DESC
LIMIT 10;
