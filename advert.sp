#include <sourcemod>
#pragma semicolon 1

new Handle:mInterval;
new Handle:mType;
new Handle:mCount;
new Handle:g_mTimer;

new n_msg;

public Plugin:myinfo =
{
	name = "Advertisement",
	description = "Randomly displays a color message advertising, translations support.",
	author = "Figa",
	version = "1.4", 
	url = "http://fiksiki.3dn.ru"
};

public OnPluginStart()
{
	mInterval = CreateConVar("sm_advert_interval", "90.0", "Amount of seconds between advertisements.", FCVAR_PLUGIN, true, 1.0);
	mType = CreateConVar("sm_advert_type", "2", "Type of output messages. 0: disable, 1: enable random mode, 2: enable linear mode", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	mCount = CreateConVar("sm_advert_count", "10", "The number of messages with advertising. 1:Min, 30: Max.", FCVAR_PLUGIN, true, 1.0, true, 30.0);
	
	HookConVarChange(mInterval, ConVarChange_mInterval);
	
	//AutoExecConfig(true, "sm_advert");
	LoadTranslations("advert.phrases");
}

public OnMapStart()
{
	if (GetConVarInt(mType) == 0) return;
	g_mTimer = CreateTimer(GetConVarFloat(mInterval), Timer_Mess, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	if(g_mTimer != INVALID_HANDLE)
	{
		CloseHandle(g_mTimer);
		g_mTimer = INVALID_HANDLE;
	}
}

SwitchPrint()
{
	switch(n_msg)
	{
		case 1:
		{
			decl String:time[16];
			FormatTime(time, sizeof(time), "%H:%M");
			PrintToChatAll("%t", "msg_1", time);
		}
		case 2: PrintToChatAll("%t", "msg_2");
		case 3: PrintToChatAll("%t", "msg_3");
		case 4: PrintToChatAll("%t", "msg_4");
		case 5: PrintToChatAll("%t", "msg_5");
		case 6:
		{
			decl String:time[16];
			FormatTime(time, sizeof(time), "%H:%M");
			PrintToChatAll("%t", "msg_6", time);
		}
		case 7: PrintToChatAll("%t", "msg_7");
		case 8: PrintToChatAll("%t", "msg_8");
		case 9: PrintToChatAll("%t", "msg_9");
		case 10: PrintToChatAll("%t", "msg_10");
		case 11: PrintToChatAll("%t", "msg_11");
		case 12: PrintToChatAll("%t", "msg_12");
		case 13: PrintToChatAll("%t", "msg_13");
		case 14: PrintToChatAll("%t", "msg_14");
		case 15: PrintToChatAll("%t", "msg_15");
		case 16: PrintToChatAll("%t", "msg_16");
		case 17: PrintToChatAll("%t", "msg_17");
		case 18: PrintToChatAll("%t", "msg_18");
		case 19: PrintToChatAll("%t", "msg_19");
		case 20: PrintToChatAll("%t", "msg_20");
		case 21: PrintToChatAll("%t", "msg_21");
		case 22: PrintToChatAll("%t", "msg_22");
		case 23: PrintToChatAll("%t", "msg_23");
		case 24: PrintToChatAll("%t", "msg_24");
		case 25: PrintToChatAll("%t", "msg_25");
		case 26: PrintToChatAll("%t", "msg_26");
		case 27: PrintToChatAll("%t", "msg_27");
		case 28: PrintToChatAll("%t", "msg_28");
		case 29: PrintToChatAll("%t", "msg_29");
		case 30: PrintToChatAll("%t", "msg_30");
	}
}

public Action:Timer_Mess(Handle:timer)
{
	new count_msg = GetConVarInt(mCount);
	if (count_msg > 30 || count_msg < 1) count_msg = 30;
	
	if (GetConVarInt(mType) == 1)
	{
		n_msg = GetRandomInt(1,count_msg);
		SwitchPrint();
	}
	
	else if (GetConVarInt(mType) == 2)
	{
		static i = 1;
		n_msg = i;
		SwitchPrint();
		i++;
		if(i > count_msg) i = 1;
	}
}

public ConVarChange_mInterval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_mTimer) KillTimer(g_mTimer);
	g_mTimer = CreateTimer(GetConVarFloat(mInterval), Timer_Mess, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
