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


string scanningMode;
string loadingMode;

list keys = [];
key token;

integer characterLoaded = FALSE;
string def;
integer level;
integer xp;
integer hp;
string name;

key loadingKey;
list loadedDetails;
string loadedTrait1;
string loadedTrait2;

integer listener1 = -1;
integer listener2 = -1;
string status = "";
integer xpTicks = 0;
string postToJudge = "";
string lastApprovedPost = "";
integer lastPostTs = 0;
integer checkNearby = FALSE;
integer inVicinity = FALSE;

checkRp(string chat)
{
    chat = llStringTrim(chat, STRING_TRIM);
    if(llGetTime() < 60) return;
    if(lastApprovedPost == chat) return;
    if(startswith(chat, "(") || startswith(chat, "[") || startswith(chat, "{") || startswith(chat, ")") || startswith(chat, "]") || startswith(chat, "}")) return;
    if(llStringLength(chat) < 30 || llGetListLength(llParseString2List(chat, [" "], [])) < 10) return;
    llResetTime();
    lastApprovedPost = chat;
    lastPostTs = llGetUnixTime();
}

awardXp(list data, integer toGrant)
{
    xp -= toGrant;
    if(xp <= 0)
    {
        level++;
        integer alreadyEarned = xp;
        if(level >= 20)
        {
            xp = (integer)llList2String(data, -1) - alreadyEarned;
        }
        else
        {
            xp = (integer)llList2String(data, level+1) - alreadyEarned;
        }
    }
    
    if(level == 99) xp = 0;
    llMessageLinked(LINK_THIS, CLIENT_SET_LEVEL_XP, (string)level, (key)((string)xp));
}

