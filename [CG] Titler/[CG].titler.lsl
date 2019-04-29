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
integer rlvEnabled = FALSE;

string mode = "";
key token = NULL_KEY;
string slot = "0";
string rlv = "0";
string combatData = "";
string fullName = "";
string name = "";
string title = "";
string status = "OOC";
vector pos;

setRlv()
{
    if(rlv == "1" && (status == "IC" || status == "CMB"))
    {
        rlvOn();
    }
    else
    {
        rlvOff();
    }
}

rlvOn()
{
    if(rlvEnabled) return;
    rlvEnabled = TRUE;
    llOwnerSay("@redirchat:4=add");
    llOwnerSay("RLV chat redirection enabled.");
}

rlvOff()
{
    if(!rlvEnabled) return;
    rlvEnabled = FALSE;
    llOwnerSay("@redirchat:4=rem");
    llOwnerSay("Chat redirection to channel 4 disabled.");
}

load()
{
    if(mode == "")
    {
        slot = "0";
        rlv = "0";
        combatData = "";
        fullName = "";
        name = "";
        title = "";
        mode = "load-basic";
        token = llReadKeyValue((string)llGetOwner());
    }
    else if(mode == "load-basic")
    {
        mode = "load-character";
        token = llReadKeyValue((string)llGetOwner() + "character" + slot);
    }
    else if(mode == "load-character")
    {
        mode = "load-title";
        token = llReadKeyValue((string)llGetOwner() + "title" + slot);
    }
}

setTitle()
{
    string workingTitle = "";

    if(slot == "0")
    {
        workingTitle = "<No Character Loaded>\nOOC";
    }
    else if(status == "OOC")
    {
        workingTitle = "<"+fullName+">\nOOC";
    }
    else if(status == "AFK")
    {
        workingTitle = "<"+fullName+">\nAFK";
    }
    else if(status == "IC")
    {
        workingTitle = "<"+fullName+">";
        if(title != "")
        {
            workingTitle += "\n \n" + title;
        }
    }
    else if(status == "CMB")
    {
        list data = llParseString2List(combatData, [";"], []);
        workingTitle = "<1.0,0.0,0.0>|||<"+fullName+">\n<1.0,0.0,0.0>|||COMBAT MODE\n<1.0, 0.0, 0.0>|||Initiative: " + llList2String(data, 0) + ", " + llList2String(data, 1) + "/" + llList2String(data, 2) + " HP";
        if(title != "")
        {
            workingTitle += "\n \n" + title;
        }
    }

    llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", <0, 0, 0>, 0]);
    list titleLines = llParseString2List(workingTitle, ["\n"], []);
    integer count = llGetListLength(titleLines);
    integer i = imin(11, count);
    string add = "";
    for(; i >= 0; --i)
    {
        string line = llList2String(titleLines, i);
        if(contains(line, "|||"))
        {
            vector c = (vector)llList2String(llParseString2List(line, ["|||"], []), 0);
            string t = llList2String(llParseString2List(line, ["|||"], []), 1);
            llSetLinkPrimitiveParamsFast(i+1, [PRIM_TEXT, t + add, c, 1.0]);
        }
        else
        {
            llSetLinkPrimitiveParamsFast(i+1, [PRIM_TEXT, line + add, <1.0, 1.0, 1.0>, 1.0]);
        }
        add = add + "\n ";
    }
}

handleIcChannel(string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName(name);
    integer bytes = getStringBytes(message);
    if(llSubStringIndex(message, "/me") == 0)
    {
        llSay(0, message);
    }
    else if(llSubStringIndex(message, "'") == 0)
    {
        if(bytes <= 1021)
        {
            llSay(0, "/me" + message);
        }
        else
        {
            llSay(0, message);
        }
    }
    else
    {
        if(bytes <= 1020)
        {
            llSay(0, "/me " + message);
        }
        else
        {
            llSay(0, message);
        }
    }
    llSetObjectName(currentObjectName);
}

handleDescribeChannel(string message)
{
    integer firstSpace = llSubStringIndex(message, " ");
    while(firstSpace == 0)
    {
        message = llDeleteSubString(message, 0, 0);
        firstSpace = llSubStringIndex(message, " ");
    }
    string currentObjectName = llGetObjectName();
    if(firstSpace == -1)
    {
        llSetObjectName(".");
        llSay(0, "/me " + message);
    }
    else
    {
        llSetObjectName(llGetSubString(message, 0, firstSpace-1));
        message = llDeleteSubString(message, 0, firstSpace);
        integer bytes = getStringBytes(message);
        if(bytes <= 1020)
        {
            llSay(0, "/me " + message);
        }
        else
        {
            llSay(0, message);
        }
    }
    llSetObjectName(currentObjectName);
}

