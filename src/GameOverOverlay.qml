/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.touchdown 1.0

// Shown when gameOver becomes true. Fades in via opacity Behavior.
// Write-back to main.qml is entirely through startLevelRequested(level).
// TouchdownStorage is a global singleton — accessed directly, not passed in.
Item {
    id: root

    property bool gameOver: false
    property bool crashed: false
    property bool landed: false
    property int  elapsedMs: 0
    property int  currentLevel: 1
    property real shipWorldX: 0
    property real targetPadXStart: 0
    property real targetPadXEnd: 0

    signal startLevelRequested(int level)

    visible: gameOver

    function formatTime(ms) {
        var s  = Math.floor(ms / 1000)
        var m  = Math.floor(s / 60)
        var ds = Math.floor((ms % 1000) / 100)
        return (m > 0 ? m + ":" : "") + (m > 0 && (s % 60) < 10 ? "0" : "") + (s % 60) + "." + ds + "s"
    }

    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        opacity: root.gameOver ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Column {
            id: gameOverTop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Dims.l(4)
            spacing: Dims.l(2)

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formatTime(root.elapsedMs)
                font.pixelSize: Dims.l(9)
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.crashed ? "CRASHED" : "TOUCHDOWN!"
                font { family: "Barlow"; styleName: "Medium"; pixelSize: Dims.l(11) }
                color: root.crashed ? "#FF4400" : "#AAFFAA"
            }

            // Hint shown when landed off the target pad
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.landed && !(root.shipWorldX >= root.targetPadXStart && root.shipWorldX <= root.targetPadXEnd)
                text: "Land on pad to advance!"
                font.pixelSize: Dims.l(5)
                opacity: 0.6
            }

            // Shown the first time a new level is unlocked
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.landed && TouchdownStorage.highestUnlockedLevel === root.currentLevel + 1
                text: "Level " + (root.currentLevel + 1) + " unlocked!"
                font.pixelSize: Dims.l(5)
                color: "#AAFFAA"
            }
        }

        // Per-level best times
        ListView {
            id: scoresList
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: gameOverTop.bottom
            anchors.topMargin: Dims.l(4)
            anchors.bottom: buttonsColumn.top
            anchors.bottomMargin: Dims.l(2)
            width: Dims.l(55)
            model: TouchdownStorage.highestUnlockedLevel

            delegate: Item {
                width: scoresList.width
                height: Dims.l(8)
                property int lvl: index + 1
                property int best: TouchdownStorage.bestTime(lvl)

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "L" + lvl
                    font.pixelSize: Dims.l(4.5)
                    opacity: lvl === root.currentLevel ? 1.0 : 0.6
                    color: lvl === root.currentLevel ? "#AAFFAA" : "#FFFFFF"
                }
                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: best > 0 ? root.formatTime(best) : "—"
                    font.pixelSize: Dims.l(4.5)
                    opacity: lvl === root.currentLevel ? 1.0 : 0.6
                    color: lvl === root.currentLevel ? "#AAFFAA" : "#FFFFFF"
                }
            }
        }

        Column {
            id: buttonsColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.l(6)
            spacing: Dims.l(3)

            Rectangle {
                width: Dims.l(38); height: Dims.l(12); radius: height / 2
                color: "#55FFFFFF"
                Label { anchors.centerIn: parent; text: "RETRY L" + root.currentLevel; font.pixelSize: Dims.l(5) }
                MouseArea { anchors.fill: parent; onClicked: root.startLevelRequested(root.currentLevel) }
            }

            Rectangle {
                visible: TouchdownStorage.highestUnlockedLevel > root.currentLevel
                width: Dims.l(38); height: Dims.l(12); radius: height / 2
                color: "#33FFFFFF"
                Label { anchors.centerIn: parent; text: "NEXT L" + TouchdownStorage.highestUnlockedLevel; font.pixelSize: Dims.l(5); opacity: 0.9 }
                MouseArea { anchors.fill: parent; onClicked: root.startLevelRequested(TouchdownStorage.highestUnlockedLevel) }
            }
        }
    }
}
