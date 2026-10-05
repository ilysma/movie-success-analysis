-- Проверяю, что созданы три таблицы
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Проверяю загрузку: число строк в movies и пропуски в certification_us
SELECT count(*) FROM movies; -- ожидаемо 1 250 553 (версия датасета 1015)
SELECT count(*) FROM movies WHERE certification_us IS NULL;
SELECT count(*) FROM movies WHERE certification_us = '';  -- должно быть 0: пропуски хранятся как NULL

-- Доля фильмов с ненулевыми бюджетом и сборами на полном датасете
SELECT
    count(*) AS total,
    count(*) FILTER (WHERE budget > 0) AS with_budget,
    count(*) FILTER (WHERE revenue > 0) AS with_revenue,
    count(*) FILTER (WHERE budget > 0 AND revenue > 0) AS with_both
FROM movies;

-- Какие значения бывают в status
SELECT status, count(*) FROM movies GROUP BY status ORDER BY 2 DESC;

-- Жанры и число фильмов в каждом
SELECT g.genre_name, count(*) AS movies_cnt
FROM movie_genres mg
JOIN genres g ON g.genre_id = mg.genre_id
GROUP BY g.genre_name
ORDER BY movies_cnt DESC;