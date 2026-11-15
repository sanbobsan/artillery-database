USE Front;

-- ============================================================
-- 0. Общие таблицы
-- ============================================================

-- 0.1. Шапки документов.
-- Колонки: ID, DocumentTypeID, Period, Amount, PersonID, TicketNumber.
-- DocumentTypeID - тип документа, Period - дата, Amount - сумма.
SELECT TOP 10 *
FROM bm_JournalBarnetDocs
ORDER BY ID;


-- 0.2. Справочник журналов и типов документов.
-- Получается связка: журнал -> вид документа.
-- Например, 4 - поступление продуктов, 5 - списание, 6 - товарный чек.
SELECT *
FROM bm_JournalType
ORDER BY ID;
SELECT *
FROM bm_JournalTypeDocuments
ORDER BY ID;

-- Например, складской учет - 3
SELECT *
FROM bm_JournalTypeDocuments
WHERE JournalID = 3;


-- 0.3. Складские операции.
-- Колонки: DocumentID, OperationID, ProductID, VendorID, Count, Price, Amount.
-- Count и Amount со знаком: приход плюс, расход минус.
SELECT TOP 10 *
FROM bm_StorageOperations
ORDER BY ID;
SELECT TOP 10 *
FROM bm_StorageOperations
ORDER BY ID DESC;


-- 0.4. Типы складских операций.
-- 1 - поступление, 2 - списание, 3 - инвентаризация, 4 - перемещение, 5 - возврат.
-- В данных встречаются только 1 и 2.
SELECT *
FROM bm_StorageOperationsType
ORDER BY ID;


-- 0.5. Расшифровка продажи по ингредиентам.
-- SourceID - это transnumber из journal.
-- BludoID - проданное блюдо, ProductID - ингредиент.
-- sBrutto - вес в граммах, Count - уже в килограммах.
SELECT TOP 10 *
FROM bm_Journal_Details
ORDER BY ID;


-- 0.6. Журнал транзакций.
-- Колонки: transnumber, transtype, receiptn, dater, id, quantity, price, amount, loginid.
SELECT TOP 30 *
FROM journal
ORDER BY transnumber;


-- 0.7. Типы транзакций.
-- 101 - продажа товара, 211 - наличные, 301 - логин, 111 - списание,
-- 501 - итог чека, 386 и 387 - открытие и закрытие смены.
SELECT *
FROM transtype
ORDER BY transtypeid;


-- 0.8. Способы оплаты.
SELECT *
FROM paymenttype
ORDER BY paymenttypeid;


-- 0.9. Продукты.
-- productid - артикул
-- CategoryID ссылается на category.id.
SELECT TOP 20 *
FROM product
ORDER BY id;


-- 0.10. Категории.
-- Тут дерево: ParentID указывает на родительскую категорию.
SELECT TOP 30 *
FROM category
ORDER BY id;


-- 0.11. Поставщики.
-- Название лежит в firstname, lastname почти везде пустой
SELECT TOP 20 *
FROM vendors
ORDER BY id;


-- 0.12. Сотрудники.
-- Роли: 2 Clerk, 3 Manager/Adm, 4 Bartender, 9 Special Access.
-- Роли 1 нет, хотя она стоит у 102 сотрудников.
SELECT TOP 20 *
FROM personnel
ORDER BY personid;

SELECT *
FROM securityaccess;

-- 0.13. Склады.
-- В базе один склад (id = 41).
SELECT TOP 10 *
FROM storages;


-- 0.14. Количество строк в основных таблицах.
-- объемы journal, документов, деталей, складских операций.
SELECT 'journal' AS table_name, COUNT(*) AS rows_count FROM journal
UNION ALL
SELECT 'bm_JournalBarnetDocs', COUNT(*) FROM bm_JournalBarnetDocs
UNION ALL
SELECT 'bm_Journal_Details', COUNT(*) FROM bm_Journal_Details
UNION ALL
SELECT 'bm_StorageOperations', COUNT(*) FROM bm_StorageOperations
UNION ALL
SELECT 'bm_JournalSessions', COUNT(*) FROM bm_JournalSessions
UNION ALL
SELECT 'product', COUNT(*) FROM product
UNION ALL
SELECT 'category', COUNT(*) FROM category
UNION ALL
SELECT 'vendors', COUNT(*) FROM vendors
UNION ALL
SELECT 'personnel', COUNT(*) FROM personnel
UNION ALL
SELECT 'storages', COUNT(*) FROM storages;

