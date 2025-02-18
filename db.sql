CREATE SCHEMA IF NOT EXISTS zalygin;
DO $$
BEGIN
    RAISE NOTICE 'Запускаем создание новой структуры базы данных meteo';
    ALTER TABLE IF EXISTS zalygin.measurment_input_params
        DROP CONSTRAINT IF EXISTS measurment_type_id_fk;
    ALTER TABLE IF EXISTS zalygin.employees
        DROP CONSTRAINT IF EXISTS military_rank_id_fk;
    ALTER TABLE IF EXISTS zalygin.measurment_baths
        DROP CONSTRAINT IF EXISTS measurment_input_param_id_fk;
    ALTER TABLE IF EXISTS zalygin.measurment_baths
        DROP CONSTRAINT IF EXISTS emploee_id_fk;
    DROP TABLE IF EXISTS zalygin.measurment_input_params;
    DROP TABLE IF EXISTS zalygin.measurment_baths;
    DROP TABLE IF EXISTS zalygin.employees;
    DROP TABLE IF EXISTS zalygin.measurment_types;
    DROP TABLE IF EXISTS zalygin.military_ranks;
    DROP TABLE IF EXISTS zalygin.temperature;
    DROP TABLE IF EXISTS zalygin.calc_temperatures_correction;
    DROP SEQUENCE IF EXISTS zalygin.measurment_input_params_seq;
    DROP SEQUENCE IF EXISTS zalygin.measurment_baths_seq;
    DROP SEQUENCE IF EXISTS zalygin.employees_seq;
    DROP SEQUENCE IF EXISTS zalygin.military_ranks_seq;
    DROP SEQUENCE IF EXISTS zalygin.measurment_types_seq;
    RAISE NOTICE 'Удаление старых данных выполнено успешно';
    CREATE TABLE zalygin.military_ranks (
        id INTEGER PRIMARY KEY NOT NULL,
        description VARCHAR(255)
    );
    INSERT INTO zalygin.military_ranks (id, description)
        VALUES (1, 'Рядовой'), (2, 'Лейтенант');
    CREATE SEQUENCE zalygin.military_ranks_seq START 3;
    ALTER TABLE zalygin.military_ranks
        ALTER COLUMN id SET DEFAULT nextval('zalygin.military_ranks_seq');
    CREATE TABLE zalygin.employees (
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT,
        birthday TIMESTAMP,
        military_rank_id INTEGER
    );
    INSERT INTO zalygin.employees (id, name, birthday, military_rank_id)
        VALUES (1, 'Воловиков Александр Сергеевич', '1978-06-24', 2);
    CREATE SEQUENCE zalygin.employees_seq START 2;
    ALTER TABLE zalygin.employees
        ALTER COLUMN id SET DEFAULT nextval('zalygin.employees_seq');
    CREATE TABLE zalygin.measurment_types (
        id INTEGER PRIMARY KEY NOT NULL,
        short_name VARCHAR(50),
        description TEXT
    );
    INSERT INTO zalygin.measurment_types (id, short_name, description)
        VALUES (1, 'ДМК', 'Десантный метео комплекс'),
               (2, 'ВР', 'Ветровое ружье');
    CREATE SEQUENCE zalygin.measurment_types_seq START 3;
    ALTER TABLE zalygin.measurment_types
        ALTER COLUMN id SET DEFAULT nextval('zalygin.measurment_types_seq');
    CREATE TABLE zalygin.measurment_input_params (
        id INTEGER PRIMARY KEY NOT NULL,
        measurment_type_id INTEGER NOT NULL,
        height NUMERIC(8,2) DEFAULT 0,
        temperature NUMERIC(8,2) DEFAULT 0,
        pressure NUMERIC(8,2) DEFAULT 0,
        wind_direction NUMERIC(8,2) DEFAULT 0,
        wind_speed NUMERIC(8,2) DEFAULT 0
    );
    INSERT INTO zalygin.measurment_input_params (id, measurment_type_id, height, temperature, pressure, wind_direction, wind_speed)
        VALUES (1, 1, 100, 12, 34, 0.2, 45);
    CREATE SEQUENCE zalygin.measurment_input_params_seq START 2;
    ALTER TABLE zalygin.measurment_input_params
        ALTER COLUMN id SET DEFAULT nextval('zalygin.measurment_input_params_seq');
    CREATE TABLE zalygin.measurment_baths (
        id INTEGER PRIMARY KEY NOT NULL,
        emploee_id INTEGER NOT NULL,
        measurment_input_param_id INTEGER NOT NULL,
        started TIMESTAMP DEFAULT now()
    );
    INSERT INTO zalygin.measurment_baths (id, emploee_id, measurment_input_param_id)
        VALUES (1, 1, 1);
    CREATE SEQUENCE zalygin.measurment_baths_seq START 2;
    ALTER TABLE zalygin.measurment_baths
        ALTER COLUMN id SET DEFAULT nextval('zalygin.measurment_baths_seq');
    RAISE NOTICE 'Создание общих справочников и наполнение выполнено успешно';
    CREATE TABLE IF NOT EXISTS zalygin.calc_temperatures_correction (
        temperature NUMERIC(8,2) PRIMARY KEY,
        correction NUMERIC(8,2)
    );
    INSERT INTO zalygin.calc_temperatures_correction (temperature, correction)
        VALUES (0, 0.5), (5, 0.5), (10, 1), (20, 1), (25, 2), (30, 3.5), (40, 4.5);
    DROP TYPE IF EXISTS zalygin.interpolation_type;
    CREATE TYPE zalygin.interpolation_type AS (
        x0 NUMERIC(8,2),
        x1 NUMERIC(8,2),
        y0 NUMERIC(8,2),
        y1 NUMERIC(8,2)
    );
    RAISE NOTICE 'Расчетные структуры сформированы';
    BEGIN
        ALTER TABLE zalygin.measurment_baths
            ADD CONSTRAINT emploee_id_fk FOREIGN KEY (emploee_id)
            REFERENCES zalygin.employees (id);
        ALTER TABLE zalygin.measurment_baths
            ADD CONSTRAINT measurment_input_param_id_fk FOREIGN KEY (measurment_input_param_id)
            REFERENCES zalygin.measurment_input_params (id);
        ALTER TABLE zalygin.measurment_input_params
            ADD CONSTRAINT measurment_type_id_fk FOREIGN KEY (measurment_type_id)
            REFERENCES zalygin.measurment_types (id);
        ALTER TABLE zalygin.employees
            ADD CONSTRAINT military_rank_id_fk FOREIGN KEY (military_rank_id)
            REFERENCES zalygin.military_ranks (id);
    END;
    RAISE NOTICE 'Связи сформированы';
    RAISE NOTICE 'Структура сформирована успешно';
