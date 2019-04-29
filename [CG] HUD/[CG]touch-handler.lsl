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
integer main = 1;
integer menubuttons = 0;
integer selectionbuttons = 0;

handleState(string s)
{
    hudState = s;
    if(hudState == "hidden")
    {
        llSetPos(llList2Vector(hudPositions, 0));
    }
    else if(hudState == "normal")
    {
        llSetPos(llList2Vector(hudPositions, 1));
    }
    else if(hudState == "menus")
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)0, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)1, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)2, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)3, (string)(<1.0, 1.0, 1.0>));
        llSetPos(llList2Vector(hudPositions, 2));
    }
    else if(hudState == "character" || hudState == "status" || hudState == "teleport" || hudState == "tools")
    {
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)0, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)1, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)2, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)3, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)4, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)5, (string)(<1.0, 1.0, 1.0>));
        llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "none", NULL_KEY);
        llSetPos(llList2Vector(hudPositions, 3));
    }
    else
    {
        llSetPos(llList2Vector(hudPositions, 3));
    }
    llMessageLinked(LINK_THIS, CLIENT_SET_HUD_STATE, s, NULL_KEY);
}

getLinks()
{
    integer i;
    for(i = llGetNumberOfPrims(); i >= 0; --i)
    {
        list info = llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        string name = llList2String(info, 0);
       
        if(name == "menubuttons")
        {
            menubuttons = i;
        }
        else if(name == "selectionbuttons")
        {
            selectionbuttons = i;
        }
    }
}

default
{
    state_entry()
    {
        getLinks();
        log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
        llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, llGetScriptName(), NULL_KEY);
    }

    touch_end(integer num_detected)
    {
        if(hudState == "hidden")
        {
            handleState("normal");
            return;
        }
        else if(hudState == "normal" && llDetectedTouchST(0) == TOUCH_INVALID_TEXCOORD)
        {
            handleState("hidden");
            return;
        }
        else if(hudState == "normal")
        {
            handleState("menus");
            return;
        }
        
        integer link = llDetectedLinkNumber(0);
        if(link == main)
        {
            llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), TEXTURE_TRANSPARENT);
            handleState("normal");
        }
        else if(link == menubuttons)
        {
            integer button = llDetectedTouchFace(0);
            if(button == 0)
            {
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)0, (string)(<1.0, 1.0, 1.0>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)1, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)2, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)3, (string)(<0.5, 0.5, 0.5>));
                handleState("character");
            }
            else if(button == 1)
            {
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)1, (string)(<1.0, 1.0, 1.0>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)0, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)2, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)3, (string)(<0.5, 0.5, 0.5>));
                handleState("status");
            }
            else if(button == 2)
            {
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)2, (string)(<1.0, 1.0, 1.0>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)1, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)0, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)3, (string)(<0.5, 0.5, 0.5>));
                handleState("teleport");
            }
            else if(button == 3)
            {
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)3, (string)(<1.0, 1.0, 1.0>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)1, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)2, (string)(<0.5, 0.5, 0.5>));
                llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)0, (string)(<0.5, 0.5, 0.5>));
                handleState("tools");
            }
        }
        else if(link == selectionbuttons)
        {
            integer button = llDetectedTouchFace(0);
            llMessageLinked(LINK_THIS, CLIENT_BUTTON_CLICKED, (string)button, NULL_KEY);
        }
    }

    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_CLOSE_MENUS)
        {
            llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)(-1), TEXTURE_TRANSPARENT);
            handleState("normal");
        }
    }
}