-- ============================================================
-- 1. Закупки продукции
-- ============================================================

-- 1.1. Документы закупки по годам.
-- По справочнику это DocumentTypeID = 4.
-- Смотрю, за какие годы они есть и на какую сумму
SELECT YEAR(Period) AS y,
  COUNT(*) AS documents,
  SUM(Amount) AS amount
FROM bm_JournalBarnetDocs
WHERE DocumentTypeID = 4
GROUP BY YEAR(Period)
ORDER BY y;


-- 1.2. Строки закупок.
-- OperationID = 1 - поступление.
SELECT COUNT(*) AS lines,
  COUNT(DISTINCT s.DocumentID) AS documents,
  SUM(s.Count) AS quantity,
  SUM(s.Amount) AS amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
WHERE s.OperationID = 1 AND d.DocumentTypeID = 4;


-- 1.3. Топ поставщиков по сумме закупок.
-- 21 поставщик, "Пятая Армия" - 9.84 млн из 19.66 млн.
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


-- 1.4. Топ продуктов по сумме закупок.
SELECT TOP 10
  p.id,
  p.description AS product_name,
  SUM(s.Count) AS quantity,
  SUM(s.Amount) AS amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
JOIN product p ON p.id = s.ProductID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
GROUP BY p.id, p.description
ORDER BY amount DESC;


-- 1.5. История закупочной цены для сыра.
SELECT d.Period,
  s.Price,
  s.Count,
  s.Amount,
  v.firstname AS vendor_name
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
JOIN product p ON p.id = s.ProductID
LEFT JOIN vendors v ON v.id = s.VendorID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
  AND p.description = 'Сыр Голландский, моцарелла'
ORDER BY d.Period DESC;


-- 1.6. Проверяю, что сумма в шапке документа совпадает с суммой строк.
-- Если запрос ничего не вернул, значит все нормально.
SELECT d.ID,
  d.Amount AS document_amount,
  SUM(s.Amount) AS lines_amount
FROM bm_JournalBarnetDocs d
JOIN bm_StorageOperations s ON s.DocumentID = d.ID
WHERE d.DocumentTypeID = 4
GROUP BY d.ID, d.Amount
HAVING ABS(d.Amount - SUM(s.Amount)) > 0.5;


-- 1.7. Есть ли документы закупки без строк.
SELECT COUNT(*) AS documents_without_lines
FROM bm_JournalBarnetDocs d
LEFT JOIN bm_StorageOperations s ON s.DocumentID = d.ID
WHERE d.DocumentTypeID = 4
  AND s.DocumentID IS NULL;

-- 1.8. Есть ли строки закупки без поставщика.
SELECT COUNT(*) AS lines_without_vendor
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
  AND (s.VendorID IS NULL OR s.VendorID = 0);


-- 1.9. Цена умножить на количество должна давать сумму строки.
-- Одно расхождение - 702.30.
-- Есть небольшие расхождение - вероятно округления.
SELECT COUNT(*) AS lines_with_bad_amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
  AND ABS(s.Price * s.Count - s.Amount) > 1;

SELECT
  s.ID,
  s.DocumentID,
  p.description AS product_name,
  s.Price,
  s.Count,
  s.Amount,
  (s.Price * s.Count - s.Amount) AS diff
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
JOIN product p ON p.id = s.ProductID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
  AND ABS(s.Price * s.Count - s.Amount) > 1
ORDER BY diff DESC;

-- ============================================================
-- 2. Продажи товара
-- ============================================================

