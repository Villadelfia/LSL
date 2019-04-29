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
        key id  = llDetectedKey(0);
        llInstantMessage(id, "Thank you for your interest in Crystalgate! Your observer tag will attach after you accept the experience.");
        llRequestExperiencePermissions(id, "");
    }

    experience_permissions_denied(key id, integer reason)
    {
        if(reason == XP_ERROR_NOT_PERMITTED)
        {
            llInstantMessage(id, "It seems you have declined the experience, please click me again and accept the experience. It's also possible that you have blocked the experience, in that case please click secondlife:///app/experience/cffbc32a-90d6-11e7-8cd9-fa4c4c32a074/profile and set it to \"Allow\".");
        }
    }
}
