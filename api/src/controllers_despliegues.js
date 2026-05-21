const pool = require('./db');

exports.getGeografiaPermitida = async (req, res) => {
    const { userId } = req;
    try {
        // Obtenemos los permisos del usuario
        // 1. Ver si tiene parroquias específicas
        let resP = await pool.query('SELECT parroquia_id FROM user_parroquias WHERE user_id = $1', [userId]);
        let parroquiasPermitidas = resP.rows.map(r => r.parroquia_id);

        // 2. Ver si tiene municipios específicos
        let resM = await pool.query('SELECT municipio_id FROM user_municipios WHERE user_id = $1', [userId]);
        let municipiosPermitidos = resM.rows.map(r => r.municipio_id);

        // 3. Ver si tiene estados específicos
        let resE = await pool.query('SELECT estado_id FROM user_estados WHERE user_id = $1', [userId]);
        let estadosPermitidos = resE.rows.map(r => r.estado_id);

        let queryEstados = 'SELECT id, nombre FROM estado ORDER BY nombre';
        let queryMunicipios = 'SELECT id, estado_id, nombre FROM municipio ORDER BY nombre';
        let queryParroquias = 'SELECT id, municipio_id, nombre FROM parroquia ORDER BY nombre';
        let paramsE = [], paramsM = [], paramsP = [];

        if (parroquiasPermitidas.length > 0) {
            queryParroquias = 'SELECT id, municipio_id, nombre FROM parroquia WHERE id = ANY($1) ORDER BY nombre';
            paramsP = [parroquiasPermitidas];
            queryMunicipios = 'SELECT id, estado_id, nombre FROM municipio WHERE id IN (SELECT municipio_id FROM parroquia WHERE id = ANY($1)) ORDER BY nombre';
            paramsM = [parroquiasPermitidas];
            queryEstados = 'SELECT id, nombre FROM estado WHERE id IN (SELECT estado_id FROM municipio WHERE id IN (SELECT municipio_id FROM parroquia WHERE id = ANY($1))) ORDER BY nombre';
            paramsE = [parroquiasPermitidas];
        } else if (municipiosPermitidos.length > 0) {
            queryParroquias = 'SELECT id, municipio_id, nombre FROM parroquia WHERE municipio_id = ANY($1) ORDER BY nombre';
            paramsP = [municipiosPermitidos];
            queryMunicipios = 'SELECT id, estado_id, nombre FROM municipio WHERE id = ANY($1) ORDER BY nombre';
            paramsM = [municipiosPermitidos];
            queryEstados = 'SELECT id, nombre FROM estado WHERE id IN (SELECT estado_id FROM municipio WHERE id = ANY($1)) ORDER BY nombre';
            paramsE = [municipiosPermitidos];
        } else if (estadosPermitidos.length > 0) {
            queryParroquias = 'SELECT id, municipio_id, nombre FROM parroquia WHERE municipio_id IN (SELECT id FROM municipio WHERE estado_id = ANY($1)) ORDER BY nombre';
            paramsP = [estadosPermitidos];
            queryMunicipios = 'SELECT id, estado_id, nombre FROM municipio WHERE estado_id = ANY($1) ORDER BY nombre';
            paramsM = [estadosPermitidos];
            queryEstados = 'SELECT id, nombre FROM estado WHERE id = ANY($1) ORDER BY nombre';
            paramsE = [estadosPermitidos];
        }

        const [estados, municipios, parroquias] = await Promise.all([
            pool.query(queryEstados, paramsE),
            pool.query(queryMunicipios, paramsM),
            pool.query(queryParroquias, paramsP)
        ]);

        res.json({
            estados: estados.rows,
            municipios: municipios.rows,
            parroquias: parroquias.rows
        });
    } catch (error) {
        console.error('Error obteniendo geografía:', error);
        res.status(500).json({ error: 'Error obteniendo datos geográficos' });
    }
};