-- 2.1. Общая выручка.
-- Беру только transtype = 101.
-- 501 - это итог чека, если сложить 101 и 501, сумма задвоится.
SELECT COUNT(*) AS lines,
  COUNT(DISTINCT receiptn) AS receipts,
  SUM(amount) AS revenue
FROM journal
WHERE transtype = 101;


-- 2.2. Продажи по годам.
SELECT YEAR(dater) AS y,
  COUNT(DISTINCT receiptn) AS receipts,
  COUNT(*) AS lines,
  SUM(amount) AS revenue
FROM journal
WHERE transtype = 101
GROUP BY YEAR(dater)
ORDER BY y;


-- 2.3. Топ товаров по выручке.
SELECT TOP 20
  j.id,
  j.description,
  SUM(j.quantity) AS quantity,
  SUM(j.amount) AS revenue
FROM journal j
WHERE j.transtype = 101
GROUP BY j.id, j.description
ORDER BY revenue DESC;


-- 2.4. Выручка по категориям.
-- journal.id - артикул, join идет через product.productid, хотя FK нет.
SELECT TOP 20
  c.description AS category_name,
  SUM(j.amount) AS revenue
FROM journal j
JOIN product p ON p.productid = j.id
JOIN category c ON c.id = p.CategoryID
WHERE j.transtype = 101
GROUP BY c.description
ORDER BY revenue DESC;


-- 2.5. Возвраты.
-- У возвратов flagrefund = 1 и отрицательное количество.
SELECT COUNT(*) AS refund_lines,
  SUM(amount) AS refund_amount
FROM journal
WHERE transtype = 101
  AND flagrefund = 1;

SELECT COUNT(*) AS negative_quantity_lines
FROM journal
WHERE transtype = 101
  AND quantity < 0;


-- 2.6. Оплаты.
-- 211 - наличные, 216 - безнал; остальные способы в journal не встречаются
SELECT j.transtype,
  pt.description,
  COUNT(*) AS lines,
  SUM(j.amount) AS amount
FROM journal j
JOIN paymenttype pt ON pt.paymenttypeid = j.transtype
WHERE j.transtype IN (211, 216)
GROUP BY j.transtype, pt.description
ORDER BY amount DESC;


-- 2.7. Средний чек.
-- Сворачиваю 501 по чеку, чтобы дубль Total не влиял на среднее.
SELECT AVG(total) AS avg_check
FROM (
  SELECT receiptn, SUM(amount) AS total
  FROM journal
  WHERE transtype = 501
  GROUP BY receiptn
) t;
-- 952.38 рублей

-- 2.8. Проверяю чеки, где строка Total встречается больше одного раза.
SELECT TOP 10
  receiptn,
  COUNT(*) AS total_rows
FROM journal
WHERE transtype = 501
GROUP BY receiptn
HAVING COUNT(*) > 1
ORDER BY total_rows DESC;


-- 2.9. Что лежит в деталях продаж.
-- Состав блюд: BludoID - блюдо, ProductID - ингредиент.
SELECT COUNT(*) AS lines,
  COUNT(DISTINCT SourceID) AS sales_lines,
  COUNT(DISTINCT BludoID) AS dishes,
  COUNT(DISTINCT ProductID) AS ingredients
FROM bm_Journal_Details;


-- 2.10. Пример состава блюда.
SELECT TOP 20
  d.BludoID,
  b.description AS dish,
  p.description AS ingredient,
  d.sBrutto,
  d.Count
FROM bm_Journal_Details d
JOIN product b ON b.id = d.BludoID
JOIN product p ON p.id = d.ProductID
ORDER BY d.ID;


-- 2.11. Документы продаж (товарные чеки).
-- 43 586 документов типа 6, 42 869 уникальных чеков, 174 чека продаж
SELECT COUNT(*) AS documents,
  MIN(Period) AS first_date,
  MAX(Period) AS last_date,
  SUM(Amount) AS amount
FROM bm_JournalBarnetDocs
WHERE DocumentTypeID = 6;


