-- Проверяю, что созданы три таблицы
-- ожидаемо: genres, movie_genres, movies
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- Проверяю загрузку: число строк в movies и пропуски в certification_us
SELECT count(*) FROM movies; -- ожидаемо 1 250 553 (версия датасета 1015)
SELECT count(*) FROM movies WHERE certification_us IS NULL; -- результат 1 157 266 (версия датасета 1015)
SELECT count(*) FROM movies WHERE certification_us = '';  -- должно быть 0: пропуски хранятся как NULL

-- Доля фильмов с ненулевыми бюджетом и сборами на полном датасете (в процентах)
-- ожидаемо: total 1 250 553; with_budget 85 138 (6,8%); with_revenue 28 814 (2,3%); with_both 18 751 (1,5%)
SELECT
    count(*) AS total,
    count(*) FILTER (WHERE budget > 0) AS with_budget,
    count(*) FILTER (WHERE revenue > 0) AS with_revenue,
    count(*) FILTER (WHERE budget > 0 AND revenue > 0) AS with_both,
    round(100.0 * count(*) FILTER (WHERE budget > 0) / count(*), 1) AS pct_budget,
    round(100.0 * count(*) FILTER (WHERE revenue > 0) / count(*), 1) AS pct_revenue,
    round(100.0 * count(*) FILTER (WHERE budget > 0 AND revenue > 0) / count(*), 1) AS pct_both
FROM movies;

-- Какие значения бывают в status
-- ожидаемо: Released = 1 226 755 (первая строка)
SELECT status, count(*) FROM movies GROUP BY status ORDER BY 2 DESC;

-- Жанры и число фильмов в каждом
-- ожидаемо: 19 строк, первая Drama 307 958
SELECT g.genre_name, count(*) AS movies_cnt
FROM movie_genres mg
JOIN genres g ON g.genre_id = mg.genre_id
GROUP BY g.genre_name
ORDER BY movies_cnt DESC;

-- ===== Этап 3: выбор порогов очистки =====

-- тип колонки release_date
SELECT data_type FROM information_schema.columns
WHERE table_name = 'movies' AND column_name = 'release_date' AND table_schema = 'public';
-- результат: date

-- Сколько фильмов с бюджетом и сборами по годам релиза
-- проверено: все годы 2000-2024 на месте, сумма за 2000-2024 = 10 873
-- в конце строка NULL: 1 472 фильма без release_date
-- 2025 (1 000) и 2026 (652) исключены: сборы неполные
SELECT EXTRACT(YEAR FROM release_date) AS year, count(*) AS cnt
FROM movies
WHERE status = 'Released' AND budget > 0 AND revenue > 0
GROUP BY 1
ORDER BY 1;

-- Квантили бюджета, сборов и числа голосов IMDb среди таких фильмов
-- ожидаемо: медиана бюджета 3 млн, сборов 2,4 млн; 5% квантиль голосов 46, 25% около 2 900
SELECT
    percentile_cont(ARRAY[0.01, 0.05, 0.5, 0.95]) WITHIN GROUP (ORDER BY budget) AS budget_q,
    percentile_cont(ARRAY[0.01, 0.05, 0.5, 0.95]) WITHIN GROUP (ORDER BY revenue) AS revenue_q,
    percentile_cont(ARRAY[0.05, 0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY imdb_votes) AS votes_q
FROM movies
WHERE status = 'Released' AND budget > 0 AND revenue > 0;

-- Минимальные бюджет и сборы среди фильмов с budget > 0 и revenue > 0
-- ожидаемо: оба равны 1
SELECT min(budget), min(revenue)
FROM movies
WHERE status = 'Released' AND budget > 0 AND revenue > 0;

-- Воронка порогов: сколько фильмов остаётся после каждого фильтра
-- ожидаемо: 10 873 / 8 443 / 7 004
SELECT
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 2000 AND 2024) AS by_year,
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 2000 AND 2024
                     AND budget >= 10000 AND revenue >= 1000) AS by_money,
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 2000 AND 2024
                     AND budget >= 10000 AND revenue >= 1000
                     AND imdb_votes >= 1000) AS by_votes
FROM movies
WHERE status = 'Released' AND budget > 0 AND revenue > 0;

-- Выбор диапазона лет для v_rating_movies (гипотеза 1): сколько фильмов при разных границах
-- результат: y2000_2024 - 34 076, y1990_2024 - 39 087,  y2000_2026 - 36 153, all_years - 53 377

SELECT
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 2000 AND 2024) AS y2000_2024,
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 1990 AND 2024) AS y1990_2024,
    count(*) FILTER (WHERE EXTRACT(YEAR FROM release_date) BETWEEN 2000 AND 2026) AS y2000_2026,
    count(*) AS all_years
FROM movies
WHERE status = 'Released'
  AND runtime >= 60
  AND imdb_rating IS NOT NULL
  AND imdb_votes >= 1000;