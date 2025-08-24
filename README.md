# Caso de Estudio – Trench Logistics  
**Análisis de desempeño logístico con SQL y Power BI**  

---

## 1. Contexto del Negocio  
**Trench Logistics** es una empresa dedicada a la distribución de útiles escolares en Lima y principales ciudades.  
Las tarifas actuales se calculan por **peso (kg)**, con ligeras variaciones por distancia.  

La política de entregas es clara:  
- **≤ 48 horas** → Cumplimiento estándar.  
- **3 días** → Penalidad del **5%**.  
- **> 3 días** → Penalidad del **10%**.  

Los ejecutivos identificaron un aumento de penalidades y un margen operativo más bajo de lo esperado.  
Se planteó la necesidad de analizar:  

1. ¿Qué factores generan más penalidades?  
2. ¿Se debe actualizar la estructura tarifaria?  
3. ¿Dónde están los principales puntos críticos de la operación?  

---

## 2. Metodología de análisis (inspirada en Google Analytics Framework)

### 🔎 a) Definir objetivos  
- Reducir penalidades.  
- Evaluar si las tarifas actuales reflejan los costos reales.  
- Detectar focos críticos en entregas y rentabilidad.  

### 📊 b) Recolectar datos  
Se generaron datasets ficticios para simular un escenario realista:  
- **Clientes** → tipo de cliente, centro de distribución, descuentos.  
- **Órdenes** → fecha de solicitud, fecha de entrega, peso, volumen.  
- **Tarifas** → costo por distrito y por kg.  

Los datos fueron cargados en **MySQL** para limpieza y cálculos iniciales.  

### 🧹 c) Procesar y transformar  
Ejemplo de consulta SQL utilizada para calcular días de entrega y clasificar pedidos:  

```sql
SELECT 
    o.id_pedido,
    o.fecha_solicitud,
    c.nombre_cliente,
    t.distrito,
    o.peso,
    o.volumen,
    o.fecha_entrega,
    DATEDIFF(fecha_entrega, fecha_solicitud) AS dias_entrega,
    CASE
        WHEN DATEDIFF(fecha_entrega, fecha_solicitud) = 0 THEN 'Express'
        WHEN DATEDIFF(fecha_entrega, fecha_solicitud) BETWEEN 1 AND 2 THEN 'A tiempo'
        ELSE 'Demorado'
    END AS status_final,
    CASE
        WHEN DATEDIFF(fecha_entrega, fecha_solicitud) = 3 THEN 0.95
        WHEN DATEDIFF(fecha_entrega, fecha_solicitud) > 3 THEN 0.90
        ELSE 1
    END AS factor_penalidad
FROM ordenes AS o
LEFT JOIN clientes AS c ON o.id_cliente = c.id_cliente
LEFT JOIN tarifas AS t ON c.id_distrito = t.id_distrito;
```

Este paso permitió construir una tabla lista para análisis en Power BI.

📈 d) Analizar

Con Power BI se desarrollaron visualizaciones clave:

KPIs: % OTIF, días promedio de entrega, penalidades totales.

Tendencia mensual de entregas (Express / A tiempo / Demorado).

Mapa de costos por distrito.

Dispersión peso vs volumen → para detectar pedidos voluminosos con bajo margen.

Ranking de clientes → rentabilidad y cumplimiento.

Ejemplo de medida en DAX:

```sql
OTIF % = 
DIVIDE(
    COUNTROWS(FILTER(Ordenes, Ordenes[status_final] IN {"A tiempo", "Express"})),
    COUNTROWS(Ordenes),
    0
)

```
📝 e) Conclusiones y recomendaciones
1. Carga voluminosa con baja rentabilidad

Se identificó un aumento en pedidos de gran volumen (m³) que requieren más transporte sin generar ingresos proporcionales.
💡 Recomendación: Implementar una tarifa diferenciada para carga voluminosa, alineada al costo real.

2. Penalidades concentradas en focos críticos

Centros de distribución de Arequipa y Chiclayo no alcanzan el objetivo de 90% OTIF.

El 60% de clientes más rentables presenta retrasos.

El 80% de los distritos clave también incumple tiempos.
💡 Recomendación: Revisar rutas, procesos operativos y evaluar capacitación adicional en estos puntos estratégicos.

3. Impacto esperado

Con estas medidas se busca:

Reducir penalidades recurrentes.

Mejorar márgenes en pedidos voluminosos.

Fortalecer la satisfacción de clientes de alto valor.

4. Demo del Dashboard

🔗 Ver Dashboard en Power BI

5. Autor

Oscar Granada Navarro
Ingeniero Industrial | Analista de Datos | SQL & Power BI

