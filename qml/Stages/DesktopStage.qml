/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Unity.Application 0.1
import "../Components/PanelState"
import Utils 0.1
import Ubuntu.Gestures 0.1

FocusScope {
    id: root

    anchors.fill: parent

    property alias background: wallpaper.source
    property var windowStateStorage: WindowStateStorage
    property bool altTabPressed: false

    onAltTabPressedChanged: {
        print("Alt+Tab pressed:", altTabPressed)
        if (altTabPressed) {
            appRepeater.highlightedIndex = Math.min(ApplicationManager.count - 1, 1);
        } else {
            if (root.state == "altTab") {
                print("focusing app", appRepeater.highlightedIndex)
                ApplicationManager.requestFocusApplication(ApplicationManager.get(appRepeater.highlightedIndex).appId)
            }
        }
    }

    function altTabNext() {
        if (root.altTabPressed) {
            print("should tab next")
            appRepeater.highlightedIndex = (appRepeater.highlightedIndex + 1) % ApplicationManager.count;
            var newContentX = ((spreadFlickable.contentWidth) / (ApplicationManager.count + 1)) * Math.max(0, Math.min(ApplicationManager.count - 5, appRepeater.highlightedIndex - 3));
            if (spreadFlickable.contentX < newContentX || appRepeater.highlightedIndex == 0) {
                spreadFlickable.snapTo(newContentX)
            }
        }
    }

    function altTabPrevious() {
        print("alttabprevious pressed")
        if (root.altTabPressed) {
            var newIndex = appRepeater.highlightedIndex - 1 >= 0 ? appRepeater.highlightedIndex - 1 : ApplicationManager.count - 1;
            appRepeater.highlightedIndex = newIndex;
            var newContentX = ((spreadFlickable.contentWidth) / (ApplicationManager.count + 1)) * Math.max(0, Math.min(ApplicationManager.count - 5, appRepeater.highlightedIndex - 1));
            if (spreadFlickable.contentX > newContentX || newIndex == ApplicationManager.count -1) {
                spreadFlickable.snapTo(newContentX)
            }
        }
    }

    CrossFadeImage {
        id: wallpaper
        anchors.fill: parent
        sourceSize { height: root.height; width: root.width }
        fillMode: Image.PreserveAspectCrop
    }

    Connections {
        target: ApplicationManager
        onApplicationAdded: {
            ApplicationManager.requestFocusApplication(ApplicationManager.get(ApplicationManager.count-1).appId)
        }

        onFocusRequested: {
            var appIndex = priv.indexOf(appId);
            var appDelegate = appRepeater.itemAt(appIndex);
            if (appDelegate.state === "minimized") {
                appDelegate.state = "normal"
            }
            appDelegate.focusWindow();
            ApplicationManager.focusApplication(appId);
        }
    }

    QtObject {
        id: priv

        readonly property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: focusedAppId ? appRepeater.itemAt(indexOf(focusedAppId)) : null

        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }
    }

    Connections {
        target: PanelState
        onClose: {
            ApplicationManager.stopApplication(ApplicationManager.focusedApplicationId)
        }
        onMinimize: appRepeater.itemAt(0).state = "minimized"
        onMaximize: appRepeater.itemAt(0).state = "normal"
    }

    Binding {
        target: PanelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.state === "maximized"
    }

    Item {
        Repeater {
            id: appRepeater
            model: ApplicationManager

            property int highlightedIndex: 1

            delegate: Item {
                id: appDelegate
                z: ApplicationManager.count - index
                y: units.gu(3)
                width: units.gu(60)
                height: units.gu(50)

                readonly property int minWidth: units.gu(10)
                readonly property int minHeight: units.gu(10)

                function focusWindow() {
                    decoratedWindow.window.forceActiveFocus();
                }

                states: [
                    State {
                        name: "normal"
                    },
                    State {
                        name: "maximized"
                        PropertyChanges { target: appDelegate; x: 0; y: 0; width: root.width; height: root.height }
                    },
                    State {
                        name: "minimized"
                        PropertyChanges { target: appDelegate; x: -appDelegate.width / 2; scale: units.gu(5) / appDelegate.width; opacity: 0 }
                    },
                    State {
                        name: "altTab"; when: root.state == "altTab"
                        PropertyChanges {
                            target: appDelegate
                            x: spreadMaths.animatedX
                            y: spreadMaths.animatedY + (appDelegate.height - decoratedWindow.height)
                            angle: spreadMaths.animatedAngle
                            //itemScale: spreadMaths.scale
                            //itemScaleOriginY: appDelegate.height;
                            z: index
                        }
                        PropertyChanges {
                            target: decoratedWindow
                            decorationShown: false
                            highlightShown: index == appRepeater.highlightedIndex
                            state: "transformed"
                            width: spreadMaths.spreadHeight
                            height: spreadMaths.spreadHeight
                        }
                        PropertyChanges {
                            target: tileInfo
                            visible: true
                            opacity: spreadMaths.tileInfoOpacity
                        }
                        PropertyChanges {
                            target: spreadSelectArea
                            enabled: true
                        }
                        PropertyChanges {
                            target: windowMoveResizeArea
                            enabled: false
                        }
                    }
                ]
                transitions: [
                    Transition {
                        from: "maximized,minimized,normal,"
                        to: "maximized,minimized,normal,"
                        PropertyAnimation { target: appDelegate; properties: "x,y,opacity,width,height,scale" }
                    }
                ]
                property real angle: 0
                property real itemScale: 1
                property int itemScaleOriginX: 0
                property int itemScaleOriginY: 0

                SpreadMaths {
                    id: spreadMaths
                    flickable: spreadFlickable
                    itemIndex: index
                    totalItems: ApplicationManager.count
                    sceneHeight: root.height
                    itemHeight: appDelegate.height
                }

                WindowMoveResizeArea {
                    id: windowMoveResizeArea
                    target: appDelegate
                    minWidth: appDelegate.minWidth
                    minHeight: appDelegate.minHeight
                    resizeHandleWidth: units.gu(0.5)
                    windowId: model.appId // FIXME: Change this to point to windowId once we have such a thing

                    onPressed: decoratedWindow.focus = true;
                }

                DecoratedWindow {
                    id: decoratedWindow
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top
                    windowWidth: appDelegate.width
                    windowHeight: appDelegate.height
                    application: ApplicationManager.get(index)
                    active: ApplicationManager.focusedApplicationId === model.appId

                    onFocusChanged: {
                        if (focus) {
                            ApplicationManager.focusApplication(model.appId);
                        }
                    }

                    onClose: ApplicationManager.stopApplication(model.appId)
                    onMaximize: appDelegate.state = (appDelegate.state == "maximized" ? "normal" : "maximized")
                    onMinimize: appDelegate.state = "minimized"

                    transform: [
                        Scale {
                            origin.x: itemScaleOriginX
                            origin.y: itemScaleOriginY
                            xScale: itemScale
                            yScale: itemScale
                        },
                        Rotation {
                            origin { x: 0; y: (decoratedWindow.height - (decoratedWindow.height * itemScale / 2)) }
                            axis { x: 0; y: 1; z: 0 }
                            angle: appDelegate.angle
                        }
                    ]

                    MouseArea {
                        id: spreadSelectArea
                        anchors.fill: parent
                        enabled: false
                        onClicked: {
                            print("clicked")
                            appDelegate.focusWindow()
                            root.state = ""
                        }
                    }
                }


                ColumnLayout {
                    id: tileInfo
                    width: units.gu(30)
                    anchors { left: parent.left; top: decoratedWindow.bottom; topMargin: units.gu(5) }
                    visible: false
                    spacing: units.gu(1)

                    UbuntuShape {
                        Layout.preferredHeight: units.gu(6)
                        Layout.preferredWidth: height
                        image: Image {
                            anchors.fill: parent
                            source: model.icon
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: units.gu(6)
                        text: model.name
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }
                }
            }
        }
    }

    FloatingFlickable {
        id: spreadFlickable
        anchors.fill: parent
        contentWidth: Math.max(6, ApplicationManager.count) * Math.min(height / 4, width / 5)

        //visible: false
        //boundsBehavior: Flickable.StopAtBounds

        onContentXChanged: print("contentXChanged", contentX)

        function ensureVisible(index) {

        }

        function snapTo(contentX) {
            snapAnimation.to = contentX
            snapAnimation.start();
        }

        UbuntuNumberAnimation {
            id: snapAnimation
            target: spreadFlickable
            property: "contentX"
        }
    }

    Rectangle {
        id: workspaceSelector
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: root.height * 0.3
        color: "#55000000"
        opacity: 0

        RowLayout {
            anchors {
                fill: parent
                topMargin: units.gu(5)
                bottomMargin: units.gu(2)
            }
            spacing: units.gu(1)
            Item { Layout.fillWidth: true }
            Repeater {
                model: 2 // TODO: should be workspacemodel
                Image {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height * root.width / root.height
                    source: root.background
                }
            }
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: height * root.width / root.height
                color: "#22ffffff"
                Label {
                    anchors.centerIn: parent
                    font.pixelSize: parent.height / 2
                    text: "+"
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    Label {
        anchors { left: parent.left; bottom: parent.bottom; margins: units.gu(1) }
        text: "Progress: " + (spreadFlickable.contentX / (spreadFlickable.contentWidth -  spreadFlickable.width)).toFixed(3) +
              ", ContentX: " + spreadFlickable.contentX +
              ", Width: " + spreadFlickable.width +
              ", ContentWidth: " + spreadFlickable.contentWidth

        color: "red"
        fontSize: "x-large"
        z: 100
    }

    states: [
        State {
            name: "windowed"
        },
        State {
            name: "altTab"; when: root.altTabPressed
            PropertyChanges { target: spreadFlickable; visible: true }
            PropertyChanges { target: workspaceSelector; opacity: 1 }
        }
    ]
    transitions: [
        Transition {
            from: "*"
            to: "altTab"
            PropertyAction { target: spreadFlickable; property: "contentX";
                value: ((spreadFlickable.contentWidth) / (ApplicationManager.count + 1)) * Math.max(0, Math.min(ApplicationManager.count - 3, 1));

            }
            PropertyAnimation { property: "opacity" }
        },
        Transition {
            from: "*"
            to: "*"
            PropertyAnimation { property: "opacity" }
        }

    ]

    MouseArea {
         anchors {
             top: parent.top
             right: parent.right
             bottom: parent.bottom
         }
         width: 1 // yes, we want 1 pixel, regardless of the scaling
         hoverEnabled: true
         onContainsMouseChanged: {
             if (containsMouse) {
                 root.state = "altTab"
             }
         }
    }
}
