const express = require('express');
const app = express();
const port = 8080;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Main endpoint
app.get('/', (req, res) => {
  res.send('Namaste from Container');
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
}); 