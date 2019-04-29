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

integer rezzerId = 0;
key token = NULL_KEY;
key activeAgent = NULL_KEY;

string attaching;
integer attached = 0;
integer attachListen = -1;
integer attachChannel = 0;

markDone()
{
    if(activeAgent == NULL_KEY)
    {
        llSetTimerEvent(0.0);
        return;
    }
    activeAgent = NULL_KEY;
    if(attachListen != -1)
    {
        llListenRemove(attachListen);
        attachListen = -1;
    }
    llMessageLinked(LINK_THIS, SERVER_AGENT_READY, "", NULL_KEY);
    llSetTimerEvent(0.0);
}

rezHUD()
{
    attachChannel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
    attachChannel = attachChannel & 0xFFFFFFE0;
    attachChannel = attachChannel | rezzerId;
    attachListen = llListen(attachChannel, "", NULL_KEY, "");
    llRegionSayTo(activeAgent, CG_IPC_CHANNEL, "target=client\nmode=detach");
    attached = 0;
    llRezObject("[CG] HUD", llGetPos() - <0, 0, 5>, ZERO_VECTOR, ZERO_ROTATION, attachChannel);
    llRezObject("[CG] TITLER", llGetPos() - <0, 0, 5>, ZERO_VECTOR, ZERO_ROTATION, attachChannel);
    llSetTimerEvent(15.0);
}

rezObserver()
{
    attachChannel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
    attachChannel = attachChannel & 0xFFFFFFE0;
    attachChannel = attachChannel | rezzerId;
    attachListen = llListen(attachChannel, "", NULL_KEY, "");
    llRegionSayTo(activeAgent, CG_IPC_CHANNEL, "target=client\nmode=detach");
    attached = 0;
    llRezObject("[CG] OBSERVER", llGetPos() - <0, 0, 5>, ZERO_VECTOR, ZERO_ROTATION, attachChannel);
    llSetTimerEvent(15.0);
}

default
{
    state_entry()
    {
        list tokens = llParseString2List(llGetScriptName(), [" "], []);
        integer amount = llGetListLength(tokens);
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        if(amount > 1)
        {
            rezzerId = (integer)llList2String(tokens, 1);
        }
        if(debugMode) log("Determined that I am rezzer " + (string)rezzerId);
    }

    link_message(integer src_link, integer api_id, string str1, key agent)
    {
        if(api_id == SERVER_DETERMINE_REZ && (integer)str1 == rezzerId)
        {
            activeAgent = agent;
            token = llReadKeyValue((string)agent);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(debugMode) log(message);
        if(channel == attachChannel)
        {
            llRegionSayTo(id, channel, (string)activeAgent);
        }

        if(activeAgent == NULL_KEY) return;
        list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
        string target = getValueFromKey(dict, "target");
        string rezzer = getValueFromKey(dict, "rezzer");
        if(target != "server" || rezzer != (string)rezzerId) return;

        string mode = getValueFromKey(dict, "mode");

        if(attaching == "HUD")
        {
            if(mode == "attach-fail")
            {
                llRegionSayTo(activeAgent, CG_IPC_CHANNEL, "target=client\nmode=detach");
                markDone();
            }
            else if(mode == "attach-hud-success" || mode == "attach-titler-success")
            {
                attached++;
                if(attached == 2)
                {
                    markDone();
                }
            }
        }
        else
        {
            if(mode == "attach-fail" || mode == "attach-observer-success")
            {
                markDone();
            }
        }
    }

    dataserver(key t, string value)
    {
        if(t == token)
        {
            if(startswith(value, "1") && value != "1,fancy=1")
            {
                if(llList2Integer(llGetObjectDetails(activeAgent, [OBJECT_ATTACHED_SLOTS_AVAILABLE]), 0) < 2)
                {
                    if(debugMode) log("Can't rez HUD, not enough room on agent.");
                    llSetTimerEvent(0.0);
                    llMessageLinked(LINK_THIS, SERVER_AGENT_READY, "", NULL_KEY);
                    activeAgent = NULL_KEY;
                }
                if(debugMode) log("Rezzing HUD...");
                attaching = "HUD";
                rezHUD();
            }
            else
            {
                if(llList2Integer(llGetObjectDetails(activeAgent, [OBJECT_ATTACHED_SLOTS_AVAILABLE]), 0) < 1)
                {
                    if(debugMode) log("Can't rez observer tag, not enough room on agent.");
                    llSetTimerEvent(0.0);
                    llMessageLinked(LINK_THIS, SERVER_AGENT_READY, "", NULL_KEY);
                    activeAgent = NULL_KEY;
                }
                if(debugMode) log("Rezzing Observer...");
                attaching = "OBSERVER";
                rezObserver();
            }
        }
    }

    timer()
    {
        markDone();
    }
}