handleOocChannel(string message)
{
    string currentObjectName = llGetObjectName();
    llSetObjectName("((" + name);
    llSay(0, message + "))");
    llSetObjectName(currentObjectName);
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
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", <0, 0, 0>, 0]);
        reportTopReady("TITLER");
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
            attachSuccess("titler", rezzer);
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
        if(debugMode) llOwnerSay("Your TITLER is ready.");
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llListen(CG_OOC_CHANNEL, "", llGetOwner(), "");
        llListen(CG_IC_CHANNEL_1, "", llGetOwner(), "");
        llListen(CG_IC_CHANNEL_2, "", llGetOwner(), "");
        llListen(CG_DESCRIBE_CHANNEL, "", llGetOwner(), "");
        llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-attached");
        setTitle();
        llResetTime();
        llSetTimerEvent(5.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            string mode = getValueFromKey(dict, "mode");
            if(target != "client") return;
            if(mode == "detach" || mode == "detach-titler")
            {
                llDetachFromAvatar();
            }
            else if(mode == "set-state")
            {
                // Will get sent if the HUD changes character state.
                dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
                string new = getValueFromKey(dict, "state");
                if(new == "CMB")
                {
                    combatData = getValueFromKey(dict, "combat-data");
                    status = new;
                    llSetObjectDesc(status);
                    setTitle();
                    setRlv();
                }
                else if(status != new)
                {
                    status = getValueFromKey(dict, "state");
                    llSetObjectDesc(status);
                    setTitle();
                    setRlv();
                }
            }
            else if(mode == "titler-reload")
            {
                // Will trigger when the HUD feels the titler should update.
                load();
            }
            else if(mode == "hud-attached" && !responded)
            {
                responded = TRUE;
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-attached");
            }
        }
        
        if(slot == "0") return;
        if(channel == CG_IC_CHANNEL_1 || channel == CG_IC_CHANNEL_2)
        {
            handleIcChannel(message);
        }
        else if(channel == CG_DESCRIBE_CHANNEL)
        {
            handleDescribeChannel(message);
        }
        else if(channel == CG_OOC_CHANNEL)
        {
            handleOocChannel(message);
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
        if(slot != "0" && pos != llGetLocalPos())
        {
            pos = llGetLocalPos();
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-moved\npos=" + (string)pos);
        }

        if(responded == FALSE && llGetTime() > 15.0)
        {
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=detach");
            llDetachFromAvatar();
        }
    }

    dataserver(key t, string data)
    {
        if(mode == "load-basic" && token == t)
        {
            string retval = llList2String(llParseString2List(data, [","], []), 0);
            string value = llList2String(llParseString2List(data, [","], []), 1);
            list dict = llParseString2List(value, ["\n"], []);
            slot = getValueFromKey(dict, "slot");
            if(retval == "0" || value == "NEW" || slot == "NONE")
            {
                slot = "0";
                mode = "";
                setTitle();
            }
            else
            {
                rlv = getValueFromKey(dict, "rlv");
                if(rlv == "1")
                {
                    rlvOn();
                }
                else
                {
                    rlvOff();
                }
                combatData = getValueFromKey(dict, "combat-data");
                load();
            }
        }
        else if(mode == "load-character" && token == t)
        {
            string retval = llList2String(llParseString2List(data, [","], []), 0);
            string value = llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ",");
            list dict = llParseString2List(value, ["\n"], []);
            if(retval == "1")
            {
                name = getValueFromKey(dict, "display-name");
                fullName = getValueFromKey(dict, "name");
                pos = (vector)getValueFromKey(dict, "title-pos");
                llSetPos(pos);
                if(name == "") name = fullName;
                load();
            }
            else
            {
                mode = "";
                setTitle();
            }
        }
        else if(mode == "load-title" && token == t)
        {
            string retval = llList2String(llParseString2List(data, [","], []), 0);
            string value = llList2String(llParseString2List(data, [","], []), 1);
            if(retval == "1")
            {
                title = llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ",");
                mode = "";
                setTitle();
            }
            else
            {
                mode = "";
                setTitle();
            }
        }
    }
}
