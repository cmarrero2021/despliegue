-- ===============================================
-- Migration: Cooldown entre intentos de login/recuperación
-- ===============================================

-- 1. Agregar columna cooldown_minutes a session_settings (global, default 10 min)
ALTER TABLE session_settings ADD COLUMN IF NOT EXISTS cooldown_minutes INTEGER NOT NULL DEFAULT 10;

-- 2. Agregar columna cooldown_minutes a roles (NULL = hereda del global, 0 = desactivado)
ALTER TABLE roles ADD COLUMN IF NOT EXISTS cooldown_minutes INTEGER DEFAULT NULL;

-- 3. Agregar columna cooldown_minutes a users (NULL = hereda del rol/global, 0 = desactivado)
ALTER TABLE users ADD COLUMN IF NOT EXISTS cooldown_minutes INTEGER DEFAULT NULL;

-- 4. Agregar columna last_login_attempt a users (para rastrear último intento de login)
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_attempt TIMESTAMP DEFAULT NULL;

-- 5. Insertar permisos de mantenimiento de enfriamiento
INSERT INTO permissions (name, resource, action, description) VALUES
('view_attempts_settings', 'attempts_settings', 'view', 'Ver configuración de tiempo de enfriamiento'),
('edit_attempts_settings', 'attempts_settings', 'update', 'Editar configuración de tiempo de enfriamiento')
ON CONFLICT (name) DO NOTHING;

-- 6. Asignar permisos al rol admin
DO $$
DECLARE
    admin_role_id INT;
BEGIN
    SELECT id INTO admin_role_id FROM roles WHERE LOWER(name) IN ('admin', 'administrador', 'administrator');
    
    IF admin_role_id IS NOT NULL THEN
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT admin_role_id, id FROM permissions 
        WHERE name IN ('view_attempts_settings', 'edit_attempts_settings')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
