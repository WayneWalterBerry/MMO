// bootstrapper.js
// Layer 1: Fetches, decompresses, and loads the engine into Fengari.
// This is the ONLY local JavaScript file loaded by index.html.
// See: docs/architecture/web/bootstrapper.md

(function () {
    'use strict';

    // --- Debug mode: ?debug in URL shows detailed loading messages ---
    window._debugMode = new URLSearchParams(window.location.search).has('debug');

    var outputEl = document.getElementById('output');
    var inputEl  = document.getElementById('input');

    // --- Output helpers ---
    function escapeHtml(str) {
        return str.replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;');
    }

    // --- Session transcript buffer (#20) ---
    // Groups all output lines between two > prompts as one response block.
    var sessionTranscript = [];
    var _currentCmd = null;
    var _currentResponseLines = [];

    function flushTranscriptEntry() {
        if (_currentCmd !== null) {
            sessionTranscript.push({
                input: _currentCmd,
                output: _currentResponseLines.join('\n')
            });
            while (sessionTranscript.length > 50) sessionTranscript.shift();
        }
        _currentResponseLines = [];
    }

    // --- DOM batching (#3): buffer DOM mutations during command processing ---
    var _outputBatching = false;
    var _outputFragment = null;
    var _rafScheduled = false;

    // --- Search trickle (#72): drip-feed search output line by line ---
    var _trickleTimers = [];
    var _trickleActive = false;
    var TRICKLE_DELAY_MS = 1050;
    var _SEARCH_RE = /^(search|find)\b/i;
    var _SEARCH_LOOK_RE = /^look\s+(for|in)\b/i;

    function _isSearchCommand(text) {
        return _SEARCH_RE.test(text) || _SEARCH_LOOK_RE.test(text);
    }

    function _cancelTrickle() {
        for (var i = 0; i < _trickleTimers.length; i++) {
            clearTimeout(_trickleTimers[i].id);
            outputEl.appendChild(_trickleTimers[i].node);
        }
        _trickleTimers = [];
        if (_trickleActive) {
            outputEl.scrollTop = outputEl.scrollHeight;
            _trickleActive = false;
        }
    }

    function _trickleFlush() {
        if (!_outputFragment) { _outputBatching = false; return; }
        var nodes = [];
        while (_outputFragment.firstChild) {
            nodes.push(_outputFragment.removeChild(_outputFragment.firstChild));
        }
        _outputFragment = null;
        _outputBatching = false;

        if (nodes.length === 0) { _rafScheduled = false; return; }

        _trickleActive = true;
        _trickleTimers = [];
        for (var i = 0; i < nodes.length; i++) {
            (function (node, idx) {
                var timerId = setTimeout(function () {
                    outputEl.appendChild(node);
                    outputEl.scrollTop = outputEl.scrollHeight;
                    // Remove from pending list
                    _trickleTimers = _trickleTimers.filter(function (t) { return t.id !== timerId; });
                    if (_trickleTimers.length === 0) { _trickleActive = false; }
                }, idx * TRICKLE_DELAY_MS);
                _trickleTimers.push({ id: timerId, node: node });
            })(nodes[i], i);
        }
        _rafScheduled = false;
    }

    function _flushOutput() {
        if (_outputFragment && _outputFragment.childNodes.length > 0) {
            outputEl.appendChild(_outputFragment);
        }
        _outputFragment = null;
        _outputBatching = false;
        outputEl.scrollTop = outputEl.scrollHeight;
        _rafScheduled = false;
    }

    function _beginBatch() {
        _outputBatching = true;
        _outputFragment = document.createDocumentFragment();
    }

    function _endBatch() {
        if (!_rafScheduled && _outputFragment) {
            _rafScheduled = true;
            requestAnimationFrame(_flushOutput);
        }
    }

    function _endBatchTrickle() {
        _trickleFlush();
    }

    function appendOutput(text, className) {
        var div = document.createElement('div');
        div.className = className || 'output-line';
        if (!text && text !== 0) {
            div.innerHTML = '&nbsp;';
        } else {
            var safe = escapeHtml(String(text));
            safe = safe.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
            div.innerHTML = safe;
        }

        if (_outputBatching && _outputFragment) {
            _outputFragment.appendChild(div);
        } else {
            outputEl.appendChild(div);
            outputEl.scrollTop = outputEl.scrollHeight;
        }

        // Record response line for transcript (#20)
        if (_currentCmd !== null) {
            _currentResponseLines.push(text != null ? String(text) : '');
        }
    }

    function showStatus(message) {
        appendOutput(message, 'output-line status-line');
    }

    function showError(message) {
        appendOutput(message, 'output-line error-line');
    }

    // --- Build version (embedded at build time) ---
    const BUILD_TIMESTAMP = "2026-03-24 13:11";
    const CACHE_BUST = "20260324131105";

    // --- Size formatting ---
    function formatSize(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
        return (bytes / 1024).toFixed(1) + ' KB';
    }

    // --- Conditional fetch bridge (called from Lua for HTTP cache) ---
    // Uses synchronous XHR to send If-None-Match / If-Modified-Since headers.
    // Returns { status, content, etag, lastModified } to Lua.
    window._cachedFetch = function (url, etag, lastModified) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, false); // synchronous
        if (etag) xhr.setRequestHeader('If-None-Match', etag);
        if (lastModified) xhr.setRequestHeader('If-Modified-Since', lastModified);
        xhr.send();
        return {
            status: xhr.status,
            content: xhr.status === 304 ? null : xhr.responseText,
            etag: xhr.getResponseHeader('ETag'),
            lastModified: xhr.getResponseHeader('Last-Modified')
        };
    };

    // Expose to Lua adapter
    window.logStatus = showStatus;
    window._logStatus = showStatus;
    window._appendOutput = appendOutput;

    // --- Status bar bridge (called from Lua game-adapter) ---
    var statusBarLeft  = document.querySelector('#status-bar .status-left');
    var statusBarRight = document.querySelector('#status-bar .status-right');
    window._updateStatusBar = function (left, right) {
        if (statusBarLeft)  statusBarLeft.textContent  = left  || '';
        if (statusBarRight) statusBarRight.textContent = right || '';
    };

    // JS bridge: open URL in new tab (used by "report bug" command)
    // Fix #13: Trim transcript to last 3 command/response pairs so GitHub
    // doesn't truncate the URL and show stale welcome text instead.
    // Fix #20: Use JS-side sessionTranscript buffer (groups all output lines
    // between > prompts) instead of relying solely on the Lua-generated text.
    window._openUrl = function (url) {
        try {
            // Flush any in-progress command before building the report
            flushTranscriptEntry();
            _currentCmd = null;

            var urlObj = new URL(url);
            if (urlObj.pathname.indexOf('/issues/new') !== -1) {
                var body = urlObj.searchParams.get('body');
                if (body && sessionTranscript.length > 0) {
                    // Rebuild transcript from JS buffer (accurate multi-line responses)
                    var blocks = sessionTranscript.slice(-3);
                    var transcriptText = blocks.map(function (entry) {
                        return '> ' + entry.input + '\n' + entry.output + '\n';
                    }).join('\n');

                    var match = body.match(/(### Session Transcript[^\n]*)\n\n```\n[\s\S]*?```([\s]*)$/);
                    if (match) {
                        var header = match[1].replace(/last \d+/, 'last ' + blocks.length);
                        body = body.replace(match[0], header + '\n\n```\n' + transcriptText + '```' + match[2]);
                        urlObj.searchParams.set('body', body);
                        url = urlObj.toString();
                    }
                } else if (body) {
                    // Fallback: trim Lua-generated transcript (original #13 logic)
                    var match = body.match(/(### Session Transcript[^\n]*\n\n```\n)([\s\S]*?)(```[\s]*)$/);
                    if (match) {
                        var luaBlocks = match[2].split(/(?=^> )/m).filter(function (b) { return b.trim(); });
                        var last3 = luaBlocks.slice(-3).join('');
                        var count = Math.min(luaBlocks.length, 3);
                        var header = match[1].replace(/last \d+/, 'last ' + count);
                        body = body.replace(match[0], header + last3 + match[3]);
                        urlObj.searchParams.set('body', body);
                        url = urlObj.toString();
                    }
                }
            }
        } catch (e) { /* proceed with original URL */ }
        window.open(url, '_blank');
    };

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

            // Flush previous command/response pair into transcript (#20)
            flushTranscriptEntry();
            _currentCmd = text;

            var echoDiv = document.createElement('div');
            echoDiv.className = 'input-echo';
            var promptSpan = document.createElement('span');
            promptSpan.className = 'input-prompt';
            promptSpan.textContent = '> ';
            echoDiv.appendChild(promptSpan);
            echoDiv.appendChild(document.createTextNode(text));
            outputEl.appendChild(echoDiv);
            outputEl.scrollTop = outputEl.scrollHeight;
            if (window._gameProcessCommand) {
                // #72: cancel any in-progress trickle before new command
                _cancelTrickle();
                var useSearchTrickle = _isSearchCommand(text);
                _beginBatch();
                try {
                    window._gameProcessCommand(text);
                } catch (err) {
                    appendOutput('[Error: ' + err.message + ']', 'error-line');
                    console.error(err);
                }
                if (useSearchTrickle) {
                    _endBatchTrickle();
                } else {
                    _endBatch();
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

    // --- Copy button: copies all output text to clipboard (#12) ---
    var copyBtn = document.getElementById('copy-btn');
    var copySvgClipboard = copyBtn ? copyBtn.innerHTML : '';
    var copySvgCheck = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>';
    if (copyBtn) {
        copyBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            var text = outputEl.innerText || outputEl.textContent;
            navigator.clipboard.writeText(text).then(function () {
                copyBtn.innerHTML = copySvgCheck;
                copyBtn.classList.add('copied');
                setTimeout(function () {
                    copyBtn.innerHTML = copySvgClipboard;
                    copyBtn.classList.remove('copied');
                }, 1500);
            }).catch(function () {
                copyBtn.innerHTML = copySvgCheck;
                copyBtn.classList.add('copied');
                setTimeout(function () {
                    copyBtn.innerHTML = copySvgClipboard;
                    copyBtn.classList.remove('copied');
                }, 1500);
            });
        });
    }

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
        var to_luastring = fengari.to_luastring;

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
            lauxlib.luaL_requiref(L, fengari.to_luastring("js"), fengari.interop.luaopen_js, 1);
            lua.lua_pop(L, 1);
        }
        return L;
    }

    // --- Main boot sequence ---
    async function boot() {
        try {
            if (window._debugMode) {
                showStatus('Loading Bootstrapper (' + BUILD_TIMESTAMP + ')...');
            }

            // Step 1: Fetch compressed engine bundle
            showStatus('Loading Game Engine...');
            var engineResponse = await fetchWithRetry('engine.lua.gz?v=' + CACHE_BUST, 1);
            var compressedData = await engineResponse.arrayBuffer();
            if (window._debugMode) {
                showStatus('Loading Game Engine... (' + formatSize(compressedData.byteLength) + ' compressed)');
            }

            // Step 2: Decompress
            if (window._debugMode) {
                showStatus('Decompressing Engine...');
            }
            var engineSource = await decompress(compressedData);
            if (window._debugMode) {
                showStatus('Decompressing Engine... (' + formatSize(engineSource.length) + ')');
            }

            // Step 3: Load engine into Fengari
            if (window._debugMode) {
                showStatus('Initializing Fengari (' + BUILD_TIMESTAMP + ')...');
            }
            var L = getLuaState();
            executeLua(L, engineSource, 'engine');

            // Step 4: Fetch and execute game adapter
            if (window._debugMode) {
                showStatus('Loading Game Adapter...');
            }
            var adapterResponse = await fetchWithRetry('game-adapter.lua?v=' + CACHE_BUST, 1);
            var adapterSource = await adapterResponse.text();
            if (window._debugMode) {
                showStatus('Loading Game Adapter... (' + formatSize(adapterSource.length) + ')');
            }
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
