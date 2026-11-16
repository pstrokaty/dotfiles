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
        Quickshell.execDetached([root.home + "/.config/quickshell-wallfx/set-wallpaper.sh", fullPath])
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
    function warmTransitions() { if (!warmProc.running) warmProc.running = true }

    Component.onCompleted: {
        root.refreshThumbs()
        root.refreshCurrentWall()
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
                    if (!root.open) return
                    stage.forceActiveFocus()
                    root.refreshCurrentWall()
                    root.refreshThumbs()
                    root.warmTransitions()
                    root.syncToCurrent()
                }
            }

            Keys.onEscapePressed: root.open = false
            Keys.onLeftPressed:   carousel.decrementCurrentIndex()
            Keys.onRightPressed:  carousel.incrementCurrentIndex()
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

                function applyCurrent() {
                    if (currentIndex < 0 || wallModel.count <= currentIndex) return
                    root.apply(wallModel.get(currentIndex, "fileName"))
                }

                delegate: Item {
                    id: slot
                    width: carousel.slotW
                    height: carousel.height
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
