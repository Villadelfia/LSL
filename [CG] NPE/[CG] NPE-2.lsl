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
list queue = [];
key checking;

doGreet(key avatar)
{
    string name = llGetObjectName();
    llSetObjectName("You can hear");
    string greet = llGetDisplayName(avatar);
    llRegionSayTo(avatar, 0,
        "/me an indistinct murmuring from beyond the darkness ahead...");
    llSetObjectName(name);
}

enqueue(key avatar)
{
    queue = queue + avatar;
}

handleQueue()
{
    if(llGetListLength(queue) == 0) return;
    checking = llList2Key(queue, 0);
    llReadKeyValue((string)checking);
    queue = llDeleteSubList(queue, 1, -1);
}

default
{
    state_entry()
    {
        llVolumeDetect(TRUE);
    }
    
    collision_start(integer num)
    {
        if(llGetListLength(queue) != 0) return;
        do
        {
            key avatar = llDetectedKey(--num);
            if(llGetAgentSize(avatar) != ZERO_VECTOR)
            {
                list attachments = llGetAttachedList(avatar);
                integer j = llGetListLength(attachments) - 1;
                integer shouldGreet = TRUE;
                for(; j >= 0; --j)
                {
                    list details = llGetObjectDetails(llList2Key(attachments, j), [OBJECT_TEMP_ATTACHED, OBJECT_CREATOR, OBJECT_NAME]);
    
                    if((llList2Integer(details, 0) == 1 && llList2Key(details, 1) == developerUuid && contains(llList2String(details, 2), "TITLER")))
                    {
                        shouldGreet = FALSE;
                    }
                }
                if(shouldGreet)
                {
                    doGreet(avatar);
                }
                else
                {
                    enqueue(avatar);
                }
            }
        } while(num);
        handleQueue();
    }
    
    dataserver(key t, string value)
    {
        if(startswith(value, "0") || value == "1,NEW" || contains(value, "fancy=1"))
        {
            doGreet(checking);
        }
        handleQueue();
    }
}