-- 2.12. Скидки.
-- discountamount - сумма скидки, discount - процент.
SELECT COUNT(*) AS lines_with_discount,
  SUM(discountamount) AS discount_amount
FROM journal
WHERE transtype = 101
  AND discountamount <> 0;


-- Сверка 101 / 501 / 111.
-- 501 больше 101 на 562.8 тыс.
-- 1978 чеков только с 501
-- Их сумма 570.9 тыс. совпадает с transtype = 111 - это списания по себестоимости
SELECT
  (SELECT COUNT(*) FROM journal WHERE transtype = 101) AS sales_lines,
  (SELECT COUNT(DISTINCT receiptn) FROM journal WHERE transtype = 101) AS sales_receipts,
  (SELECT SUM(amount) FROM journal WHERE transtype = 101) AS sales_amount,
  (SELECT COUNT(*) FROM journal WHERE transtype = 501) AS total_rows,
  (SELECT COUNT(DISTINCT receiptn) FROM journal WHERE transtype = 501) AS total_receipts,
  (SELECT SUM(amount) FROM journal WHERE transtype = 501) AS total_amount,
  (SELECT COUNT(*) FROM journal j
   WHERE j.transtype = 501
     AND NOT EXISTS (
      SELECT 1 FROM journal s
      WHERE s.transtype = 101 AND s.receiptn = j.receiptn)) AS total_only_receipts,
  (SELECT SUM(j.amount) FROM journal j
   WHERE j.transtype = 501
     AND NOT EXISTS (
      SELECT 1 FROM journal s
      WHERE s.transtype = 101 AND s.receiptn = j.receiptn)) AS total_only_amount,
  (SELECT SUM(amount) FROM journal WHERE transtype = 111) AS writeoff_amount;


-- ============================================================
-- 3. Взаимоотношения с поставщиками
-- ============================================================

-- 3.1. Справочник поставщиков.
SELECT id,
  clientid,
  firstname,
  clientgroup,
  IsUse
FROM vendors
ORDER BY id;

-- 3.2. Группы поставщиков.
SELECT *
FROM vendorgroup;

SELECT clientgroup,
  COUNT(*) AS vendors
FROM vendors
GROUP BY clientgroup
ORDER BY vendors DESC;


-- 3.3. Кто из поставщиков реально встречается в закупках.
-- 21 поставщик. "Пятая Армия" - 9.84 млн из 19.66 млн.
SELECT s.VendorID,
  v.firstname AS vendor_name,
  COUNT(*) AS lines,
  COUNT(DISTINCT s.DocumentID) AS documents,
  SUM(s.Amount) AS amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
LEFT JOIN vendors v ON v.id = s.VendorID
WHERE s.OperationID = 1
  AND d.DocumentTypeID = 4
GROUP BY s.VendorID, v.firstname
ORDER BY amount DESC;

-- 3.4. Насколько заполнены реквизиты поставщиков.
-- ИНН - 5 из 63. Телефонов, контактов и email нет.
SELECT COUNT(*) AS vendors_total,
  SUM(CASE WHEN INN IS NOT NULL AND INN <> '' THEN 1 ELSE 0 END) AS with_inn,
  SUM(CASE WHEN contactperson IS NOT NULL AND contactperson <> '' THEN 1 ELSE 0 END) AS with_contact,
  SUM(CASE WHEN teln IS NOT NULL AND teln <> '' THEN 1 ELSE 0 END) AS with_phone,
  SUM(CASE WHEN emaliaddress IS NOT NULL AND emaliaddress <> '' THEN 1 ELSE 0 END) AS with_email
FROM vendors;

-- 3.5. Связь товара с поставщиком.
-- В product есть vendorid, но он почти везде 0.
-- Единственный товар с vendorid <> 0 - бананы, поставщик "Овощи Сатурн".
SELECT SUM(CASE WHEN vendorid = 0 THEN 1 ELSE 0 END) AS vendor_zero,
  SUM(CASE WHEN vendorid <> 0 THEN 1 ELSE 0 END) AS vendor_set,
  COUNT(*) AS products_total
