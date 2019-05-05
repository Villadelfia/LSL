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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CLIENT API
// Load API.
integer CLIENT_SCRIPT_READY = 0; // llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, scriptname, NULL_KEY);

integer CLIENT_DISPLAY_TEXT = 1; // llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXT, text, (string)line);
integer CLIENT_DISPLAY_TEXTURE = 2; // llMessageLinked(LINK_THIS, CLIENT_DISPLAY_TEXTURE, (string)buttonNumber, uuid);
integer CLIENT_SET_ARROW_STATE = 3; // llMessageLinked(LINK_THIS, CLIENT_SET_ARROW_STATE, "left|right|both|none", NULL_KEY);
integer CLIENT_COLOR_SELECTION_BUTTON = 4; // llMessageLinked(LINK_THIS, CLIENT_COLOR_SELECTION_BUTTON, (string)buttonNumber, (key)buttonColor);
integer CLIENT_COLOR_MENU_BUTTON = 5; // llMessageLinked(LINK_THIS, CLIENT_COLOR_MENU_BUTTON, (string)buttonNumber, (key)buttonColor);

integer CLIENT_LOAD_CHARACTER = 6; // llMessageLinked(LINK_THIS, CLIENT_LOAD_CHARACTER, (string)slot, NULL_KEY);
integer CLIENT_CHARACTER_LOADED = 7; // llMessageLinked(LINK_THIS, CLIENT_CHARACTER_LOADED, (string)packedData, NULL_KEY);
integer CLIENT_CHARACTER_UNLOADED = 8; // llMessageLinked(LINK_THIS, CLIENT_CHARACTER_UNLOADED, "", NULL_KEY);

integer CLIENT_SET_HUD_STATE = 9; // llMessageLinked(LINK_THIS, CLIENT_SET_HUD_STATE, "normal|hidden|menus|submenuname", NULL_KEY);
integer CLIENT_BUTTON_CLICKED = 10; // llMessageLinked(LINK_THIS, CLIENT_BUTTON_CLICKED, (string)button, NULL_KEY);

integer CLIENT_CLOSE_MENUS = 11; // llMessageLinked(LINK_THIS, CLIENT_CLOSE_MENUS, "", NULL_KEY);
integer CLIENT_PERFORM_TELEPORT = 12; // llMessageLinked(LINK_THIS, CLIENT_PERFORM_TELEPORT, (string)target, (key)((string)lookat));

integer CLIENT_CHARACTER_CHANGED = 13; // llMessageLinked(LINK_THIS, CLIENT_CHARACTER_CHANGED, (string)packedData, NULL_KEY);
integer CLIENT_STATUS_CHANGED = 14; // llMessageLinked(LINK_THIS, CLIENT_STATUS_CHANGED, (string)status, (string)data);
integer CLIENT_INITIAL_VALUES = 15; // llMessageLinked(LINK_THIS, CLIENT_INITIAL_VALUES, (string)packedData, NULL_KEY);
integer CLIENT_REQUEST_INFO = 16; // llMessageLinked(LINK_THIS, CLIENT_REQUEST_INFO, "", agentKey);

integer CLIENT_SET_LEVEL_XP = 17; // llMessageLinked(LINK_THIS, CLIENT_SET_LEVEL_XP, (string)level, (key)((string)xp));
integer CLIENT_SET_TITLER_POS = 18; // llMessageLinked(LINK_THIS, CLIENT_SET_TITLER_POS, (string)pos, agentKey);
integer CLIENT_ORDER_SCAN = 19; // llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "IC|CMB|XP", NULL_KEY);
integer CLIENT_SCAN_RESULTS = 20; // llMessageLinked(LINK_THIS, CLIENT_SCAN_RESULTS, keyList, "IC|CMB|XP");
integer CLIENT_HANDLE_XP_TICK = 21; // llMessageLinked(LINK_THIS, CLIENT_HANDLE_XP_TICK, xpData, (key)multiplier);

