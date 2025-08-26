# Caso de Estudio – Trench Logistics  
**Análisis de desempeño logístico con SQL y Power BI**  

---

Se realizó este proyecto de análisis de eficiencia operativa con data de una empresa ficticia llamada **Trench Logistics**. A continuación veremos el proceso end-to-end desde que se tiene una problemática, hasta que se obtienen los insight clave para llegar a conclusiones acertadas.

## 📊 Dashboard interactivo

Este proyecto incluye un análisis logístico y financiero de penalidades, rentabilidad por cliente y eficiencia operativa.

🔗 [Haz clic aquí para ver el dashboard en Power BI](https://app.powerbi.com/view?r=eyJrIjoiMGQ5YTlhZWEtMDYwMy00NTI4LTgzM2QtNTYwMDY0MDA5M2EzIiwidCI6ImM1YjVkZjc0LWI1NWMtNDE4NS05MjQ5LWFhMjU0YzFlNjBkOCIsImMiOjR9&pageName=3f2e19b32d58d65655ff)

## 1. Contexto del Negocio  
**Trench Logistics** es una empresa dedicada a la distribución de útiles escolares en Lima, Arequipa y Chiclayo.  
Las tarifas actuales se calculan por **peso (kg)**, con ligeras variaciones por distancia.

Los principales indicadores clave de desempeño (KPI) definidos por la compañía son:
- **% de entregas dentro de 48 horas:** 90%
- **% de beneficio sobre facturación:** 99.5%
  
La política de entregas está estructurada de forma transparente:
- Entregas en ≤ 48 horas: se consideran dentro del estándar operativo.
- Entregas en 3 días: aplican un reembolso del 5% sobre el monto facturado como compensación.
- Entregas en más de 3 días: generan un reembolso del 10% sobre la facturación total.

Los ejecutivos identificaron un aumento de penalidades y un margen operativo más bajo de lo esperado.  
Se planteó la necesidad de analizar:

1. ¿Se debe actualizar la estructura tarifaria?  
2. ¿Dónde están los principales puntos críticos de la operación?  
3. ¿Qué factores generan más penalidades?

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
│   ├── coordenadas.csv
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


### Cálculo del Beneficio Neto
Una vez generada la tabla `pedidos` con los campos transformados, se calcula el beneficio neto.

```sql
SELECT *,
ROUND(`Facturación` - `Penalidad`,2)  as `Beneficio Neto`
FROM pedidos
ORDER BY `Fecha Solicitud`;
SET NAMES utf8mb4;
```
### Observaciones
- Se utilizó ROUND() para mantener consistencia en los valores monetarios.
- La lógica de penalidad está alineada con políticas de entrega: penalización del 5% si se entrega en 3 días, y del 10% si se excede.
- La clasificación de tamaño de pedido permite segmentar la logística por peso: Pedidos pequeños si pesan menos a 5kg, pedidos medianos si pesan de 5 a 20 kg, y pedidos grandes los mayores a 20 kg.

Finalmente, ejecutamos la consulta, revisamos los resultados y exportamos el resultado en el archivo `Trench_Logistics_data_consolidada.csv`.

## 5. Preparación y modelado de datos en Power BI

Se importó el archivo 📄[Trench_Logistics_data_consolidada.csv](Trench_Logistics_data_consolidada.csv) a Power BI, iniciando el proceso de limpieza y validación en Power Query. Se verificó que todas las columnas contuvieran información completa, sin errores de tipo ni valores nulos, y se aplicaron los formatos adecuados. Esta consulta se denominó `Data pedidos consolidada`

![Imagen](/Screenshots_dashboard/Revision_power_query.png)

Durante la revisión, se identificó que la base incluía información de zonas y distritos por pedido, pero no contaba con coordenadas geográficas (latitud y longitud), necesarias para la visualización en mapas dinámicos. Para resolverlo, se extrajeron las coordenadas oficiales de los distritos desde el portal del INEI y se consolidaron en un archivo auxiliar:

- 📋 [coordenadas.xlsx](coordenadas.xlsx)

Este archivo fue importado a Power BI como la consulta `Coordenadas`, y se realizó una combinación con `Data pedidos consolidada` para incorporar las columnas de `latitud` y `longitud` en la consulta principal.

![Imagen](/Screenshots_dashboard/JOIN_power_query.png)

A continuación, se definieron indicadores clave (KPI) y medidas DAX para facilitar el análisis visual y extraer insights relevantes. A continuación, se detallan las principales transformaciones:

### a) Columnas:

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

### b) Medidas DAX

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
## 6. Elaboración y Análisis de gráficos e insights operativos

Una vez modelados los datos, se desarrollaron visualizaciones clave para evaluar el desempeño logístico y financiero de Trench Logistics entre 2023 y 2025. A continuación, se detallan los principales hallazgos:

### a) Cumplimiento de entregas y penalidades

- La evolución mensual muestra una caída progresiva en el cumplimiento, pasando de 95% a 85% en algunos trimestres.
- Se identifican picos de penalidades en marzo y julio, lo que sugiere posibles cuellos de botella operativos o estacionalidad.

  
  ![Imagen](/Screenshots_dashboard/Slide_Cumplimiento_de_entrega.png)


- Los centros de distribución en Arequipa y Chiclayo no alcanzan el objetivo del 90% de entregas a tiempo, afectando la fidelidad de clientes clave.

  
  ![Imagen](/Screenshots_dashboard/Slide_Cumplimiento_de_entrega_2.png)

**Insight:** Se recomienda revisar rutas y procesos en zonas críticas, especialmente en distritos como Chorrillos, Comas y Pimentel, donde se concentran penalidades elevadas.

### b) Rentabilidad por tipo de carga

- Los pedidos de carga voluminosa presentan menor rentabilidad operativa, a pesar de requerir más unidades de transporte.
- Actualmente, las tarifas se aplican en función del peso, lo que genera una brecha entre costo logístico y facturación en pedidos de gran volumen.
  

  ![Imagen](/Screenshots_dashboard/Slide_Analisis_costo.png)
  
**Insight:** Evaluar una estructura tarifaria diferenciada para carga voluminosa, alineada al costo real de operación.


### c) Beneficio por zona y cliente

- El 60% de los clientes más rentables presentan incumplimientos en entregas.
- Distritos como Chorrillos, Alto Selva Alegre y Barranco concentran altos beneficios, pero también penalidades frecuentes.

  
  ![Imagen](/Screenshots_dashboard/Slide_Clientes_clave.png)
  
**Insight:** Priorizar mejoras operativas en zonas y clientes estratégicos para proteger la rentabilidad y fidelidad de los segmentos más valiosos.

### d) Penalidades por tipo de pedido y cliente

- El 91.5% de las penalidades se concentran en pedidos medianos, y el 89.7% provienen de clientes mayoristas.
- Se detecta una contradicción operativa: distritos con penalidad promedio alta también tienen alto volumen de pedidos afectados.

  ![Imagen](/Screenshots_dashboard/Slide_Analisis_penalidades.png)
  
**Insight:** Corregir desvíos operativos en zonas con alta congestión o fallas de coordinación. Posible necesidad de capacitación adicional o revisión de SLA.

## 7. Conclusiones y recomendaciones finales

El análisis de la operación logística de Trench Logistics entre 2023 y 2025 revela patrones críticos que afectan la rentabilidad, el cumplimiento de entregas y la eficiencia operativa. A través de la segmentación por tipo de carga, evaluación de penalidades y análisis geográfico, se identificaron oportunidades claras de mejora.

### Conclusiones:

- **Carga voluminosa con baja rentabilidad operativa**
  
    Los envíos de baja densidad presentan un desbalance entre volumen y peso, lo que genera márgenes negativos bajo el esquema tarifario actual. Además, estos pedidos concentran penalidades más altas y valores promedio por pedido más bajos, lo que compromete la eficiencia operativa.
- **Brechas de cumplimiento en zonas clave**
  
    Regiones como Arequipa y Chiclayo muestran tasas elevadas de entregas tardías y penalidades del 5%, en contraste con Lima, que alcanza un cumplimiento del 97%. Esto sugiere fallas en planificación, rutas o capacidad instalada en zonas específicas.
- **Clientes estratégicos con bajo cumplimiento**
  
    Algunos clientes de alto valor presentan niveles de incumplimiento que podrían afectar la fidelización y la facturación futura, especialmente en zonas con alta penalidad.
- **Desbalance entre tipo de carga y penalidad**
  
    La carga voluminosa no solo es menos rentable, sino que también está asociada a mayores penalidades, lo que indica una necesidad urgente de revisar procesos operativos y criterios de asignación.

  
### Recomendaciones:

- **Revisar el modelo tarifario**

  Incorporar un esquema que considere el volumen como variable clave, especialmente para pedidos de baja densidad, asegurando que el precio refleje el costo logístico real.

- **Priorizar mejoras en zonas críticas**

  Focalizar esfuerzos en Arequipa y Chiclayo, ajustando rutas, tiempos de corte y coordinación operativa para reducir penalidades.

- **Optimizar la gestión de clientes estratégicos**

  Reforzar la planificación con clientes mayoristas, ajustando SLA y anticipando picos de demanda en temporadas críticas.

- **Implementar alertas operativas en Power BI**

  Desarrollar indicadores que detecten desviaciones en tiempo real, permitiendo acciones preventivas ante posibles penalidades.


## 8. Cierre del proyecto

Este proyecto representa una síntesis entre análisis financiero, optimización logística y visualización estratégica. A través del uso de Power BI, SQL y modelado de datos, se logró transformar información operativa en decisiones accionables. La documentación busca no solo mostrar resultados, sino también el proceso detrás de cada insight.
Gracias por revisar este trabajo. Si tienes comentarios, sugerencias, estaré encantado de conectar.


##

**Autor:** Oscar Granada Navarro

*Ingeniero Industrial | Analista de Datos | SQL & Power BI*

**Linkedin:** [linkedin.com/in/oscargranada/](https://www.linkedin.com/in/oscargranada/)

**Repositorio:** [github.com/oscargranada/Logistics-Analytics-PowerBI.git](https://github.com/oscargranada/Logistics-Analytics-PowerBI.git)
