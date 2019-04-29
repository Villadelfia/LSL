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

list maybeYeet = [];
list pending = [];
key token;

checkYeet()
{
    if(maybeYeet == []) return;
    key agent = llList2Key(maybeYeet, 0);
    token = llReadKeyValue((string)agent);
}

default
{
    state_entry()
    {
        llSetTimerEvent(2.5);
    }

    timer()
    {
        if(maybeYeet != []) return;
        list agents = llGetAgentList(AGENT_LIST_REGION, []);
        integer i = llGetListLength(agents) - 1;
        for(; i >= 0; --i)
        {
            key agent = llList2Key(agents, i);
            vector pos = llList2Vector(llGetObjectDetails(agent, [OBJECT_POS]), 0);
            if(!llAgentInExperience(agent) && (pos.z < 1000 || (pos.z > 1100 && pos.z < 3950)) && llListFindList(pending, [agent]) == -1)
            {
                maybeYeet += agent;
            }
        }
        checkYeet();
    }

    experience_permissions(key agent)
    {
        integer i = llListFindList(pending, [agent]);
        if(i == -1) return;
        pending = llDeleteSubList(pending, i, i);
    }

    experience_permissions_denied(key agent, integer reason)
    {
        integer i = llListFindList(pending, [agent]);
        if(i == -1) return;
        if(!llAgentInExperience(agent))
        {
            llRegionSayTo(llList2Key(maybeYeet, 0), 0, "You either declined the experience or blocked it. Sending you home.");
            llRegionSay(CG_IPC_CHANNEL, "target=server\nagent-key="+(string)agent+"\nmode=send-home");
        }
        pending = llDeleteSubList(pending, i, i);
    }

    dataserver(key t, string value)
    {
        if(t == token)
        {
            if(startswith(value, "1"))
            {
                // No yeet!
                maybeYeet = llDeleteSubList(maybeYeet, 0, 0);
            }
            else
            {
                // Warn and maybe yeet!
                llRegionSayTo(llList2Key(maybeYeet, 0), 0, "Warning, you must wear an observer tag or the sim HUD on the sim. Please accept the experience to get one.");
                llRequestExperiencePermissions(llList2Key(maybeYeet, 0), "");
                pending += llList2Key(maybeYeet, 0);
                maybeYeet = llDeleteSubList(maybeYeet, 0, 0);
            }
            checkYeet();
        }
    }
}