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

// All properties are primitives — no object references cross the boundary.
// Set visible: playing on the instance in main.qml to gate all children at once.
Item {
    id: root

    property real thrustLower: 0.0
    property real thrustUpper: 0.0
    property real fuel: 1.0
    property real floorY: 1.0
    property real shipWorldY: 0.0
    property int  currentLevel: 1
    property real vy: 0.0
    property real shipAngle: 0.0
    property real lowerThrustForce: 70.0
    property real upperThrustForce: 15.0
    property real maxLandingSpeed: 120.0
    property real maxLandingAngleMax: 20.0

    // ── HUD bars — stacked top center
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Dims.l(6)
        spacing: Dims.l(1)

        // Thrust — lower engine fills right of pivot, upper fills left.
        // Pivot position reflects the force ratio so each side is to scale.
        Item {
            id: thrustBar
            width: Dims.l(28)
            height: Dims.l(2)
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real pivotX: width * root.upperThrustForce / (root.lowerThrustForce + root.upperThrustForce)

            Rectangle { anchors.fill: parent; radius: height / 2; color: "#33FFFFA0" }

            // Upper thrust — grows leftward from pivot
            Rectangle {
                x: thrustBar.pivotX - width
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(parent.height, thrustBar.pivotX * root.thrustUpper)
                radius: height / 2
                color: "#88CCFFFF"
                Behavior on width { SmoothedAnimation { velocity: Dims.l(60) } }
            }

            // Lower thrust — grows rightward from pivot
            Rectangle {
                x: thrustBar.pivotX
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(parent.height, (thrustBar.width - thrustBar.pivotX) * root.thrustLower)
                radius: height / 2
                color: "#FFFFA0"
                Behavior on width { SmoothedAnimation { velocity: Dims.l(120) } }
            }

            // Pivot marker
            Rectangle {
                x: thrustBar.pivotX - width / 2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: "#66FFFFA0"
            }
        }

        // Fuel — white → yellow → red
        Item {
            width: Dims.l(28); height: Dims.l(2)
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { anchors.fill: parent; radius: height / 2; color: "#33FFFFFF" }
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Math.max(height, parent.width * root.fuel)
                radius: height / 2
                color: root.fuel > 0.25 ? "#FFFFFF" : root.fuel > 0.10 ? "#FFDD00" : "#FF4400"
                Behavior on width { SmoothedAnimation { velocity: Dims.l(60) } }
            }
        }

        // Altitude — cyan, shrinks to zero at surface
        Item {
            width: Dims.l(28); height: Dims.l(2)
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { anchors.fill: parent; radius: height / 2; color: "#3300FFFF" }
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Math.max(height, parent.width * Math.min(1.0, Math.max(0, root.floorY - root.shipWorldY) / root.floorY))
                radius: height / 2; color: "#00FFFF"
                Behavior on width { SmoothedAnimation { velocity: Dims.l(40) } }
            }
        }
    }

    // Level — center bottom
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.l(2)
        text: "L" + root.currentLevel
        font { family: "Xolonium"; styleName: "Bold"; pixelSize: Dims.l(8) }
        opacity: 0.8
    }

    // ── Speed danger bar — right edge, fills upward, green → red at maxLandingSpeed
    Item {
        id: speedDangerBar
        anchors.right: parent.right
        anchors.rightMargin: Dims.l(3)
        anchors.top: parent.top
        anchors.topMargin: Dims.l(6)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.l(6)
        width: Dims.l(2)
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#22FFFFFF" }
        Rectangle {
            property real fraction: Math.min(1.0, Math.max(0, root.vy) / root.maxLandingSpeed)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(width, parent.height * fraction)
            radius: width / 2
            color: fraction > 0.75 ? "#FF4400" : fraction > 0.4 ? "#FFDD00" : "#AAFFAA"
            Behavior on height { SmoothedAnimation { velocity: Dims.l(200) } }
        }
    }

    // ── Tilt danger bar — left edge, split at centre, each half fills toward edge
    Item {
        id: tiltDangerBar
        anchors.left: parent.left
        anchors.leftMargin: Dims.l(3)
        anchors.top: parent.top
        anchors.topMargin: Dims.l(6)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.l(6)
        width: Dims.l(2)
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#22FFFFFF" }
        // Centre divider
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 2
            color: "#44FFFFFF"
        }
        // Right tilt — fills downward from centre
        Rectangle {
            property real fraction: Math.min(1.0, Math.max(0, root.shipAngle) / root.maxLandingAngleMax)
            anchors.top: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(width, (tiltDangerBar.height / 2) * fraction)
            radius: width / 2
            color: fraction > 0.75 ? "#FF4400" : fraction > 0.4 ? "#FFDD00" : "#AAFFAA"
            Behavior on height { SmoothedAnimation { velocity: Dims.l(200) } }
        }
        // Left tilt — fills upward from centre
        Rectangle {
            property real fraction: Math.min(1.0, Math.max(0, -root.shipAngle) / root.maxLandingAngleMax)
            anchors.bottom: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(width, (tiltDangerBar.height / 2) * fraction)
            radius: width / 2
            color: fraction > 0.75 ? "#FF4400" : fraction > 0.4 ? "#FFDD00" : "#AAFFAA"
            Behavior on height { SmoothedAnimation { velocity: Dims.l(200) } }
        }
    }
}
