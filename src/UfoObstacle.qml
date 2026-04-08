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
import QtQuick.Shapes 1.15

// Pure visual component — no logic, no timers, no state.
// Position and size are set by main.qml each frame.
// Aspect ratio matches blaster-ufo.svg: 35.082 × 22.758 = 1.5415
Item {
    id: ufo

    property real size:        40.0
    property real dimsFactor:  1.0
    property color strokeColor: "#44FFDD"
    // Semi-transparent fill — lighter than stroke so outlines remain readable.
    property color fillColor:   "#1A44FFDD"

    // SVG natural height is 22.758 — sc maps all coordinates to our size.
    readonly property real sc: size / 22.758

    width:  size * 1.5415
    height: size

    Shape {
        anchors.fill: parent

        // Filled upper hull — closed polygon rendered behind all stroke lines.
        // Traces: SaucerL → CockpitTL → DomeTL → DomeTR → CockpitTR → SaucerR → SaucerL
        // plus saucer underside closing back via the disk line.
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor:   ufo.fillColor
            startX:  0.000 * ufo.sc; startY: 14.962 * ufo.sc
            PathLine { x: 10.511 * ufo.sc; y:  7.284 * ufo.sc }
            PathLine { x: 14.196 * ufo.sc; y:  0.186 * ufo.sc }
            PathLine { x: 20.850 * ufo.sc; y:  0.186 * ufo.sc }
            PathLine { x: 25.184 * ufo.sc; y:  7.284 * ufo.sc }
            PathLine { x: 35.082 * ufo.sc; y: 14.962 * ufo.sc }
            PathLine { x:  0.000 * ufo.sc; y: 14.962 * ufo.sc }
        }

        // 1 — left leg: SaucerL → FootL
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX:  0.000 * ufo.sc; startY: 14.962 * ufo.sc
            PathLine { x: 11.125 * ufo.sc; y: 22.504 * ufo.sc }
        }
        // 2 — feet bar: FootR → FootL
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 25.900 * ufo.sc; startY: 22.504 * ufo.sc
            PathLine { x: 11.125 * ufo.sc; y: 22.504 * ufo.sc }
        }
        // 3 — right leg: SaucerR → FootR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 35.082 * ufo.sc; startY: 14.962 * ufo.sc
            PathLine { x: 25.900 * ufo.sc; y: 22.504 * ufo.sc }
        }
        // 4 — main saucer disk: SaucerL → SaucerR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX:  0.000 * ufo.sc; startY: 14.962 * ufo.sc
            PathLine { x: 35.082 * ufo.sc; y: 14.962 * ufo.sc }
        }
        // 5 — right cockpit wall: CockpitTR → SaucerR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 25.184 * ufo.sc; startY:  7.284 * ufo.sc
            PathLine { x: 35.082 * ufo.sc; y: 14.962 * ufo.sc }
        }
        // 6 — cockpit roof: CockpitTL → CockpitTR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 10.511 * ufo.sc; startY:  7.284 * ufo.sc
            PathLine { x: 25.184 * ufo.sc; y:  7.284 * ufo.sc }
        }
        // 7 — left cockpit wall: SaucerL → CockpitTL
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX:  0.000 * ufo.sc; startY: 14.962 * ufo.sc
            PathLine { x: 10.511 * ufo.sc; y:  7.284 * ufo.sc }
        }
        // 8 — right dome wall: CockpitTR → DomeTR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 25.184 * ufo.sc; startY:  7.284 * ufo.sc
            PathLine { x: 20.850 * ufo.sc; y:  0.186 * ufo.sc }
        }
        // 9 — dome roof: DomeTL → DomeTR
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 14.196 * ufo.sc; startY:  0.186 * ufo.sc
            PathLine { x: 20.850 * ufo.sc; y:  0.186 * ufo.sc }
        }
        // 10 — left dome wall: CockpitTL → DomeTL
        ShapePath {
            strokeWidth: ufo.dimsFactor * 1.2; strokeColor: ufo.strokeColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 10.511 * ufo.sc; startY:  7.284 * ufo.sc
            PathLine { x: 14.196 * ufo.sc; y:  0.186 * ufo.sc }
        }
    }
}
