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

list spells = [];
list staff = [];

integer listener;
integer channel;
key using;
key target;
key token;
string mode;
string slot;
list knownSpells = [];
integer targetSpell;
string targetname;

integer isStaff(key id)
{
    return llListFindList(staff, [(string)id]) != -1;
}

list orderButtons(list buttons)
{
    integer buttonCount = llGetListLength(buttons);
    if(buttonCount < 12)
    {
        for(; buttonCount < 12; ++buttonCount)
        {
            buttons += " ";
        }
    }

    buttons = llList2List(buttons, 9, 11) + llList2List(buttons, 6, 8) + llList2List(buttons, 3, 5) + llList2List(buttons, 0, 2);

    while(llList2String(buttons, 2) == " " && llList2String(buttons, 1) == " " && llList2String(buttons, 0) == " ")
    {
        buttons = llDeleteSubList(buttons, 0, 2);
    }

    return buttons;
}

default
{
    state_entry()
    {
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer c, string name, key id, string message)
    {
        if(c == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string tar = getValueFromKey(dict, "target");
            if(tar != "client") return;

            string mode = getValueFromKey(dict, "mode");

            if(mode == "clear-spells")
            {
                llOwnerSay("Clearing all spells...");
                spells = [];
                staff = [];
            }
            else if(mode == "add-spell")
            {
                integer l = llGetListLength(spells);
                integer i = (integer)getValueFromKey(dict, "index");
                string n = getValueFromKey(dict, "name");
                while(l-1 < i)
                {
                    ++l;
                    spells += "";
                }
                spells = llListReplaceList(spells, [n], i, i);
                llOwnerSay("Added spell " + (string)i + ": " + n + "...");
            }
            else if(mode == "add-spell-staff")
            {
                string agentKey = getValueFromKey(dict, "agent-key");
                llOwnerSay("Adding secondlife:///app/agent/" + agentKey + "/inspect to the spell staff registry...");
                staff += agentKey;
            }
        }
        else if(mode == "usertop" || (mode == "admintop" && message != "3"))
        {
            if(message == "1")
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=give-rules\nagent-key=" + (string)using);
            }
            else if(message == "2")
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=give-spellbook\nagent-key=" + (string)using);
            }
        }
        else if(mode == "admintop")
        {
            mode = "askid";
            llTextBox(using, "Give the username of the person whose list of known magic you wish to alter in the form firstname.lastname, or just firstname for people without a last name.", channel);
        }
        else if(mode == "askid")
        {
            targetname = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            token = llRequestUserKey((string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []));
        }
        else if(mode == "askslot")
        {
            slot = message;
            token = llReadKeyValue((string)target + "spells" + slot);
        }
        else if(mode == "selectspelloption")
        {
            if(message == "TEACH")
            {
                if(llGetListLength(knownSpells) >= 5 && !isStaff(target))
                {
                    llRegionSayTo(using, 0, "Error: One not granted the gift of teaching can only know 5 extra spells.");
                    mode = "askslot";
                    token = llReadKeyValue((string)target + "spells" + slot);
                }
                else if(llGetListLength(knownSpells) >= 8)
                {
                    llRegionSayTo(using, 0, "Error: One granted the gift of teaching can only know 8 extra spells.");
                    mode = "askslot";
                    token = llReadKeyValue((string)target + "spells" + slot);
                }
                else
                {
                    mode = "teachspell";
                    llTextBox(using, "Please enter the number of the spell you wish to teach them. See your chat for a list of all current spells.", channel);
                    integer l = llGetListLength(spells);
                    integer i = 1;
                    for(i = 1; i < l; ++i)
                    {
                        string spell = llList2String(spells, i);
                        if(spell != "REMOVED")
                        {
                            llRegionSayTo(using, 0, "Spell " + (string)i + ": " + spell);
                        }
                    }
                }
            }
            else if(message == "REMOVE")
            {
                mode = "removespell";
                integer l = llGetListLength(knownSpells);
                integer i = 0;
                list buttons = [];
                string msg = "Which spell do you wish to remove?\n";
                for(i = 0; i < l; ++i)
                {
                    msg += "\n" + (string)(i+1) + ": " + llList2String(spells, (integer)llList2String(knownSpells, i));
                    buttons += (string)(i+1);
                }
                llDialog(using, msg, orderButtons(buttons), channel);
            }
        }
        else if(mode == "teachspell")
        {
            targetSpell = (integer)message;
            if(targetSpell <= 0)
            {
                llRegionSayTo(using, 0, "Error: Enter a proper spell number please.");
                mode = "askslot";
                token = llReadKeyValue((string)target + "spells" + slot);
            }
            else
            {
                knownSpells += (string)targetSpell;
                mode = "spelltaught";
                token = llUpdateKeyValue((string)target + "spells" + slot, llDumpList2String(knownSpells, ","), FALSE, "");
            }
        }
        else if(mode == "removespell")
        {
            targetSpell = (integer)llList2String(knownSpells, ((integer)message)-1);
            knownSpells = llDeleteSubList(knownSpells, ((integer)message)-1, ((integer)message)-1);
            mode = "spellremoved";
            if(llGetListLength(knownSpells) == 0)
            {
                token = llDeleteKeyValue((string)target + "spells" + slot);
            }
            else
            {
                token = llUpdateKeyValue((string)target + "spells" + slot, llDumpList2String(knownSpells, ","), FALSE, "");
            }
        }
    }

    dataserver(key t, string data) 
    {
        if(t == token && mode == "askid" && (key)data != NULL_KEY)
        {
            target = (key)data;
            mode = "askslot";
            llDialog(using, "Give the slot of the character whose list of known magic you wish to alter.", ["4", "5", "6", "1", "2", "3"], channel);
        }
        else if(t == token && mode == "askslot")
        {
            mode = "selectspelloption";
            if(startswith(data, "0"))
            {
                llDialog(using, "This character knows no spells beyond Prestidigitation. Do you want to teach them a spell?", ["TEACH", "STOP"], channel);
            }
            else
            {
                string msg = "This character knows the following spells beyond Prestidigitation:\n";
                knownSpells = llParseString2List(llGetSubString(data, 2, -1), [","], []);
                integer l = llGetListLength(knownSpells);
                integer i = 0;
                for(i = 0; i < l; ++i)
                {
                    msg += "\n- " + llList2String(spells, (integer)llList2String(knownSpells, i));
                }
                msg += "\n\nDo you want to teach them a spell, or remove a known spell?";
                llDialog(using, msg, ["TEACH", "REMOVE", "STOP"], channel);
            }
        }
        else if(t == token && mode == "spelltaught")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(using, 0, "Error: Something went wrong teaching the spell.");
                mode = "askslot";
                token = llReadKeyValue((string)target + "spells" + slot);
            }
            else
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Crystalgate Grimoire\nmessage=" + llKey2Name(using) + " added the spell '" + llList2String(spells, targetSpell) + "' to " + targetname + "'s character in slot " + (string)slot + ".");
                llInstantMessage(target, "Arcane and eldritch knowledge suddenly invades your mind with a bursting headache as understanding of the spell '" + llList2String(spells, targetSpell) + "' suddenly becomes clear to you... When you consult your spell book to write it down, you find that your knowledge is already imprinted on the pages in your handwriting... Odd.");
                llRegionSayTo(target, CG_IPC_CHANNEL, "target=client\nmode=book-reload\nagent-key=" + (string)target);
                mode = "askslot";
                token = llReadKeyValue((string)target + "spells" + slot);
            }
        }
        else if(t == token && mode == "spellremoved")
        {
            if(startswith(data, "0"))
            {
                llRegionSayTo(using, 0, "Error: Something went wrong removing the spell.");
                mode = "askslot";
                token = llReadKeyValue((string)target + "spells" + slot);
            }
            else
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=staff-webhook\nname=Crystalgate Grimoire\nmessage=" + llKey2Name(using) + " removed the spell '" + llList2String(spells, targetSpell) + "' from " + targetname + "'s character in slot " + (string)slot + ".");
                llInstantMessage(target, "A sudden dullness invades your very mind, you soon realize that you feel the details of the spell '" + llList2String(spells, targetSpell) + "' slipping away from your mind... When you consult your spell book, you find the page it was on blank.");
                llRegionSayTo(target, CG_IPC_CHANNEL, "target=client\nmode=book-reload\nagent-key=" + (string)target);
                mode = "askslot";
                token = llReadKeyValue((string)target + "spells" + slot);
            }
        }
    }

    touch_start(integer num)
    {
        if(llVecDist(llDetectedPos(0), llGetPos()) > 2.0)
        {
            llRegionSayTo(llDetectedKey(0), 0, "You need to be within 2 meters to click the grimoire...");
            return;
        }

        knownSpells = [];
        channel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
        llListenRemove(listener);
        using = llDetectedKey(0);
        listener = llListen(channel, "", using, "");
        if(isStaff(llDetectedKey(0)))
        {
            mode = "admintop";
            llDialog(using, "A grimoire full of spells is placed on this pedestal, alongside a large pile of blank spell books... What do you do?\n\n1. Read through the spells (get a copy of the sim's rules including the spell list).\n2. Take a blank spellbook.\n3. Open the admin menu.", ["1", "2", "3"], channel);
        }
        else
        {
            mode = "usertop";
            llDialog(using, "A grimoire full of spells is placed on this pedestal, alongside a large pile of blank spell books... What do you do?\n\n1. Read through the spells (get a copy of the sim's rules including the spell list).\n2. Take a blank spellbook.", ["1", "2"], channel);
        }
    }
}