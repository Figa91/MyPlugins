#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:client_voted[MAXPLAYERS + 1];
new bool:b_TimeOutVote;

new i_TimerVote, i_UpVote, i_DownVote;
new ModeGame;
new flagi;

new Handle:h_Timer;

public Plugin:myinfo =
{
    name = "[L4D] Simple Player Menu",
    author = "Figa",
    description = "Simple Player Menu",
    version = "1.9",
    url = "http://fiksiki.3dn.ru"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_menu", PlayerPanel, "Player menu.");
	RegConsoleCmd("sm_kill", Kill_Me);
	
	HookEvent("round_freeze_end", round_freeze_end);
	
	flagi = GetCommandFlags("kill");
	SetCommandFlags("kill", flagi & ~FCVAR_CHEAT);
	
	LoadTranslations("player_menu.phrases");
}
public round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetDifficulty(ModeGame);
}
public OnClientPostAdminCheck(client)
{
	ClientCommand(client, "bind f4 sm_menu");
	ClientCommand(client, "bind f6 sm_kill");
}
public Action:PlayerPanel(client, args)
{
	new Handle:PlayerMenu = CreateMenu(PlayerMenuHandler);
	decl String:MenulTitle[32];
	Format(MenulTitle, sizeof(MenulTitle), "%T\n \n", "MenuTitle", client);
	SetMenuTitle(PlayerMenu, MenulTitle);
	new String:Value[40];

	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(PlayerMenu, "0", Value);

	Format(Value, sizeof(Value), "%T", "MenuModeTitle", client);
	AddMenuItem(PlayerMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "MenuMaps", client);
	AddMenuItem(PlayerMenu, "2", Value);

	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(PlayerMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(PlayerMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(PlayerMenu, "5", Value);
	
	SetMenuExitButton(PlayerMenu, true);
	DisplayMenu(PlayerMenu, client, 30);

	return Plugin_Handled;
}
public PlayerMenuHandler(Handle:PlayerMenu, MenuAction:action, client, option)
{
	if (action == MenuAction_Select)
	{
		switch (option)
		{
			case 0: ClientCommand(client, "sm_csp");
			case 1: Menu_Mode(client);
			case 2: ClientCommand(client, "sm_maps");
			case 3: ClientCommand(client, "sm_votekick");
			case 4: ClientCommand(client, "sm_votesilence");
			case 5: ClientCommand(client, "sm_rankmenu");
		}
	}
}
Menu_Mode(client)
{
	new Handle:PlayerMenu = CreateMenu(ModeMenuHandler);
	decl String:ModeTitle[40];
	Format(ModeTitle, sizeof(ModeTitle), "%T\n \n", "MenuModeTitle", client);
	SetMenuTitle(PlayerMenu, ModeTitle);
	new String:Value[64];
	
	if (ModeGame == 0) Format(Value, sizeof(Value), "☑%T ☠", "ModeHalfPastFive", client);
	else Format(Value, sizeof(Value), "☐%T ☠", "ModeHalfPastFive", client);
	AddMenuItem(PlayerMenu, "0", Value);
	
	if (ModeGame == 1) Format(Value, sizeof(Value), "☑%T ☠☠", "ModeOlolo", client);
	else Format(Value, sizeof(Value), "☐%T ☠☠", "ModeOlolo", client);
	AddMenuItem(PlayerMenu, "1", Value);
	
	if (ModeGame == 2) Format(Value, sizeof(Value), "☑%T ☠☠☠", "ModePRO", client);
	else Format(Value, sizeof(Value), "☐%T ☠☠☠", "ModePRO", client);
	AddMenuItem(PlayerMenu, "2", Value);
	
	if (ModeGame == 3) Format(Value, sizeof(Value), "☑%T ☠☠☠☠", "ModeLandoriki", client);
	else Format(Value, sizeof(Value), "☐%T ☠☠☠☠", "ModeLandoriki", client);
	AddMenuItem(PlayerMenu, "3", Value);
	
	SetMenuExitButton(PlayerMenu, true);
	DisplayMenu(PlayerMenu, client, 30);
}
public ModeMenuHandler(Handle:PlayerMenu, MenuAction:action, client, option) 
{
	if(action == MenuAction_End) CloseHandle(PlayerMenu);
	if (action == MenuAction_Select)
	{
		new ModeNum;
		switch (option)
		{
			case 0:
			{
				if (ModeGame == 0)
				{
					PrintToChat(client, "%t", "ModeEnableAlready");
					return;
				}
				ModeNum = 0;
			}
			case 1:
			{
				if (ModeGame == 1)
				{
					PrintToChat(client, "%t", "ModeEnableAlready");
					return;
				}
				ModeNum = 1;
			}
			case 2:
			{
				if (ModeGame == 2)
				{
					PrintToChat(client, "%t", "ModeEnableAlready");
					return;
				}
				ModeNum = 2;
			}
			case 3:
			{
				if (ModeGame == 3)
				{
					PrintToChat(client, "%t", "ModeEnableAlready");
					return;
				}
				ModeNum = 3;
			}
			default: return;
		}
		CallVoteChangeDifficulty(client, ModeNum);
	}
}
public Action:CallVoteChangeDifficulty(client, any:ModeNum)
{
	if (h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
	}
	if (IsVoteInProgress())
	{
		PrintToChat(client, "%t", "VotingAlready");
		return;
	}
	if (b_TimeOutVote)
	{
		PrintToChat(client, "%t", "VotingTimeout");
		return;
	}
	i_TimerVote = 16; // время голосования в сек.
	h_Timer = CreateTimer(1.0, Timer_Func, _, TIMER_REPEAT);
	CreateTimer(60.0, Timer_FuncOut);
	b_TimeOutVote = true;
	
	//Считаем и записываем нужное число игроков по условиям
	new i_Clients[32], i_Count;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			i_Clients[i_Count++] = i;
	}
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("%t", "VotingStart", name);
	
	decl String:ChTitle[64];
	new Handle:_menu;
	switch (ModeNum)
	{
		case 0:
		{
			_menu = CreateMenu(Handle_VoteMenuHalfPastFive);
			Format(ChTitle, sizeof(ChTitle), "%T?\n \n", "EnableModeHalfPastFive", i_Clients);
		}
		case 1:
		{
			_menu = CreateMenu(Handle_VoteMenuOlolo);
			Format(ChTitle, sizeof(ChTitle), "%T?\n \n", "EnableModeOlolo", i_Clients);
		}
		case 2:
		{
			_menu = CreateMenu(Handle_VoteMenuPro);
			Format(ChTitle, sizeof(ChTitle), "%T?\n \n", "EnableModePRO", i_Clients);
		}
		case 3:
		{
			_menu = CreateMenu(Handle_VoteMenuLandoriki);
			Format(ChTitle, sizeof(ChTitle), "%T?\n \n", "EnableModeLandoriki", i_Clients);
		}
	}
	SetMenuTitle(_menu, ChTitle);
	new String:Value[32];

	Format(Value, sizeof(Value), "%T", "VoteYes", i_Clients);
	AddMenuItem(_menu, "0", Value);

	Format(Value, sizeof(Value), "%T", "VoteNo", i_Clients);
	AddMenuItem(_menu, "1", Value);

	SetMenuExitButton(_menu, true);

	//Показываем меню голосования нужным игрокам (Число и ID которых, ранее записали в цикле)
	VoteMenu(_menu, i_Clients, i_Count, 15);
}
public Handle_VoteMenuHalfPastFive(Handle:menu, MenuAction:action, param1, param2)
{
	//param1 - клиент (Голосование при этом еще не закончено!!) param2- пункт голосования
	if (param1 > 0 && IsClientInGame(param1) && !IsFakeClient(param1))
	{
		switch (param2)
		{
			case 0:
			{
				i_UpVote++;
				client_voted[param1] = true;
			}
			case 1:
			{
				i_DownVote++;
				client_voted[param1] = true;
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		for (new i = 0; i <= MAXPLAYERS; i++) client_voted[i] = false;
		i_UpVote = 0;
		i_DownVote = 0;
	}
	//param1 - победивший пункт голосования (Голосование закончилось)
	else if (action == MenuAction_VoteEnd)
	{
		switch (param1)
		{
			case 0:
			{
				SetDifficulty(0);
				PrintToChatAll("%t %t.", "ApprovedMode", "ModeHalfPastFive");
				PrintHintTextToAll("%t %t", "EnabledMode", "ModeHalfPastFive");
			}
			case 1:
			{
				PrintToChatAll("%t %t.", "UnapprovedMode", "ModeHalfPastFive");
				PrintHintTextToAll("%t", "ModeNotChange");
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			client_voted[i] = false;
		}
		i_UpVote = 0;
		i_DownVote = 0;
		if (h_Timer != INVALID_HANDLE)
		{
			KillTimer(h_Timer);
			h_Timer = INVALID_HANDLE;
		}
	}
}
public Handle_VoteMenuOlolo(Handle:menu, MenuAction:action, param1, param2)
{
	//param1 - клиент (Голосование при этом еще не закончено!!) param2- пункт голосования
	if (param1 > 0 && IsClientInGame(param1) && !IsFakeClient(param1))
	{
		switch (param2)
		{
			case 0:
			{
				i_UpVote++;
				client_voted[param1] = true;
			}
			case 1:
			{
				i_DownVote++;
				client_voted[param1] = true;
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		for (new i = 0; i <= MAXPLAYERS; i++) client_voted[i] = false;
		i_UpVote = 0;
		i_DownVote = 0;
	}
	//param1 - победивший пункт голосования (Голосование закончилось)
	else if (action == MenuAction_VoteEnd)
	{
		switch (param1)
		{
			case 0:
			{
				SetDifficulty(1);
				PrintToChatAll("%t %t.", "ApprovedMode", "ModeOlolo");
				PrintHintTextToAll("%t %t", "EnabledMode", "ModeOlolo");
			}
			case 1:
			{
				PrintToChatAll("%t %t.", "UnapprovedMode", "ModeOlolo");
				PrintHintTextToAll("%t", "ModeNotChange");
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			client_voted[i] = false;
		}
		i_UpVote = 0;
		i_DownVote = 0;
		if (h_Timer != INVALID_HANDLE)
		{
			KillTimer(h_Timer);
			h_Timer = INVALID_HANDLE;
		}
	}
}
public Handle_VoteMenuPro(Handle:menu, MenuAction:action, param1, param2)
{
	//param1 - клиент (Голосование при этом еще не закончено!!) param2- пункт голосования
	if (param1 > 0 && IsClientInGame(param1) && !IsFakeClient(param1))
	{
		switch (param2)
		{
			case 0:
			{
				i_UpVote++;
				client_voted[param1] = true;
			}
			case 1:
			{
				i_DownVote++;
				client_voted[param1] = true;
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		for (new i = 0; i <= MAXPLAYERS; i++) client_voted[i] = false;
		i_UpVote = 0;
		i_DownVote = 0;
	}
	//param1 - победивший пункт голосования (Голосование закончилось)
	else if (action == MenuAction_VoteEnd)
	{
		switch (param1)
		{
			case 0:
			{
				SetDifficulty(2);
				PrintToChatAll("%t %t.", "ApprovedMode", "ModePRO");
				PrintHintTextToAll("%t %t", "EnabledMode", "ModePRO");
			}
			case 1:
			{
				PrintToChatAll("%t %t.", "UnapprovedMode", "ModePRO");
				PrintHintTextToAll("%t", "ModeNotChange");
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			client_voted[i] = false;
		}
		i_UpVote = 0;
		i_DownVote = 0;
		if (h_Timer != INVALID_HANDLE)
		{
			KillTimer(h_Timer);
			h_Timer = INVALID_HANDLE;
		}
	}
}
public Handle_VoteMenuLandoriki(Handle:menu, MenuAction:action, param1, param2)
{
	//param1 - клиент (Голосование при этом еще не закончено!!) param2- пункт голосования
	if (param1 > 0 && IsClientInGame(param1) && !IsFakeClient(param1))
	{
		switch (param2)
		{
			case 0:
			{
				i_UpVote++;
				client_voted[param1] = true;
			}
			case 1:
			{
				i_DownVote++;
				client_voted[param1] = true;
			}
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		for (new i = 0; i <= MAXPLAYERS; i++) client_voted[i] = false;
		i_UpVote = 0;
		i_DownVote = 0;
	}
	//param1 - победивший пункт голосования (Голосование закончилось)
	else if (action == MenuAction_VoteEnd)
	{
		switch (param1)
		{
			case 0:
			{
				SetDifficulty(3);
				PrintToChatAll("%t %t.", "ApprovedMode", "ModeLandoriki");
				PrintHintTextToAll("%t %t", "EnabledMode", "ModeLandoriki");
			}
			case 1:
			{
				PrintToChatAll("%t %t.", "UnapprovedMode", "ModeLandoriki");
				PrintHintTextToAll("%t", "ModeNotChange");
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			client_voted[i] = false;
		}
		i_UpVote = 0;
		i_DownVote = 0;
		if (h_Timer != INVALID_HANDLE)
		{
			KillTimer(h_Timer);
			h_Timer = INVALID_HANDLE;
		}
	}
}
/*Menu_Difficulty(client)
{
	new Handle:PlayerMenu = CreateMenu(DifficultyMenuHandler);
	decl String:DifficultyTitle[40];
	Format(DifficultyTitle, sizeof(DifficultyTitle), "%T\n \n", "MenuDifficultyTitle", client);
	SetMenuTitle(PlayerMenu, DifficultyTitle);
	new String:Value[32];
	
	Format(Value, sizeof(Value), "%T", "Difficulty_easy", client);
	AddMenuItem(PlayerMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty_normal", client);
	AddMenuItem(PlayerMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty_hard", client);
	AddMenuItem(PlayerMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty_impossible", client);
	AddMenuItem(PlayerMenu, "3", Value);

	SetMenuExitButton(PlayerMenu, true);
	DisplayMenu(PlayerMenu, client, 30);
}
public DifficultyMenuHandler(Handle:PlayerMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select)
	{
		switch (option)
		{
			case 0: ClientCommand(client, "callvote ChangeDifficulty Easy");
			case 1: ClientCommand(client, "callvote ChangeDifficulty Normal");
			case 2: ClientCommand(client, "callvote ChangeDifficulty Hard");
			case 3: ClientCommand(client, "callvote ChangeDifficulty Impossible");
		}
	}
}*/
public Action:Timer_Func(Handle:timer)
{
	if (--i_TimerVote > 0)
	{
		PrintHintTextToAll("%t\n%t\n< %d %t >", "UntilVotingEnd", i_UpVote, i_DownVote, "UntilVotingEnd_2", i_TimerVote, "UntilVotingEnd_3");
		return Plugin_Continue;
	}
	// Время истекло, голосование окончено
	h_Timer = INVALID_HANDLE;
	PrintHintTextToAll("%t", "ModeNotChange");
	return Plugin_Stop;
}
public Action:Timer_FuncOut(Handle:timer)
{
	b_TimeOutVote = false;
}
SetDifficulty(mode)
{
	switch(mode)
	{
		case 0:
		{
			//spec
			SetConVarInt(FindConVar("l4d_ais_limit"), 4);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 30);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 40);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 20);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 60);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 20);
			SetConVarInt(FindConVar("tongue_range"), 900);
			//tank
			SetConVarInt(FindConVar("mt_count_regular_coop"), 1);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 8000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 8000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 8000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 8000);
			//witch
			SetConVarInt(FindConVar("z_witch_health"), 1000);
			//plugins
			SetConVarInt(FindConVar("sm_hpregeneration_enable"), 0);
			SetConVarInt(FindConVar("l4d_selfhelp_enable"), 1);
			//
			ModeGame = 0;
		}
		case 1:
		{
			//spec
			SetConVarInt(FindConVar("l4d_ais_limit"), 5);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 30);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 35);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 20);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 10);
			SetConVarInt(FindConVar("tongue_range"), 900);
			//tank
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 15000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 15000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 15000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 15000);
			//witch
			SetConVarInt(FindConVar("z_witch_health"), 1000);
			//plugins
			SetConVarInt(FindConVar("sm_hpregeneration_enable"), 1);
			SetConVarInt(FindConVar("l4d_selfhelp_enable"), 1);
			//
			ModeGame = 1;
		}
		case 2:
		{
			//spec
			SetConVarInt(FindConVar("l4d_ais_limit"), 8);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 25);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 40);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 20);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 60);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 20);
			SetConVarInt(FindConVar("tongue_range"), 900);
			//tank
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 18000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 18000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 18000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 3);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 18000);
			//witch
			SetConVarInt(FindConVar("z_witch_health"), 1500);
			//plugins
			SetConVarInt(FindConVar("sm_hpregeneration_enable"), 1);
			SetConVarInt(FindConVar("l4d_selfhelp_enable"), 1);
			//
			ModeGame = 2;
		}
		case 3:
		{
			//spec
			SetConVarInt(FindConVar("l4d_ais_limit"), 10);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 25);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 30);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 20);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 30);
			SetConVarInt(FindConVar("tongue_range"), 1000);
			//tank
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 30000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 25000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 25000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 3);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 25000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 3);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 25000);
			//witch
			SetConVarInt(FindConVar("z_witch_health"), 2000);
			//plugins
			SetConVarInt(FindConVar("sm_hpregeneration_enable"), 0);
			SetConVarInt(FindConVar("l4d_selfhelp_enable"), 1);
			//
			ModeGame = 3;
			//ServerCommand("sm plugins unload");
		}
	}
}
public Action:Kill_Me(client, args)
{
	if (client < 1 || IsFakeClient(client) || !IsClientInGame(client)) return;
	if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		decl String:username[32];
		ForcePlayerSuicide(client);
		GetClientName(client, username, sizeof(username));
		PrintToChatAll("%t", "Suicide", username);
	}
}