/*
 * Copyright (C) 2026 Timo Könnecke <github.com/moWerk>
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

// SailfishOS: button plate with the top-left and bottom-right corners
// rounded and the other two square, after the SailfishOS icon shape. Qt 5.6
// rounds all four corners or none, so two squares cover the corners that
// stay sharp. The parts are drawn as one layer, so the fill's opacity does
// not double where they overlap.
Item {
    id: plate

    property color color: "#4a4a4a"
    property real fillOpacity: 0.7
    property real radius: height / 2

    layer.enabled: true
    opacity: fillOpacity

    Rectangle {
        anchors.fill: parent
        radius: plate.radius
        color: plate.color
    }
    Rectangle {
        width: plate.radius; height: plate.radius
        anchors { top: parent.top; right: parent.right }
        color: plate.color
    }
    Rectangle {
        width: plate.radius; height: plate.radius
        anchors { bottom: parent.bottom; left: parent.left }
        color: plate.color
    }
}
