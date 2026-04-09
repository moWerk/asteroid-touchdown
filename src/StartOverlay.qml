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

// Covers level selection and the pre-launch calibration countdown.
// Write-back to main.qml is through two signals only — no object references cross the boundary.
Item {
    id: root

    property bool selectingLevel: true
    property bool calibrating: false
    property int  currentLevel: 1
    property int  nextComboLevel:  0
    property int  comboStash:      0

    readonly property bool comboEligible: comboStash > 0 && nextComboLevel > 0 && currentLevel === nextComboLevel
    property int  calibrationSeconds: 3
    property int  calibrationCount: 0

    // Emitted when the player taps ENTER ORBIT. main.qml calls generateWorld(level)
    // then starts calibrationTimer in response.
    signal launchRequested(int level)
    // Emitted when the player taps the level cycler. main.qml updates currentLevel.
    signal levelSelected(int level)

    visible: selectingLevel || calibrating

    function formatTime(ms) {
        var s  = Math.floor(ms / 1000)
        var m  = Math.floor(s / 60)
        var ds = Math.floor((ms % 1000) / 100)
        return (m > 0 ? m + ":" : "") + (m > 0 && (s % 60) < 10 ? "0" : "") + (s % 60) + "." + ds + "s"
    }

    // ── Level select
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        visible: root.selectingLevel

        Column {
            anchors.centerIn: parent
            spacing: Dims.l(7)

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TOUCHDOWN"
                font { family: "Barlow"; styleName: "Medium"; pixelSize: Dims.l(11) }
                opacity: 0.9
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Dims.l(64); height: Dims.l(20); radius: height / 2
                color: root.comboEligible ? "#44f0ae0e" : "#55FFFFFF"
                Label {
                    anchors.centerIn: parent
                    text: root.comboEligible ? "COMBO STREAK" : "ENTER ORBIT"
                    font.pixelSize: Dims.l(8)
                    color: root.comboEligible ? "#f0c30e" : "#FFFFFF"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { calibBgFade.restart(); root.launchRequested(root.currentLevel) }
                }
            }

            ValueCycler {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: Dims.l(14)
                valueArray: {
                    var arr = []
                    for (var i = 1; i <= TouchdownStorage.highestUnlockedLevel; i++) arr.push("Level " + i)
                    return arr
                }
                currentValue: "Level " + root.currentLevel
                labelColor: root.comboEligible ? "#f0c30e" : "#FFFFFF"
                onValueChanged: root.levelSelected(parseInt(value.replace("Level ", "")))
            }
        }
    }

    // ── Calibration countdown
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        visible: root.calibrating
        opacity: 1.0
        NumberAnimation on opacity {
            id: calibBgFade
            running: false
            to: 0.0
            duration: root.calibrationSeconds * 1000
            easing.type: Easing.InOutCubic
        }
    }

    // "Hold still" hint — sibling so it ignores the fading rect's opacity.
    // Snaps away with visible: root.calibrating when calibration ends.
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: Dims.l(14)
        visible: root.calibrating
        text: "HOLD STILL"
        font { family: "Barlow"; styleName: "Medium"; pixelSize: Dims.l(6); letterSpacing: 2 }
        opacity: 0.7
    }

    // Countdown number — sibling of the fading rect, not a child, so opacity is independent
    Label {
        anchors.centerIn: parent
        visible: root.calibrating
        text: root.calibrationSeconds - root.calibrationCount
        font { family: "Xolonium"; styleName: "Bold"; pixelSize: Dims.l(22) }
        opacity: 0.9
    }
}
