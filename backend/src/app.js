const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const routes = require('./routes');
const requestLogger = require('./middleware/requestLogger');
const { notFound, errorHandler } = require('./middleware/error');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(requestLogger);

app.get('/health', (req, res) => res.json({ ok: true, service: 'growwithme-backend' }));
app.use('/api/v1', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