integer CLIENT_SET_COMBAT_DATA = 22; // llMessageLinked(LINK_THIS, CLIENT_SET_COMBAT_DATA, "init|hp", (key)((string)value));
integer CLIENT_LEAVE_COMBAT = 23; // llMessageLinked(LINK_THIS, CLIENT_LEAVE_COMBAT, "", NULL_KEY);

integer CLIENT_BOOK_STATUS = 24; // llMessageLinked(LINK_THIS, CLIENT_BOOK_STATUS, (string)slot or -1, NULL_KEY);
integer CLIENT_BOOK_ATTACHED = 25; // llMessageLinked(LINK_THIS, CLIENT_BOOK_ATTACHED, "", NULL_KEY);


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SERVER API
integer SERVER_DETERMINE_REZ = 0; // llMessageLinked(LINK_THIS, SERVER_DETERMINE_REZ, (string)scriptID, agentKey);
integer SERVER_AGENT_READY   = 1; // llMessageLinked(LINK_THIS, SERVER_AGENT_READY, "", NULL_KEY);
integer SERVER_REZ_CLUE      = 2; // llMessageLinked(LINK_THIS, SERVER_REZ_CLUE, "", agentKey);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHANNELS
integer CG_COMMAND_CHANNEL   = 1;
integer CG_IC_CHANNEL_1      = 2;
integer CG_IC_CHANNEL_2      = 4;
integer CG_DESCRIBE_CHANNEL  = 3;
integer CG_OOC_CHANNEL       = 5;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SUPER-GLOBALS
string fontMap = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~     ";
string fontTexture = "bf38763e-9b99-e83b-f8d7-0f003d66103c";
string idleTexture = "761313c8-b6ad-ee6a-cd4d-ab3a2428d8f8";
string menuButtonTexture = "9fc10cbb-4ea5-018a-e672-466bd53203df";
string arrowTexture = "ec1e58e1-babd-ff44-a0ba-c964bacff3de";
string characterMenuTexture = "564e2d0d-7e65-3b10-ed2c-62b6f79dfc4f";
string characterSelectTexture = "3f6bb0e1-0395-9eb0-c907-903a395ff8a4";
string characterStatusTexture = "457ed1e3-3acb-8e29-59ac-a75fd07cb907";
string rpToolsTexture = "1af73ad2-3797-cc44-ae45-4f577a26577f";
string rpToolsCombatTexture = "ed2ef765-6630-87ac-c893-93f4084af9cf";
string attachTarget = NULL_KEY;
integer BOOK_VERSION = 1;
list hudPositions = [<0.00000, 0.00000, -0.13476>, <0.00000, 0.00000, -0.05731>, <0.00000, 0.00000, -0.00335>, <0.00000, 0.00000, 0.22959>];


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SECRETS
#include <CG-Private.lsl>
// This file should define the following variables:
// integer CG_IPC_CHANNEL = X;
// integer CG_PIN = X;
// key developerUuid = "X";
// integer TELEPORT_CHANNEL = X;
// integer mailboxChannel = X;
// string apexApiKey = "X";
// string apexApiSecret = "X";
// string DISCORD_WEBHOOK = "X";
// string DISCORD_STAFF_WEBHOOK = "X";
// string DISCORD_PRIVATE_WEBHOOK = "X";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DEVELOPMENT
integer debugMode = FALSE; // Must be false and recompile for deploy.


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL UTILITY FUNCTIONS
// Will parse a string in the format key=value\nkey2=value2\nkey3=value3...
string getValueFromKey(list dict, string k)
{
    integer length = llGetListLength(dict);
    integer index = 0;
    while(index < length)
    {
        list kv = llParseStringKeepNulls(llList2String(dict, index), ["="], []);
        integer kvLength = llGetListLength(kv);
        if(kvLength != 2)
        {
            return "";
        }

        if(k == llList2String(kv, 0))
        {
            return llList2String(kv, 1);
        }
        index++;
    }
    return "";
}


