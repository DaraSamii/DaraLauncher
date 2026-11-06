import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    property string wallUrl: ""
    readonly property bool open: win.visible

    // same button in the panel (compact) and on the desktop (full), so it is never blank
    compactRepresentation: CompactRepresentation { launcher: root }
    // In a panel there must be NO full representation: the activation shortcut (Meta) would first pop up a big icon.
    // Only a floating desktop instance (form factor 0) needs one, to show the button instead of a blank square.
    fullRepresentation: Plasmoid.formFactor === 0 ? desktopButton : null
    Component { id: desktopButton; CompactRepresentation { launcher: root } }
    activationTogglesExpanded: false
    Plasmoid.icon: cfg.icon
    toolTipMainText: i18n("Applications")
    toolTipSubText: i18n("Open the application launcher")

    // --- models (shared with the window) ---------------------------------
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        Component.onCompleted: {
            favoritesModel.initForClient("io.github.darasamii.launcher.favorites.instance-" + Plasmoid.id);
            if (!root.cfg.favoritesSeeded) {
                if (favoritesModel.count < 1)
                    favoritesModel.portOldFavorites(["preferred://browser", "org.kde.dolphin.desktop", "systemsettings.desktop", "org.kde.konsole.desktop", "org.kde.discover.desktop"]);
                root.cfg.favoritesSeeded = true;
            }
            refresh();
        }
    }
    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: root
        mergeResults: true
        favoritesModel: root.rootModel.favoritesModel
    }
    readonly property Kicker.RecentUsageModel recentModel: Kicker.RecentUsageModel {
        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: Kicker.RecentUsageModel.Recent
    }
    readonly property Kicker.RecentUsageModel frequentModel: Kicker.RecentUsageModel {
        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: Kicker.RecentUsageModel.Popular
    }

    // --- helpers: run a shell command (wallpaper lookup, power actions) ----
    property int seq: 0
    property var pending: ({})
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            const cb = root.pending[source];
            delete root.pending[source];
            if (cb) cb((data["stdout"] || "").trim());
        }
    }
    function run(cmd, cb) {
        const key = cmd + " # " + (++seq); // unique so repeated calls are not deduplicated
        if (cb) pending[key] = cb;
        exec.connectSource(key);
    }
    function refreshWallpaper() {
        if (cfg.wallpaperMode !== 0) return;
        const py = Qt.resolvedUrl("../code/wallpaper.py").toString().replace("file://", "");
        run("python3 -I '" + py + "'", out => wallUrl = out);
    }
    Component.onCompleted: refreshWallpaper() // ready before the first open: no black flash
    function power(what) {
        const prompt = a => "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt." + a;
        run({ lock: "loginctl lock-session", sleep: "systemctl suspend", logout: prompt("promptLogout"),
              reboot: prompt("promptReboot"), shutdown: prompt("promptShutDown") }[what]);
    }

    LauncherWindow { id: win; launcher: root }

    Connections {
        target: Plasmoid
        function onActivated() { root.toggle(); }
    }
    // Free area of the panel's screen: the screen minus the panel (null when the panel cannot be located).
    function freeRect() {
        const pw = compactRepresentationItem ? compactRepresentationItem.Window.window : null;
        if (!pw) return null;
        const cx = pw.x + pw.width / 2, cy = pw.y + pw.height / 2;
        for (const sc of Qt.application.screens) {
            const r = { x: sc.virtualX, y: sc.virtualY, w: sc.width, h: sc.height };
            if (cx < r.x || cy < r.y || cx >= r.x + r.w || cy >= r.y + r.h) continue;
            if (pw.width > pw.height) {            // horizontal panel: cut at its top or bottom edge
                if (cy > r.y + r.h / 2) r.h = pw.y - r.y; else { r.h = r.y + r.h - (pw.y + pw.height); r.y = pw.y + pw.height; }
            } else {                               // vertical panel
                if (cx > r.x + r.w / 2) r.w = pw.x - r.x; else { r.w = r.x + r.w - (pw.x + pw.width); r.x = pw.x + pw.width; }
            }
            return r;
        }
        return null;
    }
    function toggle() {
        if (win.visible) { win.visible = false; return; }
        const r = cfg.keepTaskbar ? freeRect() : null;
        if (r) {
            // sized before it is shown, so the panel is never covered, not even for one frame
            win.x = r.x; win.y = r.y; win.width = r.w; win.height = r.h;
            win.visibility = Window.Windowed;
            win.requestActivate();
        } else {
            win.toggle();
            if (win.visibility !== Window.FullScreen) win.visibility = Window.FullScreen; // coming back from "keep taskbar" mode
        }
    }

    function openSettings() { Plasmoid.internalAction("configure").trigger(); }
}
