-- Tabela que registra os sensores disponíveis no sistema
CREATE TABLE sensores (
    id SERIAL PRIMARY KEY,                  	-- Identificador único do sensor
    tipo VARCHAR(50) NOT NULL,              	-- Tipo do sensor (ex: DHT22, sensor de solo)
    descricao VARCHAR(255),                 	-- Descrição detalhada do sensor
    unidade VARCHAR(50),                     	-- Unidade de medida do sensor (ex: %, °C)
    localizacao VARCHAR(100)                  	-- Localização física ou identificação do sensor
);

-- Tabela que armazena os atuadores que podem ser controlados
CREATE TABLE atuadores (
    id SERIAL PRIMARY KEY,                    	-- Identificador único do atuador
    tipo VARCHAR(50) NOT NULL,                	-- Tipo do atuador (ex: relé, bomba, válvula)
    descricao VARCHAR(255),                   	-- Descrição detalhada do atuador
    configuracao_json JSONB,                  	-- Configurações específicas do atuador em JSON (ex: parâmetros, timers)
    localizacao VARCHAR(100)                  	-- Localização física ou identificação do atuador
);

-- Tabela para registrar as leituras feitas pelos sensores
CREATE TABLE leituras_sensores (
    id SERIAL PRIMARY KEY,                    	-- Identificador único da leitura
    sensor_id INT REFERENCES sensores(id),   	-- FK para o sensor que realizou a leitura
    valor DECIMAL(10, 2),                     	-- Valor medido pelo sensor (com precisão decimal)
    data_leitura TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data e hora da leitura registrada
    CONSTRAINT fk_sensor FOREIGN KEY (sensor_id) REFERENCES sensores(id) -- Restrição de integridade referencial
);

-- Índice para acelerar consultas por sensor e data da leitura (muito usado para históricos)
CREATE INDEX idx_leituras_sensor_data ON leituras_sensores(sensor_id, data_leitura);

-- Tabela que registra comandos enviados para os atuadores
CREATE TABLE comandos_atuadores (
    id SERIAL PRIMARY KEY,                    	-- Identificador único do comando
    atuador_id INT REFERENCES atuadores(id), 	-- FK para o atuador a ser comandado
    estado BOOLEAN,                           	-- Estado desejado (true = ligar/ativar, false = desligar/desativar)
    data_comando TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data e hora do envio do comando
    duracao INT,                             	-- Duração do comando em segundos (se aplicável)
    status VARCHAR(50) DEFAULT 'pendente'   	-- Status do comando (ex: pendente, executado, falhou)
);

-- Tabela que contém as informações das plantas monitoradas/controladas
CREATE TABLE plantas (
    id SERIAL PRIMARY KEY,                    	-- Identificador único da planta
    nome VARCHAR(100) NOT NULL,               	-- Nome da planta (ex: Alface, Tomate)
    descricao VARCHAR(255),                    -- Descrição ou observações da planta
    umidade_soil_ideal DECIMAL(5, 2),         	-- Umidade ideal do solo para essa planta (em %)
    umidade_air_ideal DECIMAL(5, 2),          	-- Umidade ideal do ar para essa planta (em %)
    temperatura_ideal DECIMAL(5, 2),          	-- Temperatura ideal (em °C)
    luz_ideal VARCHAR(50),                     -- Necessidade ideal de luz (ex: baixa, média, alta)
    tipo_irrigacao VARCHAR(50)                 -- Tipo de irrigação (ex: gotejamento, aspersão)
);

-- Relacionamento N:N entre plantas e sensores, com configurações específicas para cada par
CREATE TABLE planta_sensor (
    id SERIAL PRIMARY KEY,                    	-- Identificador único da associação
    planta_id INT REFERENCES plantas(id),     	-- FK para a planta associada
    sensor_id INT REFERENCES sensores(id),   	-- FK para o sensor associado
    configuracao_json JSONB,                  	-- Configurações específicas do sensor para essa planta (ex: thresholds)
    status VARCHAR(50) DEFAULT 'ativo',      	-- Status da associação (ativo, inativo)
    ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Data da última atualização dessa configuração
);

-- Relacionamento N:N entre plantas e atuadores, com configurações específicas para cada par
CREATE TABLE planta_atuador (
    id SERIAL PRIMARY KEY,                    	-- Identificador único da associação
    planta_id INT REFERENCES plantas(id),     	-- FK para a planta associada
    atuador_id INT REFERENCES atuadores(id),  	-- FK para o atuador associado
    configuracao_json JSONB,                  	-- Configurações específicas do atuador para essa planta (ex: tempo de ativação)
    status VARCHAR(50) DEFAULT 'ativo',      	-- Status da associação (ativo, inativo)
    ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Data da última atualização dessa configuração
);

