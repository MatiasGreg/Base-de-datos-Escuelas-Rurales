# Roles y responsabilidades

## ¿Es obligatorio documentar roles?

La guía oficial identifica actores involucrados, por lo que documentar roles
no es una tabla obligatoria del esquema ni una exigencia de implementar
usuarios SQL. Sin embargo, sí es recomendable incluirlos: demuestra quién
produce, consulta y valida cada dato, y conecta el diseño con los procesos
solicitados. En este proyecto los roles se documentan como responsabilidades
funcionales, no como cuentas reales ni contraseñas.

| Rol | Responsabilidades principales | Datos que consulta o registra |
|---|---|---|
| Administrador de sede educativa | Mantener el inventario local y reportar novedades | Sedes, conexiones, dispositivos, incidencias y mediciones |
| Proveedor de conexión | Entregar datos técnicos y vigencias del servicio | Proveedores, conexiones, tipo, velocidad y fechas |
| Responsable de mantenimiento | Coordinar atención, cierres y responsables de equipos | Incidencias, estados, dispositivos y auditoría |
| Técnico de soporte | Diagnosticar y atender incidencias | Incidencias e `INCIDENCIA_TECNICO` |
| Administrador del sistema | Validar catálogos, permisos, integridad y reportes | Todas las entidades y consultas |

## Separación de responsabilidades

- El administrador de sede registra la necesidad y los datos de inventario.
- El proveedor suministra la información de su servicio, pero no modifica el
  historial de otras conexiones.
- El responsable de mantenimiento registra la atención y el cierre.
- El técnico aporta la atención técnica y queda asociado a la incidencia.
- El administrador del sistema revisa inconsistencias y administra el acceso.

La implementación actual no contiene autenticación ni una tabla de usuarios.
Si el alcance futuro exige control de acceso, estos roles pueden convertirse
en perfiles de aplicación o cuentas SQL con privilegios mínimos.
