# Caso de Estudio – Trench Logistics  
**Análisis de desempeño logístico con SQL y Power BI**  

---

Se realizó este proyecto de análisis de eficiencia operativa con data de una empresa ficticia llamada **Trench Logistics**. A continuación veremos el proceso end-to-end desde que se tiene una problemática, hasta que se obtienen los insight clave para llegar a conclusiones acertadas.

## 1. Contexto del Negocio  
**Trench Logistics** es una empresa dedicada a la distribución de útiles escolares en Lima, Arequipa y Chiclayo.  
Las tarifas actuales se calculan por **peso (kg)**, con ligeras variaciones por distancia.  

La política de entregas es clara:  
- **≤ 48 horas**    :    Cumplimiento estándar.  
- **3 días**        :    Reembolso del **5%** de la facturación en compensación por la demora.  
- **> 3 días**      :    Reembolso del **10%** de la facturación en compensación por la demora.  

Los ejecutivos identificaron un aumento de penalidades y un margen operativo más bajo de lo esperado.  
Se planteó la necesidad de analizar:

1. ¿Se debe actualizar la estructura tarifaria?  
2. ¿Dónde están los principales puntos críticos de la operación?  
3. ¿Qué factores generan más penalidades?

---

## 2. Metodología de análisis (basado en Google Analytics Framework)

### a) Definir objetivos
En base a la problemática expuesta por los ejecutivos, se plantearon los siguientes objetivos que se deben alcanzar.

- Evaluar si las tarifas actuales son acorde a la realidad operativa.  
- Detectar focos críticos en entregas y rentabilidad.
- Analizar las penalidades, encontrar indicios o puntos críticos y proponer soluciones.  

### b) Recolectar datos  
Se descargó la siguiente información desde el WMS (Warehouse Management System):

- 📄 [clientes.csv](clientes.csv) → Tipo de cliente, centro de distribución, descuentos. 
- 📄 [ordenes.csv](ordenes.csv) → Fecha de solicitud, fecha de entrega, peso, volumen. 
- 📄 [tarifas.csv](tarifas.csv) → Costo por distrito y por kg.

Los datos fueron cargados en **MySQL** para limpieza y cálculos iniciales.  

## 3. Estructura del proyecto

```plaintext
📂 Trench-Logistics-Analytics
├── 📁 data
│   ├── clientes.csv
│   ├── ordenes.csv
│   └── tarifas.csv
│
├── 📁 sql
│   └── penalidades.sql
│
├── 📁 powerbi
│   └── dashboard_preview.png
│
├── 📁 docs
│   ├── Trench_Logistics.pdf
│   └── README.es.md
│
└── README.md   ← archivo principal del proyecto
```

## 4. Transformación de Datos en MySQL para Power BI

Se cargaron los archivos `clientes.csv`, `ordenes.csv` y `tarifas.csv` en MySQL con el objetivo de realizar limpieza y transformación de datos. Esto permitió estructurar la información de forma óptima para su análisis en Power BI.
Integración de Tablas
Se utilizó un LEFT JOIN tomando como base la tabla ordenes, y se añadió información de clientes y tarifas. Con ello se creó la sub-tabla `pedidos` para realizar una subconsulta luego.

```sql
WITH pedidos AS (
SELECT 
    -- Identificadores y fechas
    o.id_pedido             AS `ID Pedido`,
    o.fecha_solicitud       AS `Fecha Solicitud`,
    o.id_cliente            AS `ID Cliente`,
    
    -- Información del cliente
    c.nombre_cliente        AS `Nombre Cliente`,
    c.centro_distribucion   AS `Centro de Distribución`,
    t.id_distrito           AS `ID Distrito`,
    t.distrito              AS `Distrito`,
    c.tipo_cliente          AS `Tipo Cliente`,
    
    -- Datos del pedido
    t.tarifa_kg             AS `Tarifa por kg`,
    o.peso                  AS `Peso (kg)`,
    ROUND(t.tarifa_kg * o.peso, 2) AS `Facturación`,
    o.volumen               AS `Volumen (m3)`,
    o.fecha_entrega         AS `Fecha de Entrega`,
    
    -- Métricas calculadas
    DATEDIFF(o.fecha_entrega, o.fecha_solicitud) AS `Días de Entrega`,

    -- Clasificación del estado final del pedido
    CASE
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) <= 2 THEN 'Entrega a tiempo'
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) = 3 THEN 'Penalidad 5%'
        ELSE 'Penalidad 10%'
    END AS `Status Orden`,
    
    CASE
        WHEN o.peso >= 20 THEN 'Grande'
        WHEN o.peso >= 5 THEN 'Mediano'
        ELSE 'Pequeño'
    END AS `Tipo de pedido`,
    
    CASE
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) <= 2 THEN 0
        WHEN DATEDIFF(o.fecha_entrega, o.fecha_solicitud) = 3 THEN ROUND(t.tarifa_kg * o.peso * 0.05, 2)
        ELSE ROUND(t.tarifa_kg * o.peso * 0.1, 2)
    END AS `Penalidad`
 
FROM ordenes AS o
LEFT JOIN clientes AS c
       ON o.id_cliente = c.id_cliente
LEFT JOIN tarifas AS t
       ON c.id_distrito = t.id_distrito
)
```


