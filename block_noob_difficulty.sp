#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

Handle h_Difficulty;

public Plugin myinfo =
{
	name = "Block Noob Difficulty",
	author = "Figa",
	description = "Block changing difficulty on easy or normal.",
	version = "1.3",
	url = "http://fiksiki.3dn.ru"
};
public void OnPluginStart()
{
	RegConsoleCmd("callvote",Call_Vote_Handler);
	h_Difficulty = FindConVar("z_difficulty");
	HookConVarChange(h_Difficulty, ConVarChange_GameDifficulty);
}
public Action Call_Vote_Handler(int client, int args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client) && GetUserFlagBits(client) == 0)
	{
		char vote_Name[16];
		GetCmdArg(2,vote_Name,sizeof(vote_Name));
		if ((strcmp(vote_Name,"Easy",false) == 0) || (strcmp(vote_Name,"Normal",false) == 0))
		{
			PrintToChat(client, "Нет доступа к голосованию по изменению сложности на %s.", vote_Name);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public void ConVarChange_GameDifficulty(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
	{
		int i_Count;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) i_Count++;
		}
		if (!i_Count) SetConVarString(FindConVar("z_difficulty"), "hard");
	}
}