-- Motor utilizado: SQL Server (SSMS)
-- =====================================================================
-- Proyecto: RetailPro · M4 — Consultas SQL de negocio
-- Base de datos: Ventas_Tech_DB (creada en M3 con ventas_tech_db.sql)
-- Alcance: solo tabla ventas (id_cliente, id_producto, cantidad,
--          precio_unitario, fecha_venta). Los nombres de productos y
--          clientes se incorporan con JOIN en el Módulo 5.
-- Facturación de cada venta = cantidad * precio_unitario
-- =====================================================================

USE Ventas_Tech_DB;
GO


-- === CONSULTA 1: RESUMEN EJECUTIVO MENSUAL ===
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- Se agrupa también por año para que, cuando haya más de un año de datos,
-- marzo 2024 y marzo 2025 no se mezclen en la misma fila.
-- Resultado esperado con los datos de M3: 1 fila (marzo 2024).
SELECT
    YEAR(fecha_venta)                                        AS anio,
    MONTH(fecha_venta)                                       AS mes,
    SUM(cantidad * precio_unitario)                          AS total_facturado,
    COUNT(*)                                                 AS cantidad_pedidos,
    CAST(SUM(cantidad * precio_unitario) / COUNT(*)
         AS DECIMAL(10,2))                                   AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;
GO


-- === CONSULTA 2: RANKING DE PRODUCTOS (TOP 5) ===
-- Los 5 productos que más facturaron, con sus unidades vendidas.
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
GO


-- === CONSULTA 3: CLIENTES RECURRENTES ===
-- Clientes con más de un pedido, con su cantidad de pedidos y total gastado.
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
GO


-- === CONSULTA 4: PRODUCTOS POR ENCIMA / POR DEBAJO DEL PROMEDIO ===
-- Paso 1 (CTE): total facturado por producto.
-- Paso 2 (subconsulta): promedio de ESOS totales por producto,
--         no el promedio de las filas de ventas.
WITH totales_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    CAST((SELECT AVG(total_facturado) FROM totales_por_producto)
         AS DECIMAL(10,2))                                   AS promedio_por_producto,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM totales_por_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END                                                      AS comparacion_promedio
FROM totales_por_producto
ORDER BY total_facturado DESC;
GO


-- =====================================================================
-- HALLAZGOS
-- =====================================================================
-- 1. Concentración en pocos productos: el producto 1 facturó 3.600 de un
--    total de 6.444 (55,9%). Junto con el producto 3 suman 4.950 (76,8%).
--    Son los únicos 2 de 6 productos por encima del promedio por producto
--    (1.074), así que una caída en cualquiera de los dos afectaría a casi
--    toda la facturación.
--
-- 2. Volumen no es igual a facturación: el producto 2 es el más vendido en
--    unidades (13, más que el triple que cualquier otro), pero apenas
--    facturó 364 (5,6% del total) por su precio unitario de 28. Medir el
--    desempeño solo por unidades daría una imagen equivocada del negocio.
--
-- 3. Recurrencia total pero con gasto desigual: los 5 clientes hicieron
--    2 pedidos cada uno (100% de recurrencia), pero los clientes 1 (2.640)
--    y 5 (2.100) concentran el 73,6% del gasto, mientras que el cliente 4
--    gastó solo 510. La frecuencia de compra no explica el valor del
--    cliente: lo explica qué productos compra.
--
-- Nota: con 10 ventas de un solo mes, estos hallazgos son indicativos.
-- Con más períodos se podrá medir la evolución mensual (Consulta 1).
-- =====================================================================
