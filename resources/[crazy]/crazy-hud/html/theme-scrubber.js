// Recolors red accents to blue by watching the live rendered DOM instead of patching the
// obfuscated compiled bundle - React sets colors as inline styles/SVG attributes on real
// elements regardless of how the source computed them, so this operates on the output only.
(function () {
    var BLUE_HEX = '#1573ed';
    var BLUE_RGB = 'rgba(21,115,237';

    var KNOWN_RED_HEX = /#da1b32/gi;
    var KNOWN_RED_RGBA_1 = /rgba\(\s*218,\s*27,\s*50/gi;
    var KNOWN_RED_RGBA_2 = /rgba\(\s*239,\s*22,\s*22/gi;
    var GENERIC_RGB = /rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(,\s*[\d.]+)?\)/gi;
    var GENERIC_HEX6 = /#([0-9a-f]{6})\b/gi;
    var GENERIC_HEX3 = /#([0-9a-f]{3})\b/gi;
    var NAMED_REDS = /\b(red|crimson|firebrick|indianred|darkred|maroon)\b/gi;

    // Distinguishes true red (G and B both low and close to each other) from orange/amber
    // (G noticeably higher than B) - the original heuristic treated both as "reddish" and
    // incorrectly recolored an orange hunger icon.
    function isReddish(r, g, b) {
        return r > 140 && r > g * 1.4 && r > b * 1.3 && b >= g * 0.6;
    }

    function scrubColorString(str) {
        if (!str) return str;
        var out = str
            .replace(KNOWN_RED_HEX, BLUE_HEX)
            .replace(KNOWN_RED_RGBA_1, BLUE_RGB)
            .replace(KNOWN_RED_RGBA_2, BLUE_RGB);
        out = out.replace(GENERIC_RGB, function (match, r, g, b, alpha) {
            r = +r; g = +g; b = +b;
            if (isReddish(r, g, b)) {
                return alpha ? ('rgba(21,115,237' + alpha + ')') : 'rgb(21,115,237)';
            }
            return match;
        });
        out = out.replace(GENERIC_HEX6, function (match, hex) {
            var r = parseInt(hex.substr(0, 2), 16);
            var g = parseInt(hex.substr(2, 2), 16);
            var b = parseInt(hex.substr(4, 2), 16);
            return isReddish(r, g, b) ? BLUE_HEX : match;
        });
        out = out.replace(GENERIC_HEX3, function (match, hex) {
            var r = parseInt(hex[0] + hex[0], 16);
            var g = parseInt(hex[1] + hex[1], 16);
            var b = parseInt(hex[2] + hex[2], 16);
            return isReddish(r, g, b) ? BLUE_HEX : match;
        });
        out = out.replace(NAMED_REDS, BLUE_HEX);
        return out;
    }

    // stop-color/stop-opacity live on <stop> elements inside <radialGradient>/<linearGradient>
    // (a common way to render a soft glow), flood-color on <feFlood> SVG filter primitives.
    var PAINT_ATTRS = ['stroke', 'fill', 'stop-color', 'flood-color', 'lighting-color'];

    function scrubElement(el) {
        if (!el || el.nodeType !== 1) return;
        if (el.style && el.style.cssText) {
            var cssText = el.style.cssText;
            var scrubbedCss = scrubColorString(cssText);
            if (scrubbedCss !== cssText) el.style.cssText = scrubbedCss;
        }
        if (el.getAttribute) {
            for (var i = 0; i < PAINT_ATTRS.length; i++) {
                var attr = PAINT_ATTRS[i];
                var val = el.getAttribute(attr);
                if (val) {
                    var scrubbed = scrubColorString(val);
                    if (scrubbed !== val) el.setAttribute(attr, scrubbed);
                }
            }
        }
    }

    function scrubTree(root) {
        if (!root) return;
        scrubElement(root);
        if (root.querySelectorAll) {
            var all = root.querySelectorAll('*');
            for (var i = 0; i < all.length; i++) scrubElement(all[i]);
        }
    }

    // MUI/emotion inject theme rules as <style> tags in <head> (e.g. MuiSwitch/MuiSlider colors) -
    // these aren't inline attributes, so the element-level scrubber above won't touch them.
    var scrubbedStyleSheets = new WeakSet();
    function scrubStyleSheets() {
        var sheets = document.querySelectorAll('style');
        for (var i = 0; i < sheets.length; i++) {
            var el = sheets[i];
            if (scrubbedStyleSheets.has(el)) continue;
            var text = el.textContent;
            if (text) {
                var scrubbed = scrubColorString(text);
                if (scrubbed !== text) el.textContent = scrubbed;
            }
            scrubbedStyleSheets.add(el);
        }
    }

    function start() {
        var root = document.getElementById('root') || document.body;

        scrubTree(root);
        scrubStyleSheets();

        var observer = new MutationObserver(function (mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var m = mutations[i];
                if (m.type === 'attributes') {
                    scrubElement(m.target);
                } else if (m.type === 'childList') {
                    for (var j = 0; j < m.addedNodes.length; j++) {
                        if (m.addedNodes[j].nodeType === 1) scrubTree(m.addedNodes[j]);
                    }
                }
            }
        });

        observer.observe(root, {
            attributes: true,
            attributeFilter: ['style', 'stroke', 'fill'],
            subtree: true,
            childList: true,
        });

        // Belt-and-suspenders sweep in case something sets colors in a way the observer misses,
        // and to pick up any <style> tags MUI injects after the initial render.
        setInterval(function () {
            scrubTree(root);
            scrubStyleSheets();
        }, 1000);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }
})();
