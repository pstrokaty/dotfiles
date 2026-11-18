import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel

Scope {
    id: root
    property bool open: false
    readonly property string home: Quickshell.env("HOME")
    readonly property string wallsDir: home + "/Obrazy/Wallpapers"
    readonly property string thumbsDir: home + "/.cache/wallpaper-thumbs"
    property string currentWallPath: ""
    property int g213Mode: 0
    property var g213Modes: []
    property var g213Cache: ({})
    property bool appliedInSession: false
    readonly property string centeredWallPath: (carousel.currentIndex >= 0 && carousel.currentIndex < wallModel.count) ? root.originalOf(wallModel.get(carousel.currentIndex, "fileName")) : root.currentWallPath
    function modesForWall(wp) { return (wp && root.g213Cache && root.g213Cache[wp] && Array.isArray(root.g213Cache[wp].modes)) ? root.g213Cache[wp].modes : root.g213Modes }
    function activeModeObj(wp) { const l = root.modesForWall(wp); if (l && l.length > 0) { const i = ((root.g213Mode % l.length) + l.length) % l.length; return l[i] } return { name: "Accent & Glow", colors: ["#ea7761", "#ff856e", "#e84d30", "#ffc043", "#f09e8e"] } }
    readonly property var activeG213Colors: (g213Modes.length > 0 && g213Mode >= 0 && g213Mode < g213Modes.length) ? g213Modes[g213Mode].colors : ["#ea7761", "#ff856e", "#e84d30", "#ffc043", "#f09e8e"]
    readonly property string activeG213Name: (g213Modes.length > 0 && g213Mode >= 0 && g213Mode < g213Modes.length) ? g213Modes[g213Mode].name : "Accent & Glow"
    function previewCenteredG213() { const cmd = [root.home + "/.local/bin/g213-sync-colors", "--mode", String(root.g213Mode)]; if (root.centeredWallPath) { cmd.push("--image"); cmd.push(root.centeredWallPath) } Quickshell.execDetached(cmd) }
    function cycleG213Mode(delta) { const l = root.modesForWall(root.centeredWallPath); const n = (l && l.length > 0) ? l.length : 6; root.g213Mode = (root.g213Mode + delta + n) % n; g213PreviewTimer.stop(); root.previewCenteredG213() }

    function originalOf(thumbName) {
        return root.wallsDir + "/" + String(thumbName).replace(/\.jpg$/, "").replace(/__/g, "/")
    }

    function thumbKeyOf(fullPath) {
        const prefix = root.wallsDir + "/"
        if (!fullPath.startsWith(prefix)) return ""
        return fullPath.slice(prefix.length).replace(/\//g, "__") + ".jpg"
    }

    function applyPath(fullPath) {
        if (!fullPath) return
        root.currentWallPath = fullPath
        root.appliedInSession = true
        Quickshell.execDetached([root.home + "/.config/quickshell-wallfx/set-wallpaper.sh", fullPath])
        g213SyncTimer.restart()
    }

    function apply(thumbName) {
        if (!thumbName) return
        root.applyPath(root.originalOf(thumbName))
        root.open = false
    }

    function syncToCurrent() {
        const targetThumb = root.thumbKeyOf(root.currentWallPath)
        if (!targetThumb || wallModel.count === 0) return
        for (let i = 0; i < wallModel.count; i++) {
            if (wallModel.get(i, "fileName") === targetThumb) {
                carousel.currentIndex = i
                carousel.positionViewAtIndex(i, ListView.Center)
                return
            }
        }
    }

    function stepImmediate(delta) {
        if (wallModel.count === 0) return
        let idx = -1
        const targetThumb = root.thumbKeyOf(root.currentWallPath)
        for (let i = 0; i < wallModel.count; i++) {
            if (wallModel.get(i, "fileName") === targetThumb) { idx = i; break }
        }
        const nextIdx = (idx + delta + wallModel.count) % wallModel.count
        root.applyPath(root.originalOf(wallModel.get(nextIdx, "fileName")))
    }

    Process {
        id: currentWallProc
        command: ["noctalia", "msg", "wallpaper-get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) {
                    root.currentWallPath = p
                    if (root.open) root.syncToCurrent()
                }
            }
        }
    }
    function refreshCurrentWall() {
        currentWallProc.running = false
        currentWallProc.running = true
    }

    Process {
        id: thumbsProc
        command: ["bash", root.home + "/.config/quickshell-wallfx/scripts/wall-thumbs.sh"]
        onExited: {
            if (wallModel.count === 0) {
                wallModel.folder = ""
                wallModel.folder = "file://" + root.thumbsDir
            }
            if (root.open) root.syncToCurrent()
        }
    }
    function refreshThumbs() { thumbsProc.running = false; thumbsProc.running = true }

    Process {
        id: warmProc
        command: [root.home + "/.local/bin/wallfx", "warm", root.wallsDir + "/UltraDual"]
    }
    function warmTransitions() { if (!warmProc.running) warmProc.running = true; if (!g213WarmProc.running) g213WarmProc.running = true }
    Process { id: g213WarmProc; command: [root.home + "/.local/bin/g213-sync-colors", "--warm", root.wallsDir]; onExited: root.refreshG213Cache() }
    Process { id: g213CacheProc; command: ["bash", "-c", '[ -f "$HOME/.cache/wallfx/g213-cache.json" ] && cat "$HOME/.cache/wallfx/g213-cache.json" || echo "{}"']; stdout: StdioCollector { onStreamFinished: { try { const o = JSON.parse(text.trim()); if (o && typeof o === "object") root.g213Cache = o } catch (e) {} } } }
    function refreshG213Cache() { g213CacheProc.running = false; g213CacheProc.running = true }
    Process { id: g213SingleProc; property string targetWall: ""; command: [root.home + "/.local/bin/g213-sync-colors", "--export-only", "--image", targetWall]; onExited: root.refreshG213Cache() }
    function ensureWallPalette(wp) { if (!wp || (root.g213Cache && root.g213Cache[wp]) || g213SingleProc.running) return; g213SingleProc.targetWall = wp; g213SingleProc.running = true }
    Process { id: g213ModesProc; command: ["bash", "-c", '[ -f "$HOME/.cache/wallfx/g213-modes.json" ] || "$HOME/.local/bin/g213-sync-colors" --export-only; cat "$HOME/.cache/wallfx/g213-modes.json"']; stdout: StdioCollector { onStreamFinished: { try { const o = JSON.parse(text.trim()); if (o && Array.isArray(o.modes)) { root.g213Modes = o.modes; if (typeof o.active === "number") root.g213Mode = o.active } } catch (e) {} } } }
    function refreshG213Modes() { g213ModesProc.running = false; g213ModesProc.running = true; root.refreshG213Cache() }
    Timer { id: g213SyncTimer; interval: 750; repeat: false; onTriggered: root.refreshG213Modes() }
    Timer { id: g213PreviewTimer; interval: 90; repeat: false; onTriggered: if (root.open) root.previewCenteredG213() }

    Component.onCompleted: {
        root.refreshThumbs()
        root.refreshCurrentWall()
        root.refreshG213Modes()
    }

    IpcHandler {
        target: "picker"
        function toggle(): string {
            root.open = !root.open
            return root.open ? "open" : "closed"
        }
        function next(): string {
            if (root.open) {
                carousel.incrementCurrentIndex()
                return "carousel-next"
            }
            root.stepImmediate(1)
            return "applied-next"
        }
        function prev(): string {
            if (root.open) {
                carousel.decrementCurrentIndex()
                return "carousel-prev"
            }
            root.stepImmediate(-1)
            return "applied-prev"
        }
        function random(): string {
            if (wallModel.count === 0) return "empty"
            if (root.open) {
                if (wallModel.count > 1) {
                    let r = Math.floor(Math.random() * (wallModel.count - 1))
                    if (r >= carousel.currentIndex) r++
                    carousel.currentIndex = r
                }
                return "carousel-random"
            }
            Quickshell.execDetached([root.home + "/.config/quickshell-wallfx/random-wallpaper.sh"])
            return "applied-random"
        }
    }

    HyprlandFocusGrab { windows: [win]; active: root.open; onCleared: root.open = false }

    FolderListModel {
        id: wallModel
        folder: "file://" + root.thumbsDir
        nameFilters: ["*.jpg"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: if (root.open) root.syncToCurrent()
    }

    PanelWindow {
        id: win
        screen: {
            const mon = Hyprland.focusedMonitor
            if (mon) {
                const found = Quickshell.screens.find(s => s.name === mon.name)
                if (found) return found
            }
            return Quickshell.screens[0]
        }
        visible: root.open || stage.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:wallpaper"

        Item {
            id: stage
            anchors.fill: parent
            focus: true
            opacity: root.open ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 210 : 110
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }

            Connections {
                target: root
                function onOpenChanged() {
                    if (!root.open) { g213PreviewTimer.stop(); if (!root.appliedInSession) Quickshell.execDetached([root.home + "/.local/bin/g213-sync-colors"]); return }
                    root.appliedInSession = false
                    stage.forceActiveFocus()
                    root.refreshCurrentWall()
                    root.refreshThumbs()
                    root.warmTransitions()
                    root.syncToCurrent()
                    root.refreshG213Modes()
                }
            }

            Keys.onEscapePressed: root.open = false
            Keys.onLeftPressed:   carousel.decrementCurrentIndex()
            Keys.onRightPressed:  carousel.incrementCurrentIndex()
            Keys.onUpPressed: (e) => { if ((e.modifiers & (Qt.MetaModifier | Qt.AltModifier)) === 0) { root.cycleG213Mode(-1); e.accepted = true } }
            Keys.onDownPressed: (e) => { if ((e.modifiers & (Qt.MetaModifier | Qt.AltModifier)) === 0) { root.cycleG213Mode(1); e.accepted = true } }
            Keys.onReturnPressed: carousel.applyCurrent()
            Keys.onEnterPressed:  carousel.applyCurrent()
            WheelHandler {
                onWheel: (e) => {
                    if (e.angleDelta.y > 0 || e.angleDelta.x > 0) carousel.decrementCurrentIndex()
                    else carousel.incrementCurrentIndex()
                }
            }

            MouseArea { anchors.fill: parent; z: -1; onClicked: root.open = false }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: carousel.verticalCenter
                height: carousel.height + 48
                color: "#73000000"
                z: -0.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#26ffffff"
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#26ffffff"
                }
            }

            ListView {
                id: carousel
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; verticalCenterOffset: 12 }
                height: 560
                orientation: ListView.Horizontal
                model: wallModel
                property real iw: 720
                property real ih: 406
                property real skew: -0.35
                property real bw: 3
                property real slotW: 360
                property real sideBase: 0.56
                readonly property real imgW: iw + ih * Math.abs(skew) + 12
                spacing: 0; clip: false; cacheBuffer: 2500
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - slotW) / 2
                preferredHighlightEnd:   (width + slotW) / 2
                highlightMoveDuration: 420
                highlightMoveVelocity: 3000
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds
                maximumFlickVelocity: 6000

                onCurrentIndexChanged: if (root.open) { root.ensureWallPalette(root.centeredWallPath); g213PreviewTimer.restart() }
                function applyCurrent() {
                    if (currentIndex < 0 || wallModel.count <= currentIndex) return
                    root.apply(wallModel.get(currentIndex, "fileName"))
                }

                delegate: Item {
                    id: slot
                    width: carousel.slotW
                    height: carousel.height
                    readonly property string wallPath: root.originalOf(model.fileName)
                    readonly property var slotModeObj: root.activeModeObj(slot.wallPath)
                    readonly property real d: (x + width / 2 - (carousel.contentX + carousel.width / 2)) / carousel.slotW
                    readonly property real ad: Math.abs(d)
                    readonly property real sc: ad <= 1
                        ? carousel.sideBase + (1 - carousel.sideBase) * Math.pow(1 - ad, 1.35)
                        : carousel.sideBase * Math.pow(0.86, ad - 1)
                    z: Math.round(100 - ad * 10)
                    opacity: Math.max(0, Math.min(1, 1.15 - 0.34 * ad))

                    Item {
                        id: card
                        anchors.centerIn: parent
                        width: carousel.iw
                        height: carousel.ih
                        scale: slot.sc
                        transformOrigin: Item.Center
                        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, carousel.skew, 0, -carousel.skew * carousel.ih / 2,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1) }

                        Rectangle {
                            anchors.fill: parent
                            color: "#14161b"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.22)
                        }
                        Item {
                            anchors.fill: parent; anchors.margins: carousel.bw; clip: true
                            Image {
                                anchors.centerIn: parent
                                width: carousel.imgW
                                height: carousel.ih
                                fillMode: Image.PreserveAspectCrop
                                source: model.fileUrl
                                asynchronous: true; cache: true; mipmap: true
                                sourceSize: Qt.size(carousel.imgW, carousel.ih)
                                transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -carousel.skew, 0, carousel.skew * carousel.ih / 2,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1) }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: slot.ad < 0.5 ? carousel.applyCurrent() : (carousel.currentIndex = index)
                        }
                    }
                    Item {
                        id: zoneDock
                        anchors.centerIn: parent
                        width: carousel.iw
                        height: carousel.ih
                        scale: slot.sc
                        readonly property real centerFocus: Math.max(0, 1.0 - slot.ad * 2.5)
                        readonly property real zoneH: 18
                        readonly property real zoneGap: 8
                        readonly property real gapY: 12
                        readonly property real zoneW: (carousel.iw - 4 * zoneGap) / 5
                        opacity: centerFocus
                        visible: centerFocus > 0.01
                        Row {
                            x: carousel.skew * (carousel.ih / 2 + zoneDock.gapY + zoneDock.zoneH / 2)
                            y: carousel.ih + zoneDock.gapY
                            spacing: zoneDock.zoneGap
                            Repeater {
                                model: 5
                                Rectangle {
                                    width: zoneDock.zoneW
                                    height: zoneDock.zoneH
                                    color: slot.slotModeObj.colors[index] || "#ea7761"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.28)
                                    transform: Matrix4x4 { matrix: Qt.matrix4x4(1, carousel.skew, 0, -carousel.skew * zoneDock.zoneH / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleG213Mode(1) }
                                }
                            }
                        }
                        Text {
                            x: carousel.skew * (carousel.ih / 2 + zoneDock.gapY + zoneDock.zoneH + 15)
                            y: carousel.ih + zoneDock.gapY + zoneDock.zoneH + 7
                            width: carousel.iw
                            horizontalAlignment: Text.AlignHCenter
                            text: (root.g213Mode + 1) + "/" + Math.max(1, root.modesForWall(slot.wallPath).length) + "  ·  " + slot.slotModeObj.name
                            color: "#e6e9ef"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            opacity: 0.9
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: wallModel.count === 0
                text: "No wallpapers found in ~/Obrazy/Wallpapers"
                color: "#e6e9ef"
                font.pixelSize: 18
                opacity: 0.9
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#000000"
                    shadowBlur: 1.0
                    blurMax: 16
                    shadowVerticalOffset: 0
                }
            }
        }
    }
}
