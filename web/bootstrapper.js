// bootstrapper.js
// Layer 1: Fetches, decompresses, and loads the engine into Fengari.
// This is the ONLY local JavaScript file loaded by index.html.
// See: docs/architecture/web/bootstrapper.md

(function () {
    'use strict';

    var outputEl = document.getElementById('output');
    var inputEl  = document.getElementById('input');

    // --- Output helpers ---
    function appendOutput(text, className) {
        var div = document.createElement('div');
        div.className = className || 'output-line';
        if (!text && text !== 0) {
            div.innerHTML = '&nbsp;';
        } else {
            div.textContent = String(text);
        }
        outputEl.appendChild(div);
        outputEl.scrollTop = outputEl.scrollHeight;
    }

    function showStatus(message) {
        appendOutput(message, 'output-line status-line');
    }

    function showError(message) {
        appendOutput(message, 'output-line error-line');
    }

    // Expose to Lua adapter
    window.logStatus = showStatus;
    window._logStatus = showStatus;
    window._appendOutput = appendOutput;

    // --- Command history ---
    var history = [];
    var historyIndex = -1;

    inputEl.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            var text = inputEl.value;
            if (text.trim() === '') return;
            inputEl.value = '';
            history.push(text);
            historyIndex = history.length;
            appendOutput('> ' + text, 'input-echo');
            if (window._gameProcessCommand) {
                try {
                    window._gameProcessCommand(text);
                } catch (err) {
                    appendOutput('[Error: ' + err.message + ']', 'error-line');
                    console.error(err);
                }
            } else {
                appendOutput('[Game engine still loading...]', 'error-line');
            }
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (historyIndex > 0) {
                historyIndex--;
                inputEl.value = history[historyIndex];
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (historyIndex < history.length - 1) {
                historyIndex++;
                inputEl.value = history[historyIndex];
            } else {
                historyIndex = history.length;
                inputEl.value = '';
            }
        }
    });

    document.getElementById('terminal').addEventListener('click', function () {
        inputEl.focus();
    });

    // --- Decompression ---
    async function decompress(compressedBuffer) {
        if (typeof DecompressionStream !== 'undefined') {
            var ds = new DecompressionStream('gzip');
            var writer = ds.writable.getWriter();
            var reader = ds.readable.getReader();
            writer.write(new Uint8Array(compressedBuffer));
            writer.close();
            var chunks = [];
            while (true) {
                var result = await reader.read();
                if (result.done) break;
                chunks.push(result.value);
            }
            var decoder = new TextDecoder();
            return chunks.map(function (c) { return decoder.decode(c, { stream: true }); }).join('');
        }
        if (typeof fflate !== 'undefined' && fflate.decompressSync) {
            var decompressed = fflate.decompressSync(new Uint8Array(compressedBuffer));
            return new TextDecoder().decode(decompressed);
        }
        throw new Error('No decompression method available');
    }

    // --- Fetch with retry ---
    async function fetchWithRetry(url, retries) {
        retries = retries || 1;
        for (var attempt = 0; attempt <= retries; attempt++) {
            try {
                var response = await fetch(url);
                if (!response.ok) throw new Error('HTTP ' + response.status + ' fetching ' + url);
                return response;
            } catch (err) {
                if (attempt < retries) {
                    await new Promise(function (r) { setTimeout(r, 2000); });
                } else {
                    throw err;
                }
            }
        }
    }

    // --- Execute Lua source in Fengari shared state ---
    function executeLua(L, source, name) {
        var lua = fengari.lua;
        var lauxlib = fengari.lauxlib;
        var to_luastring = lua.to_luastring;

        var src = to_luastring(source);
        var chunkName = to_luastring('@' + name);

        var loadResult = lauxlib.luaL_loadbuffer(L, src, src.length, chunkName);
        if (loadResult !== 0) {
            var err = lua.lua_tojsstring(L, -1);
            lua.lua_pop(L, 1);
            throw new Error(name + ' load error: ' + err);
        }
        var callResult = lua.lua_pcall(L, 0, 0, 0);
        if (callResult !== 0) {
            var err2 = lua.lua_tojsstring(L, -1);
            lua.lua_pop(L, 1);
            throw new Error(name + ' execution error: ' + err2);
        }
    }

    // --- Get or create Lua state ---
    function getLuaState() {
        var lua = fengari.lua;
        var lauxlib = fengari.lauxlib;

        // Try fengari-web's shared state first (has js module pre-registered)
        if (fengari.L) return fengari.L;

        // Fallback: create new state and register js interop
        var L = lauxlib.luaL_newstate();
        fengari.lualib.luaL_openlibs(L);
        if (fengari.interop && fengari.interop.luaopen_js) {
            lauxlib.luaL_requiref(L, lua.to_luastring("js"), fengari.interop.luaopen_js, 1);
            lua.lua_pop(L, 1);
        }
        return L;
    }

    // --- Main boot sequence ---
    async function boot() {
        try {
            // Step 1: Fetch compressed engine bundle
            showStatus('Loading Game Engine...');
            var engineResponse = await fetchWithRetry('engine.lua.gz', 1);
            var compressedData = await engineResponse.arrayBuffer();

            // Step 2: Decompress
            showStatus('Decompressing Engine...');
            var engineSource = await decompress(compressedData);

            // Step 3: Load engine into Fengari
            showStatus('Initializing Fengari...');
            var L = getLuaState();
            executeLua(L, engineSource, 'engine');

            // Step 4: Fetch and execute game adapter
            showStatus('Loading Game Adapter...');
            var adapterResponse = await fetchWithRetry('game-adapter.lua', 1);
            var adapterSource = await adapterResponse.text();
            executeLua(L, adapterSource, 'game-adapter');

        } catch (err) {
            showError('Failed to load game: ' + err.message);
            console.error('Bootstrapper error:', err);
        }
    }

    // Fengari should already be loaded (script tag before this one)
    if (typeof fengari !== 'undefined') {
        boot();
    } else {
        showError('Failed to load game runtime (Fengari not available)');
    }
})();
