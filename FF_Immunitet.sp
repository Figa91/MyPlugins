#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

new Handle:g_blockalldamage;

new String:FileList[64][64];
new nvip_ID;

public Plugin:myinfo = 
{
	name = "FF immunitet",
	author = "Figa",
	description = "V.I.P. friendly fire immunitet",
	version = "2.1",
	url = ""
};

public OnPluginStart()
{
	g_blockalldamage = CreateConVar("l4dtk_blockalldamage", "1", "1 - Remove All FF Damage on VIP; 0 - Disable option.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	for(new x = 1; x<=MaxClients ; x++)
	{
		if(ValidClient(x)) SDKHook(x, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
public OnPluginEnd()
{
	if (GetConVarBool(g_blockalldamage))
	{
		for(new x = 1; x<=MaxClients ; x++)
		{
			if(ValidClient(x)) SDKUnhook(x, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnMapStart()
{
	nvip_ID = 0;
	new Handle:hvip_File = OpenFile("addons/sourcemod/configs/vip_id.txt", "r");
	if(hvip_File == INVALID_HANDLE)
	{
		SetFailState("Failed to find configs/vip_id.txt");
		return;
	}
	new String:buffer[64];
	while (ReadFileLine(hvip_File, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
		FileList[nvip_ID] = buffer;
		nvip_ID++;
		
		if (IsEndOfFile(hvip_File)) break;
	}
	CloseHandle(hvip_File);
	hvip_File = INVALID_HANDLE;
}
stock ValidClient(ok)
{
	if(0 < ok <= MaxClients && IsClientConnected(ok) && IsClientInGame(ok)) return true;
	else return false;
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetConVarBool(g_blockalldamage))
	{
		if(!ValidClient(client) || !ValidClient(attacker) || client == attacker) return Plugin_Continue;

		if(GetClientTeam(client) == GetClientTeam(attacker))
		{
			decl String:SteamID[64];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
			for (new i = 0; i < nvip_ID; i++)
			{
				if (strcmp(SteamID, FileList[i], false) == 0) return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}