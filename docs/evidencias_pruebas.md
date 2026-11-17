# Evidencias de pruebas

## Resultado resumido

El proyecto original fue probado contra MariaDB 10.11 y reportó:

- 48 de 48 pruebas con el resultado esperado.
- Restricciones CHECK, UNIQUE y NOT NULL validadas.
- Llaves foráneas validadas.
- Tabla puente N:M validada.
- Procedimientos y transacciones validados.
- Triggers de coherencia e inmutabilidad validados.
- Auditoría de dispositivos validada.
- Tres vistas validadas.

## Observaciones

Las pruebas fueron ejecutadas en MariaDB 10.11, versión cercana a MariaDB 10.4.32.
No se reemplaza una base montada por otra sin verificar el entorno real.

Los scripts incluidos permiten repetir el montaje completo y ejecutar la
comprobación básica en `sql/pruebas_fase4.sql`.
