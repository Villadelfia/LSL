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
key rezzer;

vector target;
vector lookat;
float alpha;

default
{
    state_entry()
    {
        alpha = 0.0;
    }
    
    on_rez(integer start)
    {
        if(llGetAttached() != 0) return;
        rezzer = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        attachTarget = llList2String(llGetObjectDetails(rezzer, [OBJECT_DESC]), 0);
        llSetTimerEvent(10.0);
        llRequestExperiencePermissions((key)attachTarget, "");
    }
    
    experience_permissions(key id)
    {
        if(llGetAgentSize(id) != ZERO_VECTOR)
        {
            llAttachToAvatarTemp(ATTACH_HUD_CENTER_1);
        }
        
        if(llGetAttached() == 0)
        {
            llRegionSayTo(rezzer, TELEPORT_CHANNEL, "TP_FAIL\n" + (string)attachTarget);
            llDie();
        }
    }
        
    experience_permissions_denied(key agent_id, integer reason)
    {
        llRegionSayTo(rezzer, TELEPORT_CHANNEL, "TP_FAIL\n" + (string)attachTarget);
        llDie();
    }
    
    attach(key id)
    {
        if(id)
        {
            llRegionSayTo(rezzer, TELEPORT_CHANNEL, "TP_SUCCESS\n" + (string)attachTarget);
            llSetTimerEvent(0.0);
            state running;
        }
        else
        {
            llRegionSayTo(rezzer, TELEPORT_CHANNEL, "TP_FAIL\n" + (string)attachTarget);
            llDie();
        }
    }

    timer()
    {
        llRegionSayTo(rezzer, TELEPORT_CHANNEL, "TP_FAIL\n" + (string)attachTarget);
        llDie();
    }
}

state running
{
    state_entry()
    {
        // Calculate destination.
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA);
        integer start = llGetStartParameter();
        integer x = start & 0xFF;
        integer y = (start & 0xFF00) >> 8;
        integer z = (start & 0xFFF0000) >> 16;
        integer dir = (start & 0xF0000000) >> 28;
        float theta = (TWO_PI / 16.0) * dir;
        
        target = <x, y, z>;
        lookat = target + <llCos(theta), llSin(theta), 0>;        
    }
    
    run_time_permissions(integer perm)
    {
        llSetCameraParams([
            CAMERA_ACTIVE, 1,
            CAMERA_POSITION, <124.15630, 121.95350, 1016.92500>,
            CAMERA_POSITION_LOCKED, TRUE,
            CAMERA_FOCUS, <122.59887, 118.49918, 1015.61066>,
            CAMERA_FOCUS_LOCKED, TRUE,
            CAMERA_FOCUS_LAG, 3.0,
            CAMERA_POSITION_LAG, 3.0]);
        llSetObjectName("As");
        llOwnerSay("/me you get closer to the chalice, you begin to feel lightheaded. As darkness begins to creep in from the corners of your vision, you feel some kind of eldritch force kneading your body, moulding it into something else...");
        llStartAnimation("faint");
        llSleep(1.5);
        llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, TRUE, FALSE);
        llSetTimerEvent(0.02);
    }
    
    timer()
    {
        if(alpha < 1.0)
        {
            alpha += 0.01;
            llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <0, 0, 0>, alpha]);
        }
        else
        {
            llSetTimerEvent(0.0);
            llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <0, 0, 0>, 1.0]);
            llSleep(0.2);
            llRequestExperiencePermissions(llGetOwner(), "");
        }
    }
    
    experience_permissions(key id)
    {
        llTeleportAgent(llGetOwner(), "", target, lookat);
        llSetCameraParams([
            CAMERA_ACTIVE, 1,
            CAMERA_POSITION, <34.65888, 205.95378, 24.89704>,
            CAMERA_POSITION_LOCKED, TRUE,
            CAMERA_FOCUS, <33.0, 203.0, 23.0>,
            CAMERA_FOCUS_LOCKED, TRUE,
            CAMERA_FOCUS_LAG, 0.1,
            CAMERA_POSITION_LAG, 0.1]);
        llClearCameraParams();
        llSleep(0.75);
        llSetLinkPrimitiveParams(LINK_SET, [PRIM_COLOR, ALL_SIDES, <0, 0, 0>, 0.0]);
        llSetObjectName("With a start,");
        llOwnerSay("/me you wake back up in a strange ruin. Behind you, there is a crystal showing the room you were just in, but no matter what you try, it seems you can not pass through the other way. Examining yourself, you discover that the feeling you had before you fainted wasn't wrong... You find yourself entirely less human than before.\n\n((This concludes the guided intro to Crystalgate. We hope you enjoy your time here. You'll stop seeing these welcome messages once you create a character in the HUD.))");
        llStopAnimation("faint");
        llReleaseControls();
        llDetachFromAvatar();
    }
    
    attach(key id)
    {
        llDie();
    }
}