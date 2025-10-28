const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

const { Pool } = require('pg');

const pool = new Pool({
  host: 'database', //pegou
//  host: 'molha-me-database-container', //pegou
  user: 'postgres',
  password: '123456',
  database: 'molha_me_db',
  port: 5432
});

// Middleware
app.use(cors());
app.use(express.json());

// ===========================================
// THRESHOLDS PADRÃO (FALLBACK)
// ===========================================
let thresholds = {
  temperatura_max: 30.0,     // °C
  umidade_min: 40.0,        // %
  luminosidade_min: 200.0,  // lux
  distancia_min: 5.0,       // cm
  distancia_max: 50.0       // cm
};

// ===========================================
// HISTÓRICO DE DADOS (SIMPLES)
// ===========================================
let dadosHistorico = [];

// ===========================================
// ROTAS DA API
// ===========================================

// GET /api/get-thresholds - Buscar thresholds atualizados
app.get('/api/get-thresholds', (req, res) => {
  console.log('GET /api/get-thresholds - Enviando thresholds:', thresholds);
  res.json(thresholds);
});

// POST /api/send-data - Receber dados dos sensores
app.post('/api/send-data', (req, res) => {
  const dados = req.body;
  console.log('POST /api/send-data - Dados recebidos:', dados);
  
  // Adicionar timestamp se não tiver
  if (!dados.timestamp) {
    dados.timestamp = Date.now();
  }
  
  // Armazenar no histórico (manter apenas últimos 100 registros)
  dadosHistorico.push(dados);
  if (dadosHistorico.length > 100) {
    dadosHistorico.shift(); // Remove o mais antigo
  }
  
  res.json({ 
    success: true, 
    message: 'Dados recebidos com sucesso',
    timestamp: Date.now()
  });
});

// GET /api/get-data - Buscar dados para dashboard
app.get('/api/get-data', (req, res) => {
  const ultimosDados = dadosHistorico.slice(-10); // Últimos 10 registros
  const dadosAtuais = ultimosDados[ultimosDados.length - 1] || {};
  
  res.json({
    dados_atuais: dadosAtuais,
    historico: ultimosDados,
    thresholds: thresholds,
    total_registros: dadosHistorico.length,
    api_status: 'online'
  });
});

// POST /api/update-thresholds - Atualizar thresholds (opcional)
app.post('/api/update-thresholds', (req, res) => {
  const novosThresholds = req.body;
  console.log('POST /api/update-thresholds - Atualizando:', novosThresholds);
  
  // Validar dados
  if (novosThresholds.temperatura_max) thresholds.temperatura_max = novosThresholds.temperatura_max;
  if (novosThresholds.umidade_min) thresholds.umidade_min = novosThresholds.umidade_min;
  if (novosThresholds.luminosidade_min) thresholds.luminosidade_min = novosThresholds.luminosidade_min;
  if (novosThresholds.distancia_min) thresholds.distancia_min = novosThresholds.distancia_min;
  if (novosThresholds.distancia_max) thresholds.distancia_max = novosThresholds.distancia_max;
  
  res.json({ 
    success: true, 
    message: 'Thresholds atualizados',
    thresholds: thresholds
  });
});

// POST /api/inserir-data - Inserir dados na tabela visitas para testar conexao com o banco de dados
app.post('/api/inserir-data', async (req, res) => {
  try {
    const now = new Date();

    const query = 'INSERT INTO visitas (data_visita) VALUES ($1)';
    await pool.query(query, [now]);

    res.json({
      success: true,
      message: 'Data atual inserida com sucesso no banco de dados.',
      data_inserida: now
    });
  } catch (err) {
    console.error('Erro ao inserir data no PostgreSQL:', err);
    res.status(500).json({
      success: false,
      message: 'Erro ao inserir data no banco de dados.', err
    });
  }
});

// GET / - Página inicial simples
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Molha.me - API</title>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; }
            .status { background: #27ae60; color: white; padding: 10px; border-radius: 5px; margin: 20px 0; }
            .endpoint { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .method { background: #3498db; color: white; padding: 5px 10px; border-radius: 3px; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🌱 Molha.me - API IoT</h1>
            <div class="status">✅ API Online - Porta ${PORT}</div>
            
            <h2>Endpoints Disponíveis:</h2>
            
            <div class="endpoint">
                <span class="method">GET</span> /api/get-thresholds<br>
                <small>Buscar thresholds atualizados para o ESP32</small>
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /api/send-data<br>
                <small>Receber dados dos sensores do ESP32</small>
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /api/get-data<br>
                <small>Buscar dados para dashboard</small>
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /api/update-thresholds<br>
                <small>Atualizar thresholds (opcional)</small>
            </div>
            
            <h2>Thresholds Atuais:</h2>
            <ul>
                <li>Temperatura Máxima: ${thresholds.temperatura_max}°C</li>
                <li>Umidade Mínima: ${thresholds.umidade_min}%</li>
                <li>Luminosidade Mínima: ${thresholds.luminosidade_min} lux</li>
                <li>Distância Mínima: ${thresholds.distancia_min} cm</li>
                <li>Distância Máxima: ${thresholds.distancia_max} cm</li>
            </ul>
            
            <h2>Status:</h2>
            <p>Registros no histórico: ${dadosHistorico.length}</p>
            <p>Última atualização: ${new Date().toLocaleString()}</p>
        </div>
    </body>
    </html>
  `);
});

// ===========================================
// INICIAR SERVIDOR
// ===========================================
app.listen(PORT, () => {
  console.log('===============================================');
  console.log('🌱 MOLHA.ME - API IoT SIMPLIFICADA');
  console.log('===============================================');
  console.log(`Servidor rodando na porta ${PORT}`);
  console.log(`Acesse: http://localhost:${PORT}`);
  console.log('===============================================');
  console.log('Endpoints:');
  console.log('  GET  /api/get-thresholds  - Buscar thresholds');
  console.log('  POST /api/send-data       - Enviar dados');
  console.log('  GET  /api/get-data        - Buscar dados');
  console.log('  POST /api/update-thresholds - Atualizar thresholds');
  console.log('===============================================');
});
