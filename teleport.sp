#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define MAXTELEPORT 2

//new bool:CountTeleport[MAXPLAYERS + 1][MAXTELEPORT + 1];
static CountTeleport[32][2];

//new Float:CCountTeleport[MAXPLAYERS + 1][3];
new Float:CCountTeleport2[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	RegConsoleCmd("sm_tp", CreateTP, "Create teleport");
}

public Action:CreateTP(client, args)
{
	if (client < 1 || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	//if (CheckAssault[client]) CmdCreateTP(client);
	//else CmdCreateTP(client);
	
	//new Float:vPos[3], Float:vAng[3];
	//if(!CmdCreateTP(client, vPos, vAng))
	//{
	//	PrintToChat(client, "%sCannot place ammo pile, please try again.", CHAT_TAG);
	//	return;
	//}
	
	CmdCreateTP(client);
	//CmdCreateTP(client, vPos, vAng);
	//index += 1;
}

//CmdCreateTP(client, const Float:vOrigin[3], const Float:vAngles[3])
CmdCreateTP(client)
{
	new Float:vPos[3], Float:vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	if (!CountTeleport[client][1])
	{
		//CountTeleport[client][1] = true;
		//CCountTeleport[client][3] = vPos;
		
		new trigger_multiple = CreateEntityByName("trigger_multiple");
		CountTeleport[client][1] = EntIndexToEntRef(trigger_multiple);
		
		DispatchKeyValue(trigger_multiple, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple, "wait", "0");
		DispatchSpawn(trigger_multiple);
		ActivateEntity(trigger_multiple);
		TeleportEntity(trigger_multiple, vPos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple, "models/error.mdl");
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 30.0});
		SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
		
		PrintToChat (client, "Телепорт #1 размещён.");
	}
	else if (CountTeleport[client][1] && !CountTeleport[client][2])
	{
		CountTeleport[client][2] = true;
		CCountTeleport2[client][3] = vPos;
		
		new trigger_multiple = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple, "wait", "0");
		DispatchSpawn(trigger_multiple);
		ActivateEntity(trigger_multiple);
		TeleportEntity(trigger_multiple, vPos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple, "models/error.mdl");
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 30.0});
		SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch2);
		HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
		
		PrintToChat (client, "Телепорт #2 размещён.");
	}
	else PrintToChat (client, "Вы уже использовали телепорт.");
}

public OnStartTouch(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client))
	{
		if (CountTeleport[client][1] && CountTeleport[client][2])
		{
			PrintToChat(client, "Вход и выход готов!");
			new Float:vPos[3] = CCountTeleport2[client][3];
			//GetEntPropVector(CountTeleport[client][2], Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(CountTeleport[i][2], Prop_Data, "m_vecOrigin", vPos);
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	PrintToChat(client, "Зашли в телепорт!");
}

public OnStartTouch2(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client))
	{
		if (CountTeleport[client][1] && CountTeleport[client][2])
		{
			PrintToChat(client, "Вход и выход готов!");
			
		}
	}
	PrintToChat(client, "Зашли в телепорт!");
}

public OnEndTouch(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client))
	{
		
	}
	PrintToChat(client, "Вышли из телепорта!");
}