-- ============================================================
-- FIX: Remover view_all_centros del rol usuario
-- ============================================================

DELETE FROM public.role_permissions
WHERE role_id = (SELECT id FROM public.roles WHERE name = 'usuario')
  AND permission_id = (SELECT id FROM public.permissions WHERE name = 'view_all_centros');
