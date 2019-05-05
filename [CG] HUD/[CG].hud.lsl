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
integer receivedReadies = 0;
integer experienceListen;
integer rezzer;
integer responded = FALSE;
integer initialized = FALSE;
integer characterLoaded = 0;
integer level = 0;
integer xp = 0;
string status = "OOC";
string initiative = "";
string hp = "";
integer rlvState = FALSE;
key token = NULL_KEY;
string hudState = "normal";


handleStatusMessage()
{
    if(hudState == "normal" || hudState == "tools")
    {
        if(initialized)
        {
            if(characterLoaded > 0)
            {
                string sLevel = (string)level;
                string sStatus = status;
                if(llStringLength(sLevel) < 2) sLevel = "0" + sLevel;
                if(llStringLength(sStatus) < 3) sStatus = " " + sStatus;
                llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "Slot " + (string)characterLoaded + "|Lvl " + sLevel + "|Status " + sStatus, (string)1);
                if(status == "IC")
                {
                    if(level == 99)
                    {
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "You're at the max level!", (string)2);
                    }
                    else
                    {
                        string sLevelNext = (string)(level + 1);
                        string sXp = (string)xp;
                        if(llStringLength(sLevelNext) < 2) sLevelNext = "0" + sLevelNext;
                        while(llStringLength(sXp) < 5) sXp = "0" + sXp;
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, sXp + " XP to go to lvl " + sLevelNext, (string)2);
                    }
                }
                else if(status == "OOC" || status == "AFK")
                {
                    llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "OOC/AFK  Go IC to get XP", (string)2);
                }
                else if(status == "CMB")
                {
                    while(llStringLength(initiative) < 3) initiative = "0" + initiative;
                    while(llStringLength(hp) < 7) hp = " " + hp;
                    llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, initiative + " initiative" + hp + " HP", (string)2);
                }
            }
            else
            {
                llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, " Welcome to Crystalgate ", (string)1);
                llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "   Click to Open Menu   ", (string)2);
            }
        }
        else
        {
            llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, " Welcome to Crystalgate ", (string)1);
            llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "     Setting up HUD     ", (string)2);
        }
        
    }
    else if(hudState == "menus")
    {
        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "  Select a Menu Option  ", (string)2);
    }
}

initializeHud()
{
    llOwnerSay("Welcome to Crystalgate. Click the hud to open the menu, click and drag your mouse off it to hide it.");
    token = llReadKeyValue((string)llGetOwner());
}

default
{
    state_entry()
    {
        log("Initializing...");
        llSetRemoteScriptAccessPin(CG_PIN);
        resetAllOther();
        if(llGetInventoryNumber(INVENTORY_SCRIPT) == 1) state ready_for_experience_attach;
    }
    
    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_SCRIPT_READY)
        {
            receivedReadies++;
            if(receivedReadies == llGetInventoryNumber(INVENTORY_SCRIPT) - 1)
            {
                state ready_for_experience_attach;
            }
        }
    }
}

