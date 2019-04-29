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
integer idle = 1;
list queue = [];
key checking;
key token = NULL_KEY;

enqueue(key avatar)
{
    queue = queue + avatar;
}

handleQueue()
{
    if(llGetListLength(queue) == 0) return;
    checking = llList2Key(queue, 0);
    token = llReadKeyValue((string)checking);
    queue = llDeleteSubList(queue, 1, -1);
}

doFancyTp(key agent)
{
    if(idle == 1)
    {
        // Fancy teleport.
        integer startParam;
        vector target = (vector)llList2String(llParseString2List(llGetScriptName(), [";"], []), 0);
        vector lookat = (vector)llList2String(llParseString2List(llGetScriptName(), [";"], []), 1);
        
        integer x = llRound(target.x);
        if(x < 0) x = 0;
        if(x > 255) x = 255;
        
        integer y = llRound(target.y);
        if(y < 0) x = 0;
        if(y > 255) x = 255;
        y = y << 8;
        
        integer z = llRound(target.z);
        if(z < 0) x = 0;
        if(z > 4095) x = 4095;
        z = z << 16;
        
        integer angle = llRound(llAtan2(lookat.y - target.y, lookat.x - target.x) * (16 / TWO_PI));
        if(angle < 0) angle = 15;
        if(angle > 15) angle = 0;
        angle = angle << 28;
        startParam = x | y | z | angle;
        
        llSetObjectDesc((string)agent);
        idle = 0;
        llRezObject("tpeffect", llGetPos()-<0,0,10>, ZERO_VECTOR, ZERO_ROTATION, startParam);
    }
    else
    {
        string o = llGetObjectName();
        llSetObjectName("As");
        llRegionSayTo(agent, 0, "/me you get closer to the chalice, you begin to feel lightheaded. As darkness begins to creep in from the corners of your vision, you feel some kind of eldritch force kneading your body, moulding it into something else...");
        llRequestExperiencePermissions(agent, "");
        llSetObjectName("With a start,");
        llRegionSayTo(agent, 0, "/me you wake back up in a strange ruin. Behind you, there is a crystal showing the room you were just in, but no matter what you try, it seems you can not pass through the other way. Examining yourself, you discover that the feeling you had before you fainted wasn't wrong... You find yourself entirely less human than before.\n\n((This concludes the guided intro to Crystalgate. We hope you enjoy your time here. You'll stop seeing these welcome messages once you create a character in the HUD.))");
        llSetObjectName(o);
    }
}

doTp(key agent)
{
    list attachments = llGetAttachedList(agent);
    integer j = llGetListLength(attachments) - 1;
    integer fancy = TRUE;
    for(; j >= 0; --j)
    {
        list details = llGetObjectDetails(llList2Key(attachments, j), [OBJECT_TEMP_ATTACHED, OBJECT_CREATOR, OBJECT_NAME]);
        if((llList2Integer(details, 0) == 1 && llList2Key(details, 1) == developerUuid && contains(llList2String(details, 2), "HUD")))
        {
            fancy = FALSE;
        }
    }
    
    if(fancy)
    {
        doFancyTp(agent);
    }
    else
    {
        if(token == NULL_KEY)
        {
            enqueue(agent);
            handleQueue();
        }
        else
        {
            llRequestExperiencePermissions(agent, "");
        }
    }
}

default
{
    state_entry()
    {
        llVolumeDetect(TRUE);
        llListen(TELEPORT_CHANNEL, "", NULL_KEY, "");
    }
    
    collision_start(integer num)
    {
        key agent = llDetectedKey(0);
        if(!llAgentInExperience(agent))
        {
            llRegionSayTo(agent, 0, "Please fetch the observer tag at the landing point. You can find it on the wall across from where you teleported in.");
        }
        else
        {
            doTp(agent);
        }
    }
    
    experience_permissions(key agent)
    {
        llTeleportAgent(agent, "", (vector)llList2String(llParseString2List(llGetScriptName(), [";"], []), 0), (vector)llList2String(llParseString2List(llGetScriptName(), [";"], []), 1));
    }
    
    listen(integer c, string n, key id, string m)
    {
        if(startswith(m, "TP_SUCCESS"))
        {
            idle = 1;
        }
        else
        {
            string agent = llList2String(llParseString2List(m, ["\n"], []), 0);
            idle = 1;
            llRequestExperiencePermissions((key)agent, "");
        }
    }
    
    dataserver(key t, string value)
    {
        if(startswith(value, "0") || value == "1,NEW" || contains(value, "fancy=1"))
        {
            doFancyTp(checking);
        }
        else
        {
            llRequestExperiencePermissions(checking, "");
        }
        token = NULL_KEY;
        handleQueue();
    }
}
