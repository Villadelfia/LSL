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

integer listener = -1;
integer channel;
string hudState = "normal";
integer characterLoaded = 0;
integer level = 0;
string name;
string status = "OOC";
integer confirmAdmin = FALSE;
string mode = "";
list results = [];
integer init = 0;
integer hp = 8;
string specialty;
string attackType;

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

giveChoiceDialog(string msg)
{
    list buttons = [];
    integer i;
    integer l = llGetListLength(results);
    msg += "\n";
    for(i = 0; i < l; i++)
    {
        buttons += (string)(i+1);
        msg += "\n" + (string)(i+1) + ": " + llGetDisplayName((key)llList2String(results, i)) + " (" + llGetUsername((key)llList2String(results, i)) + ")";
    }
    llDialog(llGetOwner(), msg, orderButtons(buttons), channel);
}

default
{
    state_entry()
    {
        log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
        llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, llGetScriptName(), NULL_KEY);
    }

    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_SET_HUD_STATE)
        {
            if(str1 != hudState)
            {
                if(hudState == "tools-combat" && hp == 0)
                {
                    llMessageLinked(LINK_THIS, CLIENT_LEAVE_COMBAT, "", NULL_KEY);
                }
                confirmAdmin = FALSE;
                hudState = str1;
                if(hudState == "tools")
                {
                    if(characterLoaded)
                    {
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), rpToolsTexture);
                        if(listener != -1) llListenRemove(listener);
                        channel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
                        listener = llListen(channel, "", llGetOwner(), "");
                    }
                    else
                    {
                        llOwnerSay("Please load a character first.");
                        llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                    }
                }
            }
        }
        else if(api_id == CLIENT_CHARACTER_LOADED || api_id == CLIENT_CHARACTER_CHANGED)
        {
            list dict = llParseString2List(str1, ["\n"], []);
            characterLoaded = (integer)getValueFromKey(dict, "slot");
            level = (integer)getValueFromKey(dict, "level");
            name = getValueFromKey(dict, "name");
            specialty = getValueFromKey(dict, "atk");
        }
        else if(api_id == CLIENT_CHARACTER_UNLOADED)
        {
            characterLoaded = 0;
        }
        else if(api_id == CLIENT_STATUS_CHANGED)
        {
            status = str1;
            if(status == "CMB")
            {
                list params = llParseString2List((string)str2, [";"], []);
                init = (integer)llList2String(params, 0);
                hp = (integer)llList2String(params, 1);
            }
        }

        if(hudState != "tools" && hudState != "tools-combat") return;

        if(api_id == CLIENT_SCAN_RESULTS && (string)str2 == "IC")
        {
            // For scanning
            results = llParseString2List(str1, [";"], []);
            mode = "choosescan";
            giveChoiceDialog("Who do you want to scan? (Listing the 12 closest people within your chat range.)");
        }
        else if(api_id == CLIENT_SCAN_RESULTS && (string)str2 == "CMB")
        {
            // For fighting
            if(mode == "tryflee")
            {
                results = llParseString2List(str1, [";"], []);
                integer opponents = llGetListLength(results) - 1;
                integer i;
                integer succeed = TRUE;
                for(i = 0; i < opponents; ++i)
                {
                    integer roll = random(1, 100);
                    if(roll == 1 || roll + level < 25) succeed = FALSE;
                }

                if(succeed)
                {
                    string message = name + " tried to flee and succeeded.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    llMessageLinked(LINK_THIS, CLIENT_LEAVE_COMBAT, "", NULL_KEY);
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else
                {
                    string message = name + " tried to flee and failed.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
            }
            else if(mode == "heallist")
            {
                results = llParseString2List(str1, [";"], []);
                integer targets = llGetListLength(results);
                giveChoiceDialog("Who do you want to try to heal? (Listing the 12 closest people within your chat range.)");
            }
            else if(mode == "choosetarget")
            {
                results = llParseString2List(str1, [";"], []);
                integer targets = llGetListLength(results);
                giveChoiceDialog("Who do you want to try to attack? (Listing the 12 closest people within your chat range.)");
            }
        }
        else if(api_id == CLIENT_BUTTON_CLICKED)
        {
            integer button = (integer)str1;
            if(button > 5) return;
            if(button != 5 || hudState != "tools") confirmAdmin = FALSE;

            if(hudState == "tools")
            {
                if(button == 0)
                {
                    mode = "getreason";
                    llTextBox(llGetOwner(), "Please give a reason for your roll.", channel);
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else if(button == 1)
                {
                    if(status != "CMB")
                    {
                        llOwnerSay("You need to switch yourself to combat mode in the status & settings menu.");
                    }
                    else
                    {
                        hudState = "tools-combat";
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), rpToolsCombatTexture);
                    }
                }
                else if(button == 2)
                {
                    llOwnerSay("Fetching you a clue token...");
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=rez-clue\nagent-key=" + (string)llGetOwner());
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else if(button == 3)
                {
                    llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "IC", NULL_KEY);
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else if(button == 4)
                {
                    llOwnerSay("Fetching you a copy of the rules...");
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=give-rules\nagent-key=" + (string)llGetOwner());
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else if(button == 5)
                {
                    if(confirmAdmin)
                    {
                        llOwnerSay("Paging admins...");
                        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=page-staff\nagent-key=" + (string)llGetOwner());
                        confirmAdmin = FALSE;
                        llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                    }
                    else
                    {
                        confirmAdmin = TRUE;
                        llOwnerSay("Are you sure you need an admin? Click the button again to page the admins.");
                    }
                }
            }
            else
            {
                if(button == 0)
                {
                    mode = "atktype";
                    llDialog(llGetOwner(), "Please choose the type of attack you wish to make. Your specialty is " + llToUpper(specialty) + ".", ["NATURAL", "MELEE", "RANGED", "NON-PHYS"], channel);
                }
                else if(button == 1)
                {
                    mode = "heallist";
                    llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "CMB", NULL_KEY);
                }
                else if(button == 2)
                {
                    llOwnerSay("Attempting to flee...");
                    mode = "tryflee";
                    llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "CMB", NULL_KEY);
                }
                else if(button == 3)
                {
                    init = random(1, 100) + level;
                    string message = name + " rolled a " + (string)(init) + " for initiative.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    llMessageLinked(LINK_THIS, CLIENT_SET_COMBAT_DATA, "init", (key)((string)init));
                }
                else if(button == 4)
                {
                    if(hp > 0)
                    {
                        llOwnerSay("Decreasing your HP by one...");
                        hp--;
                        llMessageLinked(LINK_THIS, CLIENT_SET_COMBAT_DATA, "hp", (key)((string)hp));
                    }

                    if(hp == 0)
                    {
                        llOwnerSay("You're at 0 HP, on your next initiative you must post out. You will leave combat once you close this menu.");
                    }
                    
                }
                else if(button == 5)
                {
                    if(hp < 99 && hp > 0)
                    {
                        llOwnerSay("Increasing your HP by one...");
                        hp++;
                        llMessageLinked(LINK_THIS, CLIENT_SET_COMBAT_DATA, "hp", (key)((string)hp));
                    }
                }
            }
        }
    }

    listen(integer c, string n, key id, string m)
    {
        m = (string)llParseString2List(llStringTrim(llList2String(llParseString2List(m, ["\n"], []), 0), STRING_TRIM), [","], []);

        if(mode == "getreason")
        {
            integer num = random(1, 100);
            string message = name + " rolled a " + (string)num + " (" + (string)(num+level) + " if you include their level) for " + m + ".";
            trustedSay("Crystalgate Dice", message);
            llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
            llSay(CG_IPC_CHANNEL, "target=server\nmode=webhook\nname=Crystalgate Dice\nmessage=" + message);
        }
        else if(mode == "choosescan")
        {
            llMessageLinked(LINK_THIS, CLIENT_REQUEST_INFO, "", (key)llList2String(results, ((integer)m)-1));
        }
        else if(mode == "heallist")
        {
            integer choice = ((integer)m)-1;
            if(hp == 0)
            {
                llOwnerSay("You can't heal anyone from 0 HP in combat.");
            }
            else if((key)llList2String(results, choice) == llGetOwner())
            {
                integer roll = random(1, 20);
                integer successes = 0;
                integer target = 5;
                while(roll >= target)
                {
                    successes++;
                    target += 5;
                    roll = random(1, 20);
                }
                
                if(successes == 0)
                {
                    string message = name + " attempted to heal themselves, but failed.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
                else
                {
                    string message = name + " attempted to heal themselves, and got " + (string)successes + " success(es), healing themselves for " + (string)successes + " HP.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
            }
            else
            {
                llRegionSayTo((key)llList2String(results, choice), CG_IPC_CHANNEL, "target=client\nmode=try-heal\nhealer=" + name);
            }
        }
        else if(mode == "atktype")
        {
            attackType = m;
            mode = "choosetarget";
            llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "CMB", NULL_KEY);
        }
        else if(mode == "choosetarget")
        {
            integer choice = ((integer)m)-1;
            
            if(hp == 0)
            {
                llOwnerSay("You can't attack anyone from 0 HP in combat.");
            }
            else if((key)llList2String(results, choice) == llGetOwner())
            {
                llOwnerSay("Stop hitting yourself!");
            }
            else
            {
                llRegionSayTo((key)llList2String(results, choice), CG_IPC_CHANNEL, "target=client\nmode=try-attack\nattacker=" + name + "\ntype=" + attackType + "\nstrength=" + specialty + "\nlevel=" + (string)level);
            }
        }
    }
}