-- =========================
-- 1) PLANTAS (10 registros)
-- =========================
INSERT INTO plantas (nome, descricao, umidade_soil_ideal, umidade_air_ideal, temperatura_ideal, luz_ideal, tipo_irrigacao) VALUES
('Bromélia Porto Seguro', 'Espécie típica da Bahia, exige sombra parcial.', 60.00, 70.00, 24.00, 'média', 'aspersão'),
('Ingá de Metro', 'Árvore de fruto comestível, nativa da Mata Atlântica.', 50.00, 65.00, 26.00, 'alta', 'gotejamento'),
('Maranta Burle Marx', 'Planta ornamental de folhas largas e variegadas.', 65.00, 75.00, 23.00, 'baixa', 'aspersão'),
('Guapuruvu', 'Árvore de crescimento rápido, conhecida como Ficheira.', 45.00, 60.00, 25.00, 'alta', 'gotejamento'),
('Filodendro Ondulado', 'Planta ornamental de sombra, folhas onduladas.', 70.00, 80.00, 22.00, 'baixa', 'aspersão'),
('Bromélia Imperial', 'Espécie ornamental e resistente a ambientes úmidos.', 55.00, 70.00, 24.00, 'média', 'aspersão'),
('Trevo Roxo', 'Planta ornamental de folhas roxas, gosta de sombra.', 60.00, 75.00, 22.00, 'baixa', 'aspersão'),
('Cipó de São Miguel', 'Planta trepadeira de floração ornamental.', 50.00, 65.00, 25.00, 'média', 'gotejamento'),
('Maranta Tricolor', 'Planta de sombra com folhas verdes, vermelhas e brancas.', 65.00, 80.00, 23.00, 'baixa', 'aspersão'),
('Pau-Brasil', 'Árvore símbolo nacional, de madeira densa.', 45.00, 65.00, 27.00, 'alta', 'gotejamento');

-- =========================
-- 2) SENSORES (10 registros)
-- =========================
INSERT INTO sensores (tipo, descricao, unidade, localizacao) VALUES
('DHT22', 'Sensor de temperatura e umidade do ar', '°C/%', 'Estufa 1'),
('Sensor de Solo', 'Mede a umidade do solo', '%', 'Estufa 1'),
('LDR', 'Sensor de luminosidade', 'lux', 'Estufa 2'),
('DHT22', 'Sensor de temperatura e umidade do ar', '°C/%', 'Estufa 2'),
('Sensor de Solo', 'Mede a umidade do solo', '%', 'Estufa 3'),
('Higrômetro', 'Sensor de umidade relativa do ar', '%', 'Estufa 3'),
('BMP180', 'Sensor barométrico com temperatura', 'hPa/°C', 'Estufa 4'),
('DS18B20', 'Sensor de temperatura de solo', '°C', 'Estufa 4'),
('LDR', 'Sensor de luminosidade', 'lux', 'Estufa 5'),
('Sensor de Solo', 'Mede a umidade do solo', '%', 'Estufa 5');

-- =========================
-- 3) ATUADORES (10 registros)
-- =========================
INSERT INTO atuadores (tipo, descricao, configuracao_json, localizacao) VALUES
('Bomba', 'Bomba de irrigação gotejamento', '{"vazao":"1L/min"}', 'Estufa 1'),
('Válvula', 'Válvula de controle para aspersão', '{"pressao":"2bar"}', 'Estufa 1'),
('Relé', 'Relé de controle de luz artificial', '{"circuito":"220V"}', 'Estufa 2'),
('Bomba', 'Bomba de irrigação gotejamento', '{"vazao":"2L/min"}', 'Estufa 2'),
('Ventoinha', 'Sistema de ventilação automática', '{"velocidade":"3"}', 'Estufa 3'),
('Nebulizador', 'Controle de névoa para umidade', '{"intensidade":"média"}', 'Estufa 3'),
('Aquecedor', 'Aquecimento de estufa no inverno', '{"temp":"25"}', 'Estufa 4'),
('Exaustor', 'Controle de exaustão de ar', '{"velocidade":"alta"}', 'Estufa 4'),
('Válvula', 'Controle de irrigação por aspersão', '{"pressao":"1.5bar"}', 'Estufa 5'),
('Bomba', 'Bomba de alta pressão para fertirrigação', '{"vazao":"3L/min"}', 'Estufa 5');

