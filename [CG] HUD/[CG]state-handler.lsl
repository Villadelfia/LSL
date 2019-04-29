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

key token = NULL_KEY;
string mode = "";
string hudState = "normal";
string characterState = "OOC";
integer characterLoaded = FALSE;

string slot = "";
string fancy = "";
string rlv = "";
string combatData = "";

buttonColors()
{
    if(fancy != "1") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)5, (key)((string)<1.0, 0.0, 0.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)5, (key)((string)<0.0, 1.0, 0.0>));
    }

    if(rlv != "1") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)4, (key)((string)<1.0, 0.0, 0.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)4, (key)((string)<0.0, 1.0, 0.0>));
    }

    if(characterState == "IC") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)0, (key)((string)<1.0, 1.0, 1.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)0, (key)((string)<0.5, 0.5, 0.5>));
    }

    if(characterState == "OOC") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)1, (key)((string)<1.0, 1.0, 1.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)1, (key)((string)<0.5, 0.5, 0.5>));
    }

    if(characterState == "AFK") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)2, (key)((string)<1.0, 1.0, 1.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)2, (key)((string)<0.5, 0.5, 0.5>));
    }

    if(characterState == "CMB") 
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)3, (key)((string)<1.0, 1.0, 1.0>));
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)3, (key)((string)<0.5, 0.5, 0.5>));
    }
}

writeInitData(integer reloadTitler)
{
    if(reloadTitler)
    {
        mode = "write";
    }
    token = llUpdateKeyValue((string)llGetOwner(), "slot=" + slot + "\nfancy=" + fancy + "\nrlv=" + rlv + "\ncombat-data=" + combatData + "\nlast-update=" + (string)llGetUnixTime(), FALSE, "");
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
                hudState = str1;
                if(hudState == "status")
                {
                    if(characterLoaded)
                    {
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), characterStatusTexture);
                        buttonColors();
                        string sStatus = characterState;
                        if(llStringLength(sStatus) < 3) sStatus = " " + sStatus;
                        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "     Currently: " + sStatus + "     ", (string)2);
                    }
                    else
                    {
                        llOwnerSay("Please load a character first.");
                        llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                    }
                }
            }
            else if(hudState == "status")
            {
                buttonColors();
            }
        }
        else if(api_id == CLIENT_INITIAL_VALUES)
        {
            list dict = llParseString2List(str1, ["\n"], []);
            slot = getValueFromKey(dict, "slot");
            if(slot == "") slot = "NONE";
            fancy = getValueFromKey(dict, "fancy");
            if(fancy == "") fancy = "0";
            rlv = getValueFromKey(dict, "rlv");
            if(rlv == "") rlv = "0";
            combatData = getValueFromKey(dict, "combat-data");
        }
        else if(api_id == CLIENT_CHARACTER_LOADED)
        {
            characterLoaded = TRUE;
            list dict = llParseString2List(str1, ["\n"], []);
            slot = getValueFromKey(dict, "slot");
            writeInitData(TRUE);
            if(characterState == "OOC" || characterState == "AFK")
            {
                characterState = "IC";
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=IC");
                
                if(combatData != "")
                {
                    llOwnerSay("You have a pending combat due to a disconnect. Just go back into combat mode to reload it. Changing character or going OOC or AFK will erase it.");
                }

                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
            }
        }
        else if(api_id == CLIENT_CHARACTER_CHANGED)
        {
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-reload");
        }
        else if(api_id == CLIENT_CHARACTER_UNLOADED)
        {
            characterLoaded = FALSE;
            slot = "NONE";
            combatData = "";
            writeInitData(TRUE);
            if(characterState != "OOC")
            {
                characterState = "OOC";
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=OOC");
                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
            }
        }
        else if(api_id == CLIENT_SET_COMBAT_DATA)
        {
            if(combatData == "") return;
            list cb = llParseString2List(combatData, [";"], []);
            integer init = (integer)llList2String(cb, 0);
            integer hp = (integer)llList2String(cb, 1);
            integer hpm = (integer)llList2String(cb, 2);
            if(str1 == "init")
            {
                init = (integer)((string)str2);
            }
            else if(str1 == "hp")
            {
                hp = (integer)((string)str2);
            }
            if(hp > hpm) hpm = hp;
            combatData = (string)init + ";" + (string)hp + ";" + (string)hpm;
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=CMB\ncombat-data=" + combatData);
            llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, (string)combatData);
            writeInitData(FALSE);
        }
        else if(api_id == CLIENT_LEAVE_COMBAT)
        {
            if(characterState != "CMB") return;
            combatData = "";
            writeInitData(FALSE);
            characterState = "IC";
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=IC");
            llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
            llOwnerSay("You have left combat.");
        }

        if(hudState != "status") return;

        if(api_id == CLIENT_BUTTON_CLICKED)
        {
            integer button = (integer)str1;
            integer wipeCombat = FALSE;

            if(button == 0 && characterState != "IC")
            {
                characterState = "IC";
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=IC");
                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
                wipeCombat = TRUE;
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                llOwnerSay("You are now in character with the character in slot " + slot + ". Experience will be earned as you roleplay.");
            }
            else if(button == 1 && characterState != "OOC")
            {
                characterState = "OOC";
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=OOC");
                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
                wipeCombat = TRUE;
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                llOwnerSay("You are now in out of character mode. You will not earn any experience.");
            }
            else if(button == 2 && characterState != "AFK")
            {
                characterState = "AFK";
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=AFK");
                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, NULL_KEY);
                wipeCombat = TRUE;
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                llOwnerSay("You are now in AFK mode. You will not earn any experience.");
            }
            else if(button == 3 && characterState != "CMB")
            {
                characterState = "CMB";
                
                if(combatData == "") combatData = "0;8;8";
                
                llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=set-state\nstate=CMB\ncombat-data=" + combatData);
                llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, characterState, (string)combatData);
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                writeInitData(FALSE);
                llOwnerSay("You are now in combat mode. You can now use the combat options in the RP tools menu and others can roll against you.");
            }
            else if(button == 4)
            {
                if(rlv == "1")
                {
                    llOwnerSay("Disabled RLV redirection to the RP channel while IC.");
                    rlv = "0";
                }
                else
                {
                    llOwnerSay("Enabled RLV redirection to the RP channel while IC. Make sure that in your viewer 'RLVa → Split Long Redirected Chat' is enabled.");
                    rlv = "1";
                }
                
                buttonColors();
                writeInitData(TRUE);
            }
            else if(button == 5)
            {
                if(fancy == "1")
                {
                    llOwnerSay("Disabled the fancy landing zone experience.");
                    fancy = "0";
                }
                else
                {
                    llOwnerSay("Enabled the fancy landing zone experience.");
                    fancy = "1";
                }
                
                buttonColors();
                writeInitData(FALSE);
            }

            if(wipeCombat && combatData != "")
            {
                combatData = "";
                writeInitData(FALSE);
            }
        }
    }

    dataserver(key t, string data)
    {
        if(token == t && mode == "write")
        {
            mode = "";
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-reload");
        }
    }
}