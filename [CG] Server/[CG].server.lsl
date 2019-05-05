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
list teleportNames = [];
list teleportImages = [];
list teleportLocations = [];
list teleportLookats = [];
list staffTeleportNames = [];
list staffTeleportImages = [];
list staffTeleportLocations = [];
list staffTeleportLookats = [];

integer scriptAgentsBusy = 0;
integer scriptAgentsAvailable = 0;

integer isStaff(key id)
{
    return llListFindList(staff, [(string)id]) != -1;
}

determineAvailableAgents()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string item;
    while(count--)
    {
        item = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(startswith(item, "[CG]rezzer"))
        {
            scriptAgentsAvailable++;
        }
    }
    if(debugMode) log("Got " + (string)scriptAgentsAvailable + " rezzing agents...");
}

default
{
    state_entry()
    {
        if(debugMode) log("Resetting Crystalgate server.");
        resetAllOther();
        llSetRemoteScriptAccessPin(CG_PIN);
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        determineAvailableAgents();
        llSetTimerEvent(2.5);
        llResetTime();
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=get-settings");
    }
   
    on_rez(integer start)
    {
        resetAll();
    }
   
    touch_start(integer num)
    {
        if(isStaff(llDetectedKey(0)))
        {
            llRegionSayTo(llDetectedKey(0), 0, "Resetting...");
            llResetScript();
        }
    }
   
    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == SERVER_AGENT_READY)
        {
            scriptAgentsBusy--;
        }
    }
   
    listen(integer channel, string name, key id, string message)
    {
        list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
        string target = getValueFromKey(dict, "target");
        if(target != "server") return;

        string mode = getValueFromKey(dict, "mode");
        string agentKey = getValueFromKey(dict, "agent-key");

        if(mode == "clear-settings")
        {
            log("Settings cleared...");
            staff = [];
            teleportNames = [];
            teleportImages = [];
            teleportLocations = [];
            teleportLookats = [];
            staffTeleportNames = [];
            staffTeleportImages = [];
            staffTeleportLocations = [];
            staffTeleportLookats = [];
        }
        else if(mode == "add-staff")
        {
            log("Adding " + agentKey + " to the staff registry...");
            staff += agentKey;
        }
        else if(mode == "add-teleport-public")
        {
            string name = getValueFromKey(dict, "name");
            string image = getValueFromKey(dict, "image");
            string pos = getValueFromKey(dict, "pos");
            string lookat = getValueFromKey(dict, "lookat");
            log("Adding " + name + " to the public teleport registry...");
            teleportNames += name;
            teleportImages += image;
            teleportLocations += pos;
            teleportLookats += lookat;
        }
        else if(mode == "add-teleport-staff")
        {
            string name = getValueFromKey(dict, "name");
            string image = getValueFromKey(dict, "image");
            string pos = getValueFromKey(dict, "pos");
            string lookat = getValueFromKey(dict, "lookat");
            log("Adding " + name + " to the public teleport registry...");
            staffTeleportNames += name;
            staffTeleportImages += image;
            staffTeleportLocations += pos;
            staffTeleportLookats += lookat;
        }
        else if(mode == "is-staff")
        {
            if(isStaff(agentKey))
            {
                llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=is-staff\nagent-key=" + agentKey + "\nvalue=1");
            }
            else
            {
                llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=is-staff\nagent-key=" + agentKey + "\nvalue=0");
            }
        }
        else if(mode == "teleport-count")
        {
            integer count = llGetListLength(teleportNames);
            if(isStaff(agentKey))
            {
                count += llGetListLength(staffTeleportNames);
            }
            llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=teleport-count\nvalue=" + (string)count);
        }
        else if(mode == "teleport-get")
        {
            integer index = (integer)getValueFromKey(dict, "index");
            string name;
            string image;
            string pos;
            string lookat;
            if(index >= llGetListLength(teleportNames))
            {
                integer offset = llGetListLength(teleportNames);
                name = llList2String(staffTeleportNames, index - offset);
                image = llList2String(staffTeleportImages, index - offset);
                pos = llList2String(staffTeleportLocations, index - offset);
                lookat = llList2String(staffTeleportLookats, index - offset);
            }
            else
            {
                name = llList2String(teleportNames, index);
                image = llList2String(teleportImages, index);
                pos = llList2String(teleportLocations, index);
                lookat = llList2String(teleportLookats, index);
            }
            llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=teleport-get\nindex=" + (string)index + "\nname=" + name + "\nimage=" + image + "\npos=" + pos + "\nlookat=" + lookat);
        }
        else if(mode == "rez-clue")
        {
            llMessageLinked(LINK_THIS, SERVER_REZ_CLUE, "", (key)agentKey);
        }
        else if(mode == "give-spellbook")
        {
            llGiveInventory((key)agentKey, "[CG] SPELLBOOK");
        }
        else if(mode == "webhook")
        {
            string json = llList2Json(JSON_OBJECT, ["text", strreplace(getValueFromKey(dict, "message"), "###", "\n"), "username", getValueFromKey(dict, "name")]);
            llHTTPRequest(DISCORD_WEBHOOK, [HTTP_METHOD, "POST"], json);
        }
        else if(mode == "staff-webhook")
        {
            string json = llList2Json(JSON_OBJECT, ["text", strreplace(getValueFromKey(dict, "message"), "###", "\n"), "username", getValueFromKey(dict, "name")]);
            llHTTPRequest(DISCORD_STAFF_WEBHOOK, [HTTP_METHOD, "POST"], json);
        }
        else if(mode == "character-webhook")
        {
            string m = " has created a new character in slot " + getValueFromKey(dict, "slot") + ":\n" + 
                                            "\nUsername: " + llKey2Name(agentKey) +
                                            "\nSlot: " + getValueFromKey(dict, "slot") +
                                            "\nName: " + getValueFromKey(dict, "name") +
                                            "\nOffensive Specialty: " + llToUpper(getValueFromKey(dict, "atk")) +
                                            "\nDefensive Specialty: " + llToUpper(getValueFromKey(dict, "def")) +
                                            "\nTrait 1: " + getValueFromKey(dict, "trait1") +
                                            "\nTrait 2: " + getValueFromKey(dict, "trait2") +
                                            "\n\nPlease review their two traits as soon as possible by going to the bright red server marked STAFF CALLER in the server room.";

            string json = llList2Json(JSON_OBJECT, ["text", llKey2Name(agentKey) + m + " Remove this message when you have.", "username", "Character Creation Notification"]);
            llHTTPRequest(DISCORD_STAFF_WEBHOOK, [HTTP_METHOD, "POST"], json);

            integer i = llGetListLength(staff) - 1;
            for(;i >= 0; --i)
            {
                key staffMember = (key)llList2String(staff, i);
                if(llGetAgentSize(staffMember) != ZERO_VECTOR)
                {
                    llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about" + m);
                }
                else
                {
                    llInstantMessage(staffMember, llKey2Name(agentKey) + m);
                }
            }
        }
        else if(mode == "private-webhook")
        {
            string json = llList2Json(JSON_OBJECT, ["text", strreplace(getValueFromKey(dict, "message"), "###", "\n"), "username", getValueFromKey(dict, "name")]);
            llHTTPRequest(DISCORD_PRIVATE_WEBHOOK, [HTTP_METHOD, "POST"], json);
        }
    }

    timer()
    {
        if(scriptAgentsBusy != 0 && llGetTime() < 15.0) 
        {
            if(llGetTime() < 20.0)
            {
                return;
            }
            else
            {
                log("Something is taking too long... Resetting server.");
                resetAll();
            }
        }
        llResetTime();
        list agents = llGetAgentList(AGENT_LIST_REGION, []);
        integer i = llGetListLength(agents) - 1;
        for(; i >= 0; --i)
        {
            key agent = llList2Key(agents, i);
            if(llAgentInExperience(agent))
            {
                list attachments = llGetAttachedList(agent);
                integer j = llGetListLength(attachments) - 1;
                integer mustRez = TRUE;
                for(; j >= 0; --j)
                {
                    list details = llGetObjectDetails(llList2Key(attachments, j), [OBJECT_TEMP_ATTACHED, OBJECT_CREATOR, OBJECT_NAME]);
    
                    if((llList2Integer(details, 0) == 1 && llList2Key(details, 1) == developerUuid) || (llList2String(details, 2) == "DEVELOPMENT_TOKEN" && llList2Key(details, 1) == developerUuid && agent == (key)developerUuid))
                    {
                        mustRez = FALSE;
                    }
                }
            
                if(mustRez == TRUE && llGetAgentSize(agent) != ZERO_VECTOR)
                {
                    if(debugMode) log("Rezzing something for " + (string)agent);
                    llMessageLinked(LINK_THIS, SERVER_DETERMINE_REZ, (string)scriptAgentsBusy, agent);
                    scriptAgentsBusy++;
                }
            
                if(scriptAgentsBusy == scriptAgentsAvailable)
                {
                    return;
                }
            }
        }
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        if(body != "ok")
        {
            llInstantMessage(developerUuid, "Warning: A call to the Discord Webhook was rejected with the message: " + body);
        }
    }
}