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
            countEl.textContent = loaded + '%';
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

    // Music dial - the icon's playing/muted look is driven purely by volume level (0% = muted,
    // anything above = playing), not by audio.paused, so dragging the slider to 0 always reads
    // as muted even though the element keeps running silently underneath. Starts playing at
    // 50% as soon as the page loads.
    var musicBtn = document.getElementById('music-toggle');
    var music = document.getElementById('bg-music');
    var volumeSlider = document.getElementById('volume-slider');
    var lastVolume = 50;

    function setDialState(vol) {
        if (musicBtn) musicBtn.classList.toggle('playing', vol > 0);
    }

    function ensurePlaying() {
        if (music.paused) music.play().catch(function () {});
    }

    if (volumeSlider && music) {
        volumeSlider.value = 50;
        music.volume = 0.5;
        setDialState(50);
        ensurePlaying();

        volumeSlider.addEventListener('input', function () {
            var vol = Number(volumeSlider.value);
            music.volume = vol / 100;
            if (vol > 0) lastVolume = vol;
            setDialState(vol);
            ensurePlaying();
        });
    }

    if (musicBtn && music && volumeSlider) {
        musicBtn.addEventListener('click', function () {
            var vol = Number(volumeSlider.value);
            if (vol > 0) {
                lastVolume = vol;
                volumeSlider.value = 0;
                music.volume = 0;
                setDialState(0);
            } else {
                volumeSlider.value = lastVolume > 0 ? lastVolume : 50;
                music.volume = volumeSlider.value / 100;
                setDialState(Number(volumeSlider.value));
                ensurePlaying();
            }
        });
    }

    // FiveM's loading screen doesn't render the OS cursor over the video background, so draw
    // our own and track raw mouse input directly - this still lets players click any real
    // clickable elements added to the page later, since pointer-events on the cursor itself
    // are disabled and it's purely a visual follower.
    var cursorEl = document.getElementById('custom-cursor');
    if (cursorEl) {
        window.addEventListener('mousemove', function (e) {
            cursorEl.style.transform = 'translate(' + (e.clientX - 2) + 'px, ' + (e.clientY - 2) + 'px)';
        });
        window.addEventListener('mousedown', function () {
            cursorEl.classList.add('clicking');
        });
        window.addEventListener('mouseup', function () {
            cursorEl.classList.remove('clicking');
        });
    }
})();
