-- Фильмы для анализа окупаемости: вышедшие 2000-2024, с ненулевыми бюджетом и сборами, достаточным числом голосов
-- основа для гипотез 2-5 (окупаемость)
CREATE OR REPLACE VIEW v_roi_movies AS
SELECT
    id,
    title,
    release_date,
    EXTRACT(MONTH FROM release_date) AS release_month,
    runtime,
    budget,
    revenue,
    revenue::numeric / budget AS roi,
    certification_us,
    imdb_rating,
    imdb_votes
FROM movies
WHERE status = 'Released' -- только вышедшие, без анонсов и отмен
  AND release_date BETWEEN '2000-01-01' AND '2024-12-31' -- современная эпоха; 2025-2026 исключены: сборы неполные
  AND budget >= 10000 -- минимум бюджета равен 1: это ошибки данных, не реальные бюджеты
  AND revenue >= 1000 -- аналогично для сборов, порог мягкий
  AND imdb_votes >= 1000;	-- рейтинг по малому числу голосов ненадёжен

-- ожидаемо: 7 004
SELECT count(*) FROM v_roi_movies;

-- Фильмы для гипотезы 1 (длительность и рейтинг): 2000-2024, без бюджета и сборов
CREATE OR REPLACE VIEW v_rating_movies AS
SELECT 
	id, 
	title, 
	release_date, 
	runtime, 
	imdb_rating, 
	imdb_votes
FROM movies
WHERE status = 'Released' -- только вышедшие
	AND release_date BETWEEN '2000-01-01' AND '2024-12-31' -- та же эпоха, что в v_roi_movies
	AND runtime >= 60 -- длительностью более часа, осекаею короткометражки
	AND imdb_rating IS NOT NULL -- без рейтинга фильм для гипотезы 1 бесполезен
	AND imdb_votes >= 1000; -- рейтинг по малому числу голосов ненадёжен

SELECT count(*) FROM v_rating_movies

	