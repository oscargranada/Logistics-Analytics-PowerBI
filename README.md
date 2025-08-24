# Logistics-Analytics-PowerBI
End-to-end data analytics project: SQL data preparation + Power BI dashboard for logistics insights (Trench Logistics - fictitious case study)

# 🚚 Trench Logistics - Analytics Dashboard

## 📌 Introducción
Este proyecto simula los retos de una empresa ficticia de logística, **Trench Logistics**, que busca mejorar la eficiencia de sus entregas y reducir penalidades.  
El objetivo fue realizar un análisis end-to-end:
1. Generación y limpieza de datos (SQL).
2. Modelado y visualización en Power BI.
3. Obtención de insights y recomendaciones de negocio.

---

## 🗂️ Datos
- **Clientes.csv** → Información de clientes, tipo y descuentos.  
- **Ordenes.csv** → Pedidos con fechas, pesos y volúmenes.  
- **Tarifas.csv** → Costos por distrito.  

**Preparación**:  
La data fue cargada y limpiada en **MySQL**.  
Ejemplo de cálculo en SQL:  

```sql
DATEDIFF(fecha_entrega, fecha_solicitud) AS 'Días de entrega'

