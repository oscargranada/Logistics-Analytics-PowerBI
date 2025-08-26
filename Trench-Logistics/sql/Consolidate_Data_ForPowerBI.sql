
/* ===============================
   Dataset Final para Power BI
   Proyecto: Análisis Logístico Trench Logistics.
   Objetivo: Unificar y limpiar datos de pedidos, clientes y tarifas,
             calcular métricas clave y clasificar el estado de entrega.
================================= */
WITH pedidos AS (
SELECT 
    -- Identificadores y fechas
    o.id_pedido             AS `ID Pedido`,
    o.fecha_solicitud       AS `Fecha Solicitud`,
    o.id_cliente            AS `ID Cliente`,
    
    -- Información del cliente
    c.nombre_cliente        AS `Nombre Cliente`,
    c.centro_distribucion   AS `Centro de Distribución`,
	t.id_distrito			AS `ID Distrito`,
    t.distrito              AS `Distrito`,
    c.tipo_cliente          AS `Tipo Cliente`,
    

    -- Datos del pedido
    t.tarifa_kg              AS `Tarifa por kg`,
    o.peso                  AS `Peso (kg)`,
    ROUND(t.tarifa_kg  * o.peso ,2)	AS `Facturación`,
    o.volumen               AS `Volumen (m3)`,
    o.fecha_entrega         AS `Fecha de Entrega`,
    

    -- Métricas calculadas
    DATEDIFF(o.fecha_entrega, o.fecha_solicitud) AS `Días de Entrega`,

    -- Clasificación del estado final del pedido
    CASE
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) <=2 
             THEN 'Entrega a tiempo'
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud)= 3
             THEN 'Penalidad 5%'
        ELSE 'Penalidad 10%'
    END AS `Status Orden`,
    
    CASE
        WHEN o.peso >=20
             THEN 'Grande'
        WHEN o.peso >=5
             THEN 'Mediano'
        ELSE 'Pequeño'
    END AS `Tipo de pedido`,
    
    CASE
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) <=2 
             THEN 0
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud)= 3
             THEN ROUND (t.tarifa_kg  * o.peso *0.05,2)
        ELSE ROUND(t.tarifa_kg  * o.peso *0.1,2)
    END AS `Penalidad` 
 
FROM ordenes AS o
LEFT JOIN clientes AS c
       ON o.id_cliente = c.id_cliente
LEFT JOIN tarifas AS t
       ON c.id_distrito = t.id_distrito


)

SELECT *,
ROUND(`Facturación` - `Penalidad`,2)  as `Beneficio Neto`
FROM pedidos
ORDER BY `Fecha Solicitud`;
SET NAMES utf8mb4;

