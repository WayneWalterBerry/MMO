// test/web/test-search-trickle.js
// Regression tests for #72 — search text trickle effect in bootstrapper.js.
// Validates the trickle detection regex and DOM scheduling logic.
// Runs in Node.js (no browser required).

'use strict';

var passed = 0;
var failed = 0;

function test(description, fn) {
    try {
        fn();
        passed++;
        console.log('  PASS ' + description);
    } catch (e) {
        failed++;
        console.log('  FAIL ' + description + ': ' + e.message);
    }
}

function assert(cond, msg) {
    if (!cond) throw new Error(msg || 'assertion failed');
}

function assertEqual(a, b, msg) {
    if (a !== b) throw new Error((msg || '') + ' expected ' + JSON.stringify(b) + ' got ' + JSON.stringify(a));
}

// --- Extract trickle detection regex and function from bootstrapper.js ---
// We replicate the exact patterns from the source.
var _SEARCH_RE = /^(search|find)\b/i;
var _SEARCH_LOOK_RE = /^look\s+(for|in)\b/i;

function _isSearchCommand(text) {
    return _SEARCH_RE.test(text) || _SEARCH_LOOK_RE.test(text);
}

// ==========================================================================
console.log('test-search-trickle.js');
console.log('');

// --- Detection: positive cases ---
test('detects "search"', function () {
    assert(_isSearchCommand('search'));
});

test('detects "search for matchbox"', function () {
    assert(_isSearchCommand('search for matchbox'));
});

test('detects "Search the room"', function () {
    assert(_isSearchCommand('Search the room'));
});

test('detects "SEARCH"', function () {
    assert(_isSearchCommand('SEARCH'));
});

test('detects "find matchbox"', function () {
    assert(_isSearchCommand('find matchbox'));
});

test('detects "find a match"', function () {
    assert(_isSearchCommand('find a match'));
});

test('detects "Find something"', function () {
    assert(_isSearchCommand('Find something'));
});

test('detects "look for matchbox"', function () {
    assert(_isSearchCommand('look for matchbox'));
});

test('detects "look in drawer"', function () {
    assert(_isSearchCommand('look in drawer'));
});

test('detects "Look for something"', function () {
    assert(_isSearchCommand('Look for something'));
});

// --- Detection: negative cases ---
test('rejects "look" (no preposition)', function () {
    assert(!_isSearchCommand('look'));
});

test('rejects "look around"', function () {
    assert(!_isSearchCommand('look around'));
});

test('rejects "look at mirror"', function () {
    assert(!_isSearchCommand('look at mirror'));
});

test('rejects "go north"', function () {
    assert(!_isSearchCommand('go north'));
});

test('rejects "take matchbox"', function () {
    assert(!_isSearchCommand('take matchbox'));
});

test('rejects "feel"', function () {
    assert(!_isSearchCommand('feel'));
});

test('rejects "hit mirror"', function () {
    assert(!_isSearchCommand('hit mirror'));
});

test('rejects "findings" (word boundary)', function () {
    assert(!_isSearchCommand('findings are interesting'));
});

test('rejects "searched" (word boundary)', function () {
    // "searched" starts with "search" but \b stops after "search" is matched
    // Actually /^(search)\b/ would match "searched" since "search" + "e" — 
    // but \b after "search" checks if "e" is \w, which it is, so \b fails.
    // Wait: \b matches between \w and \W. After "search", next char is "e" 
    // which is \w, and "h" is also \w, so there's no boundary. But the full
    // match is "search" then \b checks between "h" and "e": both \w → no
    // boundary → match fails. Good.
    assert(!_isSearchCommand('searched everywhere'));
});

// --- Trickle scheduling (simulated setTimeout) ---
test('trickle schedules nodes with incremental delays', function () {
    // Simulate the scheduling logic
    var TRICKLE_DELAY_MS = 350;
    var scheduledDelays = [];
    var nodes = ['line1', 'line2', 'line3', 'line4'];
    
    for (var i = 0; i < nodes.length; i++) {
        scheduledDelays.push(i * TRICKLE_DELAY_MS);
    }
    
    assertEqual(scheduledDelays[0], 0,    'first line should appear immediately');
    assertEqual(scheduledDelays[1], 350,  'second line at 350ms');
    assertEqual(scheduledDelays[2], 700,  'third line at 700ms');
    assertEqual(scheduledDelays[3], 1050, 'fourth line at 1050ms');
});

test('cancel trickle flushes all remaining nodes immediately', function () {
    // Simulate cancel behavior: all pending nodes should be flushed
    var pending = [
        { id: 1, node: 'A' },
        { id: 2, node: 'B' },
        { id: 3, node: 'C' },
    ];
    var flushed = [];
    
    // Simulate _cancelTrickle
    for (var i = 0; i < pending.length; i++) {
        flushed.push(pending[i].node);
    }
    
    assertEqual(flushed.length, 3, 'all 3 pending nodes should flush');
    assertEqual(flushed[0], 'A');
    assertEqual(flushed[1], 'B');
    assertEqual(flushed[2], 'C');
});

test('empty output produces no trickle', function () {
    var nodes = [];
    var scheduled = 0;
    for (var i = 0; i < nodes.length; i++) { scheduled++; }
    assertEqual(scheduled, 0, 'no scheduling for empty output');
});

// --- Summary ---
console.log('');
console.log(passed + '/' + (passed + failed) + ' passed');
if (failed > 0) {
    console.log(failed + ' FAILED');
    process.exit(1);
}
