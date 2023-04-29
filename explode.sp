#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 

 

public OnPluginStart(){ 
      RegConsoleCmd("test", Command_Test); 
} 

public OnMapStart(){ 
      PrecacheSound("weapons/hegrenade/explode3.wav", true);
} 

public Action:Command_Test(client, args){ 
	decl Float:fPos[3], Float:fClientPos[3], Float:fDistance; 
	GetClientAimPosition(client, fPos); 

	EmitAmbientSound("weapons/hegrenade/explode3.wav", fPos, client, SNDLEVEL_RAIDSIREN); 
	
	decl ent;
	ent = CreateEntityByName("info_particle_system");
	DispatchKeyValue(ent, "effect_name", "gas_explosion_pump");
	DispatchSpawn(ent);
	SetVariantString("!activator");
	TeleportEntity(ent, fPos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent); 
	AcceptEntityInput(ent, "Start"); 

	for (new i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{ 
			GetClientAbsOrigin(i, fClientPos); 

			if((fDistance = GetVectorDistance(fClientPos, fPos)) <= 100.0) 
			SDKHooks_TakeDamage(i, client, client, fDistance, DMG_GENERIC);//Урон, это fDistance, то есть в данном примере урон равен дистанции от взрыва до игрока. 
		} 
	} 
} 

stock GetClientAimPosition(client, Float:fPos[3]){ 
		decl Float:fAngles[3], Float:fPosition[3], Handle:hTrace;   
		GetClientEyePosition(client, fPosition);   
		GetClientEyeAngles(client, fAngles);   
		hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, Get_PosFilter, client);   
		TR_GetEndPosition(fPos, hTrace);   
		CloseHandle(hTrace);   
}   

public bool:Get_PosFilter(ent, mask, any:i)   
      return i != ent; 