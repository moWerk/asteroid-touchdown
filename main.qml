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
import QtSensors 5.15
import Nemo.KeepAlive 1.1
import Nemo.Ngf 1.0
import org.asteroid.controls 1.0
import org.asteroid.touchdown 1.0

Application {
    id: app
    anchors.fill: parent

    // ── Tuning block ─────────────────────────────────────────────────────────
    // All gameplay numbers live here. Nothing is hardcoded elsewhere.
    QtObject {
        id: physics

        // Gravity: world-units per second squared. Positive = downward.
        // At this value a free-falling ship takes ~22s to cross worldHeight.
        readonly property real gravity:              180.0

        // Lower thruster: maximum upward force in world-units/s².
        // Must exceed gravity to allow hovering. Ratio ~2.2 gives snappy
        // braking without feeling like a rocket.
        readonly property real lowerThrustForce:     400.0

        // Upper thrusters: gentler downward boost.
        // Active when user tilts watch toward themselves (Y accel negative).
        readonly property real upperThrustForce:     120.0

        // Fuel drain per second at full lower thrust (0.0–1.0 scale).
        // At this rate full fuel lasts ~30s of continuous lower thrust.
        readonly property real lowerFuelDrainRate:   0.033

        // Upper thrusters cost 10x less.
        readonly property real upperFuelDrainRate:   0.0033

        // Lower thruster cuts out below this fuel fraction.
        readonly property real lowerThrustFuelCutoff: 0.01

        // Accelerometer sensitivity. Multiply raw X delta to get tilt angle (degrees).
        readonly property real tiltSensitivity:      18.0

        // Smoothing factor for accelerometer (0=no smoothing, 1=frozen).
        readonly property real accelSmoothing:       0.75

        // Dead zone: raw Y accel delta below this = no thrust input registered.
        readonly property real thrustDeadZone:       0.08

        // Dual-flame zone: within this tilt fraction both upper flames light.
        // 0.10 = within ±10% of center both fire, beyond that only opposite side.
        readonly property real dualFlameZone:        0.10

        // Landing judgment
        readonly property real maxLandingSpeedBase:  60.0   // world-units/s at vy
        readonly property real maxLandingAngleMin:   5.0    // degrees at max speed
        readonly property real maxLandingAngleMax:   20.0   // degrees at near-zero vy
    }

    QtObject {
        id: viewport

        // Total width of generated world surface in world-units.
        // Ship can drift this far horizontally; surface spans this width.
        // 3× screen gives enough roaming while staying navigable.
        property real worldWidth:       Dims.l(100) * 3.0

        // Total height of world. Ship starts at y=0, surface bottom at worldHeight.
        property real worldHeight:      Dims.l(100) * 4.5

        // Width of world visible in the final locked-zoom approach phase.
        // 1.4× screen means ship at full size has ~20% margin each side.
        property real descentViewWidth: Dims.l(100) * 1.4

        // Below this world-space altitude above surface, zoom locks.
        property real lockAltitude:     Dims.l(100) * 0.9

        // Ship screen-space Y position as fraction from top (0=top, 1=bottom).
        // Kept here so ship appears in upper third during descent.
        readonly property real shipScreenFraction: 0.18
    }

    // ── Game state ────────────────────────────────────────────────────────────
    property bool calibrating:        false
    property int  calibrationSeconds: 3
    property int  calibrationCount:   0
    property bool playing:            false
    property bool landed:             false
    property bool crashed:            false
    property bool gameOver:           false
    property int  currentLevel:       1
    property int  elapsedMs:          0       // running timer, ms
    property bool selectingLevel:     true

    // ── Physics state ─────────────────────────────────────────────────────────
    property real shipWorldX:   viewport.worldWidth / 2   // start centered
    property real shipWorldY:   0.0                        // start at top
    property real vx:           0.0
    property real vy:           0.0
    property real shipAngle:    0.0                        // degrees, visual + physics tilt
    property real fuel:         1.0                        // 0.0–1.0
    property real thrustLower:  0.0                        // 0.0–1.0 analog
    property real thrustUpper:  0.0                        // 0.0–1.0 analog (downward)

    // ── Accelerometer calibration baseline ───────────────────────────────────
    property real baselineX:    0.0
    property real baselineY:    0.0
    property real smoothedX:    0.0
    property real smoothedY:    0.0

    // ── Derived viewport ──────────────────────────────────────────────────────
    // Altitude above surface bottom.
    property real altitude: viewport.worldHeight - shipWorldY

    // Current view width in world-units — lerps from worldWidth down to
    // descentViewWidth as altitude drops toward lockAltitude.
    property real currentViewWidth: {
        if (altitude <= viewport.lockAltitude)
            return viewport.descentViewWidth
        var t = Math.min(1.0, (viewport.worldHeight - viewport.lockAltitude - shipWorldY)
                              / (viewport.worldHeight - viewport.lockAltitude))
        return viewport.descentViewWidth + (viewport.worldWidth - viewport.descentViewWidth) * t
    }

    // Zoom scale: how many screen pixels per world-unit.
    property real zoomScale: root.width / currentViewWidth

    // Camera center X in world-units tracks ship X, clamped so we never
    // show outside the world boundary.
    property real cameraX: Math.max(currentViewWidth / 2,
                                    Math.min(viewport.worldWidth - currentViewWidth / 2,
                                             shipWorldX))

    // World → screen coordinate helpers (used by surface canvas and ship).
    function worldToScreenX(wx) {
        return (wx - cameraX) * zoomScale + root.width / 2
    }
    function worldToScreenY(wy) {
        // Ship is pinned to shipScreenFraction of screen height.
        // Everything else shifts relative to ship.
        var shipScreenY = root.height * viewport.shipScreenFraction
        return shipScreenY + (wy - shipWorldY) * zoomScale
    }

    // ── Keep display on while playing ─────────────────────────────────────────
    onPlayingChanged: DisplayBlanking.preventBlanking = playing
    Component.onCompleted: DisplayBlanking.preventBlanking = false

    // ── Accelerometer ─────────────────────────────────────────────────────────
    Accelerometer {
        id: accel
        active: calibrating || playing
        dataRate: 60
        onReadingChanged: {
            var ax = reading.x
            var ay = reading.y
            smoothedX = smoothedX * physics.accelSmoothing + ax * (1.0 - physics.accelSmoothing)
            smoothedY = smoothedY * physics.accelSmoothing + ay * (1.0 - physics.accelSmoothing)
        }
    }

    // ── Calibration countdown ─────────────────────────────────────────────────
    Timer {
        id: calibrationTimer
        interval: 1000
        repeat: true
        onTriggered: {
            calibrationCount++
            if (calibrationCount >= calibrationSeconds) {
                stop()
                // Lock baseline from current smoothed readings
                baselineX = smoothedX
                baselineY = smoothedY
                calibrating = false
                playing = true
                elapsedMs = 0
                gameTimer.start()
                elapsedTimer.start()
            }
        }
    }

    // ── Main physics tick — 60 fps ────────────────────────────────────────────
    Timer {
        id: gameTimer
        interval: 16
        repeat: true
        property real lastMs: 0
        onTriggered: {
            var now = Date.now()
            var dt = lastMs > 0 ? Math.min((now - lastMs) / 1000.0, 0.05) : 0.016
            lastMs = now

            // --- Read accelerometer deltas from baseline ---
            var dx = smoothedX - baselineX
            var dy = smoothedY - baselineY   // positive = watch tilted away (upper thrust)
                                              // negative = tilted toward user (lower thrust)

            // --- Ship angle from X tilt ---
            var targetAngle = dx * physics.tiltSensitivity
            shipAngle = shipAngle * 0.8 + targetAngle * 0.2

            // --- Thrust from Y tilt ---
            // Lower thrust: Y delta negative (tilt watch toward user = rocket fires down)
            var rawLower = Math.max(0.0, -dy - physics.thrustDeadZone) / (1.0 - physics.thrustDeadZone)
            rawLower = Math.min(1.0, rawLower)

            // Upper thrust: Y delta positive (tilt watch away = top thrusters fire)
            var rawUpper = Math.max(0.0, dy - physics.thrustDeadZone) / (1.0 - physics.thrustDeadZone)
            rawUpper = Math.min(1.0, rawUpper)

            // Apply fuel cutoffs
            thrustLower = (fuel > physics.lowerThrustFuelCutoff) ? rawLower : 0.0
            thrustUpper = rawUpper   // upper thrusters work until fuel hits 0

            // --- Fuel drain ---
            var fuelDrain = thrustLower * physics.lowerFuelDrainRate * dt
                          + thrustUpper * physics.upperFuelDrainRate * dt
            fuel = Math.max(0.0, fuel - fuelDrain)

            // --- Forces ---
            // Lower thrust opposes gravity, slight horizontal component from angle.
            var angleRad = shipAngle * Math.PI / 180.0
            var lowerForce = thrustLower * physics.lowerThrustForce
            var upperForce = thrustUpper * physics.upperThrustForce

            // Net vertical acceleration: gravity down, lower thrust up, upper thrust down
            var accelY = physics.gravity - lowerForce * Math.cos(angleRad) + upperForce
            // Horizontal: tilt of lower thruster deflects thrust sideways
            var accelX = lowerForce * Math.sin(angleRad)

            // --- Integrate velocity ---
            vx = vx + accelX * dt
            vy = vy + accelY * dt

            // --- Integrate position ---
            shipWorldX = Math.max(0, Math.min(viewport.worldWidth, shipWorldX + vx * dt))
            shipWorldY = shipWorldY + vy * dt

            // --- Clamp ship to world top ---
            if (shipWorldY < 0) {
                shipWorldY = 0
                if (vy < 0) vy = 0
            }

            // --- Bottom boundary: placeholder crash until surface exists ---
            if (shipWorldY >= viewport.worldHeight) {
                shipWorldY = viewport.worldHeight
                playing = false
                crashed = true
                gameOver = true
                gameTimer.stop()
                elapsedTimer.stop()
            }
        }
    }

    // ── Elapsed time counter ──────────────────────────────────────────────────
    Timer {
        id: elapsedTimer
        interval: 100
        repeat: true
        onTriggered: elapsedMs += 100
    }

    // ── Haptics ───────────────────────────────────────────────────────────────
    NonGraphicalFeedback {
        id: haptic
        event: "press"
    }

    // ── Root visual container ─────────────────────────────────────────────────
    Item {
        id: root
        anchors.fill: parent

        // Starfield — decorative only, scales with zoom
        Repeater {
            model: 20
            Rectangle {
                property real wx: Math.random() * viewport.worldWidth
                property real wy: Math.random() * viewport.worldHeight
                x: worldToScreenX(wx) - width / 2
                y: worldToScreenY(wy) - height / 2
                width:  Math.max(1, zoomScale * (1.5 + Math.random() * 1.5))
                height: width
                color: "#AAFFFFFF"
                radius: width
            }
        }

        // ── Placeholder ship ─────────────────────────────────────────────────
        // Diamond-shaped colored rect standing in for the SVG ship.
        // Replaced in chunk 3 with the actual SVG + flame items.
        Item {
            id: shipItem
            width:  Dims.l(8)
            height: Dims.l(8)
            x: worldToScreenX(shipWorldX) - width / 2
            y: worldToScreenY(shipWorldY) - height / 2
            rotation: shipAngle

            Rectangle {
                anchors.centerIn: parent
                width:  parent.width * 0.72
                height: parent.height * 0.72
                rotation: 45
                color: "transparent"
                border.color: "#FFFFFF"
                border.width: 1.5

                // Lower thruster flame placeholder — white bar below center
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    width:  parent.width * 0.3
                    height: Dims.l(3) * thrustLower
                    color: "#FFFFA0"
                    opacity: thrustLower
                    Behavior on height { SmoothedAnimation { velocity: Dims.l(20) } }
                }
            }
        }

        // ── HUD — fixed screen-space, not affected by zoom ────────────────────

        // Fuel bar — horizontal pill, top center
        Item {
            id: fuelBarContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Dims.l(5)
            width:  Dims.l(40)
            height: Dims.l(3.5)

            // Track
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#33FFFFFF"
                border.color: "#55FFFFFF"
                border.width: 1
            }
            // Fill
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: Math.max(height, (parent.width - 2) * fuel)
                radius: height / 2
                color: fuel > 0.25 ? "#FFFFFF"
                     : fuel > 0.10 ? "#FFDD00"
                     :               "#FF4400"
                Behavior on width { SmoothedAnimation { velocity: Dims.l(60) } }
            }
            // Label
            Label {
                anchors.right: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Dims.l(1.5)
                text: "FUEL"
                font.pixelSize: Dims.l(4)
                opacity: 0.6
            }
        }

        // Thrust bar — vertical pill, right edge
        Item {
            id: thrustBarContainer
            anchors.right: parent.right
            anchors.rightMargin: Dims.l(3)
            anchors.verticalCenter: parent.verticalCenter
            width:  Dims.l(3.5)
            height: Dims.l(30)

            // Track
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#33FFFFFF"
                border.color: "#55FFFFFF"
                border.width: 1
            }
            // Fill — rises from bottom
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: Math.max(width, (parent.height - 2) * thrustLower)
                radius: width / 2
                color: "#FFFFA0"
                opacity: 0.5 + thrustLower * 0.5
                Behavior on height { SmoothedAnimation { velocity: Dims.l(80) } }
            }
        }

        // Altimeter — top left
        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Dims.l(4)
            anchors.topMargin: Dims.l(5)
            text: Math.round(altitude) + "m"
            font.pixelSize: Dims.l(5)
            opacity: 0.7
        }

        // Level indicator — top right
        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Dims.l(4)
            anchors.topMargin: Dims.l(5)
            text: "L" + currentLevel
            font.pixelSize: Dims.l(5)
            opacity: 0.7
        }

        // Timer — below altimeter
        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Dims.l(4)
            anchors.topMargin: Dims.l(12)
            text: {
                var s = Math.floor(elapsedMs / 1000)
                var m = Math.floor(s / 60)
                var ds = Math.floor((elapsedMs % 1000) / 100)
                return (m > 0 ? m + ":" : "") + (s % 60 < 10 && m > 0 ? "0" : "") + (s % 60) + "." + ds
            }
            font.pixelSize: Dims.l(4.5)
            opacity: 0.7
        }

        // ── Calibration overlay ───────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            visible: calibrating || selectingLevel
            opacity: calibrating || selectingLevel ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Column {
                anchors.centerIn: parent
                spacing: Dims.l(4)

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "TOUCHDOWN"
                    font.pixelSize: Dims.l(7)
                    opacity: 0.9
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: selectingLevel
                    text: "Level " + currentLevel
                    font.pixelSize: Dims.l(9)
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: selectingLevel && TouchdownStorage.bestTime(currentLevel) > 0
                    text: "Best: " + formatTime(TouchdownStorage.bestTime(currentLevel))
                    font.pixelSize: Dims.l(5)
                    opacity: 0.7
                }

                // Level selector row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Dims.l(3)
                    visible: selectingLevel

                    // Decrease level button
                    Rectangle {
                        width: Dims.l(12); height: Dims.l(12)
                        radius: height / 2
                        color: currentLevel > 1 ? "#44FFFFFF" : "#22FFFFFF"
                        Label {
                            anchors.centerIn: parent
                            text: "−"
                            font.pixelSize: Dims.l(7)
                            opacity: currentLevel > 1 ? 1.0 : 0.3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (currentLevel > 1) currentLevel--
                        }
                    }

                    // Increase level button (only up to highest unlocked)
                    Rectangle {
                        width: Dims.l(12); height: Dims.l(12)
                        radius: height / 2
                        color: currentLevel < TouchdownStorage.highestUnlockedLevel ? "#44FFFFFF" : "#22FFFFFF"
                        Label {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: Dims.l(7)
                            opacity: currentLevel < TouchdownStorage.highestUnlockedLevel ? 1.0 : 0.3
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (currentLevel < TouchdownStorage.highestUnlockedLevel) currentLevel++
                        }
                    }
                }

                // START button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: selectingLevel
                    width: Dims.l(36); height: Dims.l(14)
                    radius: height / 2
                    color: "#55FFFFFF"

                    Label {
                        anchors.centerIn: parent
                        text: "HOLD STILL"
                        font.pixelSize: Dims.l(5.5)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectingLevel = false
                            calibrating = true
                            calibrationCount = 0
                            smoothedX = 0
                            smoothedY = 0
                            calibrationTimer.start()
                        }
                    }
                }
            }
        }

        // Calibration countdown numbers
        Label {
            anchors.centerIn: parent
            visible: calibrating
            text: calibrationSeconds - calibrationCount
            font.pixelSize: Dims.l(20)
            opacity: 0.9
        }

        // ── Game over overlay ─────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: "#CC000000"
            visible: gameOver
            opacity: gameOver ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }

            Column {
                anchors.centerIn: parent
                spacing: Dims.l(3)

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: crashed ? "CRASHED" : "TOUCHDOWN"
                    font.pixelSize: Dims.l(8)
                    color: crashed ? "#FF4400" : "#AAFFAA"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: landed
                    text: formatTime(elapsedMs)
                    font.pixelSize: Dims.l(10)
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: landed && TouchdownStorage.bestTime(currentLevel) > 0
                    text: "Best: " + formatTime(TouchdownStorage.bestTime(currentLevel))
                    font.pixelSize: Dims.l(5)
                    opacity: 0.7
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: landed && currentLevel < TouchdownStorage.highestUnlockedLevel
                    text: "Level " + (currentLevel + 1) + " unlocked!"
                    font.pixelSize: Dims.l(5)
                    color: "#AAFFAA"
                    opacity: 0.9
                }

                // Retry same level
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Dims.l(44); height: Dims.l(13)
                    radius: height / 2
                    color: "#55FFFFFF"
                    Label {
                        anchors.centerIn: parent
                        text: "TRY LEVEL " + currentLevel
                        font.pixelSize: Dims.l(5)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: startLevel(currentLevel)
                    }
                }

                // Return to level 1
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: currentLevel > 1
                    width: Dims.l(44); height: Dims.l(13)
                    radius: height / 2
                    color: "#33FFFFFF"
                    Label {
                        anchors.centerIn: parent
                        text: "LEVEL 1"
                        font.pixelSize: Dims.l(5)
                        opacity: 0.8
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: startLevel(1)
                    }
                }
            }
        }
    }

    // ── Game flow functions ───────────────────────────────────────────────────

    function startLevel(level) {
        currentLevel = level

        // Reset physics
        shipWorldX = viewport.worldWidth / 2
        shipWorldY = 0.0
        vx = 0.0
        vy = 0.0
        shipAngle = 0.0
        fuel = 1.0
        thrustLower = 0.0
        thrustUpper = 0.0
        elapsedMs = 0

        // Reset state
        playing = false
        landed = false
        crashed = false
        gameOver = false
        gameTimer.stop()
        gameTimer.lastMs = 0
        elapsedTimer.stop()

        // Begin calibration
        selectingLevel = false
        calibrating = true
        calibrationCount = 0
        smoothedX = 0
        smoothedY = 0
        calibrationTimer.start()
    }

    function formatTime(ms) {
        var s  = Math.floor(ms / 1000)
        var m  = Math.floor(s / 60)
        var ds = Math.floor((ms % 1000) / 100)
        return (m > 0 ? m + ":" : "") + (m > 0 && (s % 60) < 10 ? "0" : "") + (s % 60) + "." + ds + "s"
    }

    Component.onCompleted: {
        currentLevel = 1
        selectingLevel = true
    }
}
