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

give(key id)
{
    list items;
    integer index = 0;
    integer folderNumber = 1;
    integer count = llGetInventoryNumber(INVENTORY_ALL);
    integer useNumber = count > 43;
    while(index < count)
    {
        string itemName = llGetInventoryName(INVENTORY_ALL, index);
        integer itemType = llGetInventoryType(itemName);
        if(itemType != INVENTORY_SCRIPT && itemName != llGetScriptName())
        {
            items += itemName;
        }
        
        index ++;
        
        // See if folder needs to be given.
        if(index == count || llGetListLength(items) == 42)
        {
            if(useNumber)
            {
                llGiveInventoryList(id, llGetObjectName() + " - " + (string)folderNumber, items);
                folderNumber++;
            }
            else
            {
                llGiveInventoryList(id, llGetObjectName(), items);
            }
            items = [];
        }
    }
}

default
{
    state_entry()
    {
        llSetText("Click here to get an archive\nof all past group notices.", <1,1,1>, 1.0);
    }
    
    touch_start(integer num)
    {
        key id = llDetectedKey(0);
        give(id);
    }
}