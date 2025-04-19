const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health check endpoint at /api/health
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Main endpoint at /api
app.get('/api', (req, res) => {
  res.send('Hello from Microservice');
});

// Root endpoint redirect to /api
app.get('/', (req, res) => {
  res.redirect('/api');
});

app.listen(port, () => {
  console.log(`Microservice listening at http://localhost:${port}`);
}); 