END
$$;
DROP TABLE IF EXISTS zalygin.measure_settings;
DROP TABLE IF EXISTS zalygin.constants;
CREATE TABLE IF NOT EXISTS zalygin.constants (
    key VARCHAR(30) NOT NULL COLLATE pg_catalog."default",
    value TEXT NOT NULL COLLATE pg_catalog."default"
) TABLESPACE pg_default;
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_key
    ON zalygin.constants USING btree (key COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
CREATE TABLE IF NOT EXISTS zalygin.measure_settings (
    param VARCHAR(50) NOT NULL,
    min_value NUMERIC NOT NULL,
    max_value NUMERIC NOT NULL,
    unit VARCHAR(20) NOT NULL
);
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM zalygin.measure_settings) >= 3 THEN
        RAISE NOTICE 'Данные уже добавлены';
    ELSE
        INSERT INTO zalygin.measure_settings (param, min_value, max_value, unit)
            VALUES
                ('Высота метеопоста', -10000, 10000, 'м'),
                ('Температура', -58, 58, '°C'),
                ('Давление', 500, 900, 'мм рт. ст.'),
                ('Направление ветра', 0, 59, '°'),
                ('Скорость ветра', 0, 15, 'м/c'),
                ('Дальность сноса пуль', 0, 150, 'м');
        RAISE NOTICE 'Данные добавлены успешно';
    END IF;
END
$$;
DROP TYPE IF EXISTS zalygin.measure_type CASCADE;
CREATE TYPE zalygin.measure_type AS (
    param NUMERIC
);
CREATE OR REPLACE FUNCTION zalygin.get_measure_setting(type_param VARCHAR, value_param NUMERIC)
RETURNS zalygin.measure_type AS $$
DECLARE
    mn_value NUMERIC;
    mx_value NUMERIC;
    result zalygin.measure_type;
BEGIN
    SELECT min_value, max_value
      INTO mn_value, mx_value
      FROM zalygin.measure_settings
     WHERE param = type_param;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Параметр % не найден', type_param;
    END IF;
    IF value_param < mn_value OR value_param > mx_value THEN
        RAISE EXCEPTION 'Входные данные % не входят в диапазон [% - %]', value_param, mn_value, mx_value;
    END IF;
    result.param := value_param;
    RETURN result;
