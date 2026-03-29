// audio-driver.js
// Web Audio API driver for MMO browser sound playback.
// Zero external dependencies. Works in Safari (mobile), Chrome, Firefox.
//
// Exposes window._sound* functions callable from Lua via Fengari's js bridge.
// When a real .opus/.mp3 file is missing (404), falls back to synthetic
// tones generated via Web Audio oscillators so sounds work immediately.
//
// Owner: Gil (Web Engineer)

(function () {
    'use strict';

    // --- AudioContext singleton (lazy-created on first use) ---
    var _audioCtx = null;
    var _ctxUnlocked = false;
    var _masterGain = null;
    var _masterVolume = 1.0;
    var _muted = false;

    // Decoded audio buffers: filename → AudioBuffer
    var _buffers = {};
    // Active playback nodes: handle_id → { source, gain, loop }
    var _active = {};
    var _nextHandle = 1;

    // Sound base URL (relative to page)
    var SOUND_BASE = 'sounds/';

    // --- Debug helper ---
    function _dbg(msg) {
        if (window._debugMode) {
            console.log('[audio-driver] ' + msg);
        }
    }

    // --- Create or resume AudioContext ---
    function _ensureCtx() {
        if (_audioCtx) {
            if (_audioCtx.state === 'suspended') {
                _audioCtx.resume().catch(function () {});
            }
            return _audioCtx;
        }
        try {
            var Ctx = window.AudioContext || window.webkitAudioContext;
            if (!Ctx) {
                _dbg('Web Audio API not available');
                return null;
            }
            _audioCtx = new Ctx();
            _masterGain = _audioCtx.createGain();
            _masterGain.gain.value = _masterVolume;
            _masterGain.connect(_audioCtx.destination);
            _dbg('AudioContext created (sampleRate=' + _audioCtx.sampleRate + ')');
        } catch (e) {
            _dbg('AudioContext creation failed: ' + e.message);
            return null;
        }
        return _audioCtx;
    }

    // --- AudioContext unlock on first user interaction (mobile Safari) ---
    function _unlockAudioContext() {
        if (_ctxUnlocked) return;
        var ctx = _ensureCtx();
        if (!ctx) return;

        if (ctx.state === 'running') {
            _ctxUnlocked = true;
            _dbg('AudioContext already running');
            return;
        }

        // Create a silent buffer and play it to unlock
        var silentBuffer = ctx.createBuffer(1, 1, ctx.sampleRate);
        var source = ctx.createBufferSource();
        source.buffer = silentBuffer;
        source.connect(ctx.destination);
        source.start(0);

        ctx.resume().then(function () {
            _ctxUnlocked = true;
            _dbg('AudioContext unlocked');
        }).catch(function () {
            _dbg('AudioContext unlock failed (will retry)');
        });
    }

    // Register unlock listeners on common interaction events
    var _unlockEvents = ['click', 'touchstart', 'touchend', 'keydown', 'keypress'];
    function _registerUnlockListeners() {
        function handler() {
            _unlockAudioContext();
            if (_ctxUnlocked) {
                for (var i = 0; i < _unlockEvents.length; i++) {
                    document.removeEventListener(_unlockEvents[i], handler, true);
                }
            }
        }
        for (var i = 0; i < _unlockEvents.length; i++) {
            document.addEventListener(_unlockEvents[i], handler, true);
        }
    }
    _registerUnlockListeners();

    // =====================================================================
    // Synthetic tone fallback generators
    // =====================================================================

    // Generate a brownian noise buffer (for ambient sounds)
    function _syntheticAmbient(ctx, durationSec) {
        var sr = ctx.sampleRate;
        var len = sr * (durationSec || 4);
        var buf = ctx.createBuffer(1, len, sr);
        var data = buf.getChannelData(0);
        var last = 0;
        for (var i = 0; i < len; i++) {
            var white = Math.random() * 2 - 1;
            last = (last + (0.02 * white)) / 1.02;
            data[i] = last * 3.5;
            // Clamp
            if (data[i] > 1) data[i] = 1;
            if (data[i] < -1) data[i] = -1;
        }
        // Gentle fade in/out
        var fade = Math.min(sr * 0.5, len / 4);
        for (var j = 0; j < fade; j++) {
            var env = j / fade;
            data[j] *= env;
            data[len - 1 - j] *= env;
        }
        return buf;
    }

    // Generate a short click/thud tone (for object interactions)
    function _syntheticObject(ctx) {
        var sr = ctx.sampleRate;
        var len = Math.floor(sr * 0.15);
        var buf = ctx.createBuffer(1, len, sr);
        var data = buf.getChannelData(0);
        for (var i = 0; i < len; i++) {
            var t = i / sr;
            // Low thud: 80Hz sine with quick exponential decay
            var env = Math.exp(-t * 30);
            data[i] = Math.sin(2 * Math.PI * 80 * t) * env * 0.6;
            // Add a click transient at start
            if (i < sr * 0.005) {
                data[i] += (Math.random() * 2 - 1) * 0.4 * (1 - i / (sr * 0.005));
            }
        }
        return buf;
    }

    // Generate a mid-frequency growl tone (for creature sounds)
    function _syntheticCreature(ctx) {
        var sr = ctx.sampleRate;
        var len = Math.floor(sr * 0.5);
        var buf = ctx.createBuffer(1, len, sr);
        var data = buf.getChannelData(0);
        for (var i = 0; i < len; i++) {
            var t = i / sr;
            // Growling: layered low frequencies with amplitude modulation
            var env = Math.exp(-t * 4);
            var mod = 1 + 0.5 * Math.sin(2 * Math.PI * 5 * t);
            data[i] = (Math.sin(2 * Math.PI * 60 * t) * 0.5
                      + Math.sin(2 * Math.PI * 90 * t) * 0.3
                      + Math.sin(2 * Math.PI * 45 * t) * 0.2)
                      * env * mod * 0.5;
        }
        // Fade out tail
        var fade = Math.floor(sr * 0.1);
        for (var j = 0; j < fade; j++) {
            data[len - 1 - j] *= j / fade;
        }
        return buf;
    }

    // Generate a generic fallback tone (for combat/verb sounds)
    function _syntheticGeneric(ctx) {
        var sr = ctx.sampleRate;
        var len = Math.floor(sr * 0.2);
        var buf = ctx.createBuffer(1, len, sr);
        var data = buf.getChannelData(0);
        for (var i = 0; i < len; i++) {
            var t = i / sr;
            var env = Math.exp(-t * 15);
            // Mid-range percussive: 200Hz + noise
            data[i] = (Math.sin(2 * Math.PI * 200 * t) * 0.4
                      + (Math.random() * 2 - 1) * 0.2)
                      * env;
        }
        return buf;
    }

    // Classify a filename to pick the right synthetic generator
    function _classifySoundType(filename) {
        if (!filename) return 'generic';
        var lower = filename.toLowerCase();
        if (lower.indexOf('ambient') !== -1 || lower.indexOf('wind') !== -1
            || lower.indexOf('water') !== -1 || lower.indexOf('rain') !== -1
            || lower.indexOf('drip') !== -1) {
            return 'ambient';
        }
        if (lower.indexOf('creature') !== -1 || lower.indexOf('growl') !== -1
            || lower.indexOf('howl') !== -1 || lower.indexOf('snarl') !== -1
            || lower.indexOf('spider') !== -1 || lower.indexOf('rat') !== -1) {
            return 'creature';
        }
        if (lower.indexOf('door') !== -1 || lower.indexOf('creak') !== -1
            || lower.indexOf('click') !== -1 || lower.indexOf('lock') !== -1
            || lower.indexOf('close') !== -1 || lower.indexOf('open') !== -1
            || lower.indexOf('drop') !== -1 || lower.indexOf('take') !== -1) {
            return 'object';
        }
        return 'generic';
    }

    function _generateSyntheticBuffer(ctx, filename) {
        var soundType = _classifySoundType(filename);
        switch (soundType) {
            case 'ambient':  return _syntheticAmbient(ctx, 4);
            case 'creature': return _syntheticCreature(ctx);
            case 'object':   return _syntheticObject(ctx);
            default:         return _syntheticGeneric(ctx);
        }
    }

    // =====================================================================
    // Core audio operations
    // =====================================================================

    // Async load: fetch audio file, decode it, cache the buffer.
    // Falls back to synthetic tone if file not found (404).
    function _loadSound(filename, callback) {
        var ctx = _ensureCtx();
        if (!ctx) {
            if (callback) callback(null, 'no AudioContext');
            return;
        }

        // Already cached?
        if (_buffers[filename]) {
            if (callback) callback(filename, null);
            return;
        }

        // Build URL: try .opus first, then .mp3 if .opus fails
        var url = SOUND_BASE + filename;
        // Normalize: if filename doesn't have an extension, try .opus
        if (filename.indexOf('.') === -1) {
            url = SOUND_BASE + filename + '.opus';
        }

        fetch(url).then(function (resp) {
            if (!resp.ok) {
                // Try .mp3 fallback
                var mp3Url = url.replace(/\.opus$/, '.mp3');
                if (mp3Url !== url) {
                    return fetch(mp3Url).then(function (resp2) {
                        if (!resp2.ok) return null;
                        return resp2.arrayBuffer();
                    });
                }
                return null;
            }
            return resp.arrayBuffer();
        }).then(function (arrayBuf) {
            if (!arrayBuf) {
                // No real file found — generate synthetic fallback
                _dbg('file not found: ' + filename + ' → synthetic fallback');
                _buffers[filename] = _generateSyntheticBuffer(ctx, filename);
                if (callback) callback(filename, null);
                return;
            }
            return ctx.decodeAudioData(arrayBuf).then(function (decoded) {
                _buffers[filename] = decoded;
                _dbg('loaded: ' + filename);
                if (callback) callback(filename, null);
            });
        }).catch(function (err) {
            // Decode or network error — fall back to synthetic
            _dbg('load error for ' + filename + ': ' + err.message + ' → synthetic fallback');
            _buffers[filename] = _generateSyntheticBuffer(ctx, filename);
            if (callback) callback(filename, null);
        });
    }

    // Play a sound buffer. Returns a numeric handle.
    function _playSound(filename, opts) {
        var ctx = _ensureCtx();
        if (!ctx || !_masterGain) return 0;

        opts = opts || {};
        var volume = (opts.volume !== undefined) ? opts.volume : 1.0;
        var loop = opts.loop || false;
        var fadeInMs = opts.fade_in_ms || 0;

        // Get or generate buffer
        var buffer = _buffers[filename];
        if (!buffer) {
            // Synchronous synthetic fallback for immediate playback
            buffer = _generateSyntheticBuffer(ctx, filename);
            _buffers[filename] = buffer;
            _dbg('synthetic fallback for: ' + filename);
        }

        try {
            var source = ctx.createBufferSource();
            source.buffer = buffer;
            source.loop = loop;

            var gainNode = ctx.createGain();
            var effectiveVol = _muted ? 0 : (volume * _masterVolume);

            if (fadeInMs > 0) {
                gainNode.gain.setValueAtTime(0, ctx.currentTime);
                gainNode.gain.linearRampToValueAtTime(effectiveVol, ctx.currentTime + fadeInMs / 1000);
            } else {
                gainNode.gain.value = effectiveVol;
            }

            source.connect(gainNode);
            gainNode.connect(_masterGain);
            source.start(0);

            var handle = _nextHandle++;
            _active[handle] = {
                source: source,
                gain: gainNode,
                loop: loop,
                filename: filename,
                volume: volume
            };

            // Auto-cleanup for non-looping sounds
            if (!loop) {
                source.onended = function () {
                    delete _active[handle];
                };
            }

            return handle;
        } catch (e) {
            _dbg('play error: ' + e.message);
            return 0;
        }
    }

    // Stop a specific sound by handle
    function _stopSound(handle) {
        var entry = _active[handle];
        if (!entry) return;
        try {
            entry.source.stop(0);
        } catch (e) {
            // Already stopped
        }
        try {
            entry.source.disconnect();
            entry.gain.disconnect();
        } catch (e) {}
        delete _active[handle];
    }

    // Stop all active sounds
    function _stopAll() {
        var handles = Object.keys(_active);
        for (var i = 0; i < handles.length; i++) {
            _stopSound(parseInt(handles[i], 10));
        }
    }

    // Set volume for a specific handle
    function _setVolume(handle, volume) {
        var entry = _active[handle];
        if (!entry) return;
        entry.volume = volume;
        try {
            var effectiveVol = _muted ? 0 : (volume * _masterVolume);
            entry.gain.gain.setValueAtTime(effectiveVol, _audioCtx.currentTime);
        } catch (e) {}
    }

    // Set master volume (0.0–1.0)
    function _setMasterVolume(level) {
        _masterVolume = Math.max(0, Math.min(1, level));
        if (_masterGain && _audioCtx) {
            _masterGain.gain.setValueAtTime(
                _muted ? 0 : _masterVolume,
                _audioCtx.currentTime
            );
        }
    }

    // Set muted state
    function _setMuted(muted) {
        _muted = !!muted;
        if (_masterGain && _audioCtx) {
            _masterGain.gain.setValueAtTime(
                _muted ? 0 : _masterVolume,
                _audioCtx.currentTime
            );
        }
    }

    // Unload a cached buffer
    function _unloadSound(filename) {
        delete _buffers[filename];
    }

    // Fade a playing sound
    function _fadeSound(handle, fromVol, toVol, durationMs) {
        var entry = _active[handle];
        if (!entry || !_audioCtx) return;
        try {
            var now = _audioCtx.currentTime;
            var dur = (durationMs || 1000) / 1000;
            entry.gain.gain.setValueAtTime(fromVol * _masterVolume, now);
            entry.gain.gain.linearRampToValueAtTime(toVol * _masterVolume, now + dur);
            entry.volume = toVol;

            // If fading to zero, stop after fade completes
            if (toVol <= 0) {
                setTimeout(function () {
                    _stopSound(handle);
                }, durationMs + 50);
            }
        } catch (e) {
            _dbg('fade error: ' + e.message);
        }
    }

    // =====================================================================
    // Expose to Lua via window._sound* (Fengari js bridge)
    // =====================================================================

    window._soundLoad = function (filename, callback) {
        _loadSound(filename, callback);
    };

    window._soundPlay = function (filename, opts) {
        return _playSound(filename, opts || {});
    };

    window._soundStop = function (handle) {
        _stopSound(handle);
    };

    window._soundStopAll = function () {
        _stopAll();
    };

    window._soundSetMasterVolume = function (level) {
        _setMasterVolume(level);
    };

    window._soundSetMuted = function (muted) {
        _setMuted(muted);
    };

    window._soundUnload = function (filename) {
        _unloadSound(filename);
    };

    window._soundFade = function (handle, fromVol, toVol, durationMs) {
        _fadeSound(handle, fromVol, toVol, durationMs);
    };

    window._soundSetVolume = function (handle, volume) {
        _setVolume(handle, volume);
    };

    // Query: is Web Audio available?
    window._soundAvailable = function () {
        return !!(window.AudioContext || window.webkitAudioContext);
    };

    _dbg('audio-driver.js loaded (Web Audio API ' +
         (window._soundAvailable() ? 'available' : 'NOT available') + ')');

})();
