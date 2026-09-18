<!DOCTYPE HTML>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Batalla Naval - Edición Táctica Definitiva</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;800;900&family=Rajdhani:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --neon-cyan: #38bdf8;
            --neon-blue: #0284c7;
            --neon-red: #f43f5e;
            --radar-green: #10b981;
            --dark-navy: #060913;
            --panel-bg: rgba(11, 19, 38, 0.88);
            --cell-water: #0f172a;
            --cell-water-hover: #1e293b;
            --cell-miss: #334155;
            --cell-hit: #e11d48;
            --cell-ship: #2563eb;
            --cell-sunk: #090d16;
        }

        body {
            background-color: var(--dark-navy);
            color: #f8fafc;
            font-family: 'Rajdhani', sans-serif;
            background-image: 
                radial-gradient(circle at 50% 30%, rgba(14, 165, 233, 0.08) 0%, transparent 65%),
                radial-gradient(circle at 20% 80%, rgba(244, 63, 94, 0.04) 0%, transparent 50%),
                linear-gradient(to bottom, #060913, #020408);
            min-height: 100vh;
            overflow-x: hidden;
        }

        .title-font {
            font-family: 'Orbitron', sans-serif;
        }

        .glow-box {
            background: var(--panel-bg);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(56, 189, 248, 0.25);
            box-shadow: 0 0 35px rgba(14, 165, 233, 0.12), inset 0 0 20px rgba(14, 165, 233, 0.04);
        }

        .glow-button {
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            border: 1px solid #38bdf8;
            box-shadow: 0 0 20px rgba(56, 189, 248, 0.4);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .glow-button:hover {
            background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
            box-shadow: 0 0 30px rgba(56, 189, 248, 0.8);
            transform: translateY(-2px);
        }

        .glow-button-secondary {
            background: linear-gradient(135deg, #334155 0%, #1e293b 100%);
            border: 1px solid #64748b;
            box-shadow: 0 0 15px rgba(100, 116, 139, 0.2);
            transition: all 0.3s ease;
        }

        .glow-button-secondary:hover {
            background: linear-gradient(135deg, #475569 0%, #334155 100%);
            box-shadow: 0 0 25px rgba(100, 116, 139, 0.4);
            transform: translateY(-2px);
        }

        .tactical-board {
            display: grid;
            grid-template-columns: repeat(10, 1fr);
            gap: 4px;
            background-color: rgba(15, 23, 42, 0.9);
            padding: 8px;
            border-radius: 10px;
            border: 1px solid rgba(56, 189, 248, 0.35);
            width: 100%;
            aspect-ratio: 1 / 1;
            position: relative;
            box-shadow: inset 0 0 25px rgba(0,0,0,0.7), 0 0 15px rgba(0,0,0,0.5);
        }

        .tactical-cell {
            background-color: var(--cell-water);
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 1px solid rgba(255, 255, 255, 0.03);
        }

        .board.interactive .tactical-cell:hover:not(.miss):not(.hit):not(.sunk) {
            background-color: #0284c7;
            box-shadow: 0 0 12px #38bdf8, inset 0 0 6px rgba(255,255,255,0.4);
            transform: scale(1.06);
            z-index: 10;
        }

        .tactical-cell.ship {
            background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);
            border-color: #60a5fa;
            box-shadow: inset 0 0 10px rgba(96, 165, 250, 0.6), 0 0 8px rgba(37, 99, 235, 0.4);
        }

        .tactical-cell.miss {
            background-color: #334155;
            cursor: default;
            animation: fadeInCell 0.3s ease;
        }
        .tactical-cell.miss::after {
            content: '';
            width: 7px;
            height: 7px;
            background-color: #94a3b8;
            border-radius: 50%;
            box-shadow: 0 0 8px #94a3b8;
        }

        .tactical-cell.hit {
            background: linear-gradient(135deg, #f43f5e 0%, #be123c 100%);
            border-color: #fb7185;
            box-shadow: 0 0 15px #f43f5e, inset 0 0 8px rgba(255,255,255,0.6);
            cursor: default;
            animation: pulse-hit 1.2s infinite;
        }
        .tactical-cell.hit::after {
            content: '💥';
            font-size: 0.8rem;
            filter: drop-shadow(0 0 4px rgba(0,0,0,0.8));
        }

        .tactical-cell.sunk {
            background-color: #090d16;
            border-color: #1e293b;
            box-shadow: inset 0 0 12px rgba(0,0,0,0.9);
            cursor: default;
        }
        .tactical-cell.sunk::after {
            content: '❌';
            font-size: 0.8rem;
            opacity: 0.75;
        }

        @keyframes pulse-hit {
            0% { box-shadow: 0 0 6px #f43f5e, inset 0 0 4px rgba(255,255,255,0.4); }
            50% { box-shadow: 0 0 20px #f43f5e, inset 0 0 10px #fff; transform: scale(1.03); }
            100% { box-shadow: 0 0 6px #f43f5e, inset 0 0 4px rgba(255,255,255,0.4); }
        }

        @keyframes fadeInCell {
            from { opacity: 0; transform: scale(0.7); }
            to { opacity: 1; transform: scale(1); }
        }

        .radar-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: linear-gradient(rgba(14, 165, 233, 0) 50%, rgba(14, 165, 233, 0.04) 50%);
            background-size: 100% 4px;
            pointer-events: none;
            border-radius: 10px;
        }

        .screen {
            display: none;
        }
        .screen.active {
            display: flex;
            animation: fadeInScreen 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes fadeInScreen {
            from { opacity: 0; transform: translateY(8px) scale(0.98); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        ::-webkit-scrollbar {
            width: 6px;
        }
        ::-webkit-scrollbar-track {
            background: #060913;
        }
        ::-webkit-scrollbar-thumb {
            background: #38bdf8;
            border-radius: 3px;
        }
    </style>
</head>
<body class="flex flex-col items-center justify-between p-4 md:p-8">

    <header class="w-full max-w-4xl flex items-center justify-between mb-6 border-b border-sky-500/30 pb-4">
        <div class="flex items-center gap-3">
            <div class="w-11 h-11 rounded-xl bg-gradient-to-br from-sky-500/20 to-sky-700/40 border border-sky-400 flex items-center justify-center text-sky-300 font-bold title-font text-xl shadow-[0_0_20px_rgba(56,189,248,0.4)]">
                NV
            </div>
            <div>
                <h1 class="title-font text-lg md:text-2xl font-extrabold tracking-wider text-sky-400 drop-shadow-[0_0_12px_rgba(56,189,248,0.6)]">BATALLA NAVAL</h1>
                <p class="text-xs text-sky-300/70 tracking-widest uppercase">Sistema Táctico Pass & Play</p>
            </div>
        </div>
        <div id="game-status-badge" class="hidden px-3.5 py-1.5 rounded-full text-xs font-bold tracking-wider bg-sky-500/15 border border-sky-400/40 text-sky-300 shadow-[0_0_10px_rgba(56,189,248,0.2)] animate-pulse">
            RADAR ACTIVO
        </div>
    </header>

    <main class="w-full max-w-4xl flex-1 flex flex-col items-center justify-center">

        <!-- 1. PANTALLA DE INICIO -->
        <div id="screen-start" class="screen active glow-box w-full p-8 md:p-14 rounded-2xl flex-col items-center text-center max-w-xl">
            <div class="w-24 h-24 rounded-2xl bg-gradient-to-br from-sky-500/20 to-blue-600/30 border-2 border-sky-400/60 flex items-center justify-center mb-6 shadow-[0_0_35px_rgba(56,189,248,0.35)]">
                <svg class="w-12 h-12 text-sky-400 drop-shadow-[0_0_8px_rgba(56,189,248,0.8)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
                </svg>
            </div>
            <h2 class="title-font text-2xl md:text-3xl font-extrabold mb-3 text-white tracking-wide">CENTRO DE MANDO NAVAL</h2>
            <p class="text-slate-300 text-sm md:text-base mb-8 leading-relaxed">
                Despliega tu flota en el sector estratégico. Acertar un objetivo enemigo te otorga un turno de ataque extra consecutivo. ¡Hunde toda la flota hostil para ganar!
            </p>
            <button onclick="startGame()" class="glow-button w-full md:w-auto px-10 py-4 rounded-xl text-white font-bold tracking-wider text-base md:text-lg">
                INICIALIZAR COMBATE
            </button>
        </div>

        <!-- 2. PANTALLA DE TRANSICIÓN (Pass and Play) -->
        <div id="screen-transition" class="screen glow-box w-full p-8 md:p-14 rounded-2xl flex-col items-center text-center max-w-xl">
            <div class="w-24 h-24 rounded-2xl bg-gradient-to-br from-amber-500/20 to-orange-600/30 border-2 border-amber-400/60 flex items-center justify-center mb-6 shadow-[0_0_35px_rgba(251,191,36,0.35)] text-amber-400">
                <svg class="w-12 h-12 drop-shadow-[0_0_8px_rgba(251,191,36,0.8)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                </svg>
            </div>
            <h2 id="transition-message" class="title-font text-2xl md:text-3xl font-extrabold mb-3 text-amber-300">Pasa el dispositivo al Jugador 1</h2>
            <p class="text-slate-300 text-sm md:text-base mb-8 leading-relaxed">Por protocolo táctico, asegúrate de que el comandante opuesto no esté observando la pantalla.</p>
            <button onclick="startTurn()" class="glow-button w-full md:w-auto px-10 py-4 rounded-xl text-white font-bold tracking-wider text-base md:text-lg">
                ESTOY LISTO, INICIAR TURNO
            </button>
        </div>

        <!-- 3. PANTALLA DE PREPARACIÓN DE FLOTA -->
        <div id="screen-setup" class="screen glow-box w-full p-6 md:p-8 rounded-2xl flex-col items-center">
            <h2 id="setup-title" class="title-font text-xl md:text-2xl font-bold mb-2 text-sky-400">Preparación: Comandante</h2>
            <p class="text-slate-300 text-xs md:text-sm mb-6 text-center">Tu flota ha sido posicionada por radar automático. Puedes reorganizarla antes de confirmar.</p>
            
            <div class="w-full max-w-[320px] md:max-w-[380px] mb-6">
                <div class="radar-overlay"></div>
                <div id="setup-board" class="tactical-board"></div>
            </div>

            <div class="flex flex-wrap gap-4 justify-center w-full max-w-md">
                <button onclick="randomizeShips()" class="glow-button-secondary flex-1 px-5 py-3.5 rounded-xl text-slate-200 font-semibold text-sm">
                    Reorganizar Flota
                </button>
                <button id="btn-finish-setup" onclick="finishSetup()" class="glow-button flex-1 px-5 py-3.5 rounded-xl text-white font-bold text-sm">
                    Confirmar Posiciones
                </button>
            </div>
        </div>

        <!-- 4. PANTALLA DE COMBATE TÁCTICO -->
        <div id="screen-combat" class="screen glow-box w-full p-4 md:p-6 rounded-2xl flex-col items-center">
            <div class="flex flex-col md:flex-row justify-between items-center w-full mb-5 border-b border-slate-700/60 pb-3.5 gap-3">
                <h2 id="combat-title" class="title-font text-lg md:text-xl font-bold text-sky-400">Turno de Operaciones</h2>
                <div id="combat-status" class="text-xs md:text-sm font-semibold text-sky-300 text-center px-4 py-2 rounded-xl bg-slate-900/90 border border-sky-500/30 shadow-[0_0_15px_rgba(56,189,248,0.1)]">
                    Selecciona una coordenada en el Radar Enemigo para atacar.
                </div>
            </div>
            
            <!-- Contenedor Dual de Tableros -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-3xl mb-6">
                <!-- Tablero Defensivo (Propio) -->
                <div class="flex flex-col items-center bg-slate-900/70 p-4 md:p-5 rounded-xl border border-slate-800">
                    <div class="text-xs font-bold tracking-wider text-sky-400 uppercase mb-3 flex items-center gap-2">
                        <span class="w-2.5 h-2.5 rounded-full bg-sky-400 animate-pulse"></span> Sectores de Defensa (Tu Flota)
                    </div>
                    <div class="w-full max-w-[260px] mb-3">
                        <div id="defensive-board" class="tactical-board"></div>
                    </div>
                    <div id="defensive-fleet" class="flex flex-wrap justify-center gap-1.5 w-full mt-2"></div>
                </div>

                <!-- Tablero Ofensivo (Radar Enemigo) -->
                <div class="flex flex-col items-center bg-slate-900/70 p-4 md:p-5 rounded-xl border border-slate-800">
                    <div class="text-xs font-bold tracking-wider text-rose-400 uppercase mb-3 flex items-center gap-2">
                        <span class="w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse"></span> Radar de Ataque (Enemigo)
                    </div>
                    <div class="w-full max-w-[260px] mb-3 relative">
                        <div class="radar-overlay"></div>
                        <div id="offensive-board" class="tactical-board interactive"></div>
                    </div>
                    <div id="offensive-fleet" class="flex flex-wrap justify-center gap-1.5 w-full mt-2"></div>
                </div>
            </div>

            <button id="btn-end-turn" style="display: none;" onclick="endTurn()" class="glow-button px-8 py-3.5 rounded-xl text-white font-bold tracking-wider text-sm shadow-[0_0_20px_rgba(56,189,248,0.4)]">
                FINALIZAR TURNO (PASAR DISPOSITIVO)
            </button>
        </div>

        <!-- 5. PANTALLA DE VICTORIA -->
        <div id="screen-game-over" class="screen glow-box w-full p-8 md:p-14 rounded-2xl flex-col items-center text-center max-w-xl">
            <div class="w-24 h-24 rounded-2xl bg-gradient-to-br from-rose-500/20 to-red-700/30 border-2 border-rose-500/60 flex items-center justify-center mb-6 shadow-[0_0_35px_rgba(244,63,94,0.4)] text-rose-400">
                <svg class="w-12 h-12 drop-shadow-[0_0_8px_rgba(244,63,94,0.8)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"></path>
                </svg>
            </div>
            <h2 id="winner-message" class="title-font text-2xl md:text-3xl font-extrabold mb-3 text-rose-400 tracking-wide">¡VICTORIA TÁCTICA!</h2>
            <p class="text-slate-300 text-sm md:text-base mb-8 leading-relaxed">Toda la flota hostil ha sido completamente neutralizada del sector.</p>
            <button onclick="resetGame()" class="glow-button w-full md:w-auto px-10 py-4 rounded-xl text-white font-bold tracking-wider text-base md:text-lg">
                NUEVA OPERACIÓN
            </button>
        </div>

    </main>

    <footer class="w-full max-w-4xl text-center text-xs text-slate-500 mt-6 pt-4 border-t border-slate-800">
        Batalla Naval Táctica • Edición Interactiva Pass & Play para Vercel
    </footer>

    <script>
        const BOARD_SIZE = 10;
        const SHIPS_CONFIG = [
            { id: 'carrier', name: 'Portaaviones', size: 5 },
            { id: 'battleship', name: 'Acorazado', size: 4 },
            { id: 'cruiser', name: 'Crucero', size: 3 },
            { id: 'submarine', name: 'Submarino', size: 3 },
            { id: 'destroyer', name: 'Destructor', size: 2 }
        ];

        let gameState = {
            players: [
                { id: 1, name: "Comandante Alfa", board: [], ships: [], shots: [] },
                { id: 2, name: "Comandante Omega", board: [], ships: [], shots: [] }
            ],
            currentPlayerIndex: 0,
            phase: 'start',
            actionCompleted: false
        };

        const showScreen = (screenId) => {
            document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
            document.getElementById(screenId).classList.add('active');
            const badge = document.getElementById('game-status-badge');
            if(screenId === 'screen-start' || screenId === 'screen-game-over') {
                badge.classList.add('hidden');
            } else {
                badge.classList.remove('hidden');
            }
        };

        const createEmptyBoard = () => Array(BOARD_SIZE).fill(null).map(() => Array(BOARD_SIZE).fill({ type: 'water', hit: false }));

        function initPlayerState(player) {
            player.board = createEmptyBoard();
            player.ships = SHIPS_CONFIG.map(config => ({
                ...config,
                positions: [],
                hits: 0,
                sunk: false
            }));
            player.shots = createEmptyBoard();
        }

        function startGame() {
            initPlayerState(gameState.players[0]);
            initPlayerState(gameState.players[1]);
            gameState.currentPlayerIndex = 0;
            gameState.phase = 'setup';
            prepareSetupScreen();
        }

        function prepareSetupScreen() {
            const player = gameState.players[gameState.currentPlayerIndex];
            document.getElementById('setup-title').innerText = `Preparación: ${player.name}`;
            randomizeShips();
            showScreen('screen-setup');
        }

        function canPlaceShip(board, row, col, size, isHorizontal) {
            if (isHorizontal) {
                if (col + size > BOARD_SIZE) return false;
                for (let i = 0; i < size; i++) {
                    if (board[row][col + i].type !== 'water') return false;
                }
            } else {
                if (row + size > BOARD_SIZE) return false;
                for (let i = 0; i < size; i++) {
                    if (board[row + i][col].type !== 'water') return false;
                }
            }
            return true;
        }

        function placeShip(board, ship, row, col, isHorizontal) {
            ship.positions = [];
            for (let i = 0; i < ship.size; i++) {
                let r = isHorizontal ? row : row + i;
                let c = isHorizontal ? col + i : col;
                board[r][c] = { type: 'ship', shipId: ship.id, hit: false };
                ship.positions.push({ r, c });
            }
        }

        function randomizeShips() {
            const player = gameState.players[gameState.currentPlayerIndex];
            player.board = createEmptyBoard();
            
            player.ships.forEach(ship => {
                let placed = false;
                while (!placed) {
                    const row = Math.floor(Math.random() * BOARD_SIZE);
                    const col = Math.floor(Math.random() * BOARD_SIZE);
                    const isHorizontal = Math.random() > 0.5;

                    if (canPlaceShip(player.board, row, col, ship.size, isHorizontal)) {
                        placeShip(player.board, ship, row, col, isHorizontal);
                        placed = true;
                    }
                }
            });
            renderSetupBoard();
        }

        function renderSetupBoard() {
            const player = gameState.players[gameState.currentPlayerIndex];
            const boardEl = document.getElementById('setup-board');
            boardEl.innerHTML = '';

            for (let r = 0; r < BOARD_SIZE; r++) {
                for (let c = 0; c < BOARD_SIZE; c++) {
                    const cell = document.createElement('div');
                    cell.className = 'tactical-cell';
                    if (player.board[r][c].type === 'ship') {
                        cell.classList.add('ship');
                    }
                    boardEl.appendChild(cell);
                }
            }
        }

        function finishSetup() {
            if (gameState.currentPlayerIndex === 0) {
                gameState.currentPlayerIndex = 1;
                showTransitionScreen(`Pasa el dispositivo a ${gameState.players[1].name}`);
            } else {
                gameState.phase = 'combat';
                gameState.currentPlayerIndex = 0;
                showTransitionScreen(`Iniciando Fase de Combate. Turno de ${gameState.players[0].name}`);
            }
        }

        function showTransitionScreen(message) {
            document.getElementById('transition-message').innerText = message;
            showScreen('screen-transition');
        }

        function startTurn() {
            if (gameState.phase === 'setup') {
                prepareSetupScreen();
            } else if (gameState.phase === 'combat') {
                prepareCombatScreen();
            }
        }

        function endTurn() {
            gameState.currentPlayerIndex = gameState.currentPlayerIndex === 0 ? 1 : 0;
            gameState.actionCompleted = false;
            const nextPlayer = gameState.players[gameState.currentPlayerIndex];
            showTransitionScreen(`Turno finalizado. Pasa el dispositivo a ${nextPlayer.name}`);
        }

        function prepareCombatScreen() {
            const currentPlayer = gameState.players[gameState.currentPlayerIndex];
            document.getElementById('combat-title').innerText = `Centro de Comando: ${currentPlayer.name}`;
            document.getElementById('combat-status').innerText = "Selecciona una coordenada en el Radar Enemigo para disparar.";
            document.getElementById('combat-status').style.color = "#38bdf8";
            document.getElementById('btn-end-turn').style.display = 'none';
            
            renderDefensiveBoard();
            renderOffensiveBoard();
            renderFleetStatus();
            
            showScreen('screen-combat');
        }

        function renderDefensiveBoard() {
            const player = gameState.players[gameState.currentPlayerIndex];
            const boardEl = document.getElementById('defensive-board');
            boardEl.innerHTML = '';

            for (let r = 0; r < BOARD_SIZE; r++) {
                for (let c = 0; c < BOARD_SIZE; c++) {
                    const cellData = player.board[r][c];
                    const cell = document.createElement('div');
                    cell.className = 'tactical-cell';
                    
                    if (cellData.type === 'ship') {
                        cell.classList.add('ship');
                        if (cellData.hit) {
                            const ship = player.ships.find(s => s.id === cellData.shipId);
                            cell.classList.add(ship.sunk ? 'sunk' : 'hit');
                        }
                    } else if (cellData.hit) {
                        cell.classList.add('miss');
                    }
                    boardEl.appendChild(cell);
                }
            }
        }

        function renderOffensiveBoard() {
            const currentPlayer = gameState.players[gameState.currentPlayerIndex];
            const opponentIndex = gameState.currentPlayerIndex === 0 ? 1 : 0;
            const opponent = gameState.players[opponentIndex];
            const boardEl = document.getElementById('offensive-board');
            boardEl.innerHTML = '';

            for (let r = 0; r < BOARD_SIZE; r++) {
                for (let c = 0; c < BOARD_SIZE; c++) {
                    const shotData = currentPlayer.shots[r][c];
                    const cell = document.createElement('div');
                    cell.className = 'tactical-cell';
                    
                    if (shotData.hit) {
                        if (shotData.type === 'ship') {
                            const enemyShip = opponent.ships.find(s => s.id === shotData.shipId);
                            cell.classList.add(enemyShip.sunk ? 'sunk' : 'hit');
                        } else {
                            cell.classList.add('miss');
                        }
                    }

                    cell.onclick = () => handleShot(r, c);
                    boardEl.appendChild(cell);
                }
            }
        }

        function renderFleetStatus() {
            const currentPlayer = gameState.players[gameState.currentPlayerIndex];
            const opponentIndex = gameState.currentPlayerIndex === 0 ? 1 : 0;
            const opponent = gameState.players[opponentIndex];

            const defContainer = document.getElementById('defensive-fleet');
            defContainer.innerHTML = '';
            currentPlayer.ships.forEach(ship => {
                const badge = document.createElement('span');
                badge.className = `text-[10px] md:text-xs px-2 py-0.5 rounded-md font-semibold border ${ship.sunk ? 'bg-rose-500/20 border-rose-500/40 text-rose-300 line-through' : 'bg-slate-800 border-slate-700 text-sky-300'}`;
                badge.innerText = ship.name;
                defContainer.appendChild(badge);
            });

            const offContainer = document.getElementById('offensive-fleet');
            offContainer.innerHTML = '';
            opponent.ships.forEach(ship => {
                if(ship.sunk) {
                    const badge = document.createElement('span');
                    badge.className = 'text-[10px] md:text-xs px-2 py-0.5 rounded-md font-semibold border bg-rose-500/20 border-rose-500/40 text-rose-300 line-through';
                    badge.innerText = ship.name + ' (Hundido)';
                    offContainer.appendChild(badge);
                }
            });
            if(offContainer.children.length === 0) {
                 const badge = document.createElement('span');
                 badge.className = 'text-[10px] md:text-xs px-2.5 py-0.5 rounded-md font-medium text-slate-400 bg-slate-800/50 border border-slate-700/50';
                 badge.innerText = 'Flota enemiga oculta';
                 offContainer.appendChild(badge);
            }
        }

        function handleShot(r, c) {
            if (gameState.actionCompleted) return;
            
            const currentPlayer = gameState.players[gameState.currentPlayerIndex];
            const opponentIndex = gameState.currentPlayerIndex === 0 ? 1 : 0;
            const opponent = gameState.players[opponentIndex];

            if (currentPlayer.shots[r][c].hit) return;

            const targetCell = opponent.board[r][c];
            targetCell.hit = true;
            currentPlayer.shots[r][c] = { hit: true, type: targetCell.type, shipId: targetCell.shipId };

            const statusEl = document.getElementById('combat-status');

            if (targetCell.type === 'ship') {
                const hitShip = opponent.ships.find(s => s.id === targetCell.shipId);
                hitShip.hits++;
                
                if (hitShip.hits === hitShip.size) {
                    hitShip.sunk = true;
                    statusEl.innerText = `¡IMPACTO CRÍTICO! Hundiste su ${hitShip.name}. ¡Vuelve a disparar!`;
                    statusEl.style.color = "#f43f5e";
                    checkWinCondition();
                } else {
                    statusEl.innerText = "¡TOCADO! Objetivo alcanzado. ¡Vuelve a disparar!";
                    statusEl.style.color = "#f43f5e";
                }
                gameState.actionCompleted = false;
                document.getElementById('btn-end-turn').style.display = 'none';
            } else {
                statusEl.innerText = "¡AGUA! El disparo cayó en mar abierto. Fin de tu turno.";
                statusEl.style.color = "#94a3b8";
                gameState.actionCompleted = true;
                document.getElementById('btn-end-turn').style.display = 'block';
            }

            renderOffensiveBoard();
            renderDefensiveBoard();
            renderFleetStatus();
        }

        function checkWinCondition() {
            const opponentIndex = gameState.currentPlayerIndex === 0 ? 1 : 0;
            const opponent = gameState.players[opponentIndex];
            const allSunk = opponent.ships.every(ship => ship.sunk);
            
            if (allSunk) {
                gameState.phase = 'gameover';
                document.getElementById('winner-message').innerText = `¡${gameState.players[gameState.currentPlayerIndex].name} GANA LA PARTIDA!`;
                setTimeout(() => {
                    showScreen('screen-game-over');
                }, 1500);
            }
        }

        function resetGame() {
            showScreen('screen-start');
        }
    </script>
</body>
</html>
