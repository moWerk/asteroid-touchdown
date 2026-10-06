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

pragma Singleton
import QtQuick 2.6
import Nemo.Configuration 1.0

// SailfishOS: replaces the C++ TouchdownStorage (QSettings, game.ini) so
// the app is pure QML and one noarch package. Same API; the values live in
// dconf under /apps/harbour-asteroid-touchdown. The unlocked level and the
// combo record never go down; a best time only improves.
QtObject {
    id: store

    property QtObject _cfg: ConfigurationGroup { path: "/apps/harbour-asteroid-touchdown" }
    property bool _ready: false

    property int highestUnlockedLevel: 1
    readonly property int comboHighScore: _comboHigh
    property int _comboHigh: 0
    property int comboStash: 0
    property int comboChainLength: 0
    property int nextComboLevel: 0

    onHighestUnlockedLevelChanged: {
        if (!_ready) return
        var stored = Number(_cfg.value("highestUnlockedLevel", 1))
        if (highestUnlockedLevel > stored) _cfg.setValue("highestUnlockedLevel", highestUnlockedLevel)
        else if (highestUnlockedLevel < stored) highestUnlockedLevel = stored
    }
    onComboStashChanged:       if (_ready) _cfg.setValue("comboStash", comboStash)
    onComboChainLengthChanged: if (_ready) _cfg.setValue("comboChainLength", comboChainLength)
    onNextComboLevelChanged:   if (_ready) _cfg.setValue("nextComboLevel", nextComboLevel)

    // 0 = no time recorded yet
    function bestTime(level) { return Number(_cfg.value("level" + level + "/bestTime", 0)) }
    function setBestTime(level, ms) {
        if (ms <= 0) return
        var stored = bestTime(level)
        if (stored !== 0 && ms >= stored) return
        _cfg.setValue("level" + level + "/bestTime", ms)
    }

    function submitCombo(score) {
        if (score <= 0 || score <= _comboHigh) return
        _comboHigh = score
        _cfg.setValue("comboHighScore", score)
    }

    Component.onCompleted: {
        highestUnlockedLevel = Number(_cfg.value("highestUnlockedLevel", 1))
        _comboHigh           = Number(_cfg.value("comboHighScore", 0))
        comboStash           = Number(_cfg.value("comboStash", 0))
        comboChainLength     = Number(_cfg.value("comboChainLength", 0))
        nextComboLevel       = Number(_cfg.value("nextComboLevel", 0))
        _ready = true
    }
}
