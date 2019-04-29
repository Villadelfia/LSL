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

integer experienceListen;
integer rezzer;

default
{
    state_entry()
    {
        log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
        log("\n\n\n\n!!! OBSERVER IS READY FOR SERVER !!!\n\n\n\n");
    }

    on_rez(integer start)
    {
        experienceListen = llListen(start, "", NULL_KEY, "");
        llRegionSayTo((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0), start, "ready");
        rezzer = start & 0x1F;
        llSetTimerEvent(5.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        if(llGetAgentSize((key)message) != ZERO_VECTOR)
        {    
            llRequestExperiencePermissions((key)message, "");
            llListenRemove(experienceListen);
            llSetTimerEvent(5.0);
        }
        else
        {
            failAndDie(rezzer);
        }
    }

    experience_permissions(key target_id)
    {
        llAttachToAvatarTemp(0);
        llSetTimerEvent(0.0);
        if(llGetAttached() == 0)
        {
            failAndDie(rezzer);
        }
    }

    experience_permissions_denied(key agent_id, integer reason)
    {
        failAndDie(rezzer);
    }

    attach(key id)
    {
        if(id)
        {
            attachSuccess("observer", rezzer);
            state running;
        }
        else
        {
            failAndDie(rezzer);
        }
    }

    timer()
    {
        failAndDie(rezzer);
    }
}

state running
{
    state_entry()
    {
        llOwnerSay("Hi there, welcome to Crystalgate. Once you're done looking around and ready to start playing for real, just type \"HUD\" in chat, and you will be given one.");
        llListen(0, "", llGetOwner(), "");
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llUpdateKeyValue((string)llGetOwner(), "fancy=1", FALSE, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == 0 && llToLower(message) == "hud") 
        {
            llUpdateKeyValue((string)llGetOwner(), "NEW", FALSE, "");
            llOwnerSay("Inviting you to the OOC group and converting your observer tag into a HUD, it will detach and you will get your HUD in a few moments. Welcome to Crystalgate! If your group invite doesn't arrive, contact an admin, but feel free to start playing!");
            giveGroupInvite(id, "8217296c-97a8-a9f8-5bef-933e5fd5ddb1");
            llDetachFromAvatar();
        }
        else if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            string mode = getValueFromKey(dict, "mode");
            if(target != "client" || mode != "detach") return;
            llDetachFromAvatar();
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            llDie();
        }
        else
        {
            llResetScript();
        }
    }
}