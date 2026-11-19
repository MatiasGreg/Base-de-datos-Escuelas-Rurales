# Enunciado completo: conectividad de escuelas rurales

## 1. Situación problemática

El MinTIC reporta que en Magdalena se pasó de 19 escuelas conectadas en 2022
a 570. Sin embargo, en los pueblos palafitos de la Ciénaga Grande solo el
25 % de la población accede a internet. Sin un inventario con estado y fecha
es difícil saber qué conexiones y equipos siguen funcionando.

El contexto se relaciona con información publicada por MinTIC, El Universal,
Hoy Diario del Magdalena y la UNAD sobre conectividad en El Carmen del
Magdalena. Estas fuentes justifican el problema, pero los datos operativos del
sistema deben mantenerse en el inventario institucional.

## 2. Objetivo del sistema

Mantener un inventario histórico de conexiones, dispositivos e incidencias
para conocer la conectividad efectiva de las escuelas rurales, conservar la
trazabilidad de los cambios y apoyar la priorización del mantenimiento.

## 3. Actores involucrados

- **Administrador de sede educativa:** registra sedes, conexiones,
  dispositivos, incidencias y mediciones disponibles.
- **Proveedor de conexión:** suministra información contractual y técnica de
  las conexiones, incluyendo tipo, velocidad y vigencia.
- **Responsable de mantenimiento:** consulta incidencias, registra cierres y
  conserva la asignación responsable de los dispositivos.
- **Técnico de soporte:** atiende incidencias y queda asociado con su rol
  principal o de apoyo.
- **Administrador del sistema:** controla la calidad de los catálogos,
  permisos y consistencia de la información.

## 4. Información y procesos que debe conservar

1. Sedes con municipio y zona (`Rural` o `Palafito`).
2. Conexiones contratadas o instaladas, proveedor, tipo de servicio,
   velocidad y fechas de vigencia.
3. Cambios de estado de conexión con fecha y hora, sin reemplazar estados
   anteriores.
4. Dispositivos con código de inventario, fecha de entrega, estado físico y
   responsable por código o dependencia.
5. Incidencias y mantenimientos con sede, recurso afectado, descripción,
   fecha de inicio y fecha de cierre.
6. Mediciones de uso cuando existan.
7. Técnicos asignados a las incidencias, diferenciando atención principal y
   apoyo.
8. Auditoría de cambios de estado físico o responsable de los dispositivos.

## 5. Reglas de negocio y límites

- Una sede puede tener varias conexiones a lo largo del tiempo.
- Toda conexión conserva su historial de estados.
- Un cambio de estado agrega un registro; no actualiza ni elimina los
  registros históricos.
- Una sede solo puede estar en zona `Rural` o `Palafito`.
- El tipo de conexión debe ser `Satelital`, `Fibra`, `Radioenlace` o `Movil`.
- La velocidad debe ser positiva y la fecha final no puede ser anterior a la
  fecha inicial.
- Todo dispositivo debe tener un responsable asignado.
- Los estados físicos permitidos son `Bueno`, `Regular` y `Dañado`.
- Una incidencia puede referenciar una conexión, un dispositivo o ambos,
  siempre que pertenezcan a la sede indicada.
- El cierre de una incidencia no puede ser anterior a su inicio.
- El tiempo de reparación se calcula con las fechas de inicio y cierre; no se
  almacena manualmente.
- Las mediciones de uso deben estar entre 0 y 744 horas por mes.
- Un técnico atendido en el historial se desactiva, no se elimina.

## 6. Consultas que el diseño debe permitir

El sistema debe permitir identificar sedes sin conexión o con servicio caído
en una fecha determinada, medir cobertura municipal, contar equipos y calcular
su antigüedad, obtener tiempos promedio de reparación por sede o proveedor,
consultar disponibilidad a partir de mediciones y revisar la trazabilidad de
los estados de las conexiones.

Las consultas ejecutables se encuentran en `sql/consultas.sql`. Los casos de
uso, incluidos escenarios normales, inválidos y de borde, se encuentran en
`documentos/casos_de_uso.md`. La matriz de actores y responsabilidades está
en `documentos/roles.md`.

## 7. Alcance y exclusiones

El sistema administra inventario, historial y operación de conectividad. No
reemplaza la facturación de proveedores, la gestión de contratos, la
autenticación de usuarios ni la medición automática de tráfico de red. Las
fuentes periodísticas aportan contexto y no se cargan como datos operativos
sin una fuente institucional verificable.
