USE bd_escuelas_rurales;

INSERT INTO MUNICIPIO (nombre_municipio) VALUES
('Santa Marta'), ('Ciénaga'), ('Fundación'), ('El Banco'), ('Plato'),
('Aracataca'), ('Pivijay'), ('El Retén'), ('Pueblo Viejo'), ('Sitionuevo');

INSERT INTO PROVEEDOR (nombre_proveedor) VALUES
('MinTIC - Centros Digitales'), ('HughesNet'), ('Claro Soluciones'),
('Movistar Empresas'), ('Tigo Business'), ('ETB'), ('Andired'),
('Azteca Comunicaciones'), ('Sisteco'), ('RuralNet');

INSERT INTO RESPONSABLE (descripcion_cargo) VALUES
('Rectoría Principal'), ('Coordinación Académica'), ('Secretaría General'),
('Sala de Informática'), ('Biblioteca Escolar'), ('Laboratorio de Ciencias'),
('Sala de Profesores'), ('Auxiliar TIC'), ('Mantenimiento'), ('Enlace Rural');

INSERT INTO TECNICO (codigo_tecnico, especialidad) VALUES
('TEC-001','Redes'), ('TEC-002','Hardware'), ('TEC-003','Energia'),
('TEC-004','Satelital'), ('TEC-005','Soporte general'),
('TEC-006','Redes'), ('TEC-007','Hardware'), ('TEC-008','Energia'),
('TEC-009','Satelital'), ('TEC-010','Soporte general');

INSERT INTO SEDE_EDUCATIVA (id_municipio, nombre_sede, zona)
SELECT id_municipio,
       CONCAT('I.E.D. Rural Nueva Esperanza Sede ', id_municipio),
       IF(id_municipio % 5 = 0, 'Palafito', 'Rural')
FROM MUNICIPIO
ORDER BY id_municipio;

INSERT INTO CONEXION (id_sede, id_proveedor, tipo_servicio, velocidad_mbps, vigencia_inicio, vigencia_fin)
SELECT s.id_sede,
       1 + ((s.id_sede - 1) % 10),
       IF(s.id_sede % 2 = 0, 'Satelital', 'Radioenlace'),
       20,
       '2023-01-15',
       NULL
FROM SEDE_EDUCATIVA s
ORDER BY s.id_sede;

INSERT INTO DISPOSITIVO (
    codigo_inventario, id_sede, id_responsable,
    tipo_dispositivo, fecha_entrega, estado_fisico
)
SELECT
    CONCAT('INV-MINTIC-2024-', s.id_sede),
    s.id_sede,
    1 + ((s.id_sede - 1) % 10),
    IF(s.id_sede % 3 = 0, 'Computador Portátil', 'Router Inalámbrico'),
    '2024-02-10',
    'Bueno'
FROM SEDE_EDUCATIVA s
ORDER BY s.id_sede;

INSERT INTO MEDICION_USO (id_conexion, fecha_medicion, horas_servicio_activo)
SELECT c.id_conexion, '2026-10-31', 650.50
FROM CONEXION c;

INSERT INTO AUDITORIA_DISPOSITIVO (
    codigo_inventario, estado_anterior, estado_nuevo,
    id_responsable_anterior, id_responsable_nuevo,
    usuario, origen
)
SELECT codigo_inventario, NULL, estado_fisico, NULL, id_responsable,
       'sistema', 'Carga inicial'
FROM DISPOSITIVO;