state ready_for_experience_attach
{
    state_entry()
    {
        reportTopReady("HUD");
    }

    on_rez(integer start)
    {
        if(llGetAttached() != 0) return;
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

    experience_permissions(key id)
    {
        if(llGetAgentSize(id) != ZERO_VECTOR)
        {
            llAttachToAvatarTemp(0);
            llSetTimerEvent(0.0);
        }
        
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
            attachSuccess("hud", rezzer);
            llSetTimerEvent(0.0);
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
        if(debugMode) llOwnerSay("In HUD begin state...");
        llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=hud-attached");
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llResetTime();
        llSetTimerEvent(5.0);
        llSetPos(llList2Vector(hudPositions, 1));
    }

    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_SET_HUD_STATE)
        {
            hudState = str1;
            handleStatusMessage();
        }
        else if(api_id == CLIENT_PERFORM_TELEPORT)
        {
            llTeleportAgent(llGetOwner(), "", (vector)str1, (vector)((string)str2));
        }
        else if(api_id == CLIENT_CHARACTER_LOADED || api_id == CLIENT_CHARACTER_CHANGED)
        {
            list dict = llParseString2List(str1, ["\n"], []);
            characterLoaded = (integer)getValueFromKey(dict, "slot");
            level = (integer)getValueFromKey(dict, "level");
            xp = (integer)getValueFromKey(dict, "xp");
            handleStatusMessage();
        }
        else if(api_id == CLIENT_CHARACTER_UNLOADED)
        {
            characterLoaded = 0;
            handleStatusMessage();
        }
        else if(api_id == CLIENT_STATUS_CHANGED)
        {
            status = str1;
            if(status == "CMB")
            {
                list params = llParseString2List((string)str2, [";"], []);
                initiative = llList2String(params, 0);
                hp = llList2String(params, 1) + "/" + llList2String(params, 2);
            }
            handleStatusMessage();
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            string mode = getValueFromKey(dict, "mode");
            if(target != "client") return;
            if(mode == "detach" || mode == "detach-hud")
            {
                llDetachFromAvatar();
            }
            else if(mode == "titler-attached" && !responded)
            {
                responded = TRUE;
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=hud-attached");
                initializeHud();
                handleStatusMessage();
            }
            else if(mode == "titler-moved" && characterLoaded > 0)
            {
                llMessageLinked(LINK_THIS, CLIENT_SET_TITLER_POS, getValueFromKey(dict, "pos"), NULL_KEY);
            }
            else if(mode == "page-staff")
            {
                string amount = getValueFromKey(dict, "amount");
                if(amount == "0")
                {
                    llOwnerSay("Sorry, there's no staff available right now... Please leave a notecard in the purple book in the landing zone instead.");
                }
                else
                {
                    llOwnerSay("Staff has been notified of your request, they will contact you as soon as possible.");
                }
            }
            else if(mode == "trusted-say")
            {
                trustedSay(getValueFromKey(dict, "object-name"), strreplace(getValueFromKey(dict, "message"), "###", "\n"));
            }
            else if(mode == "xp-tick")
            {
                string mult = getValueFromKey(dict, "xp-mult");
                string xpData = getValueFromKey(dict, "xp-values");
                llMessageLinked(LINK_THIS, CLIENT_HANDLE_XP_TICK, xpData, (key)mult);
            }
            else if(mode == "book-ready")
            {
                llMessageLinked(LINK_THIS, CLIENT_BOOK_STATUS, getValueFromKey(dict, "slot"), NULL_KEY);
            }
            else if(mode == "book-not-ready")
            {
                llMessageLinked(LINK_THIS, CLIENT_BOOK_STATUS, "-1", NULL_KEY);
            }
            else if(mode == "book-attached")
            {
                string ver = getValueFromKey(dict, "version");
                if((integer)ver != BOOK_VERSION)
                {
                    llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=detach-outdated\nagent-key=" + (string)llGetOwner());
                }
                llMessageLinked(LINK_THIS, CLIENT_BOOK_ATTACHED, "", NULL_KEY);
            }
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=detach");
            llDie();
        }
        else
        {
            llResetScript();
        }
    }

    timer()
    {
        if(responded == FALSE && llGetTime() > 15.0)
        {
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=detach");
            llDetachFromAvatar();
        }
    }

    dataserver(key query_id, string data)
    {
        if(token == query_id && initialized == FALSE)
        {
            string value = llList2String(llParseString2List(data, [","], []), 1);
            list dict = llParseString2List(value, ["\n", "!~~DELIM~~!"], []);
            if(value == "NEW" || getValueFromKey(dict, "slot") == "NONE")
            {
                llOwnerSay("Click on the hud and then the character button to load or create a character.");
            }
            else
            {
                llMessageLinked(LINK_THIS, CLIENT_LOAD_CHARACTER, getValueFromKey(dict, "slot"), NULL_KEY);
            }
            initialized = TRUE;
            llMessageLinked(LINK_THIS, CLIENT_INITIAL_VALUES, value, NULL_KEY);
            handleStatusMessage();
        }
    }
}