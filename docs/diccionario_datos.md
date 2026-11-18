# Diccionario de datos

Motor objetivo: MariaDB 10.4+ (también compatible con MySQL 8+).

| Tabla | Columna | Tipo | Nulo | Clave / regla |
|---|---|---|---|---|
| MUNICIPIO | `id_municipio` | INT | No | PK, AUTO_INCREMENT |
| MUNICIPIO | `nombre_municipio` | VARCHAR(100) | No | UNIQUE |
| PROVEEDOR | `id_proveedor` | INT | No | PK, AUTO_INCREMENT |
| PROVEEDOR | `nombre_proveedor` | VARCHAR(150) | No | UNIQUE |
| RESPONSABLE | `id_responsable` | INT | No | PK, AUTO_INCREMENT |
| RESPONSABLE | `descripcion_cargo` | VARCHAR(100) | No | UNIQUE |
| TECNICO | `id_tecnico` | INT | No | PK, AUTO_INCREMENT |
| TECNICO | `codigo_tecnico` | VARCHAR(20) | No | UNIQUE, código anonimizado |
| TECNICO | `especialidad` | VARCHAR(30) | No | CHECK de dominio |
| TECNICO | `activo` | TINYINT(1) | No | DEFAULT 1, CHECK 0/1 |
| SEDE_EDUCATIVA | `id_sede` | INT | No | PK, AUTO_INCREMENT |
| SEDE_EDUCATIVA | `id_municipio` | INT | No | FK a MUNICIPIO |
| SEDE_EDUCATIVA | `nombre_sede` | VARCHAR(150) | No | — |
| SEDE_EDUCATIVA | `zona` | VARCHAR(20) | No | CHECK Rural/Palafito |
| CONEXION | `id_conexion` | INT | No | PK, AUTO_INCREMENT |
| CONEXION | `id_sede` | INT | No | FK a SEDE_EDUCATIVA |
| CONEXION | `id_proveedor` | INT | No | FK a PROVEEDOR |
| CONEXION | `tipo_servicio` | VARCHAR(50) | No | CHECK de dominio |
| CONEXION | `velocidad_mbps` | INT | No | CHECK mayor que 0 |
| CONEXION | `vigencia_inicio` | DATE | No | — |
| CONEXION | `vigencia_fin` | DATE | Sí | CHECK no anterior al inicio |
| HISTORIAL_ESTADO_CONEXION | `id_historial` | INT | No | PK, AUTO_INCREMENT |
| HISTORIAL_ESTADO_CONEXION | `id_conexion` | INT | No | FK a CONEXION |
| HISTORIAL_ESTADO_CONEXION | `fecha_hora_registro` | TIMESTAMP | No | DEFAULT CURRENT_TIMESTAMP |
| HISTORIAL_ESTADO_CONEXION | `estado_actual` | VARCHAR(20) | No | CHECK Activo/Intermitente/Caído |
| HISTORIAL_ESTADO_CONEXION | `observaciones` | TEXT | Sí | — |
| DISPOSITIVO | `codigo_inventario` | VARCHAR(50) | No | PK |
| DISPOSITIVO | `id_sede` | INT | No | FK a SEDE_EDUCATIVA |
| DISPOSITIVO | `id_responsable` | INT | No | FK a RESPONSABLE |
| DISPOSITIVO | `tipo_dispositivo` | VARCHAR(100) | No | — |
| DISPOSITIVO | `fecha_entrega` | DATE | No | DEFAULT CURRENT_DATE |
| DISPOSITIVO | `estado_fisico` | VARCHAR(20) | No | DEFAULT Bueno, CHECK de dominio |
| INCIDENCIA | `id_incidencia` | INT | No | PK, AUTO_INCREMENT |
| INCIDENCIA | `id_sede` | INT | No | FK a SEDE_EDUCATIVA |
| INCIDENCIA | `id_conexion` | INT | Sí | FK opcional; coherencia por trigger |
| INCIDENCIA | `codigo_inventario` | VARCHAR(50) | Sí | FK opcional; coherencia por trigger |
| INCIDENCIA | `descripcion_falla` | TEXT | No | — |
| INCIDENCIA | `fecha_inicio` | DATETIME | No | DEFAULT CURRENT_TIMESTAMP |
| INCIDENCIA | `fecha_cierre` | DATETIME | Sí | CHECK no anterior al inicio |
| MEDICION_USO | `id_medicion` | INT | No | PK, AUTO_INCREMENT |
| MEDICION_USO | `id_conexion` | INT | No | FK a CONEXION |
| MEDICION_USO | `fecha_medicion` | DATE | No | — |
| MEDICION_USO | `horas_servicio_activo` | DECIMAL(5,2) | No | CHECK entre 0 y 744 |
| INCIDENCIA_TECNICO | `id_incidencia` | INT | No | PK compuesta, FK |
| INCIDENCIA_TECNICO | `id_tecnico` | INT | No | PK compuesta, FK |
| INCIDENCIA_TECNICO | `rol_asignado` | VARCHAR(20) | No | DEFAULT Principal, CHECK |
| INCIDENCIA_TECNICO | `fecha_asignacion` | DATETIME | No | DEFAULT CURRENT_TIMESTAMP |
| AUDITORIA_DISPOSITIVO | `id_auditoria` | INT | No | PK, AUTO_INCREMENT |
| AUDITORIA_DISPOSITIVO | `codigo_inventario` | VARCHAR(50) | No | Sin FK por retención histórica |
| AUDITORIA_DISPOSITIVO | `estado_anterior` | VARCHAR(20) | Sí | — |
| AUDITORIA_DISPOSITIVO | `estado_nuevo` | VARCHAR(20) | No | CHECK de dominio |
| AUDITORIA_DISPOSITIVO | `id_responsable_anterior` | INT | Sí | — |
| AUDITORIA_DISPOSITIVO | `id_responsable_nuevo` | INT | No | — |
| AUDITORIA_DISPOSITIVO | `usuario` | VARCHAR(100) | No | DEFAULT sistema |
| AUDITORIA_DISPOSITIVO | `fecha_cambio` | DATETIME | No | DEFAULT CURRENT_TIMESTAMP |
| AUDITORIA_DISPOSITIVO | `origen` | VARCHAR(30) | No | DEFAULT Trigger |

## Índices

Las FK tienen índices explícitos en `script_creacion_tablas.sql`. Los índices
analíticos `idx_incidencia_fecha_inicio`, `idx_incidencia_fecha_cierre` y
`idx_historial_conexion_fecha` se crean en `explain_optimizacion.sql` y se
justifican mediante los planes antes y después del índice.
