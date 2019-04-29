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
integer totalTeleports = 0;
integer totalPages = 0;
integer currentPage = 0;
integer loadedInPage = 0;
list names = [];
list locs = [];
list lookats = [];
integer listener = -1;

handleTeleportImagesInPage()
{
    if(loadedInPage == 6) return;
    if(currentPage*6+loadedInPage == totalTeleports) return;
    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=teleport-get\nindex=" + (string)(currentPage*6+loadedInPage));
}

loadNewPage()
{
    loadedInPage = 0;
    names = [];
    locs = [];
    lookats = [];
    llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), TEXTURE_TRANSPARENT);

    if(currentPage == 0)
    {
        llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "right", NULL_KEY);
    }
    else if(currentPage == totalPages)
    {
        llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "left", NULL_KEY);
    }
    else
    {
        llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "both", NULL_KEY);
    }

    handleTeleportImagesInPage();
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
                if(hudState == "teleport")
                {
                    totalPages = 0;
                    currentPage = 0;
                    loadedInPage = 0;
                    names = [];
                    locs = [];
                    lookats = [];
                    llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), TEXTURE_TRANSPARENT);
                    listener = llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
                    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=teleport-count\nagent-key=" + (string)llGetOwner());
                    llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, "  Select a Destination  ", (string)2);
                }
                else
                {
                    if(listener != -1)
                    {
                        llListenRemove(listener);
                        listener = -1;
                    }
                }
            }
        }

        if(hudState != "teleport") return;
        
        if(api_id == CLIENT_BUTTON_CLICKED)
        {
            integer button = (integer)str1;
            if(button > 5 && totalPages != 0 && ((loadedInPage == 6) || (currentPage*6+loadedInPage == totalTeleports)))
            {
                if(button == 6 && currentPage > 0)
                {
                    currentPage--;
                    loadNewPage();
                }
                else if(button == 7 && currentPage < totalPages)
                {
                    currentPage++;
                    loadNewPage();
                }
            }

            if(button < llGetListLength(names))
            {
                llOwnerSay("Teleporting you to " + llList2String(names, button));
                llMessageLinked(LINK_THIS, CLIENT_PERFORM_TELEPORT, (string)llList2Vector(locs, button), (key)((string)llList2Vector(lookats, button)));
                llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            string mode = getValueFromKey(dict, "mode");
            if(target != "client") return;
            if(mode == "teleport-count")
            {
                integer value = (integer)getValueFromKey(dict, "value");
                totalPages = value/6;
                totalTeleports = value;
                if(totalPages > 0)
                {
                    llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "right", NULL_KEY);
                }
                else
                {
                    llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "none", NULL_KEY);
                }
                handleTeleportImagesInPage();
            }
            else if(mode == "teleport-get")
            {
                string name = getValueFromKey(dict, "name");
                string image = getValueFromKey(dict, "image");
                string pos = getValueFromKey(dict, "pos");
                string lookat = getValueFromKey(dict, "lookat");
                names += name;
                locs += (vector)pos;
                lookats += (vector)lookat;
                llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)loadedInPage, (key)image);
                loadedInPage++;
                handleTeleportImagesInPage();
            }
        }
    }
}