const express = require('express');
const router = express.Router();
const controller = require('./controllers_despliegues');
const { authenticate } = require('./middlewares');

router.use(authenticate); // Todas las rutas protegidas

// Catálogos Geográficos (Filtrados por alcance del usuario)
router.get('/catalogos/geografia', controller.getGeografiaPermitida);
router.get('/catalogos/comunas/:parroquia_id', controller.getComunasByParroquia);

// Catálogo de Instituciones
router.get('/catalogos/instituciones', controller.getInstituciones);

// Registro de Despliegue
router.post('/', controller.crearDespliegue);

module.exports = router;