// Utility functions for finding substrings within strings.
integer contains(string haystack, string needle)
{
    return ~llSubStringIndex(haystack, needle);
}

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

integer endswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

string strreplace(string src, string from, string to)
{
    integer len = (~-(llStringLength(from)));
    if(~len)
    {
        string  buffer = src;
        integer b_pos = ERR_GENERIC;
        integer to_len = (~-(llStringLength(to)));
        @loop;
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos)
        {
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return src;
}

string makeProper(string src)
{
    src = llStringTrim(src, STRING_TRIM);
    src = llToUpper(llGetSubString(src, 0, 0)) + llGetSubString(src, 1, -1);
    if(startswith(src, "#"))
    {
        src = llGetSubString(src, 1, -1);
    }
    if(!endswith(src, ".") && !endswith(src, "!") && !endswith(src, "?"))
    {
        src += ".";
    }
    return src;
}


// Logging utility functions.
log(string message)
{
    llOwnerSay(llGetScriptName() + ": " + message);
}

reportReady()
{
    log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
    llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, llGetScriptName(), NULL_KEY);
}

reportTopReady(string object)
{
    log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
    if(debugMode) state running;
    log("\n\n\n\n!!! " + object + " IS READY FOR SERVER !!!\n\n\n\n");
}


// Script handling utility functions.
resetAll()
{
    resetAllOther();
    llResetScript();
}

resetAllOther()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string item;
    while(count--)
    {
        item = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(item != llGetScriptName())  
        {
            llResetOtherScript(item);
        }
    }
}

stopAllOther()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string item;
    while(count--)
    {
        item = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(item != llGetScriptName())  
        {
            llSetScriptState(item, FALSE);
        }
    }
}

startAllOther()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    string item;
    while(count--)
    {
        item = llGetInventoryName(INVENTORY_SCRIPT, count);
        if(item != llGetScriptName())  
        {
            llSetScriptState(item, TRUE);
        }
    }
}


// Math utility functions.
float max(float x,float y)
{
    return ((llAbs(x >= y)) * x) + ((llAbs(x < y)) * y);
}
 
float min(float x,float y)
{
    return ((llAbs(x >= y)) * y) + ((llAbs(x < y)) * x);
}

integer imin(integer x, integer y)
{
    return ((llAbs(x >= y)) * y) + ((llAbs(x < y)) * x);
}

integer isInRange(float bottom, float top, float i)
{
    return i >= bottom && i <= top;
}

integer isInRect(list box, vector point)
{
    vector p1 = llList2Vector(box, 0);
    vector p2 = llList2Vector(box, 1);
    float minx = min(p1.x, p2.x);
    float maxx = max(p1.x, p2.x);
    float miny = min(p1.y, p2.y);
    float maxy = max(p1.y, p2.y);
    return isInRange(minx, maxx, point.x) == TRUE && isInRange(miny, maxy, point.y) == TRUE;
}


// Gets the length of a given string in bytes for the purposes of handling renaming.
integer getStringBytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}


// Domain specific functions.
failAndDie(integer rezzer)
{
    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=attach-fail\nrezzer=" + (string)rezzer);
    llDie();
}

attachSuccess(string what, integer rezzer)
{
    llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=attach-"+what+"-success\nrezzer=" + (string)rezzer);
}

trustedSay(string oName, string message)
{
    string o = llGetObjectName();
    llSetObjectName(oName);
    llOwnerSay(message);
    llSetObjectName(o);
}

integer random(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

giveGroupInvite(key agent, string group)
{
    llHTTPRequest("http://api.apexbots.com",
            [HTTP_METHOD,"POST",
             HTTP_MIMETYPE,"application/x-www-form-urlencoded"]
            ,"command=Invite"+
            "&api_key="    + llEscapeURL(apexApiKey) +
            "&api_secret=" + llEscapeURL(apexApiSecret) +
            "&AvatarKey="  + llEscapeURL((string)agent)+
            "&GroupKey="   + llEscapeURL(group));
}