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

list staff = [];
float last_activated;
string slurl;
vector COLOR_WHITE = <1.0, 1.0, 1.0>;
vector COLOR_GREEN = <0.0, 1.0, 0.0>;
float OPAQUE = 1.0;
string READY_TEXT = "Hit the bell for an admin!";
string PAGING_TEXT = "Paging...\n \n ";
string LOCATION;
integer handle;
key user = NULL_KEY;
integer mutex = FALSE;
integer channel;

default
{
    state_entry()
    {
        last_activated = llGetTime() - 300.0;
        LOCATION = llGetObjectDesc();
        vector pos = llGetPos();
        string region = llGetRegionName();
        slurl = "secondlife://" + llEscapeURL(region) + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y) + "/" + (string)llRound(pos.z);
        llSetText(READY_TEXT, COLOR_WHITE, OPAQUE);
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=get-settings");
    }
    
    listen(integer c, string name, key id, string message)
    {
        if(c == CG_IPC_CHANNEL)
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
            return;
        }

        llSetTimerEvent(0.0);
        llListenRemove(handle);
        user = NULL_KEY;
        if(message == "Yes")
        {
            mutex = TRUE;
            last_activated = llGetTime();
            llSetText(PAGING_TEXT, COLOR_GREEN, OPAQUE);
            llPlaySound("9c29715f-8951-ac50-da8a-d3db772a20b5",1);
        
            integer x;
            integer length = llGetListLength(staff);
            key currently_paging;
            string display_name;
            integer sent = 0;
            for(x = 0; x < length; x++)
            {
                currently_paging = llList2Key(staff, x);
                display_name = llGetDisplayName(currently_paging);
                if(llGetAgentSize(currently_paging) != ZERO_VECTOR)
                {
                    if(display_name == "" || display_name == "???")
                    {
                        display_name = llGetDisplayName(currently_paging);
                    }
                    llSetText("Paging " + display_name + "...\n \n ", COLOR_GREEN, OPAQUE);
                    llRegionSayTo(currently_paging, 0, "secondlife:///app/agent/" + (string)id + "/about has requested an admin at " + LOCATION + ": " + slurl);
                    sent++;
                }
            }
            if(sent == 0)
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Staff Request\nmessage=" + llKey2Name(id) + " has requested an admin at " + LOCATION + ", but no staff is present on the sim. Please get to them as soon as possible at " + slurl + ", and remove this message when you have.");
            }
            llSetText(READY_TEXT, COLOR_WHITE, OPAQUE);
            mutex = FALSE;
        }
    }
    
    touch_start(integer total_number)
    {
        key clicker = llDetectedKey(0);

        if(llVecDist(llDetectedPos(0), llGetPos()) > 5.0)
        {
            llRegionSayTo(clicker, 0, "You need to be within 5 meters to click the bell...");
        }
        else if(llGetTime() - last_activated < 300.0)
        {
            llDialog(clicker, "\nThe bell has been rang in the last five minutes... Please wait.", ["OK"], -1);
        }
        else if(user)
        {
            llDialog(clicker, "\nSomeone else is using the bell... Please wait.", ["OK"], -1);
        }
        else if(mutex == TRUE)
        {
            llDialog(clicker, "\nThe bell is still in the process of paging... Please wait.", ["OK"], -1);
        }
        else
        {
            user = clicker;
            channel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
            handle = llListen(channel, "", clicker, "");
            llDialog(clicker, "\nDo you wish to page a member of staff?\n \n(Timeout in 30 seconds.)", ["Yes", "No"], channel);
            llSetTimerEvent(30.0);
        }
    }
    
    timer()
    {
        llListenRemove(handle);
        llSetTimerEvent(0.0);
        if(user)
        {
            llInstantMessage(user, "Timed out... You must click the bell again if you wish to use it.");
            user = NULL_KEY;
        }
    }
}