default
{
    state_entry()
    {
        log("Ready! Memory free: " + (string)(llGetFreeMemory()/1024) + " kb.");
        llMessageLinked(LINK_THIS, CLIENT_SCRIPT_READY, llGetScriptName(), NULL_KEY);
    }

    listen(integer channel, string agentName, key id, string message)
    {
        if(channel == 0)
        {
            if(id == llGetOwner() || llGetOwnerKey(id) == llGetOwner())
            {
                postToJudge = message;
                checkNearby = FALSE;
                llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "XP", NULL_KEY);
            }
        }
        else
        {
            list dict = llParseString2List(message, ["\n", "!~~DELIM~~!"], []);
            string target = getValueFromKey(dict, "target");
            string mode = getValueFromKey(dict, "mode");
            if(target != "client") return;
            if(mode == "roll-decline")
            {
                llOwnerSay("You can't target someone at 0 HP with that.");
            }
            else if(mode == "try-heal")
            {
                if(hp == 0) 
                {
                    llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=roll-decline");
                    return;
                }

                string healer = getValueFromKey(dict, "healer");

                integer roll = random(1, 20);
                integer successes = 0;
                integer target = 5;
                while(roll >= target)
                {
                    successes++;
                    target += 5;
                    roll = random(1, 20);
                }
                
                if(successes == 0)
                {
                    string message = healer + " attempted to heal " + name + ", but failed.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
                else
                {
                    string message = healer + " attempted to heal " + name + ", and got " + (string)successes + " success(es), healing them for " + (string)successes + " HP.";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
            }
            else if(mode == "try-attack")
            {
                if(hp == 0) 
                {
                    llRegionSayTo(id, CG_IPC_CHANNEL, "target=client\nmode=roll-decline");
                    return;
                }

                string attacker = getValueFromKey(dict, "attacker");
                string type = llToUpper(getValueFromKey(dict, "type"));
                string strength = llToUpper(getValueFromKey(dict, "strength"));
                integer oLevel = (integer)getValueFromKey(dict, "level");
                integer damage = 0;

                integer roll = random(1, 20);
                integer target = 10 + level;

                string strong = "";
                if(type == strength) strong = "strong ";

                if(roll == 1)
                {
                    string message = attacker + " attempted to make a " + strong + type + " attack against " + name + ", but rolled a natural 1 on the dice...";
                    trustedSay("Crystalgate Dice", message);
                    llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                }
                else if(roll == 20)
                {
                    damage = 2;
                    if(type == strength) damage++;
                    if(llToUpper(def) == type)
                    {
                        string piercing = "";
                        if(roll + oLevel >= target)
                        {
                            piercing = " piercing their natural defense and";
                        }
                        else
                        {
                            damage--;
                        }
                        string message = attacker + " attempted to make a " + strong + type + " attack against " + name + ", and rolled a natural 20 on the dice," + piercing + " dealing " + (string)damage + " HP damage!";
                        trustedSay("Crystalgate Dice", message);
                        llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    }
                    else
                    {
                        string message = attacker + " attempted to make a " + strong + type + " attack against " + name + ", and rolled a natural 20 on the dice, dealing " + (string)damage + " HP damage!";
                        trustedSay("Crystalgate Dice", message);
                        llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    }
                }
                else
                {
                    if(roll + oLevel < target)
                    {
                        string message = attacker + " attempted to make a " + strong + type + " attack against " + name + ", but rolled a " + (string)(roll+oLevel) + " (" + (string)roll + " + " + (string)oLevel + ") against their armor class of " + (string)target + " (10 + " + (string)level +")...";
                        trustedSay("Crystalgate Dice", message);
                        llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    }
                    else
                    {
                        damage = 2;
                        if(type == strength) damage++;
                        if(llToUpper(def) == type) damage--;
                        string message = attacker + " attempted to make a " + strong + type + " attack against " + name + ", and rolled a " + (string)(roll+oLevel) + " (" + (string)roll + " + " + (string)oLevel + ") against their armor class of " + (string)target + " (10 + " + (string)level +"), dealing " + (string)damage + " HP damage";
                        if(llToUpper(def) == type)
                        {
                            message += " due to their natural defense.";
                        }
                        else
                        {
                            message += "!";
                        }
                        trustedSay("Crystalgate Dice", message);
                        llSay(CG_IPC_CHANNEL, "target=client\nmode=trusted-say\nobject-name=Crystalgate Dice\nmessage=" + message);
                    }
                }
                llSay(CG_IPC_CHANNEL, "target=server\nmode=webhook\nname=Crystalgate Dice\nmessage=" + message);
            }
        }
    }

    link_message(integer src_link, integer api_id, string str1, key str2)
    {
        if(api_id == CLIENT_ORDER_SCAN)
        {
            scanningMode = str1;
            keys = [];
            if(scanningMode != "XP") keys += (string)llGetOwner();
            llSensor("", NULL_KEY, AGENT, 20.0, PI);
        }
        else if(api_id == CLIENT_SCAN_RESULTS && scanningMode == "XP")
        {
            if(llStringLength(str1) == 0)
            {
                inVicinity = FALSE;
            }
            else
            {
                inVicinity = TRUE;
            }

            if(!checkNearby && llStringLength(str1) == 0)
            {
                checkRp(postToJudge);
            }

            if(checkNearby) checkNearby = FALSE;
        }
        else if(api_id == CLIENT_REQUEST_INFO)
        {
            loadingMode = "1";
            loadingKey = str2;
            token = llReadKeyValue((string)str2);
        }
        else if(api_id == CLIENT_CHARACTER_LOADED || api_id == CLIENT_CHARACTER_CHANGED)
        {
            characterLoaded = TRUE;
            if(listener1 != -1) llListenRemove(listener1);
            listener1 = llListen(0, "", NULL_KEY, "");
            if(listener2 != -1) llListenRemove(listener2);
            listener2 = llListen(CG_IPC_CHANNEL, "", NULL_KEY, "");
            list dict = llParseString2List(str1, ["\n"], []);
            def = getValueFromKey(dict, "def");
            name = getValueFromKey(dict, "name");
            level = (integer)getValueFromKey(dict, "level");
            xp = (integer)getValueFromKey(dict, "xp");
        }
        else if(api_id == CLIENT_CHARACTER_UNLOADED)
        {
            characterLoaded = FALSE;
            xpTicks = 0;
        }
        else if(api_id == CLIENT_STATUS_CHANGED)
        {
            status = str1;
            if(status == "CMB")
            {
                list params = llParseString2List((string)str2, [";"], []);
                hp = (integer)llList2String(params, 1);
            }
        }
        else if(api_id == CLIENT_HANDLE_XP_TICK)
        {
            if(!characterLoaded || level >= 99) return;
            if(status != "CMB" && status != "IC")
            {
                lastPostTs += 300;
                return;
            }

            xpTicks++;
            integer mult = (integer)((string)str2);
            list xpData = llParseString2List(str1, [";"], []);
            integer toEarn = 0;

            if(xpTicks == 6)
            {
                xpTicks = 0;
                toEarn++;
            }

            if(inVicinity && llGetUnixTime() - lastPostTs < 1800) toEarn++;

            if(toEarn > 0)
            {
                awardXp(xpData, toEarn * mult);
            }

            checkNearby = TRUE;
            llMessageLinked(LINK_THIS, CLIENT_ORDER_SCAN, "XP", NULL_KEY);
        }
    }

    dataserver(key t, string data)
    {
        if(t == token && loadingMode == "1")
        {
            loadingMode = "2";
            token = llReadKeyValue((string)loadingKey + "character" + getValueFromKey(llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []), "slot"));
        }
        else if(t == token && loadingMode == "2")
        {
            loadedDetails = llParseString2List(llDumpList2String(llDeleteSubList(llParseString2List(data, [","], []), 0, 0), ","), ["\n"], []);
            loadingMode = "";
            loadedTrait1 = getValueFromKey(loadedDetails, "trait1");
            loadedTrait2 = getValueFromKey(loadedDetails, "trait2");
            integer trait1ts = (integer)getValueFromKey(loadedDetails, "trait1ts");
            integer trait2ts = (integer)getValueFromKey(loadedDetails, "trait2ts");
            string trait1state = " (unapproved)";
            string trait2state = " (unapproved)";
            
            if(startswith(loadedTrait1, "#"))
            {
                trait1state = " (active)";
                loadedTrait1 = llGetSubString(loadedTrait1, 1, -1);
            }
            if(startswith(loadedTrait2, "#"))
            {
                trait2state = " (active)";
                loadedTrait2 = llGetSubString(loadedTrait2, 1, -1);
            }

            if(trait1ts > llGetUnixTime() - (3600*24*7))
            {
                if(loadingKey == llGetOwner())
                {
                    trait1state = " (inactive for " + (string)(((3600*24*7) - (llGetUnixTime() - trait1ts))/3600) +" more hours)";
                }
                else
                {
                    trait1state = " (inactive)";
                }
            }
            if(trait2ts > llGetUnixTime() - (3600*24*7))
            {
                if(loadingKey == llGetOwner())
                {
                    trait2state = " (inactive for " + (string)(((3600*24*7) - (llGetUnixTime() - trait2ts))/3600) +" more hours)";
                }
                else
                {
                    trait2state = " (inactive)";
                }
            }
            if(loadingKey == llGetOwner())
            {
                llOwnerSay("Details of your current active character:\n"+
                                "\nName: " + getValueFromKey(loadedDetails, "name") +
                                "\nDisplay Name: " + getValueFromKey(loadedDetails, "display-name") +
                                "\nOffensive Specialty: " + llToUpper(getValueFromKey(loadedDetails, "atk")) +
                                "\nDefensive Specialty: " + llToUpper(getValueFromKey(loadedDetails, "def")) +
                                "\nTrait 1: " + loadedTrait1 + trait1state +
                                "\nTrait 2: " + loadedTrait2 + trait2state);
            }
            else
            {
                llOwnerSay("Details of secondlife:///app/agent/" + (string)loadingKey + "/inspect's current active character:\n"+
                                "\nName: " + getValueFromKey(loadedDetails, "name") +
                                "\nDisplay Name: " + getValueFromKey(loadedDetails, "display-name") +
                                "\nTrait 1: " + loadedTrait1 + trait1state +
                                "\nTrait 2: " + loadedTrait2 + trait2state +
                                "\n\nRemember that this is OOC information, and using any of it without learning it in character is considered metagaming.");
            }
        }
    }

    sensor(integer num)
    {
        integer i;
        for(i = 0; i < num && llGetListLength(keys) < 12; ++i)
        {
            key agent = llDetectedKey(i);
            if(llAgentInExperience(agent))
            {
                list attachments = llGetAttachedList(agent);
                integer j = llGetListLength(attachments) - 1;
                for(; j >= 0; --j)
                {
                    list details = llGetObjectDetails(llList2Key(attachments, j), [OBJECT_TEMP_ATTACHED, OBJECT_CREATOR, OBJECT_DESC]);
    
                    if(llList2Integer(details, 0) == 1 && llList2Key(details, 1) == developerUuid)
                    {
                        if(llList2String(details, 2) == "CMB" || (llList2String(details, 2) == "IC" && scanningMode != "CMB"))
                        {
                            keys += (string)agent;
                        }
                    }
                }
            }
        }
        llMessageLinked(LINK_THIS, CLIENT_SCAN_RESULTS, llDumpList2String(keys, ";"), scanningMode);
    }

    no_sensor()
    {
        llMessageLinked(LINK_THIS, CLIENT_SCAN_RESULTS, llDumpList2String(keys, ";"), scanningMode);
    }
}