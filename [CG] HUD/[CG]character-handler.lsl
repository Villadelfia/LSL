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

string hudState = "normal";
string mode = "";
string characterData = "";

key token;
integer activeSlot = 0;
integer tentativeSlot = 0;
string changingTrait;

integer listener = -1;
integer channel;

// All elements of a character
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

updateStatusLine()
{
    if(hudState == "character")
    {
        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), characterMenuTexture);
        
        if(activeSlot == 0)
        {
            llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)ALL_SIDES, (key)((string)<0.5, 0.5, 0.5>));
            llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)0, (key)((string)<1.0, 1.0, 1.0>));
            llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "none", NULL_KEY);
        }
        else
        {
            llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)ALL_SIDES, (key)((string)<1.0, 1.0, 1.0>));
            llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "none", NULL_KEY);
        }
        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "    Select an Option    ", (string)2);
    }
    else if(hudState == "character-select")
    {
        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), characterSelectTexture);
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)ALL_SIDES, (key)((string)<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "none", NULL_KEY);
        llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "    Select Character    ", (string)2);
    }
}

save(integer notifyTitler)
{
    if(notifyTitler)
    {
        mode = "savereload";
    }
    else
    {
        mode = "savehud";
    }

    // Failsafe.
    if(slot == "" || slot == "0" || activeSlot != (integer)slot || name == "" || atk == "" || def == "" || trait1 == "" || trait2 == "" || trait1ts == "" || trait2ts == "" || level == "" || xp == "" || titlePos == "")
    {
        llOwnerSay("Fatal error while saving your character. Tried to save invalid data. Please detach the HUD to reload your character.");
        return;
    }

    token = llUpdateKeyValue((string)llGetOwner() + "character" + slot, 
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

cldMenu()
{
    // Get the tentative character.
    mode = "cld";
    token = llReadKeyValue((string)llGetOwner() + "character" + (string)tentativeSlot);
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
                if(hudState == "character-select" || hudState == "character")
                {
                    if(listener != -1)
                    {
                        llListenRemove(listener);
                        listener = -1;
                    }
                }
                hudState = str1;
                if(hudState == "character")
                {
                    if(listener == -1)
                    {
                        channel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
                        listener = llListen(channel, "", llGetOwner(), "");
                    }
                    updateStatusLine();
                }
            }
        }

        // Events that you always care about...
        if(api_id == CLIENT_LOAD_CHARACTER)
        {
            if(activeSlot != 0)
            {
                llMessageLinked(LINK_THIS, CLIENT_CHARACTER_UNLOADED, "", NULL_KEY);
                activeSlot = 0;
            }
            tentativeSlot = (integer)str1;
            mode = "loading";
            token = llReadKeyValue((string)llGetOwner() + "character" + str1);
        }
        else if(api_id == CLIENT_CHARACTER_LOADED || api_id == CLIENT_CHARACTER_CHANGED)
        {
            list dict = llParseString2List(str1, ["\n"], []);
            slot = getValueFromKey(dict, "slot");
            name = getValueFromKey(dict, "name");
            displayName = getValueFromKey(dict, "display-name");

            atk = getValueFromKey(dict, "atk");
            def = getValueFromKey(dict, "def");

            trait1 = getValueFromKey(dict, "trait1");;
            trait1ts = getValueFromKey(dict, "trait1ts");
            trait2 = getValueFromKey(dict, "trait2");
            trait2ts = getValueFromKey(dict, "trait2ts");

            level = getValueFromKey(dict, "level");
            xp = getValueFromKey(dict, "xp");

            titlePos = getValueFromKey(dict, "title-pos");

            if(api_id == CLIENT_CHARACTER_LOADED) llOwnerSay("Loaded slot " + slot + ". " + name + ", a level " + level + " character. Type in channel /2 or /4 to RP, /3 to describe a scene and /5 to say something out of character.");
        }
        else if(api_id == CLIENT_SET_LEVEL_XP)
        {
            level = str1;
            xp = (string)str2;
            save(FALSE);
        }
        else if(api_id == CLIENT_SET_TITLER_POS)
        {
            titlePos = str1;
            save(FALSE);
        }


        // Events that only matter when the HUD is showing the menu...
        if(hudState != "character" && hudState != "character-select") return;

        if(api_id == CLIENT_BUTTON_CLICKED)
        {
            integer button = (integer)str1;
            if(button > 5) return;

            if(hudState == "character-select")
            {
                tentativeSlot = button + 1;
                cldMenu();
            }
            else
            {
                if(button > 0 && activeSlot == 0) 
                {
                    llOwnerSay("This button is only available with a loaded character.");
                    return;
                }

                if(button == 0)
                {
                    hudState = "character-select";
                    updateStatusLine();
                }
                else if(button == 1)
                {
                    mode = "setname";
                    if(displayName == "")
                    {
                        llTextBox(llGetOwner(), "Your name currently appears as '" + name + "' when you RP. Enter a new one below or leave the box empty to leave it unchanged.", channel);
                    }
                    else
                    {
                        llTextBox(llGetOwner(), "Your name currently appears as '" + displayName + "' when you RP. Enter a new one below or leave the box empty to change it back to your full name.", channel);
                    }
                }
                else if(button == 2)
                {
                    mode = "settitle";
                    llTextBox(llGetOwner(), "Enter a title.", channel);
                }
                else if(button == 3)
                {
                    llMessageLinked(LINK_THIS, CLIENT_REQUEST_INFO, "", llGetOwner());
                    llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                }
                else if(button == 4)
                {
                    mode = "chtr1";
                    llTextBox(llGetOwner(), "Choose your replacement first trait. Remember that a trait in this way WILL make you lose access to it for a full week.", channel);
                }
                else if(button == 5)
                {
                    mode = "chtr2";
                    llTextBox(llGetOwner(), "Choose your replacement second trait. Remember that a trait in this way WILL make you lose access to it for a full week.", channel);
                }
            }
        }
    }

    listen(integer c, string n, key id, string message)
    {
        if(mode == "cld")
        {
            if(message == "LOAD")
            {
                activeSlot = tentativeSlot;
                llMessageLinked(LINK_THIS, CLIENT_CHARACTER_LOADED, characterData, NULL_KEY);
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
            }
            else if(message == "CREATE")
            {
                characterData = "slot=" + (string)tentativeSlot +"\ndisplay-name=\nlevel=0\nxp=20\ntrait1ts=" + (string)(llGetUnixTime()-(3600*24*7)) + "\ntrait2ts=" + (string)(llGetUnixTime()-(3600*24*7)) + "\ntitle-pos=<0.0, 0.0, 0.19604>";
                activeSlot = 0;
                llMessageLinked(LINK_THIS, CLIENT_CHARACTER_UNLOADED, "", NULL_KEY);

                mode = "crname";
                llTextBox(llGetOwner(), "Type your character name. Please see your chat window for more information.", channel);
                llOwnerSay("Welcome to the Crystalgate character creation wizard. We're creating a character for slot " + (string)tentativeSlot + ". If you want to restart at any point, just click the character slot button again.\n\nFirst you must select your name. This is the name that is displayed above your title. You can NOT change this name later, but you can later select a different name to display in front of your posts. It's advisable to choose a name containing only symbols from the normal English alphabet.");
            }
            else if(message == "DELETE")
            {
                mode = "delcfrm";
                llDialog(llGetOwner(), "Are you absolutely sure? Deleting a character is irreversible and XP earned will be lost forever!", ["YES", "Nevermind..."], channel);
            }
        }
        else if(mode == "delcfrm")
        {
            if(message == "YES")
            {
                llOwnerSay("Character has been deleted...");
                llMessageLinked(LINK_THIS, CLIENT_CHARACTER_UNLOADED, "", NULL_KEY);
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                llDeleteKeyValue((string)llGetOwner() + "character" + (string)tentativeSlot);
                llDeleteKeyValue((string)llGetOwner() + "title" + (string)tentativeSlot);
                activeSlot = 0;
                tentativeSlot = 0;
                characterData = "";
            }
        }
        else if(mode == "crname")
        {
            string sName = (string)llParseString2List(llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM), [","], []);
            sName = strreplace(sName, "=", "");
            characterData += "\nname=" + sName;
            mode = "cratk";
            llDialog(llGetOwner(), "Choose your combat specialty. Please see your chat window for more information.", ["NATURAL", "MELEE", "RANGED", "NON-PHYS"], channel);
            llOwnerSay("Your name has been set to " + sName + ".\n\nYou must now select a combat specialty. With your specialty you will deal 3 damage per hit, while with any other type of attack you will deal 2 damage. There are four types available:\n\nNATURAL: This includes any melee weapon that is naturally attached to your body such as claws or spines.\nMELEE: This includes any manufactured melee weapon such as a knife, a crowbar or a stun baton.\nRANGED: This includes any ranged physical weapon such as a gun, a rock you throw using telekinesis or spines you can shoot from your body.\nNON-PHYS: This includes anything that doesn't fit in the other categories such as attacking using purely the power of your mind.\n\nThe choice you make here is permanent.");
        }
        else if(mode == "cratk")
        {
            if(message != "NATURAL" && message != "MELEE" && message != "RANGED" && message != "NON-PHYS") return;
            characterData += "\natk=" + llToLower(message);
            mode = "crdef";
            llDialog(llGetOwner(), "Choose your defensive specialty. Please see your chat window for more information.", ["NATURAL", "MELEE", "RANGED", "NON-PHYS"], channel);
            llOwnerSay("You must now select a defensive specialty. If you are attacked with an attack type you are specialized against, you take one less hit point of damage. The categories here are the same as with the previous question.\n\nThe choice you make here is permanent.");
        }
        else if(mode == "crdef")
        {
            if(message != "NATURAL" && message != "MELEE" && message != "RANGED" && message != "NON-PHYS") return;
            characterData += "\ndef=" + llToLower(message);
            mode = "crtr1";
            llTextBox(llGetOwner(), "Choose your first trait. Please see your chat window for more information.", channel);
            llOwnerSay("You must now select your first trait. If you want to play a normal human, enter 'None'. Otherwise, enter one of the two things that you can do that a normal human can't. If you choose one of the traits from the rules packet you may start using it immediately, otherwise you should wait until an admin approves it.\n\nIt's possible to change your traits, but when you change a trait you will lose access to it for one week while your body reforms.");
        }
        else if(mode == "crtr1")
        {
            trait1 = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            trait1 = strreplace(trait1, "=", "");
            trait1 = makeProper(trait1);
            mode = "cfrtr1";
            llDialog(llGetOwner(), "You have chosen \"" + trait1 + "\", is this correct?", ["YES", "NO"], channel);
        }
        else if(mode == "cfrtr1")
        {
            if(message == "YES")
            {
                characterData += "\ntrait1=" + trait1;
                mode = "crtr2";
                llTextBox(llGetOwner(), "Choose your second trait. Please see your chat window for more information.", channel);
                llOwnerSay("You must now select your second trait. If you want to play a normal human, enter 'None'. Otherwise, enter the second of the two things that you can do that a normal human can't. If you choose one of the traits from the rules packet you may start using it immediately, otherwise you should wait until an admin approves it.\n\nIt's possible to change your traits, but when you change a trait you will lose access to it for one week while your body reforms.");
            }
            else
            {
                mode = "crtr1";
                llTextBox(llGetOwner(), "Choose your first trait. Please see your chat window for more information.", channel);
                llOwnerSay("You must now select your first trait. If you want to play a normal human, enter 'None'. Otherwise, enter one of the two things that you can do that a normal human can't. If you choose one of the traits from the rules packet you may start using it immediately, otherwise you should wait until an admin approves it.\n\nIt's possible to change your traits, but when you change a trait you will lose access to it for one week while your body reforms.");
            }
        }
        else if(mode == "crtr2")
        {
            trait2 = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            trait2 = strreplace(trait2, "=", "");
            trait2 = makeProper(trait2);
            mode = "cfrtr2";
            llDialog(llGetOwner(), "You have chosen \"" + trait2 + "\", is this correct?", ["YES", "NO"], channel);
        }
        else if(mode == "cfrtr2")
        {
            if(message == "YES")
            {
                characterData += "\ntrait2=" + trait2;
                mode = "crcfr";
                llDialog(llGetOwner(), "All the settings seem to be correct, do you want to go ahead and create this character?", ["YES", "NO"], channel);
            }
            else
            {
                mode = "crtr2";
                llTextBox(llGetOwner(), "Choose your second trait. Please see your chat window for more information.", channel);
                llOwnerSay("You must now select your second trait. If you want to play a normal human, enter 'None'. Otherwise, enter the second of the two things that you can do that a normal human can't. If you choose one of the traits from the rules packet you may start using it immediately, otherwise you should wait until an admin approves it.\n\nIt's possible to change your traits, but when you change a trait you will lose access to it for one week while your body reforms.");
            }
        }
        else if(mode == "crcfr")
        {
            if(message == "NO")
            {
                llOwnerSay("Okay, cancelling...");
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
            }
            else if(message == "YES")
            {
                mode = "save";
                llSay(CG_IPC_CHANNEL, "target=server\nmode=character-webhook\nagent-key=" + (string)llGetOwner() + "\n" + characterData);
                token = llCreateKeyValue((string)llGetOwner() + "character" + (string)tentativeSlot, characterData);
            }
        }
        else if(mode == "setname")
        {
            displayName = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            displayName = strreplace(displayName, "=", "");
            if(displayName == "")
            {
                llOwnerSay("Your display name has been changed to " + name + ".");
            }
            else
            {
                llOwnerSay("Your display name has been changed to " + displayName + ".");
            }
            save(TRUE);
        }
        else if(mode == "settitle")
        {
            mode = "savetitler";
            token = llUpdateKeyValue((string)llGetOwner() + "title" + (string)activeSlot, llStringTrim(message, STRING_TRIM), FALSE, "");
            llOwnerSay("Your title has been changed.");
        }
        else if(mode == "chtr1" || mode == "chtr2")
        {
            changingTrait = llStringTrim(llList2String(llParseString2List(message, ["\n"], []), 0), STRING_TRIM);
            changingTrait = strreplace(changingTrait, "=", "");
            changingTrait = makeProper(changingTrait);
            if(mode == "chtr1")
            {
                mode = "cfrchtr1";
            }
            else
            {
                mode = "cfrchtr2";
            }

            llDialog(llGetOwner(), "You have chosen \"" + changingTrait + "\", is this correct?", ["YES", "NO"], channel);
        }
        else if(mode == "cfrchtr1" || mode == "cfrchtr2")
        {
            if(message == "YES")
            {
                if(mode == "cfrchtr1")
                {
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=trait-alert\nagent-key=" + (string)llGetOwner() + "\nslot=" + (string)activeSlot + "\ntrait=1\nvalue=" + changingTrait);
                    trait1 = changingTrait;
                    trait1ts = (string)llGetUnixTime();
                }
                else
                {
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=trait-alert\nagent-key=" + (string)llGetOwner() + "\nslot=" + (string)activeSlot + "\ntrait=2\nvalue=" + changingTrait);
                    trait2 = changingTrait;
                    trait2ts = (string)llGetUnixTime();
                }
                mode = "";
                llOwnerSay("Your trait has been changed. Remember that you immediately lose your old trait and that this new trait will not become active for one whole week.");
                save(FALSE);
            }
        }
    }

    dataserver(key t, string data)
    {
        if(token == t && mode == "cld")
        {
            string status = llList2String(llParseString2List(data, [","], []), 0);
            characterData = llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ",");
            if(status == "0")
            {
                // Character doesn't exist, only offer to create one in this slot.
                string message = "There is no character in slot " + (string)tentativeSlot + ", do you want to create one?";
                llDialog(llGetOwner(), message, ["CREATE", "CANCEL"], channel);
            }
            else
            {
                // Character does exist, offer to load or delete.
                list dict = llParseString2List(characterData, ["\n"], []);
                string name = getValueFromKey(dict, "name");
                string level = getValueFromKey(dict, "level");
                string message = "Slot " + (string)tentativeSlot + " contains " + name + ", a level " + level + " character. What do you want to do?";
                llDialog(llGetOwner(), message, ["LOAD", "DELETE", "CANCEL"], channel);
            }
        }
        else if(token == t && mode == "save")
        {
            string status = llList2String(llParseString2List(data, [","], []), 0);
            string value = llList2String(llParseString2List(data, [","], []), 1);
            if(status == "0")
            {
                llOwnerSay("Something went terribly wrong while saving your character. Please contact an admin with the following information: " + value);
            }
            else
            {
                llOwnerSay("Character saved. Now loading it.");
                mode = "";
                llMessageLinked(LINK_THIS, CLIENT_LOAD_CHARACTER, (string)tentativeSlot, NULL_KEY);
            }
            
        }
        else if(token == t && mode == "loading")
        {
            string status = llList2String(llParseString2List(data, [","], []), 0);
            string value = llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ",");
            if(status == "0")
            {
                llOwnerSay("Something went terribly wrong while loading your character. Please contact an admin with the following information: " + value);
            }
            else
            {
                activeSlot = tentativeSlot;
                characterData = value;
                llMessageLinked(LINK_THIS, CLIENT_CHARACTER_LOADED, characterData, NULL_KEY);
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
                mode = "";
            }
        }
        else if(token == t && mode == "savereload")
        {
            mode = "reloading";
            token = llReadKeyValue((string)llGetOwner() + "character" + (string)activeSlot);
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-reload");
        }
        else if(token == t && mode == "savehud")
        {
            mode = "reloading";
            token = llReadKeyValue((string)llGetOwner() + "character" + (string)activeSlot);
        }
        else if(token == t && mode == "reloading")
        {
            mode = "";
            string status = llList2String(llParseString2List(data, [","], []), 0);
            string value = llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ",");
            if(status == "0")
            {
                llOwnerSay("Something went terribly wrong while reloading your character. Please contact an admin with the following information: " + value);
            }
            else
            {
                characterData = value;
            }
            llMessageLinked(LINK_THIS, CLIENT_CHARACTER_CHANGED, characterData, NULL_KEY);
        }
        else if(token == t && mode == "savetitler")
        {
            mode = "";
            llRegionSayTo(llGetOwner(), CG_IPC_CHANNEL, "target=client\nmode=titler-reload");
        }
    }
}