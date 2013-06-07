/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato.filho@canonical.com>
 */

import IndicatorsClient 0.1 as IndicatorsClient
import QtQuick 2.0
import Ubuntu.Components 0.1

IndicatorsClient.PluginItem {
    anchors.fill: parent

    function stop() {
        // never stops the service
        // this will keep all objects in memory, consume more memory
        // but will optimize the menu contruction on the screen
    }
}