FROM product;

SELECT v.firstname, p.description
FROM product p
LEFT JOIN vendors v ON v.id = p.vendorid
WHERE vendorid != 0;


-- 3.6. Поставщик в прайс-листе.
-- Все 24 797 строк без vendorid, группы groupid = 1 (закупочная) нет.
SELECT COUNT(*) AS rows_total,
  SUM(CASE WHEN vendorid IS NULL OR vendorid = 0 THEN 1 ELSE 0 END) AS without_vendor,
  SUM(CASE WHEN basecost > 0 THEN 1 ELSE 0 END) AS with_price
FROM pricelist;


-- 3.7. Розничные цены из прайс-листа.
-- groupid = 2 - розничная цена.
SELECT TOP 20
  p.description AS product_name,
  pr.basecost AS price
FROM pricelist pr
JOIN product p ON p.id = pr.productid
WHERE pr.groupid = 2
ORDER BY pr.id DESC;

-- ============================================================
-- 4. Работа персонала
-- ============================================================

-- 4.1. Сотрудники.
-- У всех 109 записей deleteflag = 1.
SELECT personid,
  lastname,
  firstname,
  middlename,
  securityaccess,
  deleteflag
FROM personnel
ORDER BY personid;


-- 4.2. Роли.
-- 102 / 2 / 5; роль 1 без описания в securityaccess.
SELECT p.securityaccess,
  s.description,
  COUNT(*) AS persons
FROM personnel p
LEFT JOIN securityaccess s ON s.securityaccessid = p.securityaccess
GROUP BY p.securityaccess, s.description
ORDER BY persons DESC;

SELECT *
FROM securityaccess;

-- 4.3. Кто вообще встречается в journal.
SELECT loginid,
  COUNT(*) AS rows_count,
  MIN(dater) AS first_date,
  MAX(dater) AS last_date
FROM journal
GROUP BY loginid
ORDER BY rows_count DESC;


-- 4.4. Кто из сотрудников продавал.
SELECT loginid,
  COUNT(*) AS lines,
  SUM(amount) AS revenue
FROM journal
WHERE transtype = 101
GROUP BY loginid;
-- Только доставка

--  4.5. Кто создавал документы.
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


-- 4.6. Смены.
-- 386 - открытие смены, 387 - закрытие
SELECT loginid,
  transtype,
  COUNT(*) AS events,
  MIN(dater) AS first_date,
  MAX(dater) AS last_date
FROM journal
WHERE transtype IN (386, 387)
GROUP BY loginid, transtype
ORDER BY loginid, transtype;


-- 4.7. Активность в журнале сессий по типам.
-- Большинство ошибок - с пустым Type.
SELECT Type,
  COUNT(*) AS events,
  SUM(CASE WHEN IsError = 1 THEN 1 ELSE 0 END) AS errors
FROM bm_JournalSessions
GROUP BY Type
ORDER BY events DESC;


-- 4.8. Частые ошибки в сессиях.
-- Основная масса - таймауты.
SELECT TOP 20
  Type,
  Message,
  COUNT(*) AS events
FROM bm_JournalSessions
WHERE IsError = 1
GROUP BY Type, Message
ORDER BY events DESC;

-- 4.9 Права доступа сотрудников к объектам программы.
SELECT TOP 20
  ps.PersonID,
  p.lastname,
  p.firstname,
  COUNT(*) AS permissions
FROM bm_PersonnelSecurity ps
LEFT JOIN personnel p ON p.personid = ps.PersonID
WHERE ps.IsUse = 1
GROUP BY ps.PersonID, p.lastname, p.firstname
ORDER BY permissions DESC;

-- ============================================================
-- 5. Остатки
-- ============================================================

-- 5.1. Приход и расход по складу.
-- приход 20.0 млн, списание -86.1 млн, итог -66.1 млн.
SELECT OperationID,
  COUNT(*) AS lines,
  COUNT(DISTINCT ProductID) AS products,
  SUM(Amount) AS amount
