USE Front;

-- Запросы к базе Front.
-- Описание запросов есть в отчете front-tables.md.

-- 1.1. Документы закупки по годам.
-- По справочнику это DocumentTypeID = 4.
-- Считает количество документов и сумму по годам.
SELECT YEAR(Period) AS y,
  COUNT(*) AS documents,
  SUM(Amount) AS amount
FROM bm_JournalBarnetDocs
WHERE DocumentTypeID = 4
GROUP BY YEAR(Period)
ORDER BY y;


-- 1.3. Топ поставщиков по сумме закупок.
-- Этот же запрос есть в разделе 3.
SELECT TOP 10
  s.VendorID,
  v.firstname AS vendor_name,
  COUNT(*) AS lines,
  SUM(s.Amount) AS amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
LEFT JOIN vendors v ON v.id = s.VendorID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
GROUP BY s.VendorID, v.firstname
ORDER BY amount DESC;


-- 2.3. Топ товаров по выручке.
-- 501 и 111 не входят в выручку, это итог чека и списание по себестоимости.
SELECT TOP 20
  j.id,
  j.description,
  SUM(j.quantity) AS quantity,
  SUM(j.amount) AS revenue
FROM journal j
WHERE j.transtype = 101
GROUP BY j.id, j.description
ORDER BY revenue DESC;


-- 4.4. Продажи по логинам.
-- Все строки на 906 ("Доставка").
SELECT loginid,
  COUNT(*) AS lines,
  SUM(amount) AS revenue
FROM journal
WHERE transtype = 101
GROUP BY loginid
ORDER BY lines DESC;


-- 4.5. Кто создавал документы.
-- 906 - 46 400 документов, 897 - 8132.
SELECT d.PersonID,
  p.lastname,
  p.firstname,
  COUNT(*) AS documents,
  MIN(d.Period) AS first_date,
  MAX(d.Period) AS last_date
FROM bm_JournalBarnetDocs d
LEFT JOIN personnel p ON p.personid = d.PersonID
GROUP BY d.PersonID, p.lastname, p.firstname
ORDER BY documents DESC;


-- 5.2. Остатки по продуктам с учетом единицы измерения.
-- Самые большие минусы - вода, мука, сыр.
SELECT TOP 20
  p.id,
  p.description AS product_name,
  s.RangeID,
  sz.description AS unit,
  SUM(s.Count) AS rest
FROM bm_StorageOperations s
JOIN product p ON p.id = s.ProductID
LEFT JOIN size sz ON sz.ID = s.RangeID
GROUP BY p.id, p.description, s.RangeID, sz.description
ORDER BY rest ASC;
