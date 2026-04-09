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

    property int selectedLevel: currentLevel

    // True when the selected level continues the active combo chain.
    readonly property bool comboEligible: TouchdownStorage.comboStash > 0
        && TouchdownStorage.nextComboLevel > 0
        && selectedLevel === TouchdownStorage.nextComboLevel

    visible: gameOver

    onGameOverChanged: {
        if (gameOver) {
            var next = root.currentLevel + 1
            selectedLevel = next <= TouchdownStorage.highestUnlockedLevel ? next : root.currentLevel
            // Scroll list to show current level — small delay lets ListView finish layout
            scrollTimer.start()
        }
    }

    Timer {
        id: scrollTimer
        interval: 50
        repeat: false
        onTriggered: {
            var offset = TouchdownStorage.comboHighScore > 0 ? 1 : 0
            var idx = offset + (TouchdownStorage.highestUnlockedLevel - root.currentLevel)
            scoresList.positionViewAtIndex(idx, ListView.Center)
        }
    }

    function formatTime(ms) {
        var s  = Math.floor(ms / 1000)
        var m  = Math.floor(s / 60)
        var ds = Math.floor((ms % 1000) / 100)
        return (m > 0 ? m + ":" : "") + (m > 0 && (s % 60) < 10 ? "0" : "") + (s % 60) + "." + ds + "s"
    }

    Rectangle {
        anchors.fill: parent
        color: "#AA000000"
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
                color: root.crashed ? "#dc2919" : "#AAFFAA"
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.landed && !(root.shipWorldX >= root.targetPadXStart && root.shipWorldX <= root.targetPadXEnd)
                text: "Land on pad to advance!"
                font.pixelSize: Dims.l(5)
                opacity: 0.6
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.landed && TouchdownStorage.highestUnlockedLevel === root.currentLevel + 1
                text: "Level " + (root.currentLevel + 1) + " unlocked!"
                font.pixelSize: Dims.l(5)
                color: "#AAFFAA"
            }
        }

        // Scores list — combo row first, then per-level times, centred on current level
        ListView {
            id: scoresList
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: gameOverTop.bottom
            anchors.topMargin: Dims.l(2)
            anchors.bottom: buttonsColumn.top
            anchors.bottomMargin: Dims.l(2)
            width: Dims.l(55)
            // Natural top-to-bottom order — highest level at top after reverse sort
            model: TouchdownStorage.highestUnlockedLevel + (TouchdownStorage.comboHighScore > 0 ? 1 : 0)
            clip: true

            delegate: Item {
                width: scoresList.width
                height: Dims.l(8)

                // Index 0 is combo row when combo exists, rest are levels highest-first
                property bool isComboRow: TouchdownStorage.comboHighScore > 0 && index === 0
                property int lvl: {
                    if (isComboRow) return 0
                    var offset = TouchdownStorage.comboHighScore > 0 ? 1 : 0
                    return TouchdownStorage.highestUnlockedLevel - (index - offset)
                }
                property int best: isComboRow ? 0 : TouchdownStorage.bestTime(lvl)

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: isComboRow ? "COMBO" : "L" + lvl
                    font.pixelSize: Dims.l(4.5)
                    color: isComboRow ? "#f0c30e" : (lvl === root.currentLevel ? "#AAFFAA" : "#FFFFFF")
                    opacity: isComboRow ? 0.9 : (lvl === root.currentLevel ? 1.0 : 0.6)
                }
                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: isComboRow ? TouchdownStorage.comboHighScore : (best > 0 ? root.formatTime(best) : "—")
                    font.pixelSize: Dims.l(4.5)
                    color: isComboRow ? "#f0c30e" : (lvl === root.currentLevel ? "#AAFFAA" : "#FFFFFF")
                    opacity: isComboRow ? 0.9 : (lvl === root.currentLevel ? 1.0 : 0.6)
                }
            }
        }

        Column {
            id: buttonsColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.l(6)
            spacing: Dims.l(3)

            ValueCycler {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Dims.l(64)
                height: Dims.l(14)
                valueArray: {
                    var arr = []
                    for (var i = 1; i <= TouchdownStorage.highestUnlockedLevel; i++) arr.push("Level " + i)
                    return arr
                }
                currentValue: "Level " + root.selectedLevel
                labelColor: root.comboEligible ? "#f0c30e" : "#FFFFFF"
                onValueChanged: root.selectedLevel = parseInt(value.replace("Level ", ""))
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Dims.l(38); height: Dims.l(12); radius: height / 2
                color: root.comboEligible ? "#44f0ae0e" : "#55FFFFFF"
                Label {
                    anchors.centerIn: parent
                    text: root.comboEligible ? "COMBO L" + root.selectedLevel : "FLY L" + root.selectedLevel
                    font.pixelSize: Dims.l(5)
                    color: root.comboEligible ? "#f0c30e" : "#FFFFFF"
                }
                MouseArea { anchors.fill: parent; onClicked: root.startLevelRequested(root.selectedLevel) }
            }
        }
    }
}
