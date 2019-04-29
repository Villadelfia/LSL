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
/*
denyAndRemove(integer x)
{
    removing = x;
    mode = "get";
    string agent = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 0);
    string slot = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 1);
    token = llReadKeyValue(agent + "character" + slot);
}

getInfo(integer x)
{
    removing = x;
    mode = "info";
    string agent = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 0);
    string slot = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 1);
    token = llReadKeyValue(agent + "character" + slot);
}

nag()
{
    integer i = llGetListLength(staff) - 1;
    integer x = llGetListLength(awaiting);
    for(;i >= 0; --i)
    {
        key staffMember = (key)llList2String(staff, i);
        if(llGetAgentSize(staffMember) != ZERO_VECTOR)
        {
            llRegionSayTo(staffMember, 0, "There are " + (string)x + " trait requests awaiting your attention in the staff room. Clicking the emergency lamp there will allow you to handle requests.");
        }
    }
}

summary(key k)
{
    llRegionSayTo(k, 0, "There are currently " + (string)llGetListLength(awaiting) + " awaiting traits:");
    integer x = llGetListLength(awaiting);
    integer i;
    for(i = 0; i < x; ++i)
    {
        string id = llList2String(llParseString2List(llList2String(awaiting, i), [";"], []), 0);
        string slot = llList2String(llParseString2List(llList2String(awaiting, i), [";"], []), 1);
        string trait = llList2String(llParseString2List(llList2String(awaiting, i), [";"], []), 2);
        llRegionSayTo(k, 0, (string)i + ": secondlife:///app/agent/" + id + "/about for slot " + slot + ", trait " + trait + ".");
    }
    llRegionSayTo(k, 0, "Type 'info X' where X is a number from the list above to see the trait they chose, and then type 'approve X' to approve it or type 'deny X' to deny it. If you deny it, it may be prudent to message the player with your reasoning.\n\n");
}*/

