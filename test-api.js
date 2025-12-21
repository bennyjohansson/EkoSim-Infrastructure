const express = require('express');
const app = express();

app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

app.get('/', (req, res) => {
    res.json({ 
        status: 'API Connected!', 
        message: 'EkoSim Infrastructure Working',
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Test API running on port ${PORT}`);
});