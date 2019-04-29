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

string message = "Suggestions?\nQuestions?\nIdea for an event?\nImpressive RP?\n \nPlease drop a notecard here!";
key owner;
key agent;
string scriptName;

default
{
    state_entry()
    {
        owner = llGetOwner();
        scriptName = llGetScriptName();
        llSetText(message + "\n \n \n \n \n", <1.0, 1.0, 1.0>, 1.0);
        llAllowInventoryDrop(TRUE);
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    }

    touch_start(integer total_number)
    {
        agent = llDetectedKey(0);
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=is-staff\nagent-key=" + (string)agent);
    }
    
    changed(integer mask)
    {
        if(mask & CHANGED_ALLOWED_DROP || mask & CHANGED_INVENTORY) 
        {
            llSetText(message + "\n \n[NEW MAIL]\n \n \n \n \n", <0.0, 1.0, 0.0>, 1.0);
        }
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(msg, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            if(target != "client") return;
    
            string mode = getValueFromKey(dict, "mode");
            string value = getValueFromKey(dict, "value");
            string agentKey = getValueFromKey(dict, "agent-key");
            
            if(mode == "is-staff" && agent == agentKey)
            {
                if(value == "1")
                {
                    llDialog(agent, "What do you want to do?", ["Get All", "Delete All"], mailboxChannel);
                }
                agent = NULL_KEY;
            }
        }
        if(channel == mailboxChannel)
        {
            if(msg == "Get All")
            {
                list items;
                integer index = 0;
                integer folderNumber = 1;
                integer count = llGetInventoryNumber(INVENTORY_ALL);
                integer useNumber = count > 43;
                if(count > 1)
                {
                    while(index < count)
                    {
                        // Append item to list.
                        string itemName = llGetInventoryName(INVENTORY_ALL, index);
                        integer itemType = llGetInventoryType(itemName);
                        if(itemType != INVENTORY_SCRIPT && itemName != scriptName)
                        {
                            items += itemName;
                        }
                        
                        // Increment index.
                        index ++;
                        
                        // See if folder needs to be given.
                        if(index == count || llGetListLength(items) == 42)
                        {
                            if(useNumber)
                            {
                                llGiveInventoryList(agent, "Crystalgate Mailbox - " + (string)folderNumber, items);
                                folderNumber++;
                            }
                            else
                            {
                                llGiveInventoryList(agent, "Crystalgate Mailbox", items);
                            }
                            items = [];
                        }
                    }
                }
            }
            else if(msg == "Delete All")
            {
                integer index = llGetInventoryNumber(INVENTORY_ALL);
                
                while(index)
                {
                    --index;
     
                    string itemName = llGetInventoryName(INVENTORY_ALL, index);
                    integer itemType = llGetInventoryType(itemName);
     
                    if (itemType != INVENTORY_SCRIPT && itemName != scriptName)
                    {
                        llRemoveInventory(itemName);
                        index = llGetInventoryNumber(INVENTORY_ALL);
                    }
                }
                llSetText(message + "\n \n \n \n \n", <1.0, 1.0, 1.0>, 1.0);
            }
        }
    }
}
