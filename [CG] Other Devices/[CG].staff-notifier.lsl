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
string choice;
string targetName;
string changedTrait;

integer isStaff(key id)
{
    return llListFindList(staff, [(string)id]) != -1;
}

save()
{
    mode = "save";
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
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Staff Request\nmessage=" + llKey2Name(agentKey) + " has requested an admin via the HUD, but no staff is present on the sim. Please get to them as soon as possible, and remove this message when you have.");
                }
                llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=page-staff\namount=" + (string)x);
            }
            else if(mode == "trait-alert")
            {
                string slot = getValueFromKey(dict, "slot");
                string trait = getValueFromKey(dict, "trait");
                string value = getValueFromKey(dict, "value");
                if(trait == "1")
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Trait Approval Request\nmessage=" + llKey2Name(agentKey) + " has set their first trait for their character in slot " + slot + ":######'" + value + "'######Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. Remove this message when you have.######Name: " + llKey2Name(agentKey) + "###Slot: " + slot + "###Trait: 1");
                }
                else
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Trait Approval Request\nmessage=" + llKey2Name(agentKey) + " has set their second trait for their character in slot " + slot + ":######'" + value + "'######Please review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room. Remove this message when you have.######Name: " + llKey2Name(agentKey) + "###Slot: " + slot + "###Trait: 2");
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
                            llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about has set their first trait for their character in slot " + slot + ":\n\n'" + value + "'\n\nPlease review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room.");
                        }
                        else
                        {
                            llRegionSayTo(staffMember, 0, "secondlife:///app/agent/" + agentKey + "/about has set their second trait for their character in slot " + slot + ":\n\n'" + value + "'\n\nPlease review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room.");
                        }
                        
                    }
                    else
                    {
                        if(trait == "1")
                        {
                            llInstantMessage(staffMember, "secondlife:///app/agent/" + agentKey + "/about (" + n + ") has set their first trait for their character in slot " + slot + ":\n\n'" + value + "'\n\nPlease review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room.");
                        }
                        else
                        {
                            llInstantMessage(staffMember, "secondlife:///app/agent/" + agentKey + "/about (" + n + ") has set their second trait for their character in slot " + slot + ":\n\n'" + value + "'\n\nPlease review it as soon as possible by going to the bright red server marked STAFF CALLER in the server room.");
                        }
                    }
                }
            }
        }

        if(id != using) return;

        if(mode == "askid")
        {
            targetName = (string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []);
            token = llRequestUserKey(targetName);
        }
        else if(mode == "askslot")
        {
            slot = (string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []);
            token = llReadKeyValue((string)target + "character" + (string)slot);
        }
        else if(mode == "askwhich")
        {
            changing = message;
            mode = "acceptreject";
            if(changing == "TRAIT 1")
            {
                llDialog(using, "Trait 1:\n\n" + trait1 + "\n\nDo you wish to accept or deny this trait?", ["ACCEPT", "DENY"], channel);
            }
            else
            {
                llDialog(using, "Trait 2:\n\n" + trait2 + "\n\nDo you wish to accept or deny this trait?", ["ACCEPT", "DENY"], channel);
            }
        }
        else if(mode == "acceptreject")
        {
            choice = message;
            if(message == "ACCEPT")
            {
                if(changing == "TRAIT 1")
                {
                    changedTrait = trait1;
                    trait1 = "#" + trait1;
                }
                else
                {
                    changedTrait = trait2;
                    trait2 = "#" + trait2;
                }
                save();
            }
            else if(message == "DENY")
            {
                if(changing == "TRAIT 1")
                {
                    changedTrait = trait1;
                    trait1 = "#None.";
                }
                else
                {
                    changedTrait = trait2;
                    trait2 = "#None.";
                }
                save();
            }
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
                llDialog(using, "There is no character in the chosen slot.", ["OK"], -1);
            }
            else
            {
                list dict = llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []);
                slot = getValueFromKey(dict, "slot");
                name = getValueFromKey(dict, "name");
                displayName = getValueFromKey(dict, "display-name");

                atk = getValueFromKey(dict, "atk");
                def = getValueFromKey(dict, "def");

                trait1 = getValueFromKey(dict, "trait1");
                trait1ts = getValueFromKey(dict, "trait1ts");
                trait2 = getValueFromKey(dict, "trait2");
                trait2ts = getValueFromKey(dict, "trait2ts");

                level = getValueFromKey(dict, "level");
                xp = getValueFromKey(dict, "xp");

                titlePos = getValueFromKey(dict, "title-pos");
                mode = "askwhich";

                integer approvalState1 = FALSE;
                integer approvalState2 = FALSE;
                if(startswith(trait1, "#"))
                {
                    approvalState1 = TRUE;
                }
                if(startswith(trait2, "#"))
                {
                    approvalState2 = TRUE;
                }

                if(approvalState1 && approvalState2)
                {
                    llDialog(using, name + " has no unapproved traits. Please make sure to delete the message that asked you to approve a trait.", ["OK"], -1);
                }
                else if(approvalState1)
                {
                    llDialog(using, "Character name: " + name + "\nTrait 1: " + llGetSubString(trait1, 1, -1) + "\nTrait 2: " + trait2 + "\n\nWhich trait do you want to approve/deny?", ["TRAIT 2"], channel);
                }
                else if(approvalState2)
                {
                    llDialog(using, "Character name: " + name + "\nTrait 1: " + trait1 + "\nTrait 2: " + llGetSubString(trait2, 1, -1) + "\n\nWhich trait do you want to approve/deny?", ["TRAIT 1"], channel);
                }
                else
                {
                    llDialog(using, "Character name: " + name + "\nTrait 1: " + trait1 + "\nTrait 2: " + trait2 + "\n\nWhich trait do you want to approve/deny?", ["TRAIT 1", "TRAIT 2"], channel);
                }                
            }
        }
        else if(t == token && mode == "save")
        {
            if(startswith(data, "0"))
            {
                llDialog(using, "Something went wrong while updating the trait... Please try again.", ["OK"], -1);
            }
            else
            {
                if(changing == "TRAIT 1")
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=private-webhook\nname=Trait Approval/Denial\nmessage=Admin has handled a trait request.######Admin: " + llKey2Name(using) + "###Target: " + targetName + "###Slot: " + slot + "###Trait number: 1###Trait: " + changedTrait + "###Decision: " + choice);
                }
                else
                {
                    llSay(CG_IPC_CHANNEL, "target=server\nmode=private-webhook\nname=Trait Approval/Denial\nmessage=Admin has handled a trait request.######Admin: " + llKey2Name(using) + "###Target: " + targetName + "###Slot: " + slot + "###Trait number: 2###Trait: " + changedTrait + "###Decision: " + choice);
                }
                if(choice == "ACCEPT")
                {
                    llDialog(using, "Trait accepted successfully. Please remove the message in Discord.", ["OK"], -1);
                    if(changing == "TRAIT 1")
                    {
                        llInstantMessage(target, "A staff member has approved trait 1 of your character '" + name + "'. You are now free to use it.");
                    }
                    else
                    {
                        llInstantMessage(target, "A staff member has approved trait 2 of your character '" + name + "'. You are now free to use it.");
                    }
                }
                else
                {
                    llDialog(using, "Trait denied successfully. Please contact the player to help them improve their trait so it can be accepted and remove the message in Discord.", ["OK"], -1);
                    if(changing == "TRAIT 1")
                    {
                        llInstantMessage(target, "A staff member has denied trait 1 of your character '" + name + "'. It has been set to 'None.' They will contact you soon to discuss the trait.");
                    }
                    else
                    {
                        llInstantMessage(target, "A staff member has denied trait 2 of your character '" + name + "'. It has been set to 'None.' They will contact you soon to discuss the trait.");
                    }
                }
            }
        }
    }
}
