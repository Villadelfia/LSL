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

list text = [1, 1, 1, 1, 1, 1];
integer main = 1;
integer menubuttons = 0;
integer selectionbuttons = 0;
string line1 = "                        ";
string line2 = "                        ";

vector selectionButtonScale = <0.33333, 0.5, 0.0>;
list selectionButtonOffsets = [<-0.33333, 0.25, 0.0>, <0.0, 0.25, 0.0>, <0.33333, 0.25, 0.0>, <-0.33333, -0.25, 0.0>, <0.0, -0.25, 0.0>, <0.33333, -0.25, 0.0>];
vector menuButtonScale = <1.0, 0.25, 0.0>;
list menuButtonOffsets = [<0.0, 0.375, 0.0>, <0.0, 0.125, 0.0>, <0.0, -0.125, 0.0>, <0.0, -0.375, 0.0>];

getLinks()
{
    integer i;
    for(i = llGetNumberOfPrims(); i >= 0; --i)
    {
        list info = llGetLinkPrimitiveParams(i, [PRIM_NAME, PRIM_DESC]);
        string name = llList2String(info, 0);
        string desc = llList2String(info, 1);
       
        if(name == "text")
        {
            integer id = (integer)desc;
            text = llListReplaceList(text, [i], id, id);
           
            llSetLinkPrimitiveParamsFast(i,
                [PRIM_COLOR, ALL_SIDES, <0.445, 1.000, 0.445>, 1.0,
                 PRIM_TEXTURE, ALL_SIDES, fontTexture, <1.6, 1.6, 0>, indexToOffset(llSubStringIndex(fontMap, " ")), 0.0]);
        }
        else if(name == "menubuttons")
        {
            menubuttons = i;
            llSetLinkPrimitiveParamsFast(menubuttons,
                [PRIM_COLOR, 0, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 1, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 2, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 3, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_TEXTURE, 0, menuButtonTexture, menuButtonScale, llList2Vector(menuButtonOffsets, 0), 0.0,
                 PRIM_TEXTURE, 1, menuButtonTexture, menuButtonScale, llList2Vector(menuButtonOffsets, 1), 0.0,
                 PRIM_TEXTURE, 2, menuButtonTexture, menuButtonScale, llList2Vector(menuButtonOffsets, 2), 0.0,
                 PRIM_TEXTURE, 3, menuButtonTexture, menuButtonScale, llList2Vector(menuButtonOffsets, 3), 0.0]);
        }
        else if(name == "selectionbuttons")
        {
            selectionbuttons = i;
            displayTexture(-1, TEXTURE_TRANSPARENT);
            setArrowState("none");
            llSetLinkPrimitiveParamsFast(selectionbuttons,
                [PRIM_COLOR, 6, <1.0, 1.0, 1.0>, 0.0,
                 PRIM_COLOR, 7, <1.0, 1.0, 1.0>, 0.0,
                 PRIM_TEXTURE, 6, arrowTexture, <1.0, 1.0, 0.0>, <1.0, 1.0, 0.0>, PI,
                 PRIM_TEXTURE, 7, arrowTexture, <1.0, 1.0, 0.0>, <1.0, 1.0, 0.0>, 0.0]);
        }
    }
}

displayTexture(integer slot, key uuid)
{
    if(slot == -1)
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
                [PRIM_COLOR, 0, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 1, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 2, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 3, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 4, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_COLOR, 5, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_TEXTURE, 0, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 0), 0.0,
                 PRIM_TEXTURE, 1, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 1), 0.0,
                 PRIM_TEXTURE, 2, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 2), 0.0,
                 PRIM_TEXTURE, 3, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 3), 0.0,
                 PRIM_TEXTURE, 4, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 4), 0.0,
                 PRIM_TEXTURE, 5, uuid, selectionButtonScale, llList2Vector(selectionButtonOffsets, 5), 0.0]);
    }
    else
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
                [PRIM_COLOR, slot, <1.0, 1.0, 1.0>, 1.0,
                 PRIM_TEXTURE, slot, uuid, <1.0, 1.0, 0.0>, <1.0, 1.0, 0.0>, 0.0]);
    }
}

setArrowState(string s)
{
    if(s == "left")
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
            [PRIM_COLOR, 6, <1.0, 1.0, 1.0>, 1.0,
             PRIM_COLOR, 7, <1.0, 1.0, 1.0>, 0.0]);
    }
    else if(s == "right")
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
            [PRIM_COLOR, 6, <1.0, 1.0, 1.0>, 0.0,
             PRIM_COLOR, 7, <1.0, 1.0, 1.0>, 1.0]);
    }
    else if(s == "both")
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
            [PRIM_COLOR, 6, <1.0, 1.0, 1.0>, 1.0,
             PRIM_COLOR, 7, <1.0, 1.0, 1.0>, 1.0]);
    }
    else if(s == "none")
    {
        llSetLinkPrimitiveParamsFast(selectionbuttons,
            [PRIM_COLOR, 6, <1.0, 1.0, 1.0>, 0.0,
             PRIM_COLOR, 7, <1.0, 1.0, 1.0>, 0.0]);
    }
}

colorSelectionButton(integer button, vector color)
{
    llSetLinkPrimitiveParamsFast(selectionbuttons, [PRIM_COLOR, button, color, 1.0]);
}

colorMenuButton(integer button, vector color)
{
    llSetLinkPrimitiveParamsFast(menubuttons, [PRIM_COLOR, button, color, 1.0]);
}
 
vector indexToOffset(integer index)
{
    if(index < 0 || index > 99) return <0, 0, 0>;
    integer x = index % 10;
    integer y = index / 10;
    return <-0.7+(x*0.1), 0.7-(y*0.1), 0>;
}
 
renderMessage()
{
    
    integer j = 0;
    list options = [];
    string message = line1 + line2;
   
    while(j < 6)
    {
        integer i = 0;
        integer link = llList2Integer(text, j);
        options += PRIM_LINK_TARGET;
        options += link;
        while(i < 8)
        {
            options += [PRIM_TEXTURE, i, fontTexture, <1.6,1.6,0>, indexToOffset(llSubStringIndex(fontMap, llGetSubString(message, i+(j*8), i+(j*8)))), 0.0];
            ++i;
        }
        ++j;
    }
    llSetLinkPrimitiveParamsFast(0, options);
}

default
{
    state_entry()
    {
        getLinks();
        log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
        llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, llGetScriptName(), NULL_KEY);
    }
   
    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_DISPLAY_TEXT)
        {
            if(llStringLength(line1) > 24) return;
            integer line = (integer)((string)str2);
            if(line == 1)
            {
                line1 = str1;
                while(llStringLength(line1) < 24) line1 += " ";
            }
            else
            {
                line2 = str1;
                while(llStringLength(line2) < 24) line2 += " ";
            }
            renderMessage();
        }
        else if(api_id == CLIENT_DISPLAY_TEXTURE)
        {
            displayTexture((integer)str1, str2);
        }
        else if(api_id == CLIENT_SET_ARROW_STATE)
        {
            setArrowState(str1);
        }
        else if(api_id == CLIENT_COLOR_SELECTION_BUTTON)
        {
            colorSelectionButton((integer)str1, (vector)((string)str2));
        }
        else if(api_id == CLIENT_COLOR_MENU_BUTTON)
        {
            colorMenuButton((integer)str1, (vector)((string)str2));
        }
    }
}