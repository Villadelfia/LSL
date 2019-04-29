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
key notecardQueryId;
string notecardName;
integer notecardLine;
string handling = "";
 
default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    
        notecardLine = 0;
        notecardName = llGetInventoryName(INVENTORY_NOTECARD, notecardLine);
        
        log("Sending new settings...");
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=clear-settings");
        notecardQueryId = llGetNotecardLine(notecardName, notecardLine);
    }
        
    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
    
    on_rez(integer param)
    {
        llResetScript();
    }
    
    dataserver(key query_id, string data)
    {
        if(query_id == notecardQueryId)
        {
            if(data == EOF)
            {
                log("Done sending settings. Read " + (string) notecardLine + " notecard lines.");
                return;
            }
            
            data = llStringTrim(llList2String(llParseStringKeepNulls(llStringTrim(data, STRING_TRIM), ["#"], []), 0), STRING_TRIM);
            
            if(data != "SERVER_STAFF" && data != "SERVER_TELEPORT_PUBLIC" && data != "SERVER_TELEPORT_STAFF")
            {
                if(handling == "SERVER_STAFF" && data != "")
                {
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=add-staff\nagent-key=" + data);
                }
                else if(handling == "SERVER_TELEPORT_PUBLIC" && data != "")
                {
                    list tokens = llParseString2List(data, [";"], []);
                    string name = llList2String(tokens, 0);
                    string image = llList2String(tokens, 1);
                    string pos = llList2String(tokens, 2);
                    string lookat = llList2String(tokens, 3);
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=add-teleport-public\nname=" + name + "\nimage=" + image + "\npos=" + pos + "\nlookat=" + lookat);
                }
                else if(handling == "SERVER_TELEPORT_STAFF" && data != "")
                {
                    list tokens = llParseString2List(data, [";"], []);
                    string name = llList2String(tokens, 0);
                    string image = llList2String(tokens, 1);
                    string pos = llList2String(tokens, 2);
                    string lookat = llList2String(tokens, 3);
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=add-teleport-staff\nname=" + name + "\nimage=" + image + "\npos=" + pos + "\nlookat=" + lookat);
                }
            }
            
            if(data == "SERVER_STAFF")
            {
                handling = "SERVER_STAFF";
                log("Sending staff settings...");
            }
            else if(data == "SERVER_TELEPORT_PUBLIC")
            {
                handling = "SERVER_TELEPORT_PUBLIC";
                log("Sending public teleport settings...");
            }
            else if(data == "SERVER_TELEPORT_STAFF")
            {
                handling = "SERVER_TELEPORT_STAFF";
                log("Sending staff teleport settings...");
            }
            
            ++notecardLine;
            notecardQueryId = llGetNotecardLine(notecardName, notecardLine);
        }
    }
    
    listen(integer c, string n, key k, string m)
    {
        list dict = llParseString2List(m, ["\n", "!~~DELIM~~!"], []);
        string target = getValueFromKey(dict, "target");
        if(target != "server") return;

        string mode = getValueFromKey(dict, "mode");
        if(mode == "get-settings")
        {
            llResetScript();
        }
    }
}