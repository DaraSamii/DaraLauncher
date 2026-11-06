import QtQuick

// Scripted tour of the launcher for the README: grabs numbered frames (-> demo.gif) and a few full-size screenshots.
// Injected into a sandbox copy by tools/media.sh; uses a stock KDE wallpaper and a restricted search (apps, calculator,
// settings) so nothing personal ends up in the pictures.
Item {
    id: me
    required property var root
    required property var win
    readonly property var cfg: root.cfg
    readonly property string out: "@OUT@"
    property int elapsed: 0
    property int frames: 0
    property var done: ({})
    property var av: null

    function items() { const r = []; const w = it => { r.push(it); for (const c of it.children) w(c); }; w(win.mainItem); return r; }
    function shot(name) { win.mainItem.grabToImage(r => r.saveToFile(out + "/" + name + ".png")); }
    function scrollTo(y, ms) { if (!av) return; sa.stop(); sa.to = y; sa.duration = ms; sa.start(); }
    function typeText(text, stepMs) { for (let i = 1; i <= text.length; ++i) pending.push([elapsed + i * stepMs, () => win.searchField.text = text.slice(0, i)]); }
    property var pending: []

    NumberAnimation { id: sa; target: me.av; property: "contentY"; easing.type: Easing.InOutCubic }

    readonly property var plan: [
        [0,     () => {
            cfg.wallpaperMode = 1; cfg.wallpaperPath = "/usr/share/wallpapers/MilkyWay/contents/images/5120x2880.png"; cfg.dim = 52; cfg.blur = 38;
            root.runnerModel.runners = ["krunner_services", "calculator", "krunner_systemsettings"];
            cfg.viewMode = 0; cfg.iconPreset = 2; cfg.textPreset = 2; cfg.keepTaskbar = false; win.toggle();
        }],
        [900,   () => { av = items().find(it => it.reuseItems === true && it.contentY !== undefined); }],
        [1700,  () => shot("hero")],
        [2000,  () => scrollTo(2300, 2600)],
        [5000,  () => { shot("sections-scrolled"); win.catIndex = 5; }],
        [5700,  () => shot("category")],
        [6700,  () => { win.catIndex = 0; scrollTo(0, 200); }],
        [7300,  () => typeText("128/4+17", 190)],
        [9800,  () => shot("search")],
        [10800, () => win.searchField.text = ""],
        [11300, () => cfg.viewMode = 1],
        [12000, () => shot("grid")],
        [13200, () => cfg.viewMode = 2],
        [13900, () => shot("list")],
        [15100, () => cfg.viewMode = 0],
        [15800, () => win.settingsOpen = true],
        [16700, () => shot("settings")],
        [16900, () => cfg.iconPreset = 0],
        [17700, () => cfg.iconPreset = 4],
        [18500, () => { shot("settings-huge"); cfg.iconPreset = 3; }],
        [19300, () => cfg.iconPreset = 2],
        [20100, () => win.settingsOpen = false],
        [21000, () => console.warn("DEMO DONE frames=" + frames)]
    ]

    Timer {
        interval: 125
        running: true
        repeat: true
        onTriggered: {
            me.elapsed += 125;
            plan.forEach((p, i) => { if (!me.done[i] && p[0] <= me.elapsed) { me.done[i] = true; p[1](); } });
            me.pending = me.pending.filter(p => { if (p[0] <= me.elapsed) { p[1](); return false; } return true; });
            if (me.elapsed > 900 && me.elapsed < 21000) {
                const n = ("000" + me.frames++).slice(-4);
                win.mainItem.grabToImage(r => r.saveToFile(me.out + "/frames/f" + n + ".png"), Qt.size(win.width * 0.4, win.height * 0.4));
            }
        }
    }
}
