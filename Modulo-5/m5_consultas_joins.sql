-- Motor utilizado: SQL Server (SSMS)
-- =====================================================================
-- Proyecto: RetailPro · M5 — Consultas con JOINs
-- Base de datos: Ventas_Tech_DB (versión 2 de ventas_tech_db.sql,
--                con la tabla territorios y la columna clientes.segmento)
-- Total de cada venta = cantidad * precio_unitario
-- =====================================================================

USE Ventas_Tech_DB;
GO


-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: reunir en una sola fila cada venta con su cliente, producto,
-- categoría y región. Es la fuente de datos principal para Power BI:
-- region y nombre_categoria sirven para agrupar; segmento, para filtrar.
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                              AS cliente,
    c.segmento,
    c.ciudad,
    t.region,
    p.nombre_producto                     AS producto,
    cat.nombre_categoria                  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario        AS total_venta
FROM ventas AS v
INNER JOIN clientes    AS c   ON c.id_cliente     = v.id_cliente
INNER JOIN productos   AS p   ON p.id_producto    = v.id_producto
INNER JOIN categorias  AS cat ON cat.id_categoria = p.id_categoria
INNER JOIN territorios AS t   ON t.id_territorio  = v.id_territorio
ORDER BY v.fecha_venta, v.id_venta;
GO
-- Hallazgo: las 10 ventas se cruzan completas (10 filas), sin datos perdidos en los JOIN.
-- La región Centro concentra el 59,5% de la facturación (3.834 de 6.444) y Computación el 76,8%.


-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que CRM los contacte.
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v ON v.id_cliente = c.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;
GO
-- Hallazgo: 0 de los 5 clientes registrados nunca compraron; todos tienen al menos 2 pedidos.
-- CRM no necesita una campaña de activación: el foco está en subir el gasto de clientes como el 4 (510).


-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento, para que el área de producto revise su continuidad.
SELECT
    p.nombre_producto,
    cat.nombre_categoria   AS categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS cat ON cat.id_categoria = p.id_categoria
LEFT JOIN ventas AS v        ON v.id_producto    = p.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.precio DESC;
GO
-- Hallazgo: 0 de los 6 productos del catálogo quedaron sin ventas; todo el catálogo tuvo movimiento.
-- Producto no tiene artículos para discontinuar, aunque Auriculares BT Pro (360) y Teclado Mecánico (380) son los que menos facturan.


-- Consulta 4: Consolidado por semana (UNION ALL)
-- Propósito: comparar la facturación de las dos semanas con ventas de marzo 2024
-- (lunes 4 a domingo 10, y lunes 11 a domingo 17).
-- La columna origen no existe en las tablas: se crea como texto fijo en cada SELECT.
-- Se usa UNION ALL para que ninguna venta se descarte aunque coincida en todos sus valores con otra.
SELECT
    origen,
    COUNT(*)     AS cantidad_ventas,
    SUM(total)   AS total_origen
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Semana 4-10 mar' AS origen
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-04' AND '2024-03-10'
    UNION ALL
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Semana 11-17 mar' AS origen
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-11' AND '2024-03-17'
) AS consolidado
GROUP BY origen
ORDER BY total_origen DESC;
GO
-- Hallazgo: la semana del 4 al 10 facturó 3.620 y la del 11 al 17, 2.824: una caída del 22% con 5 ventas en cada una.
-- La diferencia la explica una sola venta: 2 Laptop Pro 15 (2.400) el 5 de marzo.
