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

integer version = 1;
key ownerKey = NULL_KEY;
key token;
string mode;
integer listener = -1;
integer menuListener = -1;
integer menuChannel = 0;
integer ready = FALSE;
integer invisible = FALSE;
integer loadingIndex = 1;
integer selectedSpell = -1;
integer loadedCharacter = -1;
string casterName;
list currentSpells = [];
list currentSpellNames = [];

loadSpells()
{
    currentSpells = [0];
    currentSpellNames = ["Prestidigitation"];
    loadingIndex = 1;
    mode = "getspelllist";
    token = llReadKeyValue((string)ownerKey + "spells" + (string)loadedCharacter);
}

loadSpellName()
{
    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=spell-name\nagent-key=" + (string)ownerKey + "\nspell=" + (string)llList2Integer(currentSpells, loadingIndex));
}

informReady()
{
    ready = TRUE;
    llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-ready\nagent-key=" + (string)ownerKey + "\nslot=" + (string)loadedCharacter);
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

getTopMenu()
{
    if(!ready) return;

    integer l = llGetListLength(currentSpells);
    integer i = 0;
    list buttons = [];
    string msg = "You know the following spells:\n";

    for(i = 0; i < l; ++i)
    {
        msg += "\n" + (string)(i + 1) + ": " + llList2String(currentSpellNames, i);
        buttons += (string)(i + 1);
    }

    msg += "\n\nChoose a spell to cast or to get info on.";

    mode = "top";
    llDialog(ownerKey, msg, orderButtons(buttons), menuChannel);
}

getSubMenu()
{
    if(!ready) return;
    mode = "sub";
    llDialog(ownerKey, "You have selected the spell '" + llList2String(currentSpellNames, selectedSpell) + "'. What do you want to do?", ["CAST SPELL", "GET INFO", "CANCEL"], menuChannel);
}

attachBehavior()
{
    ready = FALSE;
    loadedCharacter = -1;
    currentSpells = [];
    currentSpellNames = [];
    if(listener != -1) 
    {
        llListenRemove(listener);
        listener = -1;
    }
    if(menuListener != -1) 
    {
        llListenRemove(menuListener);
        menuListener = -1;
    }

    integer attachPoint = llGetAttached();
    if(attachPoint == 0) 
    {
        llOwnerSay("Don't rez me, wear me!");
        return;
    }
    else if(attachPoint != 6)
    {
        invisible = TRUE;
        llSetAlpha(0.0, ALL_SIDES);
        llRequestPermissions(ownerKey, PERMISSION_ATTACH);
        llOwnerSay("Starting up in invisible mode... (Attach me to your right hand to make me visible.)");
    }
    else
    {
        invisible = FALSE;
        llSetAlpha(1.0, ALL_SIDES);
        llRequestPermissions(ownerKey, PERMISSION_TRIGGER_ANIMATION | PERMISSION_ATTACH);
        llOwnerSay("Starting up... (Attach me anywhere but your right hand to make me invisible.)");
    }

    menuChannel = ((integer)("0x"+llGetSubString((string)llGenerateKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFF;
    menuListener = llListen(menuChannel, "", ownerKey, "");
    listener = llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
    llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-attached\nagent-key=" + (string)ownerKey + "\nversion=" + (string)version);
}

default
{
    listen(integer channel, string name, key id, string message)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            if(target != "client") return;

            string agentKey = getValueFromKey(dict, "agent-key");
            if(agentKey != (string)ownerKey) return;

            string mode = getValueFromKey(dict, "mode");

            if(mode == "book-unload-character")
            {
                ready = FALSE;
                llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-not-ready\nagent-key=" + (string)ownerKey);
                currentSpells = [];
                currentSpellNames = [];
                loadedCharacter = -1;
            }
            else if(mode == "book-load-character")
            {
                ready = FALSE;
                llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-not-ready\nagent-key=" + (string)ownerKey);
                loadedCharacter = (integer)getValueFromKey(dict, "slot");
                casterName = getValueFromKey(dict, "name");
                loadSpells();
            }
            else if(mode == "book-reload")
            {
                ready = FALSE;
                llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-not-ready\nagent-key=" + (string)ownerKey);
                loadSpells();
            }
            else if(mode == "book-menu")
            {
                getTopMenu();
            }
            else if(mode == "spell-name")
            {
                currentSpellNames += getValueFromKey(dict, "name");
                loadingIndex++;
                integer l = llGetListLength(currentSpells);
                if(loadingIndex >= l)
                {   
                    informReady();
                    return;
                }
                else
                {
                    loadSpellName();
                }
            }
            else if(mode == "detach-outdated")
            {
                llOwnerSay("Please get a new spellbook via the HUD, this one is outdated.");
                llDetachFromAvatar();
            }
        }
        else
        {
            if(mode == "top")
            {
                selectedSpell = ((integer)message)-1;
                getSubMenu();
            }
            else if(mode == "sub")
            {
                if(message == "CAST SPELL")
                {
                    mode = "effect";
                    llTextBox(ownerKey, "Please describe in short the effect of the spell you are casting. (Max 255 characters.)", menuChannel);
                }
                else if(message == "GET INFO")
                {
                    llOwnerSay("Requesting spell info...");
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=give-spell\nagent-key=" + (string)llGetOwner() + "\nspell=" + (string)llList2Integer(currentSpells, selectedSpell));
                    getSubMenu();
                }
            }
            else if(mode == "effect")
            {
                message = casterName + " cast the spell '" + llList2String(currentSpellNames, selectedSpell) + "' with the following described effect:######" + llStringTrim(message, STRING_TRIM);
                llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Spell\nmessage=" + message);
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=webhook\nname=Crystalgate Spell\nmessage=" + message);
            }
        }
    }

    dataserver(key t, string data)
    {
        if(t == token && mode == "getspelllist")
        {
            if(startswith(data, "0,"))
            {
                informReady();
                return;
            }
            else
            {
                list spells = llParseStringKeepNulls(llGetSubString(data, 2, -1), [","], []);
                integer l = llGetListLength(spells);
                integer i = 0;
                for(i = 0; i < l; ++i)
                {
                    currentSpells += (integer)llList2String(spells, i);
                }
                loadSpellName();
            }
        }
    }

    touch_start(integer num_detected)
    {
        if(llDetectedKey(0) == ownerKey) getTopMenu();
    }

    state_entry()
    {
        ownerKey = llGetOwner();
        attachBehavior();
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation("hold");
            llSetTimerEvent(5.0);
        }
    }

    timer()
    {
        if(invisible) return;
        llStopAnimation("hold");
        llSleep(0.05);
        llStartAnimation("hold");
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            llSetTimerEvent(0.0);
            ready = FALSE;
            llRegionSayTo(ownerKey, CG_IPC_CHANNEL, "target=client\nmode=book-not-ready\nagent-key=" + (string)ownerKey);
        }
    }

    on_rez(integer start)
    {
        llSetTimerEvent(0.0);
        if(ownerKey != llGetOwner())
        {
            llResetScript();
        }
        else
        {
            attachBehavior();
        }
    }
}