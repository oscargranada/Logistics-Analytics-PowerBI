# Trench Logistics - Analytics Dashboard

## Introducción
Este proyecto simula los retos de una empresa ficticia de logística, **Trench Logistics**, que busca mejorar la eficiencia de sus entregas y reducir penalidades.  

El objetivo fue realizar un análisis **end-to-end**:
1. Generación y limpieza de datos en **MySQL**.  
2. Modelado y visualización en **Power BI**.  
3. Obtención de **insights accionables** y recomendaciones de negocio.  

---

## 🗂️ Datos
Se diseñaron tres datasets ficticios para el análisis:  

- **Clientes.csv** → Información de clientes, centro de distribución, tipo y descuentos.  
- **Ordenes.csv** → Pedidos con fechas de solicitud/entrega, peso, volumen.  
- **Tarifas.csv** → Costos por distrito y kg.  

Los datos fueron cargados en **MySQL**, donde se realizó limpieza, validación de consistencia y creación de campos derivados (ej. días de entrega, status final, penalidades).

---

## Preparación de datos (SQL)
Ejemplo de consulta en MySQL para calcular métricas clave:  

```sql
SELECT
o.id_pedido AS 'ID Pedido',
o.fecha_solicitud AS 'Fecha Solicitud',
c.nombre_cliente AS 'Nombre Cliente',
t.distrito AS 'Distrito',
o.peso AS 'Peso (kg)',
o.volumen AS 'Volumen (m3)',
o.fecha_entrega AS 'Fecha de entrega',
DATEDIFF(fecha_entrega, fecha_solicitud) AS 'Días de entrega',
CASE
WHEN DATEDIFF(fecha_entrega, fecha_solicitud) = 0 THEN 'Entregado express'
WHEN DATEDIFF(fecha_entrega, fecha_solicitud) BETWEEN 1 AND 2 THEN 'Entregado a tiempo'
ELSE 'Demorado'
END AS 'Status final'
FROM ordenes AS o
LEFT JOIN clientes AS c ON o.id_cliente = c.id_cliente
LEFT JOIN tarifas AS t ON c.id_distrito = t.id_distrito
ORDER BY fecha_solicitud;

```


📂 Ver el archivo completo de SQL en [`/sql/data_preparation.sql`](./sql/data_preparation.sql)  

---

## Análisis en Power BI
Se construyó un dashboard interactivo con las siguientes secciones:  

### KPIs principales
- **OTIF % (On Time In Full)**  
- **Días promedio de entrega**  
- **Costo promedio por pedido**  
- **% de entregas express**  
- **Penalidades totales**

### Visualizaciones destacadas
- **Barras apiladas** → Pedidos entregados express, a tiempo y demorados por mes.  
- **Línea de tendencia** → % OTIF en el tiempo.  
- **Mapa** → Costo total por distrito.  
- **Dispersión** → Peso vs. Volumen, identificando clusters de pedidos.  
- **Burbujas** → Margen vs. Peso con tamaño por costo operativo (eficiencia de pedidos).  
- **Tabla dinámica** → Ranking de clientes clave.  

Ejemplo de medida en **DAX** usada en Power BI:  

```
OTIF % =
DIVIDE(
COUNTROWS(FILTER(Ordenes, Ordenes[Status final] IN {"Entregado a tiempo", "Entregado express"})),
COUNTROWS(Ordenes),
0
)
```

--

## 📌 Insights clave
1. **60% de las penalidades** corresponden al **20% de órdenes más demoradas**.  
2. Se identifican **dos clusters** de pedidos por peso/volumen → recomendar tarifas diferenciadas.  
3. Distritos como **Arequipa y Chiclayo** presentan **bajo cumplimiento de entregas**.  
4. Pedidos pequeños (<5 kg) generan **bajo margen** pero consumen gran capacidad operativa.  

---

## 🔗 Demo interactivo  

[![Ver Dashboard](./images/dashboard_preview.png)](https://app.powerbi.com/view?r=eyJrIjoiMGQ5YTlhZWEtMDYwMy00NTI4LTgzM2QtNTYwMDY0MDA5M2EzIiwidCI6ImM1YjVkZjc0LWI1NWMtNDE4NS05MjQ5LWFhMjU0YzFlNjBkOCIsImMiOjR9&pageName=3f2e19b32d58d65655ff)

## Autor
**Oscar Granada Navarro**  
Industrial Engineer | Data Analyst | SQL & Power BI  

🔗 [LinkedIn](https://www.linkedin.com/in/oscargranada/)  
📧 [Email](mailto:ing.oscar,granada@gmail.com)  
