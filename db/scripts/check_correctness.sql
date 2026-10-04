-- Скрипт для "проверки" корректности данных в базе данных
-- Версия базы данных: 02

-- Перед проверками скрипт специально вставляет неправильные данные,
-- которые он позднее он должен словить. Для реальной проверки нужно убрать это.

BEGIN; -- Начинаем транзакцию

-- Вставляем временные неправильные данные
-- Только в текущую транзакцию, после проверки select запросов мы их сбрасываем: ROLLBACK

-- В одной пачке будут присутствовать измерения и с ДМК и с ВР
INSERT INTO measurements
(measurements_bucket_id, equipment_type_id, parameter_id, "value")
VALUES (1, 1, 6, 100);

-- Добавляем новые пачки, вторая будет пустой
INSERT INTO measurements_buckets
(id, employee_id)
VALUES (7, 1), (8, 1);

-- Добавляем неправильные величины, которые выходят за границы, для первой пачки
INSERT INTO measurements
(measurements_bucket_id, equipment_type_id, parameter_id, "value")
VALUES (7, 1, 1, 101), -- Высота: 101 м
  (7, 1, 2, 1200), -- Температура: 120 *C - неправильная
  (7, 1, 3, 711), -- Давление: 762 мм рт. ст.
  (7, 1, 4, 88), -- Направление ветра: 88 дел. угл. - неправильная
  (7, 1, 5, 20); -- Скорость ветра: 20 м/с - неправильная


------------------------------------------------
-- Запросы для выполнения проверок по заданию --
------------------------------------------------

-- Проверка 1: Каждый пользователь имеет одинаковое количество измерений.
SELECT e.id, name, surname, "count" AS "Количество измерений", title AS "Звание"
FROM employees e
LEFT JOIN (
  -- Выбираем айди сотрудников и считаем сколько измерений они сделали
  SELECT employee_id, COUNT(employee_id)
  FROM (
    SELECT employee_id
    FROM measurements m
    LEFT JOIN measurements_buckets mb ON mb.id = m.measurements_bucket_id
  )
  GROUP BY employee_id
) AS measurements_count ON measurements_count.employee_id = e.id
LEFT JOIN military_ranks mr ON mr.id = e.rank_id;

-- Проверка 2: У нас нет пустых пачек измерения.
-- Создаю временную таблицу, чтобы не дублировать ее в нескольких запросах
-- Выбираем пачки с количеством измерений
CREATE TEMPORARY TABLE measurements_buckets_with_count AS -- measurements buckets with measurements count
SELECT mb.id, COUNT(measurements_bucket_id), mb.employee_id
FROM measurements_buckets mb
LEFT JOIN measurements m ON m.measurements_bucket_id = mb.id
GROUP BY mb.id
ORDER BY mb.id;

SELECT measurements_buckets_with_count.id, "count" AS "Количество измерений в пачке", e.id, e.name, e.surname
FROM measurements_buckets_with_count -- Использую временную таблицу
-- Объединяем с пользователями, чтобы видеть, у кого пустые пачки
LEFT JOIN employees e ON e.id = measurements_buckets_with_count.employee_id
-- Выбираем только пустые пачки
WHERE "count" = 0;

-- Проверка 3: Каждая пачка измерений содержит полное количеситво параметров (5 шт)?
-- То же самое, только проверять нужно не на 0 а на то, что их ровно 5
-- Моя схема не позволяет создавать измерения одного и того же параметра в пачке, поэтому этой проверки хватает, чтобы сказать, что пасчка правильна или нет
SELECT measurements_buckets_with_count.id, "count" AS "Количество измерений в пачке", e.id, e.name, e.surname,
  CASE -- Добавляем столбец с правильностью пачки для наглядности
    WHEN "count" = 5 THEN 'Правильно'
    ELSE 'Неправильно'
  END AS "Правильность пачки"
FROM measurements_buckets_with_count -- Использую временную таблицу
-- Объединяем с пользователями, чтобы видеть, у правильные или неправильные пачки
LEFT JOIN employees e ON e.id = measurements_buckets_with_count.employee_id
-- Сортируем по правильности
ORDER BY "Правильность пачки" DESC, measurements_buckets_with_count.id; -- DESC, чтобы сначала шли правильные

-- Проверка 4: Все значения который сформировал корректны и в рамках нужного нам диаппазонов?
-- Вывожу m.measurements_bucket_id, parameter_id, потому что они образуют PK
SELECT m.measurements_bucket_id, m.parameter_id, m."value", p.min_value, p.max_value,
  CASE -- Добавляем столбец с правильностью измерения
    WHEN m."value" BETWEEN p.min_value AND p.max_value THEN 'Правильно' -- Проверяем ограничения
    WHEN m."value" >= p.min_value AND p.max_value IS NULL THEN 'Правильно' -- Когда ограничения только снизу
    WHEN m."value" <= p.max_value AND p.min_value IS NULL THEN 'Правильно' -- Когда ограничения только сверху
    WHEN p.max_value IS NULL AND p.min_value IS NULL THEN 'Правильно' -- Когда ограничений нет
    ELSE 'Неправильно' -- Ограничения нарушены
  END AS "Правильность измерения"
FROM measurements m
-- Соединяем с параметрами, потому что в них указаны минимальные и максимальные возможные значения
LEFT JOIN parameters p ON p.id = m.parameter_id
-- Сортируем по правильности
ORDER BY "Правильность измерения" DESC, m.measurements_bucket_id, m.parameter_id;

-- Проверка 5: Все единицы измерения верны и корректны по отношению к указанным параметрам?
-- У меня единицы измерения привязаны к типам параметров через таблицу параметров.
-- То есть у меня, при измерениях прописывается параметр, в котором есть тип параметра и единицы измерения.
-- Поэтому для проверки достаточно вывести таблицу параметров, типов параметров и единиц измерения.
SELECT p.id, pt.title, u.title, u.abbreviation
FROM parameters p
LEFT JOIN parameter_types pt ON pt.id = p.parameter_type_id
LEFT JOIN units u ON u.id = p.unit_id;


ROLLBACK; -- Откатываем изменения (неправильные данные)