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

QtObject {
    id: commsMessages

    readonly property var lose: [
        "Houston we have a problem.",
        "Gravity called, it won today.",
        "That crater has your name.",
        "Rapid unscheduled disassembly occurred.",
        "Mission control is weeping quietly.",
        "Impact confirmed you are paste.",
        "That was not a landing.",
        "You turned into asteroid paste.",
        "Nice try but you pancaked.",
        "Too hot for soft landing.",
        "Asteroid wins again sorry pilot.",
        "Your ship is now confetti.",
        "Welcome to the new crater.",
        "Fuel wasted on that crash.",
        "Did you even brake pilot.",
        "Next time try slowing down.",
        "Bold strategy pilot, it failed.",
        "Physics were not your friend.",
        "You forgot the slowing part.",
        "That is one way down.",
        "New crater named after you.",
        "Earth coms are facepalming hard.",
        "Aldrin would be embarrassed pilot.",
        "The asteroid felt nothing pilot.",
        "Not your finest hour pilot.",
        "Mission log says nope nope nope.",
        "Magnificent total failure spiral.",
        "Zero stars on landing approach.",
        "You have failed this asteroid.",
        "Try using the brakes pilot."
    ]

    readonly property var win: [
        "You stuck the landing pilot.",
        "Touchdown is confirmed good work.",
        "Nice soft landing there pilot.",
        "Fuel is zero but success.",
        "You actually pulled it off.",
        "Perfect controlled descent pilot.",
        "Soft landing achieved, bravo pilot.",
        "We have a successful touchdown.",
        "Houston we have a touchdown.",
        "Gear down locked and landed.",
        "You made it look easy.",
        "Textbook approach and flare out.",
        "One small step landing achieved.",
        "Not bad for a first try.",
        "Shaky but the gear held.",
        "Rough but we will take it.",
        "Close enough counts in landing.",
        "Ground team gives it a seven.",
        "Tranquility base here, we landed.",
        "That will buff right out."
    ]

    // score is injected by main.qml as a template token — replace {score} before display.
    readonly property var comboStart: [
        "Nice landing. Go again for combo.",
        "Landed. Chain it for a combo score.",
        "One down. Land again to start combo.",
        "Good approach. Keep the streak alive.",
        "Landed safely. One more for combo."
    ]

    readonly property var combo: [
        "Combo started. Stash: {score}.",
        "Chain is live. Bank: {score}.",
        "Sequential landing. Stash: {score}.",
        "Two in a row. Carrying {score}.",
        "Combo building. Current stash: {score}."
    ]

    readonly property var comboChain: [
        "Chain grows. Stash now {score}.",
        "Combo extends. Bank: {score}.",
        "Still going. Stash: {score}.",
        "Unbroken streak. Carrying {score}.",
        "Consecutive landings. Stash: {score}."
    ]

    readonly property var comboBroken: [
        "Chain broken. {score} saved to record.",
        "Streak ended. {score} added to record.",
        "Combo banked at {score}. Start again.",
        "Run complete. Record updated: {score}.",
        "Landing streak closed at {score}."
    ]

    readonly property var comboRecord: [
        "New combo record: {score}. Outstanding.",
        "Personal best combo: {score}. Logged.",
        "Record combo {score} achieved. Noted.",
        "Combo highscore: {score}. Well done pilot.",
        "New all-time combo: {score}."
    ]

    readonly property var pad: [
        "Bullseye landing on the pad.",
        "Precision approach executed with style.",
        "Dead center on the landing pad.",
        "Eagle has landed on target.",
        "Perfect pad touchdown, well done.",
        "That is how it is done.",
        "Mission control is going wild.",
        "Pinpoint accuracy outstanding work.",
        "You nailed the designated landing zone.",
        "Flawless pad touchdown, nice one pilot.",
        "Ground crew is cheering right now.",
        "That is a ten from the judges.",
        "Target acquired and swiftly nailed.",
        "Buzz Aldrin would be proud.",
        "Neil is smiling from above.",
        "Textbook pad landing, pilot bravo.",
        "Center pad hit, that is rare.",
        "Designated zone locked and landed.",
        "The pad was always the plan.",
        "Historic touchdown on the landing zone."
    ]
}