## Cálculo del Beneficio Neto
Una vez generada la tabla `pedidos` con los campos transformados, se calcula el beneficio neto.

```sql
SELECT *,
ROUND(`Facturación` - `Penalidad`,2)  as `Beneficio Neto`
FROM pedidos
ORDER BY `Fecha Solicitud`;
SET NAMES utf8mb4;
```
## Observaciones
- Se utilizó ROUND() para mantener consistencia en los valores monetarios.
- La lógica de penalidad está alineada con políticas de entrega: penalización del 5% si se entrega en 3 días, y del 10% si se excede.
- La clasificación de tamaño de pedido permite segmentar la logística por peso: Pedidos pequeños si pesan menos a 5kg, pedidos medianos si pesan de 5 a 20 kg, y pedidos grandes los mayores a 20 kg.

Finalmente, ejecutamos la consulta, revisamos los resultados y exportamos el resultado en el archivo `Trench_Logistics_data_consolidada.csv`.

### 5. Preparación y modelado de datos en Power BI

Se importó el archivo 📄[Trench_Logistics_data_consolidada.csv](Trench_Logistics_data_consolidada.csv) a Power BI, iniciando el proceso de limpieza y validación en Power Query. Se verificó que todas las columnas contuvieran información completa, sin errores de tipo ni valores nulos, y se aplicaron los formatos adecuados. Esta consulta se denominó `Data pedidos consolidada`

![Imagen](/Screenshots_dashboard/Revision_power_query.png)

Durante la revisión, se identificó que la base incluía información de zonas y distritos por pedido, pero no contaba con coordenadas geográficas (latitud y longitud), necesarias para la visualización en mapas dinámicos. Para resolverlo, se extrajeron las coordenadas oficiales de los distritos desde el portal del INEI y se consolidaron en un archivo auxiliar:

- 📋 [coordenadas.xlsx](coordenadas.xlsx)

Este archivo fue importado a Power BI como la consulta `Coordenadas`, y se realizó una combinación con `Data pedidos consolidada` para incorporar las columnas de `latitud` y `longitud` en la consulta principal.

![Imagen](/Screenshots_dashboard/JOIN_power_query.png)

A continuación, se definieron indicadores clave (KPI) y medidas DAX para facilitar el análisis visual y extraer insights relevantes. A continuación, se detallan las principales transformaciones:

#### a) Columnas:

- **Calculo de entrega en 48 horas**
  
  Clasifica los pedidos según si fueron entregados dentro del plazo establecido
```sql
¿Entrega en 48h? = 
IF('Data pedidos consolidada'[Status Orden] = "Entrega a tiempo", "Sí", "No")
```
- **Agrupación por densidad**

  Segmenta los pedidos en función de su densidad. Se considera "Voluminosa" si el ratio peso/volumen es menor a 115 kg/m³, y "Densa" si es igual o superior.

```sql
GrupoDensidad = 
IF('Data pedidos consolidada'[Peso/volumen]<115,"Voluminosa", "Densa")
```

#### b) Medidas DAX

- **Cálculo Peso vs volumen**
  
  Calcula la densidad de cada pedido.
  
```sql
Peso/volumen =
'Data pedidos consolidada'[Peso (kg)]/'Data pedidos consolidada'[Volumen (m3)]
```

- **Penalidad promedio por pedido**

  Promedio de penalidades aplicadas a pedidos con penalización.
```sql
PenalidadPromedioPorPedido = 
DIVIDE(
    SUMX(
        FILTER('Data pedidos consolidada','Data pedidos consolidada'[Penalidad] > 0),
        'Data pedidos consolidada'[Penalidad]
    ),
    COUNTROWS(
        FILTER('Data pedidos consolidada','Data pedidos consolidada'[Penalidad] > 0)
    )
)
```
- **Ratio Beneficio vs Facturación**

  Ratio de beneficio neto sobre la facturación total.
```sql
%Beneficio/Facturacion =

sum('Data pedidos consolidada'[Beneficio Neto])/sum('Data pedidos consolidada'[Facturación])
```
- **Ratio Penalidad vs Facturación**

  Proporción de penalidades respecto a la facturación.
```sql
%Penalidad/Facturacion = 
DIVIDE(
    SUM('Data pedidos consolidada'[Penalidad]),
    SUM('Data pedidos consolidada'[Facturación])
)
```
### 6. Elaboración y Análisis de gráficos e insights operativos

Una vez modelados los datos, se desarrollaron visualizaciones clave para evaluar el desempeño logístico y financiero de Trench Logistics entre 2023 y 2025. A continuación, se detallan los principales hallazgos:

#### a) Cumplimiento de entregas y penalidades
![Imagen](/Screenshots_dashboard/Slide_Cumplimiento_de_entrega.png)
- La evolución mensual muestra una caída progresiva en el cumplimiento, pasando de 95% a 85% en algunos trimestres.
- Se identifican picos de penalidades en marzo y julio, lo que sugiere posibles cuellos de botella operativos o estacionalidad.
- Los centros de distribución en Arequipa y Chiclayo no alcanzan el objetivo del 90% de entregas a tiempo, afectando la fidelidad de clientes clave



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

