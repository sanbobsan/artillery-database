-- DDL Data Definition Language
DROP TABLE military_ranks CASCADE;
DROP TABLE employees CASCADE;
DROP TABLE equipment_types CASCADE;
DROP TABLE parameter_types CASCADE;
DROP TABLE units CASCADE;
DROP TABLE measurements CASCADE;
DROP TABLE measurements_buckets CASCADE;
DROP TABLE unit_conversions CASCADE;

-- Звания
CREATE TABLE military_ranks (
    "id" INT PRIMARY KEY,
    "title" VARCHAR(100) UNIQUE NOT NULL
); 

-- Работники
CREATE TABLE employees (
    "id" INT PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL,
    "surname" VARCHAR(100) NOT NULL,
    "rank_id" INT
);

-- Типы оборудования для измерений
CREATE TABLE equipment_types (
    "id" INT PRIMARY KEY,
    "title" VARCHAR(100) NOT NULL UNIQUE,
    "abbreviation" VARCHAR(20) NOT NULL UNIQUE
);

-- Типы параметров, возможные параметры без единиц измерения
CREATE TABLE parameter_types (
    "id" INT PRIMARY KEY,
    "title" VARCHAR(100) UNIQUE NOT NULL
);

-- Единицы измерения
CREATE TABLE units (
    "id" INT PRIMARY KEY,
    "title" VARCHAR(100) UNIQUE NOT NULL,
    "abbreviation" VARCHAR(20) NOT NULL UNIQUE
);

-- Параметры с единицами измерения, не хранит измерения
CREATE TABLE parameters (
    "id" INT PRIMARY KEY,
    "parameter_type_id" INT NOT NULL,
    "unit_id" INT NOT NULL
    -- Можно сделать primary key комбинацию из айди параметров и айди единиц измерения
);

-- Измерения
CREATE TABLE measurements (
    "id" INT PRIMARY KEY,
    "measurements_bucket_id" INT NOT NULL,
    "equipment_type_id" INT NOT NULL, -- Можно перенести в параметры, чтобы уточнять в них оборудование, которое нужно для измерения
    "parameter_id" INT NOT NULL,
    "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Возможно, стоит перенести в пачки измерений, потому что в приложении не подразумеваются отдельные измерения
    "value" DECIMAL(10, 0) NOT NULL
);

-- Пачки измерений
CREATE TABLE measurements_buckets (
    "id" INT PRIMARY KEY,
    "employee_id" INT NOT NULL
);

-- Таблица для перевода единиц измерения
CREATE TABLE unit_conversions (
    "id" INT PRIMARY KEY,
    -- parameter_type_id INT NOT NULL, -- Можно добавить для проверки типа параметра
    "from_unit_id" INT NOT NULL,
    "to_unit_id" INT NOT NULL,
    "from_value" DECIMAL(10, 0),
    "to_value" DECIMAL(10, 0)
    -- Можно сделать primary key комбинацию из айди начальных и конечных единиц измерения
);