# Matriz de dependencias funcionales

La matriz documenta las dependencias funcionales relevantes del modelo y la
decisión de normalización que las mantiene hasta 3FN.

| Relación | Determinante | Atributos determinados | Justificación |
|---|---|---|---|
| MUNICIPIO | `id_municipio` | `nombre_municipio` | La PK identifica un municipio; el nombre es único. |
| PROVEEDOR | `id_proveedor` | `nombre_proveedor` | La PK identifica un proveedor; el nombre es único. |
| RESPONSABLE | `id_responsable` | `descripcion_cargo` | La PK identifica una dependencia responsable. |
| TECNICO | `id_tecnico` | `codigo_tecnico`, `especialidad`, `activo` | El técnico se identifica por una PK y un código anonimizado único. |
| SEDE_EDUCATIVA | `id_sede` | `id_municipio`, `nombre_sede`, `zona` | La sede determina su ubicación y clasificación. |
| CONEXION | `id_conexion` | `id_sede`, `id_proveedor`, `tipo_servicio`, `velocidad_mbps`, `vigencia_inicio`, `vigencia_fin` | La conexión determina sus atributos contractuales y técnicos. |
| HISTORIAL_ESTADO_CONEXION | `id_historial` | `id_conexion`, `fecha_hora_registro`, `estado_actual`, `observaciones` | Cada evento de historial es inmutable e identificable. |
| DISPOSITIVO | `codigo_inventario` | `id_sede`, `id_responsable`, `tipo_dispositivo`, `fecha_entrega`, `estado_fisico` | El código de inventario identifica un equipo. |
| INCIDENCIA | `id_incidencia` | `id_sede`, `id_conexion`, `codigo_inventario`, `descripcion_falla`, `fecha_inicio`, `fecha_cierre` | La incidencia identifica un evento operativo. |
| MEDICION_USO | `id_medicion` | `id_conexion`, `fecha_medicion`, `horas_servicio_activo` | Cada medición es un registro independiente. |
| INCIDENCIA_TECNICO | (`id_incidencia`, `id_tecnico`) | `rol_asignado`, `fecha_asignacion` | El rol y la fecha dependen de la asignación completa, no de una sola entidad. |
| AUDITORIA_DISPOSITIVO | `id_auditoria` | `codigo_inventario`, estados, responsables, `usuario`, `fecha_cambio`, `origen` | Cada fila conserva una fotografía histórica de un cambio. |

## Dependencias transitivas evitadas

- `SEDE_EDUCATIVA.id_municipio` no almacena el nombre del municipio.
- `CONEXION.id_proveedor` no almacena el nombre del proveedor.
- `DISPOSITIVO.id_responsable` no repite la descripción del cargo.
- `INCIDENCIA_TECNICO` no repite los datos del técnico ni de la incidencia.
- Las horas de reparación y el porcentaje de disponibilidad son valores
  derivados mediante funciones y consultas, no atributos almacenados.

## Excepciones justificadas

`AUDITORIA_DISPOSITIVO` conserva valores anteriores y nuevos sin FK al equipo
porque su objetivo es preservar evidencia aun cuando el dispositivo se retire.
Esto es una decisión de trazabilidad, no una dependencia transgresora del
modelo operativo.
