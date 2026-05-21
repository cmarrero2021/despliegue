-- Agregar permiso perform_purge si no existe
INSERT INTO permissions (name, resource, action, description)
SELECT 'perform_purge', 'maintenance', 'delete', 'Ejecutar purga fisica del sistema'
WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE name = 'perform_purge');

SELECT id, name, resource, action FROM permissions WHERE name = 'perform_purge';
