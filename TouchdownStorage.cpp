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

#include "TouchdownStorage.h"
#include <QDir>
#include <QStandardPaths>

TouchdownStorage *TouchdownStorage::s_instance = nullptr;

TouchdownStorage::TouchdownStorage(QObject *parent)
    : QObject(parent)
    , m_settings(
          QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
          + QStringLiteral("/.config/asteroid-touchdown/game.ini"),
          QSettings::IniFormat)
{
    QDir().mkpath(
        QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
        + QStringLiteral("/.config/asteroid-touchdown"));
    s_instance = this;
}

TouchdownStorage *TouchdownStorage::instance()
{
    if (!s_instance)
        s_instance = new TouchdownStorage();
    return s_instance;
}

QObject *TouchdownStorage::qmlInstance(QQmlEngine *, QJSEngine *)
{
    return instance();
}

// ── Highest unlocked level ────────────────────────────────────────────────────

int TouchdownStorage::highestUnlockedLevel() const
{
    return m_settings.value(QStringLiteral("highestUnlockedLevel"), 1).toInt();
}

void TouchdownStorage::setHighestUnlockedLevel(int v)
{
    if (v <= highestUnlockedLevel()) return;
    m_settings.setValue(QStringLiteral("highestUnlockedLevel"), v);
    m_settings.sync();
    emit highestUnlockedLevelChanged();
}

// ── Per-level best time ───────────────────────────────────────────────────────
// Key format: "level<N>/bestTime"  — QSettings treats / as group separator.
// Returns 0 when no time recorded yet (0 = no entry, not a valid time).

int TouchdownStorage::bestTime(int level) const
{
    return m_settings.value(
        QStringLiteral("level%1/bestTime").arg(level), 0).toInt();
}

void TouchdownStorage::setBestTime(int level, int ms)
{
    if (ms <= 0) return;
    int stored = bestTime(level);
    // Lower time is better; 0 means no entry yet so always write in that case.
    if (stored != 0 && ms >= stored) return;
    m_settings.setValue(
        QStringLiteral("level%1/bestTime").arg(level), ms);
    m_settings.sync();
}

// ── Utility ───────────────────────────────────────────────────────────────────

QString TouchdownStorage::fileName() const
{
    return m_settings.fileName();
}
