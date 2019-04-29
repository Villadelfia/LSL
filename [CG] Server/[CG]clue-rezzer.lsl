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

integer busy = FALSE;
key activeAgent = NULL_KEY;

integer attachListen = -1;
integer attachChannel = 0;

rezIt(key agent)
{
    if(busy) return;
    activeAgent = agent;
    busy = TRUE;
    attachChannel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
    attachListen = llListen(attachChannel, "", NULL_KEY, "");
    llRezObject("[CG] CLUE", llGetPos() - <0, 0, 5>, ZERO_VECTOR, ZERO_ROTATION, attachChannel);
    llSetTimerEvent(5.0);
}

markDone()
{
    if(!busy) return;
    busy = FALSE;
    llListenRemove(attachListen);
}

default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    }

    link_message(integer src_link, integer api_id, string str1, key agent)
    {
        if(api_id == SERVER_REZ_CLUE)
        {
            rezIt(agent);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == attachChannel && message == "ready")
        {
            llRegionSayTo(id, channel, (string)activeAgent);
        }
        else if(channel == attachChannel && message == "done")
        {
            markDone();
        }
    }

    timer()
    {
        markDone();
    }
}