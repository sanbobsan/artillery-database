DO $$
BEGIN
    -- Проверка нахождения параметров температуры для интерполяции в одном промежутке
    ASSERT calc.get_temperature_interpolation_params(12.0) = calc.get_temperature_interpolation_params(14.0),
    'Ошибка: Параметры 12.0 и 14.0 должны возвращать одни и те же параметры'; -- зависит от версии бд, так как значения в таблице являются частью версии бд
    
    -- Проверка нахождения параметров температуры для интерполяции с переполнением
    ASSERT calc.get_temperature_interpolation_params(50.0) = calc.get_temperature_interpolation_params(44.0),
    'Ошибка: Параметры 50.0 и 44.0 должны возвращать одни и те же параметры'; -- зависит от версии бд, так как значения в таблице являются частью версии бд

    -- Проверка того, что готовая функция для подсчета температуры совпадает с расчетом температуры с помощью функции линейной интерполяции
    ASSERT calc.calculate_interpolation(25.0, calc.get_temperature_interpolation_params(25.0)) = calc.calculate_temperature_correction(25.0),
    'Ошибка: функция расчета температуры не совпадает с расчетом интерполяции для заданных параметров';

    -- Точное попадание (25 -> поправка 2.0)
    ASSERT calc.calculate_temperature_correction(25.0) = 2.00, 
    'Ошибка: Точное попадание в 25';

    -- В интервале (13 -> поправка 1.0)
    ASSERT calc.calculate_temperature_correction(13.0) = 1.00, 
    'Ошибка: В интервале 10-15 (13)';

    -- В интервале между (27.5 -> поправка 2.75)
    ASSERT calc.calculate_temperature_correction(27.5) = 2.75, 
    'Ошибка: В интервале 25-30 (27.5)';

    -- Выход за нижнюю границу (-10.0 -> поправка 0.0)
    ASSERT calc.calculate_temperature_correction(-10.0) = 0.0, 
    'Ошибка: Выход за нижнюю границу в -10';

    -- Выход за верхнюю границу (40.0 -> поправка 4.5)
    ASSERT calc.calculate_temperature_correction(45.0) = 4.5, 
    'Ошибка: Выход за верхнюю границу в 45';
END $$;