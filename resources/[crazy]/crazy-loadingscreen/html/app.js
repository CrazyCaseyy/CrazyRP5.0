(function () {
    var fill = document.getElementById('progress-fill');
    var countEl = document.getElementById('progress-percent');
    var labelEl = document.getElementById('progress-label');
    var video = document.getElementById('bg-video');

    // Belt-and-suspenders for the `loop` attribute, which doesn't always reliably restart
    // playback in FiveM's CEF-based NUI - manually restart on end/stall/pause as a fallback.
    if (video) {
        var restart = function () {
            video.currentTime = 0;
            video.play().catch(function () {});
        };
        video.addEventListener('ended', restart);
        video.addEventListener('pause', function () {
            if (!video.ended) return;
            restart();
        });
        video.play().catch(function () {});
    }

    // loadFraction (0-1) is the ONLY real download-progress signal FiveM exposes - there is no
    // genuine per-file/asset download count available anywhere in the loading screen API (the
    // data-file-entry/init-function events tried earlier looked like counts but actually fire
    // almost instantly AFTER everything is already downloaded, which is why that number was
    // huge and never made sense as "still downloading"). So the "total" here is a fixed 100-unit
    // scale derived from the real fraction, not a literal file count. Once the fraction hits
    // 100%, downloading is done and the engine moves into the resource-startup phase, which
    // onLogLine (real console output) actually reflects - so switch the label to that instead of
    // sitting on a meaningless "100 / 100".
    function render(fraction) {
        var pct = Math.max(0, Math.min(1, fraction || 0));
        var loaded = Math.round(pct * 100);

        if (loaded >= 100) {
            countEl.textContent = 'Initializing';
        } else {
            countEl.textContent = loaded + ' / 100';
        }

        fill.style.width = loaded + '%';
    }

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.eventName) return;

        if (data.eventName === 'loadProgress') {
            render(data.loadFraction);
        }

        // FiveM doesn't expose a clean "current resource" field anywhere in the loading screen
        // API - onLogLine is the actual console output as resources start, which is the closest
        // real signal of "what's loading right now" that exists.
        if (data.eventName === 'onLogLine' && data.message) {
            labelEl.textContent = data.message;
        }
    });

    render(0);
})();