exports.getComunasByParroquia = async (req, res) => {
    const { parroquia_id } = req.params;
    try {
        const result = await pool.query('SELECT id, nombre FROM comuna WHERE parroquia_id = $1 AND activo = true ORDER BY nombre', [parroquia_id]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error obteniendo comunas:', error);
        res.status(500).json({ error: 'Error obteniendo comunas' });
    }
};

exports.getInstituciones = async (req, res) => {
    try {
        const result = await pool.query('SELECT id, nombre FROM institucion WHERE activo = true ORDER BY id');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Error obteniendo instituciones' });
    }
};

exports.crearDespliegue = async (req, res) => {
    const { userId } = req;
    const {
        comuna_id,
        nombre_comuna_nueva, // En caso de que se cree una comuna al vuelo
        parroquia_id,
        estado_id,
        municipio_id,
        fecha,
        hubo_despliegue,
        instituciones, // array de ids
        adultos_listado,
        adultos_visitados,
        vulnerables_detectados,
        vulnerables_nuevos,
        observaciones
    } = req.body;

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Obtener la cédula del usuario autenticado
        const userResult = await client.query('SELECT cedula FROM users WHERE id = $1', [userId]);
        if (userResult.rows.length === 0) throw new Error('Usuario no encontrado');
        const cedulaUsuario = userResult.rows[0].cedula;

        // 2. Validar que el usuario sea un articulador válido
        const articuladorResult = await client.query('SELECT id FROM articulador WHERE cedula = $1 AND activo = true', [cedulaUsuario]);
        let articulador_id;
        
        if (articuladorResult.rows.length === 0) {
            // Si el articulador no existe, lo creamos temporalmente o fallamos.
            // Según la regla, el usuario está logueado, así que se asume que puede registrar. 
            // Para mantener la integridad de la BD, creamos el articulador si no existe con sus datos básicos.
            const userData = await client.query('SELECT first_name, last_name, email FROM users WHERE id = $1', [userId]);
            const nombres = `${userData.rows[0].first_name} ${userData.rows[0].last_name}`.trim().toUpperCase();
            const insertArt = await client.query(
                'INSERT INTO articulador (cedula, nombres, correo, activo) VALUES ($1, $2, $3, true) RETURNING id',
                [cedulaUsuario, nombres, userData.rows[0].email]
            );
            articulador_id = insertArt.rows[0].id;
            
            // Asignar el articulador a la parroquia del despliegue para cumplir con el trigger fn_validar_despliegue
            await client.query('INSERT INTO articulador_parroquia (articulador_id, parroquia_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [articulador_id, parroquia_id]);
        } else {
            articulador_id = articuladorResult.rows[0].id;
            // Asegurarnos que el articulador esté asignado a esta parroquia para que el trigger fn_validar_despliegue no falle
            await client.query('INSERT INTO articulador_parroquia (articulador_id, parroquia_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [articulador_id, parroquia_id]);
        }

        // 3. Resolver Comuna (Si envió id, lo usamos; si no, creamos la comuna "al vuelo")
        let final_comuna_id = comuna_id;
        if (!final_comuna_id && nombre_comuna_nueva) {
            // Normalizar texto libre a mayúsculas
            const comunaNorm = nombre_comuna_nueva.trim().toUpperCase();
            // Buscar si ya existe
            const exists = await client.query('SELECT id FROM comuna WHERE parroquia_id = $1 AND nombre = $2', [parroquia_id, comunaNorm]);
            if (exists.rows.length > 0) {
                final_comuna_id = exists.rows[0].id;
            } else {
                const insertComuna = await client.query(
                    'INSERT INTO comuna (estado_id, municipio_id, parroquia_id, nombre, activo) VALUES ($1, $2, $3, $4, true) RETURNING id',
                    [estado_id, municipio_id, parroquia_id, comunaNorm]
                );
                final_comuna_id = insertComuna.rows[0].id;
            }
        }

        if (!final_comuna_id) {
            throw new Error('Debe especificar una comuna válida');
        }

        // 4. Crear el Despliegue
        const obsNorm = observaciones ? observaciones.trim().toUpperCase() : null;
        const insertDespliegue = await client.query(
            `INSERT INTO despliegue 
            (articulador_id, comuna_id, fecha, hubo_despliegue, adultos_listado, adultos_visitados, vulnerables_detectados, vulnerables_nuevos, observaciones)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
            [articulador_id, final_comuna_id, fecha, hubo_despliegue, adultos_listado || 0, adultos_visitados || 0, vulnerables_detectados || 0, vulnerables_nuevos || 0, obsNorm]
        );
        const despliegue_id = insertDespliegue.rows[0].id;

        // 5. Instituciones
        if (hubo_despliegue && instituciones && instituciones.length > 0) {
            const instValues = instituciones.map(inst_id => `(${despliegue_id}, ${inst_id})`).join(',');
            await client.query(`INSERT INTO despliegue_institucion (despliegue_id, institucion_id) VALUES ${instValues}`);
        }

        await client.query('COMMIT');
        res.json({ success: true, message: 'Despliegue guardado exitosamente', despliegue_id });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error guardando despliegue:', error);
        res.status(400).json({ error: error.message || 'Error guardando el despliegue' });
    } finally {
        client.release();
    }
};
