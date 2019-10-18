/*  SM Franug Slender Mod
 *
 *  Copyright (C) 2018-2019 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smartdm>
#include <multicolors>

#define PLUGIN_VERSION "0.2beta"

#define EF_DIMLIGHT 4

int g_linterna[MAXPLAYERS + 1];

Handle timers;

int g_oldeffect[MAXPLAYERS + 1];

int slender;

int g_pages;

new g_flFlashDuration;
new g_flFlashMaxAlpha;

Handle g_randomtimer;

Handle timerdamage[MAXPLAYERS+1];

EngineVersion g_Game;

public Plugin:myinfo = 
{
	name = " SM Franug Slender Mod",
	author = "Franc1sco franug",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
}
 
public OnPluginStart()
{
	CreateConVar("sm_franugslendermod_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	
	
	g_Game = GetEngineVersion();
	
	HookEvent("round_freeze_end", Event_Start);
	
	HookEvent("player_spawn", PlayerSpawn);
	
	HookEvent("player_death", PlayerDeath);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	CreateTimer(1.0, Timer_Stuff, _, TIMER_REPEAT);
	
		// for hiding players on radar
	g_flFlashDuration = FindSendPropInfo("CCSPlayer", "m_flFlashDuration");
	if(g_flFlashDuration == -1)
		SetFailState("Couldnt find the m_flFlashDuration offset!");
	g_flFlashMaxAlpha = FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha");
	if(g_flFlashMaxAlpha == -1)
		SetFailState("Couldnt find the m_flFlashMaxAlpha offset!");
}

public OnMapStart()
{
	char temp[128];
	for (int i = 0; i <= 8;i++)
	{
		for (int x = 0; x <= 3; x++)
		{
			Format(temp, 128, "materials/overlays/slender/p%ib%i.vmt", i, x);
			
			AddFileToDownloadsTable(temp);
			ReplaceString(temp, 128, ".vmt", ".vtf");
			AddFileToDownloadsTable(temp);
			ReplaceString(temp, 128, ".vtf", ".vmt");
			ReplaceString(temp, 128, "materials/", "");

			PrecacheDecal(temp);
		}
	}
	
	Format(temp, 128, "materials/overlays/slender/newoverlay.vmt");
			
	AddFileToDownloadsTable(temp);
	ReplaceString(temp, 128, ".vmt", ".vtf");
	AddFileToDownloadsTable(temp);
	ReplaceString(temp, 128, ".vtf", ".vmt");
	ReplaceString(temp, 128, "materials/", "");

	PrecacheDecal(temp);
	
	AddFileToDownloadsTable("sound/slender/ambient.mp3");
	PrecacheSound("slender/ambient.mp3");
	
	if(g_Game == Engine_CSS)
	{
		Downloader_AddFileToDownloadsTable("models/arrival/slenderman.mdl");
		PrecacheModel("models/arrival/slenderman.mdl");
	}
	else if(g_Game == Engine_CSGO)
	{
		Downloader_AddFileToDownloadsTable("models/player/custom_player/caleon1/l4d2_tank/l4d2_tank.mdl");
		PrecacheModel("models/player/custom_player/caleon1/l4d2_tank/l4d2_tank.mdl");
	}
	AddFileToDownloadsTable("sound/slender/jumpscare.wav");
	PrecacheSound("slender/jumpscare.wav");
	
	AddFileToDownloadsTable("sound/slender/dead.mp3");
	PrecacheSound("slender/dead.mp3");
	
	AddFileToDownloadsTable("sound/slender/dramatic1b.mp3");
	PrecacheSound("slender/dramatic1b.mp3");
	
	AddFileToDownloadsTable("sound/slender/dramatic1c.mp3");
	PrecacheSound("slender/dramatic1c.mp3");
	
	AddFileToDownloadsTable("sound/slender/dramatic1d.mp3");
	PrecacheSound("slender/dramatic1d.mp3");
	
	AddFileToDownloadsTable("sound/slender/page_grab.wav");
	PrecacheSound("slender/page_grab.wav");
	
	AddFileToDownloadsTable("sound/slender/flash_on.mp3");
	PrecacheSound("slender/flash_on.mp3");
	
	PrecacheSound("ambient/energy/zap1.wav");
	
	CreateTimer(1.0, Timer_Map, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szClass[65];
	for (new i = MaxClients; i <= GetMaxEntities(); i++)
	{
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(StrEqual("func_buyzone", szClass))
            {
                AcceptEntityInput(i, "Kill");
            }
        }
	} 
}

public Action Timer_Map(Handle timer)
{
	ServerCommand("bot_kick");
	ServerCommand("bot_difficulty 3");
	ServerCommand("bot_quota_mode normal");
	ServerCommand("bot_quota 1");	
}

public Action PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	EmitSoundToClient(client, "slender/dead.mp3");
	
	ShowOverlayToClient(client, "");
	
	CreateTimer(3.5, FinMuerte, GetClientUserId(client));
}

public Action FinMuerte(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client))return;
	
	ShowOverlayToClient(client, "overlays/slender/newoverlay");
	
	CreateTimer(6.0, FinMuerte2, GetClientUserId(client));
}

public Action FinMuerte2(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client))return;
	
	ShowOverlayToClient(client, "");
}

public Action Timer_Spawn(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	if (!client || !IsClientInGame(client))return;
	
	if(GetClientTeam(client) < 2)
		return;
		
	if(!IsFakeClient(client))
	{
		if(GetClientTeam(client) != CS_TEAM_CT)
		{
			CS_SwitchTeam(client, CS_TEAM_CT);
			CS_RespawnPlayer(client);
		}	
		StripAllPlayerWeapons(client);	

		SetEntDataFloat(client, g_flFlashDuration, 10000.0, true);
		SetEntDataFloat(client, g_flFlashMaxAlpha, 0.5, true);
	}
	else
	{
			
		if(GetClientTeam(client) != CS_TEAM_T)
		{
			CS_SwitchTeam(client, CS_TEAM_T);
			CS_RespawnPlayer(client);
		}else
		{
			if(g_Game == Engine_CSS)
			{
				SetEntityModel(client, "models/arrival/slenderman.mdl");
			}
			else if(g_Game == Engine_CSGO)
			{
				SetEntityModel(client, "models/player/custom_player/caleon1/l4d2_tank/l4d2_tank.mdl");
			}
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.8);
			
			slender = client;
		}
		StripAllPlayerWeapons(client);
		GivePlayerItem(client, "weapon_knife");
		
	}	
	
}

public Action PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Spawn, GetEventInt(event, "userid"));
}

public Action Timer_Stuff(Handle timer)
{
	char temp[128];
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetEntProp(i, Prop_Send, "m_fEffects") & EF_DIMLIGHT)
				--g_linterna[i];
			else
				++g_linterna[i];
			
			if(g_linterna[i] > 150)
				g_linterna[i] = 150;
			
			
			if(g_linterna[i] > 110)
			{
				Format(temp, 128, "overlays/slender/p%ib3", g_pages);
				ShowOverlayToClient(i, temp);
			}
			else if(g_linterna[i] > 70)
			{
				Format(temp, 128, "overlays/slender/p%ib2", g_pages);
				ShowOverlayToClient(i, temp);
			}
			else if(g_linterna[i] > 30)
			{
				Format(temp, 128, "overlays/slender/p%ib1", g_pages);
				ShowOverlayToClient(i, temp);
			}
			else
			{
				Format(temp, 128, "overlays/slender/p%ib0", g_pages);
				ShowOverlayToClient(i, temp);
			}

			if(g_linterna[i] <= 0)
			{
				g_linterna[i] = 0;
				RemoveEntityEffects(i, EF_DIMLIGHT);
				
			}
			
			
		}
}

public Action Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_pages = 0;
	
	ShowOverlayToAll("");
	
	ClearAll();
	
	ClearTimer(timers);
	
	timers = CreateTimer(2.0, RoundStartPost);
	
	ClearTimer(g_randomtimer);
	g_randomtimer = CreateTimer(GetRandomFloat(20.0, 120.0), Apagar);
	
}
public Action Apagar(Handle:timer)
{		
	g_randomtimer = null;
	
	g_randomtimer = CreateTimer(GetRandomFloat(20.0, 120.0), Apagar);
	
	
	
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (IsClientInGame(x))
		{
			g_linterna[x] = 0;
			
			EmitSoundToClient(x, "ambient/energy/zap1.wav");
		}
	}
}

public Action RoundStartPost(Handle:timer)
{		
	ServerCommand("mp_flashlight 1");
	
	timers = null;
	
	timers = CreateTimer(0.0, Timer_NextMusic);
	
	
	int ent=MaxClients+1;
	
	char name[64];
	while( (ent = FindEntityByClassname(ent, "prop_*")) != -1 )
	{
		if (!IsValidEntity(ent))continue;
		
		GetEntityName(ent, name, sizeof(name));
		
		//PrintToServer(name);
			
		if(StrEqual(name, "page", false))
			SetEntityRenderColor(ent, 0, 0, 0, 255);
	}
}

public Action Timer_NextMusic(Handle:timer)
{
	timers = null;
	
	//EmitSoundToAll("slender/ambient.mp3");
	
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			EmitSoundToClient(i, "slender/ambient.mp3");
	
	timers = CreateTimer(120.0, Timer_NextMusic);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))return;
    
    if(GetEntProp(client, Prop_Send, "m_fEffects") & EF_DIMLIGHT && !(g_oldeffect[client] & EF_DIMLIGHT))
    {
    	// ENCENDIDO
		if(g_linterna[client] <= 10)
		{
			RemoveEntityEffects(client, EF_DIMLIGHT);
				
		}
		
		EmitSoundToClient(client, "slender/flash_on.mp3");
		//ClientCommand(client, "play slender/flash_on.mp3");
    }
    else if(!(GetEntProp(client, Prop_Send, "m_fEffects") & EF_DIMLIGHT) && (g_oldeffect[client] & EF_DIMLIGHT))
    {
    	// APAGADO

    	EmitSoundToClient(client, "slender/flash_on.mp3");
    	//ClientCommand(client, "play slender/flash_on.mp3");
    }
    
    	
    	
    g_oldeffect[client] = GetEntProp(client, Prop_Data, "m_fEffects");
    
    
    int target = GetClientAimTarget(client, false);
    	
    if(target != -1)
    {
			//char clsname[64], name[128];
			char name[128];
			//GetEntityClassname(target, clsname, sizeof(clsname));
			GetEntityName(target, name, sizeof(name));
			
			if(StrEqual(name, "page", false))
			{
				SetEntityRenderColor(target, 255, 255, 255, 255);
				
				if(buttons & IN_USE)
				{
					AcceptEntityInput(target, "Kill");
				
					g_pages++;
				
					EmitSoundToClient(client, "slender/page_grab.wav");
				
					CPrintToChatAll("{green}%N found a page. Remain %i/8 pages.", client, g_pages);
				
					if(g_pages >= 8)
					{
						CS_TerminateRound(7.0, CSRoundEnd_CTWin);
					
						//g_pages = 0;
					}
				}
			}
	}
    
    if(IsValidClient(slender) && IsTargetInSightRange(client, slender, 90.0, 1000.0) && CanSeeOther(client, slender))
	{
		StopSound(client, SNDCHAN_AUTO, "slender/dramatic1b.mp3");
		StopSound(client, SNDCHAN_AUTO, "slender/dramatic1c.mp3");
		StopSound(client, SNDCHAN_AUTO, "slender/dramatic1d.mp3");
		
		ClearTimer(timerdamage[client]);
		
		timerdamage[client] = CreateTimer(0.2, Timer_Miedo, client);
		
		
		//ClientCommand(client, "play slender/flash_on.mp3");
		EmitSoundToClient(client, "slender/jumpscare.wav", SOUND_FROM_PLAYER);
		
		SDKHooks_TakeDamage(client, slender, slender, 1.0);
		
		VEffectsShakeClientScreen(client);
	}
}

public Action Timer_Miedo(Handle timer, int client)
{
	timerdamage[client] = null;
	
	switch(GetRandomInt(1, 3))
	{
			case 1:
				EmitSoundToClient(client, "slender/dramatic1b.mp3", SOUND_FROM_PLAYER);
			case 2:
				EmitSoundToClient(client, "slender/dramatic1c.mp3", SOUND_FROM_PLAYER);
			case 3:
				EmitSoundToClient(client, "slender/dramatic1d.mp3", SOUND_FROM_PLAYER);		
	}
}

public OnClientDisconnect(client)
{
	ClearTimer(timerdamage[client]);
}

ClearAll()
{
	for (new i = 1; i <= MaxClients; i++)
		g_linterna[i] = 150;
}

public OnClientPutInServer(client)
{
	g_oldeffect[client] = 0;
	g_linterna[client] = 150;
}

ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

ShowOverlayToAll(const String:overlaypath[])
{
	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			ShowOverlayToClient(x, overlaypath);
		}
	}
}

stock RemoveEntityEffects(entity,effect)
{
    new _effect = GetEntProp(entity,Prop_Data,"m_fEffects")
    
    SetEntProp(entity,Prop_Data,"m_fEffects",_effect & ~effect);
}

stock ClearTimer(&Handle:timer)
{
    if (timer != null)
    {
        KillTimer(timer);
        timer = null;
    }     
}  

stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 6; i++)
	{
		while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}

stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

stock bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

stock bool:CanSeeOther(index, target, Float:distance = 0.0, Float:Height = 50.0)
{

		new Float:Position[3], Float:vTargetPosition[3];
		
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", Position);
		Position[2] += Height;
		
		GetClientEyePosition(target, vTargetPosition);
		
		if (distance == 0.0 || GetVectorDistance(Position, vTargetPosition, false) < distance)
		{
			new Handle:trace = TR_TraceRayFilterEx(Position, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);

			if(TR_DidHit(trace))
			{
				CloseHandle(trace);
				return (false);
			}
			
			CloseHandle(trace);

			return (true);
		}
		return false;
}

public bool:Base_TraceFilter(entity, contentsMask, any:data)
{
	if(entity != data)
		return (false);

	return (true);
}

stock void GetEntityName(int entity, char[] name, int maxlen)
{
	GetEntPropString(entity, Prop_Data, "m_iName", name, maxlen);
}

VEffectsShakeClientScreen(client, Float:amplitude=20.0, Float:frequency=50.0, Float:duration=1.0)
{
	new Handle:hShake = StartMessageOne("Shake", client);
	
	// Validate.
	if (hShake == INVALID_HANDLE)
	{
		return;
	}
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hShake, "command", 0);
		PbSetFloat(hShake, "local_amplitude", amplitude);
		PbSetFloat(hShake, "frequency", frequency);
		PbSetFloat(hShake, "duration", duration);
	}
	else
	{
		BfWriteByte(hShake, 0);
		BfWriteFloat(hShake, amplitude);
		BfWriteFloat(hShake, frequency);
		BfWriteFloat(hShake, duration);
	}
	EndMessage();
}