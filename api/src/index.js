require('dotenv').config({ path: `.env.${process.env.NODE_ENV || 'development'}` });
const express = require('express');
const cors = require('cors');
const listEndpoints = require('./endpointlister');
const desplieguesRoutes = require('./routes_despliegues');

const app = express();
const PORT = process.env.PORT_API || 4131;

// CORS
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map(o => o.trim())
    .filter(Boolean);

app.use(cors({
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('No autorizado por CORS'));
        }
    },
    credentials: true,
}));

app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'Despliegue API', timestamp: new Date().toISOString() });
});

// Endpoints Lister
app.get('/endpoints', (req, res) => {
    const endpoints = listEndpoints(app);
    let html = '<html><head><title>API Endpoints</title><style>body{font-family:sans-serif;}table{border-collapse:collapse;width:100%;}th,td{border:1px solid #ddd;padding:8px;text-align:left;}th{background-color:#f2f2f2;}</style></head><body>';
    html += '<h2>Endpoints Disponibles en API</h2><table><tr><th>Métodos</th><th>Ruta</th></tr>';
    endpoints.forEach(e => {
        html += `<tr><td>${e.methods.join(', ')}</td><td>${e.path}</td></tr>`;
    });
    html += '</table></body></html>';
    res.send(html);
});

// Routes
app.use('/api/despliegues', desplieguesRoutes);

// Error Handler
app.use((err, req, res, next) => {
    console.error('API Error:', err.message);
    res.status(500).json({ error: 'Error interno del servicio API' });
});

app.listen(PORT, () => {
    console.log(`🚀 API Service corriendo en http://localhost:${PORT}`);
    console.log(`📄 Endpoints: http://localhost:${PORT}/endpoints`);
});