default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llListen(0, "", NULL_KEY, "");
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
            llTextBox(using, "Give the username of the person whose trait you wish to approve/deny in the form firstname.lastname, or just firstname for people without a last name.", channel);
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
            else if(mode == "page-staff")
            {
                integer i = llGetListLength(staff);
                integer x = 0;
                for(;i >= 0; --i)
                {
                    key staffMember = (key)llList2String(staff, i);
                    if(llGetAgentSize(staffMember) != ZERO_VECTOR)
                    {
                        llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about has requested an admin via the HUD.");
                        x++;
                    }
                }
                if(x == 0)
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Staff Request\nmessage=" + llKey2Name(agentKey) + "has requested an admin via the HUD, but no staff is present on the sim. Please get to them as soon as possible, and remove this message when you have.");
                }
                llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=page-staff\namount=" + (string)x);
            }
            else if(mode == "trait-alert")
            {
                string slot = getValueFromKey(dict, "slot");
                string trait = getValueFromKey(dict, "trait");
                if(trait == "1")
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Trait Approval Request\nmessage=" + llKey2Name(agentKey) + "has set their first trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. Remove this message when you have.###Name: " + llKey2Name(agentKey) + "###Trait: 1###Slot: " + slot);
                }
                else
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Trait Approval Request\nmessage=" + llKey2Name(agentKey) + "has set their second trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. . Remove this message when you have.###Name: " + llKey2Name(agentKey) + "###Trait: 2###Slot: " + slot);
                }

                integer i = llGetListLength(staff) - 1;
                string n = llKey2Name((key)agentKey);
                for(;i >= 0; --i)
                {
                    key staffMember = (key)llList2String(staff, i);
                    if(llGetAgentSize(staffMember) != ZERO_VECTOR)
                    {
                        if(trait == "1")
                        {
                            llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about has set their first trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. .");
                        }
                        else
                        {
                            llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about has set their second trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. .");
                        }
                        
                    }
                    else
                    {
                        if(trait == "1")
                        {
                            llInstantMessage(staffMember, "secondlife:///app/agent/" + agentKey + "/about (" + n + ") has set their first trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. .");
                        }
                        else
                        {
                            llInstantMessage(staffMember, "secondlife:///app/agent/" + agentKey + "/about (" + n + ") has set their second trait for their character in slot " + slot + ". Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. .");
                        }
                    }
                }
            }
        }
        else
        {
            if(id != lastStaff && llGetOwnerKey(id) != lastStaff) return;
            message = llToLower(message);
            if(startswith(message, "accept ") || startswith(message, "approve "))
            {
                integer x = (integer)llList2String(llParseString2List(message, [" "], []), 1);
                string agent = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 0);
                string slot = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 1);
                string trait = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 2);
                llRegionSayTo(id, 0, "Accepting trait " + trait + " for secondlife:///app/agent/" + agent + "/about's character in slot " + slot + ".\n\n");
                llInstantMessage(agent, "Trait " + trait + " of your character in slot " + slot + " has been approved!");
                awaiting = llDeleteSubList(awaiting, x, x);
                summary(lastStaff);
            }
            else if(startswith(message, "deny "))
            {
                integer x = (integer)llList2String(llParseString2List(message, [" "], []), 1);
                string agent = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 0);
                string slot = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 1);
                string trait = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 2);
                llRegionSayTo(id, 0, "Denying trait " + trait + " for secondlife:///app/agent/" + agent + "/about's character in slot " + slot + ".\n\n");
                denyAndRemove(x);
            }
            else if(startswith(message, "info "))
            {
                integer x = (integer)llList2String(llParseString2List(message, [" "], []), 1);
                string agent = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 0);
                string slot = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 1);
                string trait = llList2String(llParseString2List(llList2String(awaiting, x), [";"], []), 2);
                getInfo(x);
            }
        }
    }
    
    timer()
    {
        lastStaff = NULL_KEY;
        if(llGetListLength(awaiting) != 0)
        {
            nag();
        }
    }

    dataserver(key t, string data) 
    {
        if(t == token && mode == "get")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(lastStaff, 0, "Something went wrong denying the request... Try again please.");
                summary(lastStaff);
                return;
            }
            string agent = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 0);
            string trait = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 2);

            list dict = llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []);
            string slot = getValueFromKey(dict, "slot");
            string name = getValueFromKey(dict, "name");
            string displayName = getValueFromKey(dict, "display-name");

            string atk = getValueFromKey(dict, "atk");
            string def = getValueFromKey(dict, "def");

            string trait1 = getValueFromKey(dict, "trait1");
            string trait1ts = getValueFromKey(dict, "trait1ts");
            string trait2 = getValueFromKey(dict, "trait2");
            string trait2ts = getValueFromKey(dict, "trait2ts");

            string level = getValueFromKey(dict, "level");
            string xp = getValueFromKey(dict, "xp");

            string titlePos = getValueFromKey(dict, "title-pos");

            if(trait == "1")
            {
                trait1 = "None.";
            }
            else if(trait == "2")
            {
                trait2 = "None.";
            }
            mode = "del";
            token = llUpdateKeyValue((string)agent + "character" + slot, 
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
        }
        else if(t == token && mode == "info")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(lastStaff, 0, "Something went wrong getting info... Try again please.");
                summary(lastStaff);
                return;
            }
            string agent = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 0);
            string trait = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 2);

            list dict = llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []);
            string slot = getValueFromKey(dict, "slot");
            string trait1 = getValueFromKey(dict, "trait1");
            string trait2 = getValueFromKey(dict, "trait2");

            if(trait == "1")
            {
                llRegionSayTo(lastStaff, 0, "secondlife:///app/agent/" + agent + "/about's character in slot " + slot + " has the following first trait awaiting approval: " + trait1);
            }
            else if(trait == "2")
            {
                llRegionSayTo(lastStaff, 0, "secondlife:///app/agent/" + agent + "/about's character in slot " + slot + " has the following second trait awaiting approval: " + trait2);
            }
            summary(lastStaff);
        }
        else if(t == token && mode == "del")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(lastStaff, 0, "Something went wrong denying the request... Try again please.");
                summary(lastStaff);
                return;
            }
            
            string agent = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 0);
            string slot = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 1);
            string trait = llList2String(llParseString2List(llList2String(awaiting, removing), [";"], []), 2);
            llInstantMessage(agent, "Trait " + trait + " of your character in slot " + slot + " has been denied and has been set to 'None'. You may contact an admin to see how you might change your proposed trait to better fit within the power level of this sim, or you can choose another from the HUD.");
            awaiting = llDeleteSubList(awaiting, removing, removing);
            summary(lastStaff);
        }
    }
}
