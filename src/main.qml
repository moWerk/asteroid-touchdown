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

import QtQuick 2.15
import QtSensors 5.15
import QtQuick.Shapes 1.15
import Nemo.KeepAlive 1.1
import Nemo.Ngf 1.0
import org.asteroid.controls 1.0
import org.asteroid.touchdown 1.0

Application {
    id: app
    anchors.fill: parent

    // ── Physics tuning
    QtObject {
        id: physics
        // World-space downward acceleration in units/s². Raise to make descents faster and harder to arrest.
        readonly property real gravity: 30.0
        // Main engine force in units/s². Must comfortably exceed gravity to allow ascent (here ~2.3×).
        // This is the dominant force — most other values are tuned relative to it.
        readonly property real lowerThrustForce: 70.0
        // Retro/top thruster force. Intentionally weaker — for braking and fine altitude control, not ascent.
        readonly property real upperThrustForce: 15.0
        // Fraction of full fuel consumed per second at full lower thrust. 1.0 / 0.07 ≈ 14 s of continuous burn.
        readonly property real lowerFuelDrainRate: 0.07
        // Upper thruster is 10× more fuel-efficient — penalises overuse of main engine less than braking.
        readonly property real upperFuelDrainRate: 0.007
        // Lower engine cuts off below this fuel fraction, preserving a reserve for upper and lateral control.
        readonly property real lowerThrustFuelCutoff: 0.05
        // Ship tilt in degrees per g of accelerometer X delta. Higher = snappier lateral response, harder to stabilise.
        readonly property real tiltSensitivity: 12.0
        // Low-pass filter weight for accelerometer readings (0 = raw, 1 = frozen). 0.75 adds ~4 frame lag, filters hand tremor.
        // Tip: calibrate at your natural playing angle — steep holds compress the Y range and reduce thrust headroom.
        readonly property real accelSmoothing: 0.75
        // g-force below which thrust is ignored. Prevents unintended firing when holding the watch at the calibration pose.
        readonly property real thrustDeadZone: 0.08
        // Maximum vertical impact speed in units/s for a survivable landing.
        readonly property real maxLandingSpeed: 120.0
        // Maximum ship tilt in degrees at contact for a survivable landing. Matches real lander tolerances (~15–20°).
        readonly property real maxLandingAngleMax: 20.0
        // Fraction of lowerThrustForce applied as lateral when upper thruster fires while the ship is tilted.
        // Small by design — lateral nudge, not a sidestep.
        readonly property real upperLateralFraction: 0.04
        // Constant lateral acceleration in units/s² per radian of tilt. Active whenever the ship is angled,
        // independent of thrust. Keeps the ship drifting in the direction it points.
        readonly property real tiltLateralForce: 4.0
    }

    // ── Viewport tuning
    QtObject {
        id: viewport
        // Total scrollable world width in world-units. Ship wraps carousel-style at both edges.
        property real worldWidth: Dims.l(100) * 10.0
        // Total play-space height from spawn (Y = 0) to the floor plane.
        property real worldHeight: Dims.l(100) * 3.5
        // Ship is always pinned at this fraction from the top of the screen (0 = top, 1 = bottom).
        // Lower values give more sky above the ship; higher values expose more ground.
        property real shipVerticalFraction: 0.22
        // Floor is always pinned this many pixels above the screen bottom edge.
        // Keeps the surface visible and clear of round-screen clipping.
        property real surfaceBottomMargin: Dims.l(20)
        // Zoom locks when fewer than this many world-units remain between ship and floor.
        // Prevents the camera from zooming to infinity on final approach.
        property real minViewBand: Dims.l(100) * 0.8
    }

    // ── World generation tuning
    QtObject {
        id: world
        // Y coordinate of the flat ground plane. Rocks extend above (visible) and below (hidden by floor fill).
        readonly property real floorY: viewport.worldHeight * 0.80
        // Target rock count per level. Actual count may fall short if the placement loop
        // exhausts its attempt budget — increase rockCount * 8 attempts if that happens.
        property int rockCount: 55
        // Median rock radius in world-units. Rocks range from 0.5× (pebbles) to 8× (boulders) via size tiers.
        property real rockBaseRadius: viewport.worldWidth * 0.008
        // Vertex perturbation factor (0 = perfect polygon, 1 = maximally jagged). Increases with level.
        property real rockRoughness: 0.80
        // Landing pad width at level 1. Shrinks each level down to a minimum of 2 % of world width.
        property real targetPadWidth: viewport.worldWidth * 0.05
        // World-unit distance from ship centre to the visual gear tip in the SVG at close zoom.
        // Retune this if you resize the ship art — gear contact fires when this depth crosses the surface.
        readonly property real landingGearOffset: 37.0

        property var rocks: []
        property var pads: []
        property real targetPadXStart: 0
        property real targetPadXEnd: 0
    }

    // ── Game state
    property bool   calibrating:        false
    property int    calibrationSeconds: 3
    property int    calibrationCount:   0
    property bool   playing:            false
    property bool   landed:             false
    property bool   crashed:            false
    property bool   gameOver:           false
    property int    currentLevel:       1
    property int    elapsedMs:          0
    property bool   selectingLevel:     true
    property bool   playerDying:        false
    property real   deathProgress:      0.0
    property string crashSide:          "left"
    property string missionMessage: ""
    property bool   showingComms:   false
    property real   commsOpacity:   0.0
    
    CommsMessages { id: comms }

    // ── Physics state
    property real shipWorldX:  viewport.worldWidth / 2
    property real shipWorldY:  0.0
    property real vx:          0.0
    property real vy:          0.0
    property real shipAngle:   0.0
    property real fuel:        1.0
    property real thrustLower: 0.0
    property real thrustUpper: 0.0
    property real lateralUpper: 0.0
    // Computed each physics tick — magnitude of vertical acceleration in multiples of in-game gravity.
    property real gForce: 0.0

    // ── Accelerometer baseline
    property real baselineX: 0.0
    property real baselineY: 0.0
    property real smoothedX: 0.0
    property real smoothedY: 0.0

    // ── Derived viewport
    // Both anchors are fixed screen positions — floor never drifts, ship never
    // drifts. Zoom is derived purely from shipWorldY, not from altitude or the
    // heightmap, so lateral flight over uneven terrain causes zero zoom bumps.
    property real shipScreenY:    app.height * viewport.shipVerticalFraction
    property real surfaceScreenY: app.height - viewport.surfaceBottomMargin
    property real zoomScale: (surfaceScreenY - shipScreenY) / Math.max(viewport.minViewBand, world.floorY - shipWorldY)

    // currentViewHeight lerps from startViewHeight down to lockViewHeight as
    // altitude drops from worldHeight to lockAltitude. startViewHeight > worldHeight
    // guarantees a visible zoom-out at game start.

    property real currentViewHeight: {
        if (landed) return viewport.lockViewHeight
        if (altitude <= viewport.lockAltitude) return viewport.lockViewHeight
        var t = Math.max(0, Math.min(1.0,
            (altitude - viewport.lockAltitude) /
            (viewport.worldHeight - viewport.lockAltitude)))
        return viewport.lockViewHeight + (viewport.startViewHeight - viewport.lockViewHeight) * t
    }

    property real shipScreenFraction: 0.20 + Math.min(1.0, shipWorldY / world.floorY) * 0.20

    property real cameraX:   shipWorldX

    // World → screen helpers. worldToScreenX handles carousel wrapping.
    function worldToScreenX(wx) {
        var dx = wx - shipWorldX
        var ww = viewport.worldWidth
        dx = dx - Math.floor((dx + ww / 2) / ww) * ww
        return app.width / 2 + dx * zoomScale
    }

    function worldToScreenY(wy) {
        return surfaceScreenY + (wy - world.floorY) * zoomScale
    }

    // ── World generation

    // Returns the minimum world-Y (highest surface) of rock polygon at wx.
    // Returns -1 if wx is outside the rock's X bounding box.
    function rockTopAtX(rock, wx) {
        if (wx < rock.minX || wx > rock.maxX) return -1
        var verts = rock.vertices
        var n     = verts.length
        var minY  = world.floorY   // only care about above-floor surface
        var found = false
        for (var i = 0; i < n; i++) {
            var v0 = verts[i]
            var v1 = verts[(i + 1) % n]
            var x0 = v0.x; var x1 = v1.x
            if ((x0 <= wx && wx <= x1) || (x1 <= wx && wx <= x0)) {
                if (Math.abs(x1 - x0) < 0.001) continue
                var t  = (wx - x0) / (x1 - x0)
                var y  = v0.y + t * (v1.y - v0.y)
                if (y < minY) { minY = y; found = true }
            }
        }
        return found ? minY : -1
    }

    // Build rocks and pads for the given level, then rasterize the heightmap.
    function generateWorld(level) {
        var ww  = viewport.worldWidth
        var fy  = world.floorY
        var baseR = world.rockBaseRadius

        // Level scaling
        var padWidth    = Math.max(ww * 0.02,
                                   world.targetPadWidth - (level - 1) * ww * 0.006)
        var roughness   = Math.min(0.92, world.rockRoughness + (level - 1) * 0.06)
        var rockCnt     = world.rockCount + (level - 1) * 5

        // ── Target pad 
        // Level 1: dead center. Each level pad moves one pad-width further from
        // center, randomly left or right. Clamped to keep pad within world bounds.
        var centerX    = ww / 2 - padWidth / 2
        var direction  = (Math.random() < 0.5 ? -1 : 1)
        var offsetSteps = level - 1
        var padX       = centerX + direction * offsetSteps * padWidth * 1.5
        padX = Math.max(ww * 0.05, Math.min(ww * 0.95 - padWidth, padX))
        world.targetPadXStart = padX
        world.targetPadXEnd   = padX + padWidth
        world.pads = [{ wx: padX, wy: fy, width: padWidth, isTarget: true }]
        
        // ── Rocks
        // Placed after pad assignment. Each rock is an irregular polygon centered
        // at floorY. Vertices extend above (wy < floorY) and below (underground).
        // The floor fill Rectangle hides the underground portion visually.
        var newRocks = []
        var attempts = 0
        var placed   = 0
        var padClearance = padWidth * 1.2 + baseR * 2

        while (placed < rockCnt && attempts < rockCnt * 8) {
            attempts++
            var cx       = Math.random() * ww
            var rockRoll = placed % 10
            var r = rockRoll === 9 ? baseR * (5 + Math.random() * 3) : rockRoll === 4 ? baseR * (2 + Math.random() * 2) : baseR * (0.5 + Math.random() * 1.0)

            if (cx > padX - r && cx < padX + padWidth + r) continue

            var tooClose = false
            for (var ri = 0; ri < newRocks.length; ri++) {
                if (Math.abs(newRocks[ri].cx - cx) < r + newRocks[ri].r * 0.7) {
                    tooClose = true
                    break
                }
            }
            if (tooClose) continue

            var rockRoughness = rockRoll === 9 ? 0.95 : rockRoll === 4 ? 0.75 : roughness
            var nVert         = rockRoll === 9 ? 7 + Math.floor(Math.random() * 4) : 5 + Math.floor(Math.random() * 4)
            var cy            = fy
            var verts         = []

            for (var j = 0; j < nVert; j++) {
                var angle   = (j / nVert) * 2 * Math.PI - Math.PI / 2
                var perturb = 1.0 - rockRoughness * 0.5 + Math.random() * rockRoughness
                var rv      = r * perturb
                verts.push({ x: cx + Math.cos(angle) * rv, y: cy + Math.sin(angle) * rv * 0.7 })
            }

            var minX = verts[0].x
            var maxX = verts[0].x
            var minY = verts[0].y
            for (var k = 1; k < verts.length; k++) {
                if (verts[k].x < minX) minX = verts[k].x
                if (verts[k].x > maxX) maxX = verts[k].x
                if (verts[k].y < minY) minY = verts[k].y
            }

            newRocks.push({ cx: cx, cy: cy, r: r, vertices: verts, minX: minX, maxX: maxX, minY: minY })
            placed++
        }

        world.rocks = newRocks
    }

    // ── Keep display on only while game is actively running
    // Explicitly excludes selectingLevel and gameOver so display can blank on
    // menus and the result screen — prevents battery drain on forgotten watches.
    property bool keepAwake: playing || landed || playerDying
    onKeepAwakeChanged: DisplayBlanking.preventBlanking = keepAwake

    // ── Accelerometer
    Accelerometer {
        id: accel
        active:   calibrating || playing
        dataRate: 60
        onReadingChanged: {
            var ax = -reading.x; var ay = reading.y
            smoothedX = smoothedX * physics.accelSmoothing + ax * (1 - physics.accelSmoothing)
            smoothedY = smoothedY * physics.accelSmoothing + ay * (1 - physics.accelSmoothing)
        }
    }

    // ── Calibration countdown
    Timer {
        id: calibrationTimer
        interval: 1000
        repeat:   true
        onTriggered: {
            calibrationCount++
            if (calibrationCount >= calibrationSeconds) {
                stop()
                baselineX = smoothedX
                baselineY = smoothedY
                calibrating      = false
                playing          = true
                elapsedMs        = 0
                gameTimer.lastMs = 0
                gameTimer.start()
                elapsedTimer.start()
            }
        }
    }

    // ── Physics tick — 60 fps
    Timer {
        id: gameTimer
        interval: 16
        repeat:   true
        property real lastMs: 0
        property real lastVy: 0
        onTriggered: {
            var now = Date.now()
            var dt  = lastMs > 0 ? Math.min((now - lastMs) / 1000.0, 0.05) : 0.016
            lastMs  = now

            var dx = smoothedX - baselineX
            var dy = baselineY - smoothedY

            var targetAngle = dx * physics.tiltSensitivity
            shipAngle = shipAngle * 0.8 + targetAngle * 0.2

            var rawLower = Math.max(0.0,  dy - physics.thrustDeadZone) / (1 - physics.thrustDeadZone)
            rawLower = Math.min(1.0, rawLower)
            var rawUpper = Math.max(0.0, -dy - physics.thrustDeadZone) / (1 - physics.thrustDeadZone)
            rawUpper = Math.min(1.0, rawUpper)

            thrustLower = (fuel > physics.lowerThrustFuelCutoff) ? rawLower : 0.0
            thrustUpper = rawUpper

            fuel = Math.max(0.0, fuel - thrustLower * physics.lowerFuelDrainRate * dt
                                      - thrustUpper * physics.upperFuelDrainRate * dt)

            var angleRad   = shipAngle * Math.PI / 180.0
            var lowerForce = thrustLower * physics.lowerThrustForce
            var upperForce = thrustUpper * physics.upperThrustForce
            var lateralUpper = thrustUpper * physics.lowerThrustForce * physics.upperLateralFraction * Math.sin(angleRad)
            app.lateralUpper = Math.abs(lateralUpper) > 0.001 ? Math.sign(lateralUpper) : 0
            var tiltLateral = Math.sin(angleRad) * physics.tiltLateralForce
            vx = vx + (lowerForce * Math.sin(angleRad) + lateralUpper + tiltLateral) * dt
            vy = vy + (physics.gravity - lowerForce * Math.cos(angleRad) + upperForce) * dt
            gForce = Math.abs(vy - gameTimer.lastVy) / dt / physics.gravity
            gameTimer.lastVy = vy

            // Carousel X wrap
            var newX = shipWorldX + vx * dt
            if (newX < 0)                    newX += viewport.worldWidth
            if (newX >= viewport.worldWidth) newX -= viewport.worldWidth
            shipWorldX = newX

            shipWorldY = shipWorldY + vy * dt
            if (shipWorldY < 0) { shipWorldY = 0; if (vy < 0) vy = 0 }

            // ── Surface contact
            if (world.rocks.length > 0) {
                var gearTipY = shipWorldY + world.landingGearOffset
                var surfY = world.floorY
                for (var ri = 0; ri < world.rocks.length; ri++) {
                    var top = rockTopAtX(world.rocks[ri], shipWorldX)
                    if (top >= 0 && top < surfY) surfY = top
                }
                if (gearTipY >= surfY) {
                    shipWorldY = surfY - world.landingGearOffset
                    var contactVy    = vy
                    var contactAngle = Math.abs(shipAngle)
                    gameTimer.stop()
                    elapsedTimer.stop()
                    playing = false
                    var speedOk = contactVy <= physics.maxLandingSpeed
                    var angleOk = contactAngle <= physics.maxLandingAngleMax
                    if (speedOk && angleOk) {
                        landed = true
                        TouchdownStorage.setBestTime(currentLevel, elapsedMs)
                        if (shipWorldX >= world.targetPadXStart - 20 && shipWorldX <= world.targetPadXEnd + 20) {
                            TouchdownStorage.highestUnlockedLevel = currentLevel + 1
                        }
                        landingAnimation.start()
                    } else {
                        crashed       = true
                        crashSide     = vx >= 0 ? "right" : "left"
                        playerDying   = true
                        deathProgress = 0.0
                        haptic.event  = "notif_strong"
                        haptic.play()
                        crashAnimation.start()
                        deathAnim.start()
                    }
                }
            }
        }
    }

    // ── Elapsed timer
    Timer {
        id: elapsedTimer
        interval: 100
        repeat:   true
        onTriggered: elapsedMs += 100
    }

    // ── Landing: tilt ship to upright then show game over
    SequentialAnimation {
        id: landingAnimation
        NumberAnimation { target: app; property: "shipAngle"; to: 0; duration: 500; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 1 }
        ScriptAction    { script: showComms() }
    }

    // ── Crash: tilt ship 45° to broken side
    NumberAnimation {
        id: crashAnimation
        target: app; property: "shipAngle"
        to: crashSide === "right" ? 45 : -45
        duration: 300; easing.type: Easing.OutCubic
    }

    // ── Death shader drive
    NumberAnimation {
        id: deathAnim
        target: app; property: "deathProgress"
        from: 0; to: 1; duration: 1000; easing.type: Easing.InCubic
        onStopped: { playerDying = false; showComms() }
    }

    // ── Haptics
    NonGraphicalFeedback { id: haptic; event: "press" }

    SequentialAnimation {
        id: commsSequence
        NumberAnimation { target: app; property: "commsOpacity"; to: 1.0; duration: 400 }
        PauseAnimation  { duration: 3000 }
        NumberAnimation { target: app; property: "commsOpacity"; to: 0.0; duration: 400 }
        ScriptAction    { script: { showingComms = false; gameOver = true } }
    }

    function showComms() {
        var arr
        if (landed) {
            var onPad = (shipWorldX >= world.targetPadXStart - 20 && shipWorldX <= world.targetPadXEnd + 20)
            arr = onPad ? comms.pad : comms.win
        } else {
            arr = comms.lose
        }
        missionMessage = arr[Math.floor(Math.random() * arr.length)]
        showingComms   = true
        commsOpacity   = 0.0
        commsSequence.start()
    }

    // ── Visual root
    Item {
        id: root
        anchors.fill: parent

        // Black space
        Rectangle { anchors.fill: parent; color: "#000000" }

        // ── Starfield — world-space, scales with zoom
        Repeater {
            model: 22
            delegate: Rectangle {
                property real wx: (index * 137.508 * viewport.worldWidth)  % viewport.worldWidth
                property real wy: (index * 97.333  * viewport.worldHeight) % viewport.worldHeight
                x: worldToScreenX(wx) - width / 2
                y: worldToScreenY(wy) - height / 2
                width:  Math.max(1, zoomScale * (1.0 + (index % 3) * 0.8))
                height: width
                color:  "#AAFFFFFF"
                radius: width / 2
            }
        }

        // ── Floor fill — dark rock base, extends from floorY to screen bottom ─
        // Plain Rectangle, no PathPolyline, no stray lines possible.
        Rectangle {
            x:      0
            y:      worldToScreenY(world.floorY)
            width:  app.width
            height: Math.max(0, app.height - worldToScreenY(world.floorY))
            color:  "#1A1A1A"
        }

        // ── Rocks — one Shape per rock, each fully self-contained
        // No world-spanning polyline = zero stray lines by construction.
        Repeater {
            model: world.rocks.length
            delegate: Shape {
                property int rockIndex: index   // explicit capture for nested binding scope
                anchors.fill: parent
                ShapePath {
                    fillColor:   "#2A2A2A"
                    strokeColor: "#CCFFFFFF"
                    strokeWidth: Math.max(1.5, zoomScale * 2.4)
                    capStyle:    ShapePath.RoundCap
                    joinStyle:   ShapePath.RoundJoin
                    PathPolyline {
                        path: {
                            if (rockIndex >= world.rocks.length) return []
                                var rock  = world.rocks[rockIndex]
                                var verts = rock.vertices
                                // Wrap center once — avoids per-vertex seam stretch
                                var scx = worldToScreenX(rock.cx)
                                var scy = worldToScreenY(rock.cy)
                                var pts = []
                                for (var i = 0; i < verts.length; i++)
                                    pts.push(Qt.point(
                                        scx + (verts[i].x - rock.cx) * zoomScale,
                                                      scy + (verts[i].y - rock.cy) * zoomScale))
                                    pts.push(Qt.point(
                                        scx + (verts[0].x - rock.cx) * zoomScale,
                                                      scy + (verts[0].y - rock.cy) * zoomScale))
                                    return pts
                        }
                    }
                }
            }
        }

        // ── Target pad highlight
        // Only the top edge — the floor fill handles the body below.
        Shape {
            anchors.fill: parent
            visible: world.pads.length > 0
            ShapePath {
                fillColor:   "transparent"
                strokeColor: "#FFFFA0"
                strokeWidth: Math.max(2.5, zoomScale * 4.5)
                capStyle:    ShapePath.RoundCap
                PathPolyline {
                    path: {
                        if (world.pads.length === 0) return []
                        var sx = worldToScreenX(world.targetPadXStart)
                        var ex = worldToScreenX(world.targetPadXEnd)
                        // Cull when pad is entirely off-screen
                        if (ex < -app.width || sx > app.width * 2) return []
                        var sy = worldToScreenY(world.floorY)
                        return [Qt.point(sx, sy), Qt.point(ex, sy)]
                    }
                }
            }
        }

        // ── Ship
        Item {
            id: shipItem
            width:  80 * zoomScale
            height: 80 * zoomScale
            x: worldToScreenX(shipWorldX) - width / 2
            y: worldToScreenY(shipWorldY) - height / 2
            rotation: shipAngle
            visible:  playing || landed || (crashed && !playerDying)

            Image {
                anchors.centerIn: parent
                width:  parent.width
                height: parent.height
                source: crashed
                        ? (crashSide === "left" ? "asteroid-touchdown-ship-right-gear.svg"
                                                : "asteroid-touchdown-ship-left-gear.svg")
                        : "asteroid-touchdown-ship.svg"
                smooth: true
            }

            // Lower thruster flame
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top:              parent.verticalCenter
                anchors.topMargin:        parent.width * 0.4
                width:  parent.width * 0.3
                height: shipItem.height * 1.6 * Math.max(0.05, thrustLower)
                source: "asteroid-touchdown-thruster.svg"
                smooth: true
                opacity: Math.max(0.05, thrustLower)
                Behavior on height { SmoothedAnimation { velocity: shipItem.height * 6 } }
            }

            // Upper-left thruster
            Image {
                id: thrusterUpperLeft
                anchors.horizontalCenter:       parent.horizontalCenter
                anchors.horizontalCenterOffset: -shipItem.height * 0.22
                anchors.verticalCenter:         parent.verticalCenter
                anchors.verticalCenterOffset:   -shipItem.height * 0.02
                width:  parent.width * 0.2
                height: shipItem.height * 0.5 * Math.max(0.05, thrustUpper)
                source: "asteroid-touchdown-thruster.svg"
                smooth: true
                mirror: true
                rotation: 135
                transformOrigin: Item.Top
                opacity: Math.max(thrustUpper * (Math.abs(shipAngle) < 5 ? 1.0 : shipAngle > 0 ? 1.0 : 0.4), Math.min(1.0, Math.max(0.0, shipAngle / 30.0)))
                Behavior on height { SmoothedAnimation { velocity: shipItem.height * 3 } }
            }

            // Upper-right thruster
            Image {
                id: thrusterUpperRight
                anchors.horizontalCenter:       parent.horizontalCenter
                anchors.horizontalCenterOffset: shipItem.height * 0.22
                anchors.verticalCenter:         parent.verticalCenter
                anchors.verticalCenterOffset:   -shipItem.height * 0.02
                width:  parent.width * 0.2
                height: shipItem.height * 0.5 * Math.max(0.05, thrustUpper)
                source: "asteroid-touchdown-thruster.svg"
                smooth: true
                rotation: -135
                transformOrigin: Item.Top
                opacity: Math.max(thrustUpper * (Math.abs(shipAngle) < 5 ? 1.0 : shipAngle < 0 ? 1.0 : 0.4), Math.min(1.0, Math.max(0.0, -shipAngle / 30.0)))
                Behavior on height { SmoothedAnimation { velocity: Dims.l(15) } }
            }          
        }

        // G-force readout — above altitude label, same horizontal anchor
        Label {
            id: gForceLabel
            anchors.horizontalCenter: shipItem.horizontalCenter
            anchors.bottom: altitudeLabel.top
            anchors.bottomMargin: Dims.l(1)
            text: gForce.toFixed(1) + "g"
            font.pixelSize: Dims.l(5)
            font.family: "Noto Sans"
            font.styleName: "Condensed Light"
            opacity: 0.9
            visible: playing
        }

        // Altitude readout
        Label {
            id: altitudeLabel
            anchors.horizontalCenter: shipItem.horizontalCenter
            anchors.bottom: shipItem.top
            anchors.bottomMargin: Dims.l(3)
            text: Math.round(Math.max(0, world.floorY - shipWorldY)) + "m"
            font.pixelSize: Dims.l(5)
            font.family: "Noto Sans"
            font.styleName: "Condensed Light"
            opacity: 0.9
            visible: playing
        }
        
        // ── Speed danger bar — right edge, fills upward, green → red at maxLandingSpeed
        Item {
            anchors.right: parent.right
            anchors.rightMargin: Dims.l(3)
            anchors.top: parent.top
            anchors.topMargin: Dims.l(6)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.l(6)
            width: Dims.l(2)
            visible: playing
            Rectangle { anchors.fill: parent; radius: width / 2; color: "#22FFFFFF" }
            Rectangle {
                property real fraction: Math.min(1.0, Math.max(0, vy) / physics.maxLandingSpeed)
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
            id: tiltBar
            anchors.left: parent.left
            anchors.leftMargin: Dims.l(3)
            anchors.top: parent.top
            anchors.topMargin: Dims.l(6)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.l(6)
            width: Dims.l(2)
            visible: playing
            Rectangle { anchors.fill: parent; radius: width / 2; color: "#22FFFFFF" }
            // Centre divider
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 2
                color: "#44FFFFFF"
            }
            // Right tilt — fills downward from centre (positive shipAngle)
            Rectangle {
                property real fraction: Math.min(1.0, Math.max(0, shipAngle) / physics.maxLandingAngleMax)
                anchors.top: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: Math.max(width, (tiltBar.height / 2) * fraction)
                radius: width / 2
                color: fraction > 0.75 ? "#FF4400" : fraction > 0.4 ? "#FFDD00" : "#AAFFAA"
                Behavior on height { SmoothedAnimation { velocity: Dims.l(200) } }
            }
            // Left tilt — fills upward from centre (negative shipAngle)
            Rectangle {
                property real fraction: Math.min(1.0, Math.max(0, -shipAngle) / physics.maxLandingAngleMax)
                anchors.bottom: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: Math.max(width, (tiltBar.height / 2) * fraction)
                radius: width / 2
                color: fraction > 0.75 ? "#FF4400" : fraction > 0.4 ? "#FFDD00" : "#AAFFAA"
                Behavior on height { SmoothedAnimation { velocity: Dims.l(200) } }
            }
        }

        // ── Death shader
        DeathShader {
            visible:       playerDying
            width:         root.width * 1.2
            height:        root.width * 1.2
            anchors.centerIn: root
            deathProgress: app.deathProgress
            ringColor:     "#FF4400"
        }

        // ── Houston comms message
        Rectangle {
            anchors.fill: parent
            color:        "#CC000000"
            visible:      showingComms
            opacity:      commsOpacity
            
            Label {
                anchors.centerIn:    parent
                text:                missionMessage
                font.pixelSize:      Dims.l(14)
                font.family:         "Barlow"
                font.styleName:      "Bold"
                lineHeight:          0.9
                lineHeightMode:      Text.ProportionalHeight
                horizontalAlignment: Text.AlignHCenter
                color: landed ? (shipWorldX >= world.targetPadXStart - 20 && shipWorldX <= world.targetPadXEnd + 20 ? "#DDFFB830" : "#DDAAFFAA") : "#DDFF6644"
                wrapMode:            Text.WordWrap
                width:               Dims.l(80)
                clip: false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    commsSequence.stop()
                    showingComms  = false
                    commsOpacity  = 0.0
                    gameOver      = true
                }
            }
        }

        HudOverlay {
            anchors.fill: parent
            visible: playing
            thrustLower: app.thrustLower
            thrustUpper: app.thrustUpper
            fuel: app.fuel
            floorY: world.floorY
            shipWorldY: app.shipWorldY
            currentLevel: app.currentLevel
            vy: app.vy
            shipAngle: app.shipAngle
            lowerThrustForce: physics.lowerThrustForce
            upperThrustForce: physics.upperThrustForce
            maxLandingSpeed: physics.maxLandingSpeed
            maxLandingAngleMax: physics.maxLandingAngleMax
        }

        StartOverlay {
            anchors.fill: parent
            selectingLevel: app.selectingLevel
            calibrating: app.calibrating
            currentLevel: app.currentLevel
            calibrationSeconds: app.calibrationSeconds
            calibrationCount: app.calibrationCount
            onLaunchRequested: {
                generateWorld(level)
                app.selectingLevel = false
                app.calibrating = true
                app.calibrationCount = 0
                smoothedX = 0; smoothedY = 0
                calibrationTimer.start()
            }
            onLevelSelected: app.currentLevel = level
        }

        GameOverOverlay {
            anchors.fill: parent
            gameOver: app.gameOver
            crashed: app.crashed
            landed: app.landed
            elapsedMs: app.elapsedMs
            currentLevel: app.currentLevel
            shipWorldX: app.shipWorldX
            targetPadXStart: world.targetPadXStart
            targetPadXEnd: world.targetPadXEnd
            onStartLevelRequested: startLevel(level)
        }
    }

    // ── Game flow

    function startLevel(level) {
        currentLevel  = level
        shipWorldX    = viewport.worldWidth / 2
        shipWorldY    = 0.0
        vx = 0.0; vy = 0.0; shipAngle = 0.0
        fuel = 1.0; thrustLower = 0.0; thrustUpper = 0.0
        elapsedMs     = 0
        playing       = false; landed = false; crashed = false
        gameOver      = false; playerDying = false; deathProgress = 0.0
        deathAnim.stop(); crashAnimation.stop(); landingAnimation.stop()
        gameTimer.stop(); gameTimer.lastMs = 0; gameTimer.lastVy = 0; elapsedTimer.stop()
        gForce = 0.0
        generateWorld(level)
        selectingLevel   = false; calibrating = true; calibrationCount = 0
        missionMessage  = ""
        showingComms    = false
        commsOpacity    = 0.0
        commsSequence.stop()
        smoothedX = 0; smoothedY = 0
        calibrationTimer.start()
    }

    Component.onCompleted: {
        DisplayBlanking.preventBlanking = keepAwake
        currentLevel = TouchdownStorage.highestUnlockedLevel
        selectingLevel = true
    }
}
