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

integer ncLine = 0;
string ncName = ".masterlist";
integer i = 0;
list names = [];
list staff = [];
key token;

integer isStaff(key id)
{
    return llListFindList(staff, [(string)id]) != -1;
}

default
{
    state_entry()
    {
        llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=clear-spells");
        token = llGetNotecardLine(ncName, ncLine);
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
        string target = getValueFromKey(dict, "target");
        if(target != "server") return;

        string agentKey = getValueFromKey(dict, "agent-key");
        if(agentKey == "") return;

        string mode = getValueFromKey(dict, "mode");

        if(mode == "give-spell")
        {
            integer spell = (integer)getValueFromKey(dict, "spell");
            llGiveInventory((key)agentKey, llList2String(names, spell));
        }
        else if(mode == "spell-name")
        {
            integer spell = (integer)getValueFromKey(dict, "spell");
            llRegionSayTo((key)agentKey, CG_IPC_CHANNEL, "target=client\nmode=spell-name\nagent-key=" + agentKey +"\nname=" + llList2String(names, spell));
        }
    }
 
    dataserver(key t, string data)
    {
        if(t == token && ncName == ".masterlist")
        {
            if(data == EOF)
            {
                llOwnerSay("Done reading spells. Getting staff...");
                ncLine = 0;
                ncName = ".staff";
                llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
                token = llGetNotecardLine(ncName, ncLine);
                return;
            }
            else
            {
                ++ncLine;
                integer id = (integer)llList2String(llParseString2List(data, [";"], []), 0);
                string name = llList2String(llParseString2List(data, [";"], []), 1);
                while(i < id)
                {
                    ++i;
                    names += "REMOVED";
                    llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=add-spell\nindex=" + (string)(i-1) + "\nname=REMOVED");
                }
                ++i;
                names += name;
                llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=add-spell\nindex=" + (string)(i-1) + "\nname=" + name);
                token = llGetNotecardLine(ncName, ncLine);
            }
        }
        else if(t == token)
        {
            if(data == EOF)
            {
                llOwnerSay("Done reading staff. Idling...");
                return;
            }
            else
            {
                ++ncLine;
                data = llStringTrim(llList2String(llParseStringKeepNulls(llStringTrim(data, STRING_TRIM), ["#"], []), 0), STRING_TRIM);
                staff += data;
                llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=add-spell-staff\nagent-key=" + data);
                token = llGetNotecardLine(ncName, ncLine);
            }
        }
    }

    touch_start(integer num)
    {
        if(isStaff(llDetectedKey(0)))
        {
            llRegionSayTo(llDetectedKey(0), 0, "Resetting...");
            llResetScript();
        }
    }
}