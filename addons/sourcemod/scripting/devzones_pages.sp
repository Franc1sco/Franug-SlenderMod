#pragma semicolon 1

#include <sourcemod>
#include <devzones>
#include <sdktools>

public Plugin myinfo =
{
	name = "SM Pages generator for franug slendermod",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "https://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	PrecacheModel("models/slender/sheet.mdl");
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{	
	int g_ZoneCount = 1;
	
	char temp[64];
	Format(temp, 64, "page%i", g_ZoneCount);
	
	float position[3];
	
	while (Zone_CheckIfZoneExists(temp))
	{
		Zone_GetZonePosition(temp, false, position);
		
		int ent = CreateEntityByName("prop_physics_override"); 
		SetEntityModel(ent, "models/slender/sheet.mdl"); 
		DispatchKeyValue(ent, "StartDisabled", "false"); 
		DispatchKeyValue(ent, "Solid", "6"); 
		DispatchKeyValue(ent, "spawnflags", "1026"); 
		DispatchKeyValue(ent, "targetname", "page");  
		DispatchKeyValue(ent, "classname", "page");
		DispatchSpawn(ent); 
		AcceptEntityInput(ent, "TurnOn", ent, ent, 0); 
		AcceptEntityInput(ent, "EnableCollision"); 
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR); 
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);  
        
		g_ZoneCount++;
		Format(temp, 64, "page%i", g_ZoneCount);
	}
}