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
    llSetObjectName("The murmuring");
    string greet = llGetDisplayName(avatar);
    llRegionSayTo(avatar, 0,
        "/me grows louder and louder as you approach, yet it remains indistinct in a strange unknowable language... As you enter the strange ritualistic chamber, the murmurs abruptly stop, being replaced by a singular whisper. While that whisper is in that same unknown language, you somehow know that it is drawing you to the chalice ahead...\n\nA quick survey of the room reveals no exits but the one back to the inescapable cave you came from... Will you dare approach, or would you rather wait until starvation sets in?");
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
    
                    if((llList2Integer(details, 0) == 1 && llList2Key(details, 1) == developerUuid && contains(llList2String(details, 2), "HUD")))
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