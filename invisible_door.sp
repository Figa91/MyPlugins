#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

//l4d_river03_port
new Float:invisible_door[3] = {-1541.0, -197.0, 166.0};

public OnPluginStart()
{
	RegConsoleCmd("sm_tp", CreateTP, "Create teleport");
	//sv_noclipspeed 0.7
	//sv_noclipaccelerate 5
	
	HookEvent("round_freeze_end", round_freeze_end);
}

public Action:CreateTP(client, args)
{
	if (client < 1 || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	CmdCreateTP(client);
}

public round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrecacheModel("models/error.mdl", true);
	new String:gMapName[64];
	GetCurrentMap(gMapName, sizeof(gMapName));
	if(StrContains(gMapName, "river03", false) != -1)
	{
		new trigger_multiple = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple, "wait", "0");
		DispatchSpawn(trigger_multiple);
		ActivateEntity(trigger_multiple);
		TeleportEntity(trigger_multiple, invisible_door, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple, "models/error.mdl");
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-20.0, -40.0, -100.0});
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {40.0, 240.0, 300.0});
		SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
	}
}

CmdCreateTP(client)
{
	new Float:vPos[3], Float:vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	new trigger_multiple = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger_multiple, "spawnflags", "1");
	DispatchKeyValue(trigger_multiple, "wait", "0");
	DispatchSpawn(trigger_multiple);
	ActivateEntity(trigger_multiple);
	TeleportEntity(trigger_multiple, vPos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(trigger_multiple, "models/error.mdl");
	SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-100.0, -100.0, -10.0});
	SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {100.0, 100.0, 10.0});
	SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
	HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch);
	HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
	
	PrintToChat (client, "Проход размещён.");
}
public OnStartTouch(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		PrintToChat(client, "Вошли в проход!");

		//SetEntProp(client, Prop_Data, "m_MoveType", MOVETYPE_NOCLIP);
		SetEntProp(client, Prop_Send, "m_iTeamNum", 3);
	}
}
public OnEndTouch(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client) && !IsClientZombie(client))
	{
		PrintToChat(client, "Вышли из прохода!");

		//SetEntProp(client, Prop_Data, "m_MoveType", MOVETYPE_WALK);
		SetEntProp(client, Prop_Send, "m_iTeamNum", 2);
	}
}
bool:IsClientZombie(client)
{
	decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	if (StrContains(playermodel, "hulk", false) != -1 ||
		StrContains(playermodel, "hunter", false) != -1 ||
		StrContains(playermodel, "boomer", false) != -1 ||
		StrContains(playermodel, "witch", false) != -1 ||
		StrContains(playermodel, "smoker", false) != -1) return true;
	else return false;
}