-- =========================
-- 4) LEITURAS_SENSORES (10 registros simulados)
-- =========================
INSERT INTO leituras_sensores (sensor_id, valor, data_leitura) VALUES
(1, 24.50, NOW() - INTERVAL '10 min'),
(2, 58.20, NOW() - INTERVAL '9 min'),
(3, 320.00, NOW() - INTERVAL '8 min'),
(4, 25.10, NOW() - INTERVAL '7 min'),
(5, 61.40, NOW() - INTERVAL '6 min'),
(6, 68.30, NOW() - INTERVAL '5 min'),
(7, 1013.00, NOW() - INTERVAL '4 min'),
(8, 22.40, NOW() - INTERVAL '3 min'),
(9, 290.00, NOW() - INTERVAL '2 min'),
(10, 55.00, NOW() - INTERVAL '1 min');

-- =========================
-- 5) COMANDOS_ATUADORES (10 registros simulados)
-- =========================
INSERT INTO comandos_atuadores (atuador_id, estado, duracao, status, data_comando) VALUES
(1, TRUE, 120, 'executado', NOW() - INTERVAL '15 min'),
(2, TRUE, 90, 'executado', NOW() - INTERVAL '14 min'),
(3, TRUE, 300, 'pendente', NOW() - INTERVAL '13 min'),
(4, FALSE, 0, 'executado', NOW() - INTERVAL '12 min'),
(5, TRUE, 180, 'executado', NOW() - INTERVAL '11 min'),
(6, TRUE, 240, 'falhou', NOW() - INTERVAL '10 min'),
(7, TRUE, 600, 'executado', NOW() - INTERVAL '9 min'),
(8, FALSE, 0, 'executado', NOW() - INTERVAL '8 min'),
(9, TRUE, 150, 'executado', NOW() - INTERVAL '7 min'),
(10, TRUE, 200, 'pendente', NOW() - INTERVAL '6 min');

-- =========================
-- 6) PLANTA_SENSOR (10 associações)
-- =========================
INSERT INTO planta_sensor (planta_id, sensor_id, configuracao_json) VALUES
(1, 2, '{"umidade_min":55}'),
(2, 1, '{"temp_max":28}'),
(3, 3, '{"lux_min":200}'),
(4, 4, '{"temp_max":30}'),
(5, 5, '{"umidade_min":65}'),
(6, 6, '{"umidade_ar_min":65}'),
(7, 7, '{"pressao_min":1000}'),
(8, 8, '{"temp_solo_max":26}'),
(9, 9, '{"lux_min":250}'),
(10, 10, '{"umidade_min":50}');

-- =========================
-- 7) PLANTA_ATUADOR (10 associações)
-- =========================
INSERT INTO planta_atuador (planta_id, atuador_id, configuracao_json) VALUES
(1, 2, '{"tempo_segundos":120}'),
(2, 1, '{"tempo_segundos":180}'),
(3, 3, '{"horario":"18:00"}'),
(4, 4, '{"tempo_segundos":200}'),
(5, 5, '{"intervalo_minutos":30}'),
(6, 6, '{"tempo_segundos":150}'),
(7, 7, '{"manter_temp":25}'),
(8, 8, '{"velocidade":"alta"}'),
(9, 9, '{"tempo_segundos":90}'),
(10, 10, '{"tempo_segundos":210}');

-- Listar todas as plantas cadastradas
SELECT id, nome, tipo_irrigacao, luz_ideal
FROM plantas;

-- Listar todos os sensores disponíveis
SELECT id, tipo, unidade, localizacao
FROM sensores;

-- Listar todos os atuadores disponíveis
SELECT id, tipo, localizacao
FROM atuadores;

-- Últimas 5 leituras de sensores
SELECT id, sensor_id, valor, data_leitura
FROM leituras_sensores
ORDER BY data_leitura DESC
LIMIT 5;

-- Últimos 5 comandos enviados a atuadores
SELECT id, atuador_id, estado, status, data_comando
FROM comandos_atuadores
ORDER BY data_comando DESC
LIMIT 5;

-- tabela visitas - teste para gravar dados no banco integrado com a api e o docker
create table visitas (
	id SERIAL PRIMARY KEY,
	data_visita TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);