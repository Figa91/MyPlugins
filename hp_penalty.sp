#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Health penalty",
	author = "Figa",
	description = "Penalty health for suicide",
	version = "1.1",
	url = "http://www.fiksiki.3dn.ru/"
};

//new Handle: SuicideCheck[MAXPLAYERS + 1];
new bool: SuicideCheck[MAXPLAYERS + 1];
new bool: SuicideHandle[MAXPLAYERS + 1];
new Handle: PenaltyHealth;
new flagi;

public OnPluginStart()
{
	PenaltyHealth = CreateConVar("hp_penalty", "1", "How much to give penalty HP player in the early rounds.", FCVAR_PLUGIN);
	
	RegConsoleCmd("sm_kill", Kill_Me);
	flagi = GetCommandFlags("kill");
	SetCommandFlags("kill", flagi & ~FCVAR_CHEAT);
	
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	
	LoadTranslations("hp_penalty.phrases");
}
public OnPluginEnd()
{
	SetCommandFlags("kill", flagi);
}
public Action:Kill_Me(client, args)
{
	if (client < 1 || IsFakeClient(client) || !IsClientInGame(client)) return;
	if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		SuicideCheck[client] = true;
		decl String:username[32];
		ForcePlayerSuicide(client);
		GetClientName(client, username, sizeof(username));
		PrintToChatAll("%t", "suicide", username);
		//PrintToChat(client, "%t", "penalty");
	}
}
public Action:Event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			//if (!IsPlayerAlive(i)) SuicideCheck[i] = true;
			if (IsPlayerAlive(i)) SuicideCheck[i] = false;
			
			if (SuicideCheck[i]) SuicideHandle[i] = true;
			else SuicideHandle[i] = false;
		}
	}
}
public Action:Event_FinaleWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && SuicideCheck[i])
		{
			SuicideCheck[i] = false;
		}
	}
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && SuicideHandle[i])
		{
			CreateTimer(0.1, GivePenaltyHealth, i);
		}
	}
}
public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) != 3 && SuicideCheck[client])
	{
		CreateTimer(0.1, GivePenaltyHealth, client);
	}
}
public Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim > 0 && !IsFakeClient(victim) && IsClientInGame(victim) && GetClientTeam(victim) != 3)
	{
		if (victim != attacker) SuicideCheck[victim] = false;
		//else PrintToChat(victim, "%t", "penalty", GetConVarInt(PenaltyHealth));
	}
}
public Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 3)
		{
			SuicideCheck[i] = false;
		}
	}
}
public OnClientPutInServer(client)
{
	if (client < 1 || IsFakeClient(client)) return;
	if (SuicideHandle[client]) CreateTimer(1.0, GivePenaltyHealth, client);
}
public Action:GivePenaltyHealth(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(PenaltyHealth));
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 50.0);
	}
}
