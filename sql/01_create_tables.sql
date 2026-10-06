-- создаю таблицы

-- Основная таблица: один фильм = одна строка. Колонки из списков 1 и 2
CREATE TABLE IF NOT EXISTS movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    status TEXT,
    release_date DATE,
    runtime INTEGER,
    budget BIGINT,
    revenue BIGINT,
    certification_us TEXT,
    imdb_rating NUMERIC(3,1),
    imdb_votes INTEGER,
    vote_count INTEGER,
    director TEXT,
    writers TEXT,
    original_language TEXT,
    production_countries TEXT,
    imdb_id TEXT
);

-- Справочник жанров: каждый жанр записан один раз
CREATE TABLE IF NOT EXISTS genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name TEXT UNIQUE
);

-- Связь многие-ко-многим: какому фильму какие жанры соответствуют
CREATE TABLE IF NOT EXISTS movie_genres (
    movie_id INTEGER REFERENCES movies(id),
    genre_id INTEGER REFERENCES genres(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);