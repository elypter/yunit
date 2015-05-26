import QtQuick 2.0
import Ubuntu.Components 1.3
import QtMultimedia 5.0

Rectangle {
    id: root
    property int position: 0
    property int playbackState: 0
    property var resolution: { "width": 16, "height": 9 }

    anchors.centerIn: parent
    color: "black"

    // scale to the parent window.
    implicitWidth: parent ? aspectScale(Qt.size(resolution.width, resolution.height), Qt.size(parent.width, parent.height)).width : 160
    implicitHeight: parent ? aspectScale(Qt.size(resolution.width, resolution.height), Qt.size(parent.width, parent.height)).height : 90

    function aspectScale(fromSize, toSize) {
        var rw = toSize.height * fromSize.width / fromSize.height;
        var useHeight = (rw <= toSize.width);

        if (useHeight) {
            return Qt.size(rw, toSize.height);
        } else {
            return Qt.size(toSize.width,
                           toSize.width * (fromSize.height / fromSize.width));
        }
    }

    GridView {
        anchors.fill: parent
        model: (parent.width / units.gu(5)) * ((parent.height / units.gu(5) + 1))
        clip: true

        cellHeight: units.gu(5)
        cellWidth: units.gu(5)

        onModelChanged: console.log("COUNT", model)

        delegate: Item {
            width: units.gu(5)
            height: units.gu(5)

            Rectangle {
                id: rect
                color: "red"
                anchors.fill: parent
                anchors.margins: units.gu(1)

                Connections {
                    target: root
                    onPositionChanged: {
                        rect.rotation = position/100
                    }
                }
            }
        }
    }

    Column {
        anchors {
            left: parent.left;
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: units.gu(10)

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var pos = (position/1000).toFixed(0)

                var m = Math.floor(pos/60);
                var ss = pos % 60;
                if (ss >= 10) {
                    return m + ":" + ss;
                } else {
                    return m + ":0" + ss;
                }
            }
            fontSize: "x-large"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: getPlaybackState(playbackState)
            fontSize: "x-large"
        }
    }

    function getPlaybackState(playbackState) {
        if (playbackState === MediaPlayer.PlayingState) return "Playing";
        else if (playbackState === MediaPlayer.PausedState) return "Paused";
        else if (playbackState === MediaPlayer.StoppedState) return "Stopped";
        return "";
    }
}
