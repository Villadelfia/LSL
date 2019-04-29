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

integer totaldonated;
integer highestdonation = 0;
string highestname = "";
 
default
{
    on_rez( integer sparam )
    {
        llResetScript();
    }
 
    state_entry()
    {
        llSetText("Crystalgate Tip Cthulhu\nGokln'gha cthulhu!!!\n \nL$0 donated so far.",<0.250, 1.000, 0.250>,1);
    }
 
    money(key id, integer amount)
    {
        totaldonated = totaldonated + amount;
        if(highestdonation < amount)
        {
            highestdonation = amount;
            highestname = llKey2Name(id);
        }
        
        llSetText("Crystalgate Tip Cthulhu\nGokln'gha cthulhu!!!\n \nL$" + (string)totaldonated + " donated so far.\nHighest donation: L$" + (string)highestdonation + " by " + highestname + ".",<0.250, 1.000, 0.250>,1);
        llRegionSayTo(id, 0, "Thank you for the donation! Cthulhu's hunger has been lessened " + llKey2Name(id) + " ");
        llPlaySound("d3453fc0-faa9-2504-4089-df50149e041e", 1.0);
        
        float glow = 0.0;
        while(glow < 0.2)
        {
            glow += 0.01;
            llSetLinkPrimitiveParams(LINK_SET, [PRIM_GLOW, ALL_SIDES, glow]);
        }
        
        while(glow > 0.0)
        {
            glow -= 0.01;
            llSetLinkPrimitiveParams(LINK_SET, [PRIM_GLOW, ALL_SIDES, glow]);
            llSleep(0.2);
        }
        llSetLinkPrimitiveParams(LINK_SET, [PRIM_GLOW, ALL_SIDES, 0.0]);
        llInstantMessage(llGetOwner(), llKey2Name(id) + " just donated $L" + (string)amount);
    }
}