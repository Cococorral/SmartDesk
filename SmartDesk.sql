-- Tablas a disposición 

SELECT * FROM sales;
SELECT * FROM forecasts;
SELECT * FROM accounts;


-- EJERCICIOS


-- Ejercicio 1


SELECT category,                                         -- Selección de las columnas especificadas por el ejercicio.
       SUM (units_sold) AS total_units_sold,             
       SUM (total) AS total_sum_$,                           -- Estas tres columnas incluyen la función de agregación 'SUM' que calculará la suma de las filas de las columnas 
       SUM (profit) AS total_profit_$,                       -- escritas.
       AVG (profit) AS average_profit                    -- Esta columna incluye una función de agregación 'AVG' que nos calculará el promedio del 'beneficio' 
FROM sales                                               -- Tabla de donde vamos a seleccionar esas columnas.
WHERE account = 'Abbot Industries' AND year = 2020       -- Filtro con 'WHERE' para seleccionar la cuenta y el año deseados.
GROUP BY category;                                       -- Agrupación de los resultados por 'categoría'



-- Ejercicio 2 


SELECT f.category,                                              -- Especificación con 'f.' para determinar de que tabla queremos que la query seleccione esa columna.
       quarter, 
       SUM (forecast) AS total_forecast, 
       SUM (profit) AS total_profit, 
       MIN (opportunity_age) AS minimum_opportunity_age,        -- Uso de función de agregación 'MIN', que nos calcula el mínimo de los datos de la columna seleccionada.
       MAX (opportunity_age) AS maximum_opportunity_age         -- Uso de función de agregación 'MAX', que nos calcula el máximo de los datos de la columna seleccionada.
FROM forecasts AS f JOIN sales AS s                             -- Utilización de 'FULL JOIN' para la recuperación de todas las filas de ambas tablas involucradas en la consulta.
ON f.account = s.account                                        -- 'ON' es parte del 'JOIN' y determina la columna en común entre ambas tablas.
WHERE quarter = '2020 Q1' OR quarter = '2021 Q3'
GROUP BY f.category, quarter
ORDER BY 1;                                                     -- Uso de 'ORDER BY' para ordenar los resultados de la query en función de la primera columna seleccionada.




-- Ejercicio 3 


SELECT industry, 
       country, 
       SUM (product) AS sum_product_$, 
       SUM (parts) AS sum_parts_$, 
       SUM (maintenance) AS sum_maintenance_$, 
       SUM (support) AS sum_support_$, 
       SUM (units_sold) AS sum_units_sold_$, 
       SUM (total) AS sum_total_$, 
       SUM (profit) AS sum_profit_$, 
       MAX (profit) AS max_profit_$, 
       AVG (profit) AS avg_profit_$
FROM sales AS s JOIN accounts AS a
ON s.account = a.account
WHERE region = 'APAC' OR region = 'EMEA'
GROUP BY industry, country
ORDER BY AVG (profit) DESC;                            -- En este ejercicio ordenamos los resultados en función de la media de beneficio de forma descendente, es decir, las 
                                                       -- combinaciones industria/pais que más beneficio generen de media serán las primeras e ira descendiendo progresivamente.



-- Ejercicio 4  


SELECT industry, 
       a.account, 
       SUM(product) AS sum_product_$, 
       SUM(parts) AS sum_parts_$,
       SUM(maintenance) AS sum_maintenance_$,
       SUM(support) AS sum_support_$, 
       SUM(units_sold) AS sum_units_sold_$, 
       SUM(profit) AS sum_profit_$, 
CASE WHEN SUM (profit) > 1000000 THEN 'Alto' ELSE 'Normal' END AS profit_level           -- La cláusula 'CASE' nos sirve para crear una condición y llevar a cabo una acción en 
FROM accounts AS a                                                                       -- función de si se cumple o no.
JOIN sales AS s ON a.account = s.account
WHERE a.account IN (                                                                     -- Uso de subconsulta no correlacionada 'WHERE' ya que se lleva a cabo independientemente
    SELECT f.account                                                                     -- de la consulta principal
    FROM forecasts AS f 
    GROUP BY f.account
    HAVING SUM (forecast) > 500000)                                                      -- Uso de 'HAVING' como filtro debido a que es sobre una función de agregación.
GROUP BY industry, a.account
ORDER BY 1;



-- Ejercicio 5

SELECT DISTINCT industry, 
                quarter_of_year,
                SUM (profit) OVER(PARTITION BY quarter_of_year ORDER BY quarter_of_year) AS total_profit_quarter_of_year,                 -- Uso de funciones de ventana para hacer 
                SUM (profit) OVER(PARTITION BY industry ORDER BY quarter_of_year) AS cumulative_profit_quarter_of_year_industry,          -- un cálculo sobre determinadas filas.
                SUM (profit) OVER(PARTITION BY industry ORDER BY industry) AS total_profit_industry,
                SUM (forecast) OVER(ORDER BY industry) AS cumulative_forecast_industry,
                MIN (opportunity_age) OVER(PARTITION BY industry, quarter_of_year) AS min_opportunity_age_quarter_of_year_industry,       -- Empleo de funciones ventana para 
                MAX (opportunity_age) OVER(PARTITION BY industry, quarter_of_year) AS max_opportunity_age_quarter_of_year_industry        -- calcular datos acumulativos
FROM sales AS s 
JOIN accounts AS a ON s.account = a.account
JOIN forecasts AS f ON s.account = f.account
ORDER BY industry ASC, quarter_of_year;


















-- Caso práctico


-- Análisis de los datos a tratar. Vemos los ejecutivos de cuentas y su desempeño para cada año.


SELECT year, account_executive, SUM (profit)
FROM accounts AS a JOIN sales AS s
ON s.account = a.account
GROUP BY year, account_executive
ORDER BY 1 DESC, 3 DESC;



-- Vista para calcular la media de los percentiles obtenidos para cada año



CREATE VIEW average_percentiles AS
WITH profit_summary AS (
    SELECT year, SUM(profit) AS total_profit                                  -- Uso de CTE's para obtener resultados intermedios que luego podamos usar en la consulta principal
    FROM accounts AS a 
    JOIN sales AS s ON s.account = a.account
    GROUP BY year, account_executive
),
percentiles AS (
    SELECT year,
           PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY total_profit) AS percentile_40,
           PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_profit) AS percentile_20,
           PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_profit) AS percentile_5
    FROM profit_summary
    GROUP BY year
)
SELECT 
    AVG(percentile_40) AS avg_percentile_40,
    AVG(percentile_20) AS avg_percentile_20,
    AVG(percentile_5) AS avg_percentile_5
FROM percentiles
WHERE year IN (SELECT DISTINCT year FROM percentiles);




-- Vista para obtener los ejecutivos de cuentas que no han generado ningún beneficio


CREATE VIEW executives_with_no_profit AS
SELECT account_executive, SUM(profit) AS total_profit
FROM accounts AS a
LEFT JOIN sales AS s ON a.account = s.account
GROUP BY account_executive
HAVING SUM(profit) IS NULL;



-- Unión de ambas vistas para obtener el conjunto de resultados deseados.


SELECT 
    e.account_executive,
    e.total_profit,
    a.avg_percentile_40,
    a.avg_percentile_20,
    a.avg_percentile_5
FROM executives_with_no_profit AS e JOIN average_percentiles AS a;