FROM bm_StorageOperations
GROUP BY OperationID
ORDER BY lines DESC;


-- 5.2. Остатки по продуктам с учетом единицы измерения.
-- верхние отрицательные - вода, мука, сыр
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

-- Есть группы и с положительным остатком.
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
ORDER BY rest DESC;


-- 5.3. Сколько групп продукт + единица с отрицательным остатком
-- 308 из 485 групп отрицательные
SELECT COUNT(*) AS groups_total,
  SUM(CASE WHEN rest < 0 THEN 1 ELSE 0 END) AS negative_groups
FROM (
  SELECT ProductID, RangeID, SUM(Count) AS rest
  FROM bm_StorageOperations
  GROUP BY ProductID, RangeID
) t;

SELECT COUNT(*) AS products_with_negative_group
FROM (
  SELECT ProductID
  FROM (
    SELECT ProductID, RangeID, SUM(Count) AS rest
    FROM bm_StorageOperations
    GROUP BY ProductID, RangeID
  ) g
  GROUP BY ProductID
  HAVING MIN(rest) < 0
) p;


-- 5.4. Остатки по складам: количество товаров и денежная сумма.
SELECT s.StorageID,
  st.description AS storage_name,
  COUNT(DISTINCT s.ProductID) AS products,
  SUM(s.Amount) AS amount
FROM bm_StorageOperations s
LEFT JOIN storages st ON st.id = s.StorageID
GROUP BY s.StorageID, st.description
ORDER BY amount ASC;
-- Склад всего один.

-- 5.5. Обороты по месяцам в деньгах
SELECT YEAR(d.Period) AS y,
  MONTH(d.Period) AS m,
  SUM(CASE WHEN s.Count > 0 THEN s.Amount ELSE 0 END) AS income_amount,
  SUM(CASE WHEN s.Count < 0 THEN -s.Amount ELSE 0 END) AS outcome_amount
FROM bm_StorageOperations s
JOIN bm_JournalBarnetDocs d ON d.ID = s.DocumentID
GROUP BY YEAR(d.Period), MONTH(d.Period)
ORDER BY y, m;


-- 5.6. Какие поля в складских операциях вообще заполняются
-- Quantity, Rest и PriceCost везде 0, то есть они не используются.
SELECT
  SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS quantity_zero,
  SUM(CASE WHEN Rest = 0 THEN 1 ELSE 0 END) AS rest_zero,
  SUM(CASE WHEN PriceCost = 0 THEN 1 ELSE 0 END) AS cost_zero,
  COUNT(*) AS lines_total
FROM bm_StorageOperations;


-- 5.7. В базе есть вторая складская таблица.
SELECT COUNT(*) AS matched_rows
FROM bm_StorageOperations_Table t
WHERE EXISTS (
  SELECT 1
  FROM bm_StorageOperations s
  WHERE 
    s.DocumentID = t.DocumentID
    AND s.ProductID = t.ProductID
    AND s.Count = t.Count
    AND s.Amount = t.Amount
);


-- 5.8. Инвентаризация.
-- Документ всего один и с нулевым количеством
SELECT TOP 10 *
FROM bm_JournalBarnetDocs
WHERE DocumentTypeID = 8;


-- 5.9. Старая таблица остатков.
SELECT TOP 10 *
FROM stockperiod;
-- Данные в ней за 2015 год


-- 5.10. Причины списаний.
-- ReasonID = 0 - 978 381 из 1 009 182 строк
-- причины заполнены у ручных списаний
SELECT s.ReasonID,
  r.Description AS reason_name,
  COUNT(*) AS lines,
  SUM(s.Count) AS quantity
FROM bm_StorageOperations s
LEFT JOIN bm_ReasonDebit r ON r.ID = s.ReasonID
WHERE s.OperationID = 2
GROUP BY s.ReasonID, r.Description
ORDER BY lines DESC;
