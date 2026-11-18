# Evidencias de pruebas

## Entorno

La validación reproducible se ejecutó en MariaDB 10.4.34, con InnoDB y una
instalación limpia de la base de datos.

## Resultado de instalación y carga

La cadena completa:

```text
script_creacion_tablas.sql
insercion_catalogos.sql
carga_asignaciones_tecnicos.sql
logica_avanzada.sql
vistas.sql
```

terminó correctamente. La carga base deja como mínimo 50 filas en cada tabla:

| Tabla | Filas verificadas |
|---|---:|
| MUNICIPIO | 50 |
| PROVEEDOR | 50 |
| RESPONSABLE | 50 |
| TECNICO | 50 |
| SEDE_EDUCATIVA | 50 |
| CONEXION | 50 |
| HISTORIAL_ESTADO_CONEXION | 50 |
| DISPOSITIVO | 50 |
| MEDICION_USO | 50 |
| AUDITORIA_DISPOSITIVO | 50 |
| INCIDENCIA | 60 |
| INCIDENCIA_TECNICO | 60 |

Las 10 filas adicionales de `INCIDENCIA` provienen de
`carga_asignaciones_tecnicos.sql`, que conserva datos para demostrar la
asignación N:M.

## Pruebas funcionales

`sql/pruebas_fase4.sql` se ejecutó con `--force` porque incluye errores
intencionales que deben ser rechazados:

- `chk_sede_zona` rechazó una zona inválida.
- `chk_conexion_tipo` rechazó un tipo de conexión no permitido y velocidad
  cero.
- `chk_medicion_horas` rechazó 800 horas.
- Las funciones devolvieron los valores esperados para datos disponibles.
- Los procedimientos registraron y cerraron una incidencia con transacción.
- El trigger de inmutabilidad rechazó una actualización del historial.

## Vistas y optimización

Se validaron cuatro vistas, incluida
`vw_sedes_con_alta_carga_incidencias`, que utiliza `GROUP BY` y `HAVING`.
`sql/explain_optimizacion.sql` mostró el uso de
`idx_incidencia_fecha_cierre` e `idx_historial_conexion_fecha` y dejó
documentada la comparación de planes antes y después de indexar.

## Concurrencia

La prueba de dos sesiones está en `sql/estres_concurrencia_sesion_1.sql` y
`sql/estres_concurrencia_sesion_2.sql`. La primera sesión conserva un bloqueo
de fila con `FOR UPDATE`; la segunda espera el `COMMIT` y luego actualiza,
demostrando serialización InnoDB y auditoría de ambos cambios.