END;
$$ LANGUAGE plpgsql;
DROP FUNCTION IF EXISTS zalygin."fnHeaderGetPresure"();
DROP FUNCTION IF EXISTS zalygin."fnHeaderGetData"();
DROP FUNCTION IF EXISTS zalygin."fnHeaderGetHeight"();
CREATE OR REPLACE FUNCTION zalygin."fnHeaderGetPresure"(pressure NUMERIC, temperature NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
COST 100
VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result NUMERIC;
    txt TEXT;
    results NUMERIC;
    int_res INTEGER;
BEGIN
    SELECT value::NUMERIC
      INTO var_result
      FROM zalygin.constants
     WHERE key = 'const_pressure';
    results := pressure - var_result;
    int_res := results::INTEGER;
    IF int_res > 0 THEN
        txt := LPAD(int_res::TEXT, 3, '0');
    ELSE
        int_res := abs(int_res);
        txt := '5' || LPAD(int_res::TEXT, 2, '0');
    END IF;
    RETURN txt;
END;
$$;
CREATE OR REPLACE FUNCTION zalygin."fnHeaderGetData"()
RETURNS TEXT
LANGUAGE plpgsql
COST 100
VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result TEXT;
BEGIN
    var_result := TO_CHAR(NOW(), 'DDHH') || LEFT(TO_CHAR(NOW(), 'MI'), 1);
    RETURN var_result;
END;
$$;
CREATE OR REPLACE FUNCTION zalygin."fnHeaderGetHeight"(height INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
COST 100
VOLATILE PARALLEL UNSAFE
AS $$
DECLARE
    var_result TEXT;
BEGIN
    var_result := LPAD(height::TEXT, 4, '0');
    RAISE NOTICE 'Результат: %', var_result;
    RETURN var_result;
END;
$$;
CREATE OR REPLACE FUNCTION zalygin.interpolate_correction(temp_input NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    interp_data zalygin.interpolation_type;
    correction_result NUMERIC;
BEGIN
    SELECT correction
      INTO correction_result
      FROM zalygin.calc_temperatures_correction
     WHERE temperature = temp_input;
    IF FOUND THEN
        RETURN correction_result;
    END IF;
    SELECT t1.temperature AS x0, t2.temperature AS x1,
           t1.correction AS y0, t2.correction AS y1
      INTO interp_data
      FROM (
            SELECT temperature, correction
              FROM zalygin.calc_temperatures_correction
             WHERE temperature <= temp_input
             ORDER BY temperature DESC
             LIMIT 1
           ) AS t1,
           (
            SELECT temperature, correction
              FROM zalygin.calc_temperatures_correction
             WHERE temperature >= temp_input
             ORDER BY temperature ASC
             LIMIT 1
           ) AS t2;
    IF interp_data.x0 IS NULL OR interp_data.x1 IS NULL THEN
        RETURN NULL;
    END IF;
    correction_result := interp_data.y0 +
        (interp_data.y1 - interp_data.y0) * (temp_input - interp_data.x0) /
        (interp_data.x1 - interp_data.x0);
    RETURN correction_result;
END;
$$ LANGUAGE plpgsql;
SELECT zalygin."fnHeaderGetPresure"(730, 23);
SELECT zalygin."fnHeaderGetData"();
SELECT zalygin."fnHeaderGetHeight"(10);
SELECT * FROM zalygin.calc_temperatures_correction;
SELECT zalygin.interpolate_correction(23);
INSERT INTO zalygin.employees (id, name, birthday, military_rank_id)
    VALUES
        (2, 'Иванов Иван Иванович', '1985-03-15', 1),
        (3, 'Петров Петр Петрович', '1990-07-10', 2),
        (4, 'Сидоров Александр Александрович', '1982-09-23', 1),
        (5, 'Кузнецов Дмитрий Дмитриевич', '1992-01-05', 2);
DO $$
DECLARE
    user_id INTEGER;
    measurment_type_id INTEGER;
    param_id INTEGER;
BEGIN
    FOR user_id IN 1..5 LOOP
        FOR measurment_type_id IN 1..2 LOOP
            FOR i IN 1..100 LOOP
                INSERT INTO zalygin.measurment_input_params (
                    measurment_type_id,
                    height,
                    temperature,
                    pressure,
                    wind_direction,
                    wind_speed
                )
                VALUES (
                    measurment_type_id,
                    100 + (random() * 400),
                    20 + (random() * 10),
                    1010 + (random() * 20),
                    random() * 360,
                    random() * 15
                )
                RETURNING id INTO param_id;
                INSERT INTO zalygin.measurment_baths (
                    emploee_id,
                    measurment_input_param_id,
                    started
                )
                VALUES (
                    user_id,
                    param_id,
                    NOW() - (random() * INTERVAL '30 days')
                );
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;
SELECT * FROM zalygin.measurment_baths;