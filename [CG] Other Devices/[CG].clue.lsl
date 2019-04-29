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
integer experienceListen;
integer startParam;
key target;
integer setUpDone = FALSE;
integer timeToLiveInHours = 1;
string mode = "";
string mess = "";
vector lockedPos;
integer otherClues = 0;
integer staff = FALSE;
integer staffDetermined = FALSE;

default
{
    on_rez(integer start)
    {
        startParam = start;
        experienceListen = llListen(start, "", NULL_KEY, "");
        llSetRot(llEuler2Rot(<0, 90, 0> * DEG_TO_RAD));
        llTargetOmega(<1.0,0.0,0.0>*llGetRot(),0.1,0.03);
        llRegionSayTo((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0), start, "ready");
        llSetTimerEvent(5.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        llRegionSayTo((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0), startParam, "done");
        llListenRemove(experienceListen);
        if(llGetAgentSize((key)message) != ZERO_VECTOR)
        {
            target = (key)message;
            state running;
        }
        else
        {
            llDie();
        }
    }
    
    timer()
    {
        llRegionSayTo((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0), startParam, "done");
        llDie();
    }
}

state running
{
    state_entry()
    {
        // Go to target and set up a 5 minute timer.
        vector pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
        llSetRegionPos(<pos.x, pos.y, pos.z+0.5>);
        llSetTimerEvent(300.0);
        llRegionSayTo(target, 0, "Please move the clue token into your desired location FIRST (by using the SL edit tools) and then click it to set it up. You have five minutes before I self-delete.");
        experienceListen = llListen(startParam, "", target, "");
        llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
        llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=is-staff\nagent-key=" + (string)target);
        llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=report-clue\nagent-key=" + (string)target);
    }

    touch_end(integer num)
    {
        if(llDetectedKey(0) == target && !setUpDone)
        {
            mode = "1";
            llTextBox(target, "Please type in the clue you wish others to see when they click the orb. Note that your name will NOT be revealed to whomever clicks the clue, so if you want it known, include it.", startParam);
        }
        else if(llDetectedKey(0) == target)
        {
            llListenRemove(experienceListen);
            experienceListen = llListen(startParam, "", target, "");
            mode = "3";
            llDialog(target, "You left this clue: \"" + mess + "\"\n\nDo you want to delete your clue?", ["YES", "NO"], startParam);
        }
        else if(setUpDone)
        {
            if(llVecDist(llDetectedPos(0), lockedPos) < 5.0)
            {
                llRegionSay(CG_IPC_CHANNEL, "target=server\nmode=is-staff\nagent-key=" + (string)llDetectedKey(0));
            }
            else
            {
                llRegionSayTo(llDetectedKey(0), 0, "Come closer...");
            }
        }
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == startParam)
        {
            if(mode == "1")
            {
                mess = llStringTrim(m, STRING_TRIM);
                mode = "2";
                llTextBox(target, "Please type in the length in hours you wish for the clue to remain behind.\n\n(Max. 1 week = 168 hours.)", startParam);
            }
            else if(mode == "2")
            {
                timeToLiveInHours = (integer)m;
                if(timeToLiveInHours < 1) timeToLiveInHours = 1;
                else if(timeToLiveInHours > (7*24)) timeToLiveInHours = (7*24);
                lockedPos = llGetPos();
                llRegionSayTo(target, 0, "Your clue has been set and locked in place. It will expire in " + (string)timeToLiveInHours + " hours from now. You can click it to delete it earlier.");
                setUpDone = TRUE;
                mode = "";
                llResetTime();
                llSetTimerEvent(5.0);
                llListenRemove(experienceListen);
            }
            else if(mode == "3")
            {
                if(m == "YES")
                {
                    llRegionSayTo(target, 0, "Deleting myself...");
                    llDie();
                }
                else
                {
                    llListenRemove(experienceListen);
                }
            }
        }
        else if(c == CG_IPC_CHANNEL)
        {
            list dict = llParseString2List(m, ["\n", "!~~DELIM~~!"], []);
            string tar = getValueFromKey(dict, "target");
            if(tar != "client") return;

            string mode = getValueFromKey(dict, "mode");
            string agentKey = getValueFromKey(dict, "agent-key");
            if(mode == "delete-clue" && (agentKey == "" || agentKey == (string)target))
            {
                llDie();
            }
            else if(mode == "is-staff" && agentKey == (string)target && !staffDetermined)
            {
                staffDetermined = TRUE;
                if(getValueFromKey(dict, "value") == "1") staff = TRUE;
            }
            else if(mode == "is-staff" && staffDetermined)
            {
                if(getValueFromKey(dict, "value") == "1")
                {
                    llRegionSayTo((key)agentKey, 0, "A clue was left here by secondlife:///app/agent/" + (string)target + "/about: " + mess);
                }
                else
                {
                    llRegionSayTo((key)agentKey, 0, "A clue was left here: " + mess);
                }
            }
            else if(mode == "report-clue" && agentKey == (string)target)
            {
                if(staff) return;
                llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=report-clue-response");
            }
            else if(mode == "report-clue-response")
            {
                otherClues++;
                if(otherClues == 3)
                {
                    llRegionSayTo(target, 0, "You may only have three clues on sim at any time.");
                    llDie();
                }
            }
        }
    }

    timer()
    {
        if(llGetTime() >= timeToLiveInHours * 3600 || !setUpDone)
        {
            llInstantMessage(target, "Your clue has expired and has deleted itself.");
            llDie();
        }
        else if(setUpDone && llGetPos() != lockedPos)
        {
            llSetRegionPos(lockedPos);
        }
    }
}