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

default
{
    touch_start(integer total_number)
    {
        key agent = llDetectedKey(0);
        if(!llAgentInExperience(agent))
        {
            llRegionSayTo(agent, 0, "Please accept the secondlife:///app/experience/" + llList2String(llGetExperienceDetails(NULL_KEY), 2) + "/profile experience permissions to use this sim's teleporters.");
        }
        llRequestExperiencePermissions(agent, "");
    }
    
    collision_start(integer num)
    {
        key agent = llDetectedKey(0);
        if(!llAgentInExperience(agent))
        {
            llRegionSayTo(agent, 0, "Please accept the secondlife:///app/experience/" + llList2String(llGetExperienceDetails(NULL_KEY), 2) + "/profile experience permissions to use this sim's teleporters.");
        }
        llRequestExperiencePermissions(agent, "");
    }
    
    experience_permissions(key agent)
    {
        llRegionSayTo(agent, 0, "You're being teleported back to the landing point. Please note that in character there is NO WAY to use this crystal to get back. This was only added for convenience.");
        llTeleportAgent(agent, "", (vector)llList2String(llParseString2List(llGetObjectDesc(), [";"], []), 0), (vector)llList2String(llParseString2List(llGetObjectDesc(), [";"], []), 1));
    }
    
    experience_permissions_denied(key agent, integer reason)
    {
        llRegionSayTo(agent, 0, "You need to accept the secondlife:///app/experience/" + llList2String(llGetExperienceDetails(NULL_KEY), 2) + "/profile experience to use this sim's teleporters.");
    }
}