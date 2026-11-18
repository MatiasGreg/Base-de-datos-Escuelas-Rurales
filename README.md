# Base de Datos - Escuelas Rurales

Proyecto de base de datos para administrar sedes educativas rurales, conexiones de internet, dispositivos, mediciones, incidencias, técnicos y auditorías.

Diseñado y probado para **MariaDB 10.4+** y compatible con **MySQL 8+**.

## Contenido

- `sql/script_creacion_tablas.sql`: estructura completa de tablas, llaves foráneas y restricciones.
- `sql/insercion_catalogos.sql`: catálogos y datos base.
- `sql/carga_asignaciones_tecnicos.sql`: asignación principal y de apoyo de técnicos.
- `sql/logica_avanzada.sql`: funciones, procedimientos almacenados y triggers.
- `sql/vistas.sql`: vistas de consulta.
- `sql/pruebas_fase4.sql`: pruebas de restricciones y lógica avanzada.
- `sql/explain_optimizacion.sql`: análisis de planes de ejecución e índices.
- `sql/estres_concurrencia_sesion_1.sql` y `sql/estres_concurrencia_sesion_2.sql`: prueba de dos sesiones concurrentes.
- `docs/evidencias_pruebas.md`: resumen de resultados de pruebas.
- `docs/diccionario_datos.md`: diccionario completo de tablas y columnas.
- `docs/dependencias_funcionales.md`: matriz de dependencias y decisiones de normalización.
- `docs/memoria_tecnica_borrador.md`: borrador de la memoria técnica final.

## Requisitos

- MariaDB 10.4 o superior, o MySQL 8.
- Cliente `mysql` o `mariadb`.
- Permisos para crear la base de datos y sus objetos.

## Instalación

Ejecute los scripts en este orden:

```bash
mysql -u root -p < sql/script_creacion_tablas.sql
mysql -u root -p < sql/insercion_catalogos.sql
mysql -u root -p < sql/carga_asignaciones_tecnicos.sql
mysql -u root -p < sql/logica_avanzada.sql
mysql -u root -p < sql/vistas.sql
```

La carga principal genera como mínimo 50 registros por tabla, incluyendo
historial, incidencias, mediciones, asignaciones N:M y auditoría.

## Pruebas

Después de cargar el proyecto completo:

```bash
mysql --force -t bd_escuelas_rurales < sql/pruebas_fase4.sql
mysql -t bd_escuelas_rurales < sql/explain_optimizacion.sql
```

Las pruebas incluyen comprobaciones de CHECK, NOT NULL, UNIQUE, claves foráneas, tabla N:M, funciones, procedimientos, transacciones, triggers e inmutabilidad del historial.

## Reglas principales

- El historial de estados de conexión solo admite inserciones.
- Una incidencia debe referenciar una conexión y/o dispositivo perteneciente a su sede.
- Los técnicos se identifican mediante códigos anonimizados.
- Los técnicos con atenciones se desactivan, no se eliminan.
- Los cambios de estado físico o responsable generan auditoría.
- Las fechas derivan las horas de reparación; no se almacenan horas manualmente.
- El diseño usa una auditoría sin llave foránea al dispositivo para conservar el historial si el equipo se elimina del inventario.

## Uso básico

Consultar el resumen por sede:

```sql
USE bd_escuelas_rurales;
SELECT * FROM vw_resumen_general_sedes;
```

Consultar la tendencia mensual:

```sql
SELECT * FROM vw_tendencia_mensual_conectividad
ORDER BY fecha_mes;
```

Consultar el análisis geográfico y de proveedores:

```sql
SELECT * FROM vw_analisis_dimension_geografica_proveedor
ORDER BY municipio;
```

Consultar sedes con alta carga de incidencias:

```sql
SELECT * FROM vw_sedes_con_alta_carga_incidencias
ORDER BY total_incidencias DESC;
```
