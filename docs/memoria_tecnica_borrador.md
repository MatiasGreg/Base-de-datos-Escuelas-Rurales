# Memoria técnica — borrador

## 1. Introducción y contexto

Las escuelas rurales requieren una solución para administrar sedes,
conectividad, dispositivos, incidencias, mediciones y mantenimiento técnico.
El sistema centraliza la información operativa sin almacenar datos personales
innecesarios: los técnicos se identifican mediante códigos anonimizados y los
responsables mediante cargos o dependencias.

El alcance incluye 12 tablas, integridad referencial, reglas de negocio,
auditoría, consultas analíticas y objetos programables para MariaDB 10.4+.

## 2. Reglas de negocio

1. Una sede puede tener varias conexiones.
2. Los estados de conexión son históricos e inmutables.
3. Todo dispositivo tiene una dependencia responsable.
4. Las horas de reparación se calculan a partir de las fechas.
5. La conexión y el dispositivo de una incidencia deben pertenecer a la sede.
6. Una incidencia puede tener técnicos principal y de apoyo.
7. Los técnicos atendidos se desactivan en vez de eliminarse.
8. Los cambios reales de dispositivo generan auditoría.

## 3. Modelado y normalización

El diagrama ER y el modelo lógico se encuentran en `fase_1_requisitos_y_diagrama_er.md`
y `fase_2_modelo_logico_y_normalizacion.md`. El modelo cumple 3FN mediante
catálogos separados, valores atómicos, una tabla puente para la relación N:M y
valores derivados calculados por funciones. Las dependencias funcionales están
en `dependencias_funcionales.md`.

## 4. Implementación

La instalación se ejecuta en este orden:

```text
script_creacion_tablas.sql
insercion_catalogos.sql
carga_asignaciones_tecnicos.sql
logica_avanzada.sql
vistas.sql
```

La carga genera al menos 50 registros en cada tabla. Se implementan tres
procedimientos de negocio relevantes, dos funciones definidas por el usuario,
seis triggers, cuatro vistas y restricciones CHECK, UNIQUE, NOT NULL, DEFAULT
y FK.

## 5. Implementación y consultas

### Consultas analíticas

```sql
SELECT * FROM vw_resumen_general_sedes
ORDER BY total_incidencias_historicas DESC;

SELECT * FROM vw_tendencia_mensual_conectividad
ORDER BY fecha_mes;

SELECT * FROM vw_sedes_con_alta_carga_incidencias
ORDER BY total_incidencias DESC;
```

La tercera vista usa `GROUP BY` y `HAVING` para seleccionar sedes con al menos
dos incidencias y una incidencia abierta, demostrando filtrado posterior a la
agregación.

### Transacciones

`sp_registrar_incidencia`, `sp_cerrar_incidencia` y
`sp_actualizar_dispositivo` usan `START TRANSACTION`, `COMMIT`, `ROLLBACK` y
handlers para propagar excepciones. El script de concurrencia demuestra
bloqueo pesimista con `SELECT ... FOR UPDATE` y serialización InnoDB.

### Índices y EXPLAIN

Los índices de FK soportan joins y validaciones. El script
`explain_optimizacion.sql` compara una consulta de incidencias por fecha antes
y después de crear `idx_incidencia_fecha_inicio`, además de consultas de
incidencias abiertas e historial por conexión. La evidencia debe conservar la
salida de `EXPLAIN` del entorno de evaluación y justificar la reducción de
filas examinadas o el uso del índice.

## 6. Pruebas y evidencias

`pruebas_fase4.sql` valida restricciones, funciones, procedimientos,
inmutabilidad, coherencia entre sede y recursos, y auditoría. Los resultados
resumidos y las observaciones de entorno están en
`evidencias_pruebas.md`.

## 7. Conclusiones y trabajo futuro

El esquema reduce redundancias, protege la integridad referencial y conserva
trazabilidad de cambios. La separación de catálogos y la tabla puente permiten
crecer sin duplicar información, mientras que los triggers cubren reglas que
no expresan por sí solas las FK.

Como trabajo futuro se propone agregar autenticación y roles de aplicación,
particionar el historial cuando el volumen crezca, automatizar cargas
periódicas de mediciones, incorporar alertas de disponibilidad y publicar un
tablero para seguimiento territorial.
