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
key id;
key token;

default
{
    touch_start(integer total_number)
    {
        id  = llDetectedKey(0);
        
        if(llAgentInExperience(id) == FALSE)
        {
            llInstantMessage(id, "Thank you for your interest in Crystalgate! Your HUD will attach after you accept the experience.");
            llRequestExperiencePermissions(id, "");
        }
        else
        {
            token = llReadKeyValue((string)id);
        }
    }
    
    experience_permissions(key target)
    {
        llUpdateKeyValue((string)id, "NEW", FALSE, "");
    }

    experience_permissions_denied(key id, integer reason)
    {
        if(reason == XP_ERROR_NOT_PERMITTED)
        {
            llInstantMessage(id, "It seems you have declined the experience, please click me again and accept the experience. It's also possible that you have blocked the experience, in that case please click secondlife:///app/experience/cffbc32a-90d6-11e7-8cd9-fa4c4c32a074/profile and set it to \"Allow\".");
        }
    }
    
    dataserver(key t, string value)
    {
        if(t != token) return;
        if(startswith(value, "0") || value == "1,fancy=1")
        {
            llUpdateKeyValue((string)id, "NEW", FALSE, "");
            llRegionSayTo(id, 0, "Inviting you to the OOC group and converting your observer tag into a HUD, welcome to Crystalgate! If your group invite doesn't arrive, contact an admin, but feel free to start playing!");
        }
        else
        {
            llRegionSayTo(id, 0, "Reattaching your HUD...");
        }
        llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=detach");
        giveGroupInvite(id, "8217296c-97a8-a9f8-5bef-933e5fd5ddb1");
    }
}
