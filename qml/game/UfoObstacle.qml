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

import QtQuick 2.6

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

    // SailfishOS (Qt 5.6) has no QtQuick.Shapes: the filled hull and the
    // ten line segments are drawn on a Canvas with the same coordinates.
    Canvas {
        anchors.fill: parent
        property var hull: [[0.000, 14.962], [10.511, 7.284], [14.196, 0.186], [20.850, 0.186], [25.184, 7.284], [35.082, 14.962], [0.000, 14.962]]
        property var segments: [[0.000, 14.962, 10.511, 7.284],
            [0.000, 14.962, 11.125, 22.504],
            [25.900, 22.504, 11.125, 22.504],
            [35.082, 14.962, 25.900, 22.504],
            [0.000, 14.962, 35.082, 14.962],
            [25.184, 7.284, 35.082, 14.962],
            [10.511, 7.284, 25.184, 7.284],
            [0.000, 14.962, 10.511, 7.284],
            [25.184, 7.284, 20.850, 0.186],
            [14.196, 0.186, 20.850, 0.186],
            [10.511, 7.284, 14.196, 0.186]]
        property color stroke: ufo.strokeColor
        property color fill: ufo.fillColor
        onStrokeChanged: requestPaint()
        onFillChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = fill
            ctx.beginPath()
            ctx.moveTo(hull[0][0] * ufo.sc, hull[0][1] * ufo.sc)
            for (var i = 1; i < hull.length; i++) ctx.lineTo(hull[i][0] * ufo.sc, hull[i][1] * ufo.sc)
            ctx.closePath()
            ctx.fill()
            ctx.strokeStyle = stroke
            ctx.lineWidth = ufo.dimsFactor * 1.2
            ctx.lineCap = "round"
            ctx.beginPath()
            for (var j = 0; j < segments.length; j++) {
                var s = segments[j]
                ctx.moveTo(s[0] * ufo.sc, s[1] * ufo.sc)
                ctx.lineTo(s[2] * ufo.sc, s[3] * ufo.sc)
            }
            ctx.stroke()
        }
    }
}
