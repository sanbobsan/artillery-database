SELECT 
    m.created_at AS "Дата измерения",
    m.measurements_bucket_id AS "Номер пачки",
    e.surname || ' ' || e.name AS "ФИО сотрудника",
    pt.title || ' (' || u.abbreviation || ')' AS "Наименование параметра",
    m.value AS "Значение"
FROM measurements m
JOIN measurements_buckets mb ON mb.id = m.measurements_bucket_id
JOIN employees e ON e.id = mb.employee_id
JOIN parameters p ON p.id = m.parameter_id
JOIN parameter_types pt ON pt.id = p.parameter_type_id
JOIN units u ON u.id = p.unit_id
ORDER BY m.measurements_bucket_id;