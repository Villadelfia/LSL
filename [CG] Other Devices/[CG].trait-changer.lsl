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

key using;
key target;
string slot = "";
string name = "";
string displayName = "";
string atk = "";
string def = "";
string trait1 = "";
string trait1ts = "";
string trait2 = "";
string trait2ts = "";
string level = "";
string xp = "";
string titlePos = "";
string changing = "";
list staff = [];
integer channel;
integer listener;
string mode = "";
key token;

integer isStaff(key id)
{
    return llListFindList(staff, [(string)id]) != -1;
}

save()
{
    token = llUpdateKeyValue((string)target + "character" + slot, 
            "slot=" + slot + 
            "\nname=" + name + 
            "\ndisplay-name=" + displayName + 
            "\natk=" + atk + 
            "\ndef=" + def+
            "\ntrait1=" + trait1 +
            "\ntrait1ts=" + trait1ts +
            "\ntrait2=" + trait2 +
            "\ntrait2ts=" + trait2ts +
            "\nlevel=" + level +
            "\nxp=" + xp +
            "\ntitle-pos=" + titlePos, FALSE, "");
    if(llGetAgentSize(target) != ZERO_VECTOR)
    {
        llRegionSayTo(target, 0, "A staff member has changed one of your traits. You can use your HUD to see what was changed.");
    }
}

default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=get-settings");
    }
    
    touch_start(integer num)
    {
        if(isStaff(llDetectedKey(0)))
        {
            channel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
            llListenRemove(listener);
            using = llDetectedKey(0);
            listener = llListen(channel, "", using, "");
            mode = "askid";
            slot = "";
            name = "";
            displayName = "";
            atk = "";
            def = "";
            trait1 = "";
            trait1ts = "";
            trait2 = "";
            trait2ts = "";
            level = "";
            xp = "";
            titlePos = "";
            llTextBox(using, "Give the username of the person whose trait you wish to alter in the form firstname.lastname, or just firstname for people without a last name.", channel);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            if(target != "server") return;
    
            string mode = getValueFromKey(dict, "mode");
            string agentKey = getValueFromKey(dict, "agent-key");
    
            if(mode == "clear-settings")
            {
                log("Clearing settings...");
                staff = [];
            }
            else if(mode == "add-staff")
            {
                log("Adding " + agentKey + " to the staff registry...");
                staff += agentKey;
            }
        }
        else if(mode == "askid")
        {
            token = llRequestUserKey((string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []));
        }
        else if(mode == "askslot")
        {
            slot = (string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []);
            token = llReadKeyValue((string)target + "character" + (string)slot);
        }
        else if(mode == "askwhich")
        {
            changing = message;
            mode = "selecttrait";
            llTextBox(using, "Changing " + changing + ".\n\nWhat do you want to change the trait to?", channel);
        }
        else if(mode == "selecttrait")
        {
            message = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            message = strreplace(message, "=", "");
            if(changing == "TRAIT 1")
            {
                trait1 = message;
            }
            else
            {
                trait2 = message;
            }
            mode = "timer";
            llDialog(using, "Changing " + changing + " to \"" + message + "\"\n\nDo you want to set it as immediately available, leave the timer unchanged, or set it unavailable for a week?\n\nIf changing a typo or making any other small change you should leave it unchanged in most cases.", ["NO CHANGE", "AVAILABLE", "UNAVAILABLE"], channel);
        }
        else if(mode == "timer")
        {
            integer ts = 0;
            if(message == "AVAILABLE")
            {
                ts = llGetUnixTime() - (3600*24*7);
            }
            else if(message == "UNAVAILABLE")
            {
                ts = llGetUnixTime();
            }

            if(ts != 0 && changing == "TRAIT 1")
            {
                trait1ts = (string)ts;
            }
            else if(ts != 0 && changing == "TRAIT 2")
            {
                trait2ts = (string)ts;
            }

            save();
            llRegionSayTo(using, 0, "Saved character with updated settings...");
        }
    }

    dataserver(key t, string data) 
    {
        if(t == token && mode == "askid" && (key)data != NULL_KEY)
        {
            target = (key)data;
            mode = "askslot";
            llTextBox(using, "Give the slot of the character who's trait you wish to alter.", channel);
        }
        else if(t == token && mode == "askslot")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(using, 0, "There is no character in the chosen slot.");
            }
            else
            {
                list dict = llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []);
                slot = getValueFromKey(dict, "slot");
                name = getValueFromKey(dict, "name");
                displayName = getValueFromKey(dict, "display-name");

                atk = getValueFromKey(dict, "atk");
                def = getValueFromKey(dict, "def");

                trait1 = getValueFromKey(dict, "trait1");;
                trait1ts = getValueFromKey(dict, "trait1ts");
                trait2 = getValueFromKey(dict, "trait2");
                trait2ts = getValueFromKey(dict, "trait2ts");

                level = getValueFromKey(dict, "level");
                xp = getValueFromKey(dict, "xp");

                titlePos = getValueFromKey(dict, "title-pos");
                mode = "askwhich";
                llDialog(using, "Character name: " + name + "\nTrait 1: " + trait1 + "\nTrait 2: " + trait2 + "\n\nWhich trait do you want to change?", ["TRAIT 1", "TRAIT 2"], channel);
            }
        }
    }
}
