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

integer startOfEpoch = 1552194000;
integer decayDays = -1;
integer xpMult = 1;
integer timeLeft = 0;
string xpValues;

float xpConstant     = 20;
float xpPoly1        = 1.11;
float xpPoly2        = 1.808;
float xpPoly3        = 2.142;
float xpPoly4        = 2.1507;
float decayFactor    = 0.99995;

updateFactors()
{
    integer newDecayDays = (llGetUnixTime() - startOfEpoch) / (3600*24);
    if(newDecayDays != decayDays)
    {
        decayDays = newDecayDays;
        llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=xp-refresh");
        xpValues = "0";
        integer i;
        for(i = 1; i <= 21; ++i)
        {
            xpValues += ";" + (string)xpForLevel(i);
        }
    }
}

integer xpForLevel(integer level)
{
    float totalDecay = llPow(decayFactor, decayDays);
    float decayPoly2 = max(xpPoly1, xpPoly2 * totalDecay);
    float decayPoly3 = max(xpPoly1, xpPoly3 * totalDecay);
    float decayPoly4 = max(xpPoly1, xpPoly4 * totalDecay);
    if(level <= 0)
    {
        return 0;
    }
    else if(level < 5)
    {
        return llRound(xpConstant * llPow((float)level, xpPoly1));
    }
    else if(level < 10)
    {
        return llRound(xpConstant * llPow((float)level, decayPoly2));
    }
    else if(level < 15)
    {
        return llRound(xpConstant * llPow((float)level, decayPoly3));
    }
    else if(level < 21)
    {
        return llRound(xpConstant * llPow((float)level, decayPoly4));
    }
    else if(level < 100)
    {
        return llRound(xpConstant * llPow(20.0, xpPoly4));
    }
    else
    {
        return -1;
    }
}

default
{
    state_entry()
    {
        updateFactors();
        llListen(0, "", llGetOwner(), "");
        llSetTimerEvent(300.0);
    }
    
    touch_start(integer num)
    {
        if(llGetOwner() != llDetectedKey(0)) return;
        llOwnerSay("Say either 'XP BONUS RESET' to reset the XP bonus multiplier to x1, or say 'XP xX Zh' where X is the multiplier and Z is the time in hours to remain active.");
    }
    
    listen(integer chan, string agentname, key id, string text)
    {
        if(llToLower(text) == "xp bonus reset")
        {
            timeLeft = 0;
            xpMult = 1;
            llOwnerSay("Resetting the global XP multiplier to the default of x1.");
        }
        else if(startswith(text, "XP "))
        {
            list inp = llParseString2List(text, [" "], []);
            integer mult = (integer)llGetSubString(llList2String(inp, 1), 1, -1);
            integer dur = (integer)llGetSubString(llList2String(inp, 2), 0, -2);
            if(mult <= 1 || dur <= 1) return;
            else
            {
                xpMult = mult;
                timeLeft = dur * 12;
            }
            llOwnerSay("Set the global XP multiplier to x" + (string)mult + " for " + (string)dur + " hours.");
        }
    }
    
    timer()
    {
        updateFactors();
        if(xpMult > 1)
        {
            timeLeft--;
            if(timeLeft <= 0)
            {
                llInstantMessage(llGetOwner(), "Resetting the global XP multiplier to the default of x1.");
                xpMult = 1;
            }
        }
        llRegionSay(CG_IPC_CHANNEL, "target=client\nmode=xp-tick\nxp-mult=" + (string)xpMult + "\nxp-values=" + xpValues);
    }
}