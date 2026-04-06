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
        "Houston we have\na problem.",
        "Gravity called,\nit won today.",
        "That crater has\nyour name.",
        "Rapid unscheduled\ndisassembly occurred.",
        "Mission control is\nweeping quietly.",
        "Impact confirmed\nyou are paste.",
        "That was not\na landing.",
        "You turned into\nasteroid paste.",
        "Nice try but\nyou pancaked.",
        "Too hot for\nsoft landing.",
        "Asteroid wins again\nsorry pilot.",
        "Your ship is\nnow confetti.",
        "Welcome to the\nnew crater.",
        "Fuel wasted on\nthat crash.",
        "Did you even\nbrake pilot.",
        "Next time try\nslowing down.",
        "Bold strategy pilot,\nit failed.",
        "Physics were not\nyour friend.",
        "You forgot the\nslowing part.",
        "That is one\nway down.",
        "New crater named\nafter you.",
        "Earth coms are\nfacepalming hard.",
        "Aldrin would be\nembarrassed pilot.",
        "The asteroid felt\nnothing pilot.",
        "Not your finest\nhour pilot.",
        "Mission log says\nnope nope nope.",
        "Magnificent total\nfailure spiral.",
        "Zero stars on\nlanding approach.",
        "You have failed\nthis asteroid.",
        "Try using the\nbrakes pilot."
    ]

    readonly property var win: [
        "You stuck the\nlanding pilot.",
        "Touchdown is\nconfirmed good work.",
        "Nice soft landing\nthere pilot.",
        "Fuel is zero\nbut success.",
        "You actually pulled\nit off.",
        "Perfect controlled\ndescent pilot.",
        "Soft landing achieved,\nbravo pilot.",
        "We have a\nsuccessful touchdown.",
        "Houston we have\na touchdown.",
        "Gear down locked\nand landed.",
        "You made it\nlook easy.",
        "Textbook approach\nand flare out.",
        "One small step\nlanding achieved.",
        "Not bad for\na first try.",
        "Shaky but the\ngear held.",
        "Rough but we\nwill take it.",
        "Close enough counts\nin landing.",
        "Ground team gives\nit a seven.",
        "Tranquility base here,\nwe landed.",
        "That will buff\nright out."
    ]

    readonly property var pad: [
        "Bullseye landing\non the pad.",
        "Precision approach\nexecuted with style.",
        "Dead center on\nthe landing pad.",
        "Eagle has landed\non target.",
        "Perfect pad touchdown,\nwell done.",
        "That is how\nit is done.",
        "Mission control is\ngoing wild.",
        "Pinpoint accuracy\noutstanding work.",
        "You nailed the\ndesignated landing zone.",
        "Flawless pad touchdown,\nnice one pilot.",
        "Ground crew is\ncheering right now.",
        "That is a ten\nfrom the judges.",
        "Target acquired and\nnailed completely.",
        "Buzz Aldrin would\nbe proud.",
        "Neil is smiling\nfrom above.",
        "Textbook pad landing,\npilot bravo.",
        "Center pad hit,\nthat is rare.",
        "Designated zone locked\nand landed.",
        "The pad was\nalways the plan.",
        "Historic touchdown on\nthe landing zone."
    ]
}
