/*
 * Crystalgate Source Code
 * Copyright (C) 2019 - Randy Thiemann
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <CG.lsl>

default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    }
    
    listen(integer c, string name, key id, string message)
    {
        list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
        string target = getValueFromKey(dict, "target");
        if(target != "server") return;

        string mode = getValueFromKey(dict, "mode");
        string agentKey = getValueFromKey(dict, "agent-key");

        if(mode == "send-home")
        {
            llTeleportAgentHome((key)agentKey);
        }
    }
}