# Casos de uso

Los casos se expresan sobre las tablas y reglas actuales de
`bd_escuelas_rurales`. Cada caso indica el resultado esperado.

## CU-01. Registrar una sede válida

- **Actor:** Administrador de sede.
- **Precondición:** existe el municipio.
- **Flujo:** registra municipio, nombre y zona `Rural` o `Palafito`.
- **Resultado:** se crea la sede y queda disponible para conexiones,
  dispositivos e incidencias.

## CU-02. Registrar una conexión y su proveedor

- **Actor:** Administrador de sede o proveedor.
- **Precondición:** existen la sede y el proveedor.
- **Flujo:** registra tipo permitido, velocidad positiva y fechas coherentes.
- **Resultado:** la conexión queda asociada a la sede y al proveedor.

## CU-03. Registrar estados sin perder historial

- **Actor:** Responsable de mantenimiento.
- **Precondición:** existe la conexión.
- **Flujo:** inserta `Activo`, `Intermitente` o `Caído` con observación.
- **Resultado:** se agrega una marca temporal; los estados anteriores
  permanecen consultables.

## CU-04. Registrar un dispositivo con responsable

- **Actor:** Administrador de sede.
- **Precondición:** existen la sede y el responsable.
- **Flujo:** registra código de inventario, tipo, fecha de entrega y estado.
- **Resultado:** el dispositivo queda inventariado y auditado cuando cambie.

## CU-05. Registrar y cerrar una incidencia

- **Actor:** Responsable de mantenimiento o técnico.
- **Precondición:** existe la sede y, si se informa un recurso, pertenece a
  esa sede.
- **Flujo:** registra la falla; después registra el cierre y el estado final.
- **Resultado:** el tiempo de reparación se calcula desde las fechas.

## CU-06. Consultar cobertura municipal

- **Actor:** Administrador del sistema.
- **Flujo:** agrupa sedes y conexiones por municipio y compara sedes
  conectadas con el total de sedes.
- **Resultado:** se identifican municipios con menor cobertura.

## CU-07. Consultar sedes sin conexión o caídas en una fecha

- **Actor:** Administrador de sede.
- **Flujo:** determina las conexiones vigentes y el último estado registrado
  hasta la fecha consultada.
- **Resultado:** se listan sedes sin conexión vigente o con estado `Caído`.

## CU-08. Consultar antigüedad y estado de equipos

- **Actor:** Responsable de mantenimiento.
- **Flujo:** calcula años desde `fecha_entrega` y agrupa por sede o estado.
- **Resultado:** se priorizan equipos antiguos, regulares o dañados.

## CU-09. Rechazar una sede con zona inválida

- **Tipo:** Inválido.
- **Entrada:** zona distinta de `Rural` o `Palafito`, por ejemplo `Urbana`.
- **Resultado:** falla el `CHECK` `chk_sede_zona`; no se crea la sede.

## CU-10. Rechazar una conexión inválida

- **Tipo:** Inválido.
- **Entrada:** tipo `Cable`, velocidad cero o fecha final anterior al inicio.
- **Resultado:** falla la restricción correspondiente; no se crea la
  conexión.

## CU-11. Rechazar una medición fuera de rango

- **Tipo:** Inválido.
- **Entrada:** 800 horas de servicio en un mes.
- **Resultado:** falla `chk_medicion_horas`; no se crea la medición.

## CU-12. Rechazar un cierre anterior al inicio

- **Tipo:** Inválido.
- **Entrada:** `fecha_cierre` menor que `fecha_inicio`.
- **Resultado:** falla `chk_incidencia_fechas`; la incidencia permanece sin
  ese cierre.

## CU-13. Rechazar una incidencia con recurso de otra sede

- **Tipo:** Inválido.
- **Entrada:** se indica una conexión o dispositivo existente, pero
  perteneciente a otra sede.
- **Resultado:** el trigger de coherencia rechaza la operación.

## CU-14. Consultar un mes sin mediciones

- **Tipo:** Borde.
- **Entrada:** conexión y mes válidos, pero sin filas en `MEDICION_USO`.
- **Resultado:** la disponibilidad se devuelve como `NULL`, no como cero
  inventado.

## CU-15. Consultar una incidencia aún abierta

- **Tipo:** Borde.
- **Entrada:** incidencia con `fecha_cierre IS NULL`.
- **Resultado:** no se calcula tiempo de reparación; aparece como incidencia
  abierta.

## CU-16. Intentar modificar el historial

- **Tipo:** Inválido.
- **Entrada:** `UPDATE` o `DELETE` sobre un registro histórico.
- **Resultado:** el trigger de inmutabilidad rechaza la operación; solo se
  permiten nuevas inserciones.

## CU-17. Registrar una fecha de entrega futura

- **Tipo:** Borde.
- **Entrada:** fecha de entrega posterior a la fecha de consulta.
- **Resultado:** el registro puede conservarse si la política institucional
  lo permite; las consultas de antigüedad deben evitar edades negativas y
  marcar el dato para revisión.

## CU-18. Consultar una sede sin incidencias

- **Tipo:** Borde.
- **Entrada:** sede válida sin filas en `INCIDENCIA`.
- **Resultado:** los conteos devuelven cero y los promedios de reparación
  permanecen `NULL` o cero según la consulta, sin crear incidencias ficticias.
