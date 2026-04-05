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

#ifndef TOUCHDOWNSTORAGE_H
#define TOUCHDOWNSTORAGE_H

#include <QObject>
#include <QSettings>
#include <QString>
#include <QQmlEngine>

class TouchdownStorage : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int highestUnlockedLevel READ highestUnlockedLevel WRITE setHighestUnlockedLevel NOTIFY highestUnlockedLevelChanged)

public:
    explicit TouchdownStorage(QObject *parent = nullptr);
    static TouchdownStorage *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);

    int highestUnlockedLevel() const;
    void setHighestUnlockedLevel(int v);

    // Best time per level — stored in ms, lower is better. Returns 0 if unset.
    Q_INVOKABLE int  bestTime(int level) const;
    Q_INVOKABLE void setBestTime(int level, int ms);

    Q_INVOKABLE QString fileName() const;

signals:
    void highestUnlockedLevelChanged();

private:
    QSettings m_settings;
    static TouchdownStorage *s_instance;
};

#endif // TOUCHDOWNSTORAGE_H
