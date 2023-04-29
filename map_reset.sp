public Plugin:myinfo = 
{
	name = "L4D Map Reset",
	author = "Figa",
	description = "Reset map if Not Standart",
	version = "1.0 TK Edition",
	url = "http://fiksiki.3dn.ru/"
};

new Handle:ResetMapTimer;

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client) && IsAddonsMap() && ResetMapTimer == INVALID_HANDLE)
	{
		ResetMapTimer = CreateTimer(30.0, TimerChDelayAddonsCOOP);
	}
}

public OnMapStart()
{
	if (ResetMapTimer != INVALID_HANDLE) 
	{ 
		KillTimer(ResetMapTimer); 
		ResetMapTimer = INVALID_HANDLE; 
	}
	if (IsAddonsMap()) ResetMapTimer = CreateTimer(30.0, TimerChDelayAddonsCOOP);
}

bool IsAddonsMap()
{
	decl String:s_currentMap[64];
	GetCurrentMap(s_currentMap, sizeof(s_currentMap));

	if(StrContains(s_currentMap, "river", false) == -1	&&
	StrContains(s_currentMap, "airport", false) == -1	&&
	StrContains(s_currentMap, "farm", false) == -1		&&
	StrContains(s_currentMap, "garage", false) == -1	&&
	StrContains(s_currentMap, "hospital", false) == -1	&&
	StrContains(s_currentMap, "smalltown", false) == -1) return true;
	return false;
}

public Action:TimerChDelayAddonsCOOP(Handle:timer)
{
	if (IsAddonsMap())
	{
		new PlayerCount;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) PlayerCount++;
		}
		if (PlayerCount == 0) 
		{
			switch(GetRandomInt(0, 3))
			{
				case 0: ServerCommand("changelevel l4d_airport01_greenhouse");
				case 1: ServerCommand("changelevel l4d_farm01_hilltop");
				case 2: ServerCommand("changelevel l4d_hospital01_apartment");
				case 3: ServerCommand("changelevel l4d_smalltown01_caves");
			}
		}
	}
	ResetMapTimer = INVALID_HANDLE;
}