#include <sdktools>
#include <osblackhole>
#include <shop>
#include <zombiereloaded>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SHOP] Black Hole",
	author = "KiKiEEKi | NZ",
	version = "( PRIVATE 1.0 )"
};

bool g_bBlackHole[MAXPLAYERS+1];
int g_iPrice = 100; //Цена покупки
int g_iLimit[2] = {2, 3}; //Лимит в раунде для Т и КТ
int g_iLimitRound[2];

public void CVarChanged_1(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iPrice = cvar.IntValue;
}
public void CVarChanged_2(ConVar cvar, const char[] oldVal, const char[] newVal) {
	g_iLimit[0] = cvar.IntValue;
}
public void CVarChanged_3(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iLimit[1] = cvar.IntValue;
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", Event_PlayerHurt);

	if(Shop_IsStarted()) Shop_Started();

	ConVar cvar;
	(cvar = CreateConVar("sm_bh_shop_price", "100", "Цена покупки Black Hole")).AddChangeHook(CVarChanged_1);
	CVarChanged_1(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gh_shop_limit_t", "2", "Лимит в раунде для Т")).AddChangeHook(CVarChanged_2);
	CVarChanged_2(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gh_shop_limit_ct", "3", "УЛимит в раунде для CТ")).AddChangeHook(CVarChanged_3);
	CVarChanged_3(cvar, NULL_STRING, NULL_STRING);
	AutoExecConfig(true, "[OS][SHOP]BlackHole", "BlackHole");
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; ++i) {
		g_bBlackHole[i] = false;
	}
}

void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	g_iLimitRound[0] = g_iLimit[0];
	g_iLimitRound[1] = g_iLimit[1];
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory("ability", "Способности", "");
	if(category_id == INVALID_CATEGORY) SetFailState("Failed to register category");

	if(Shop_StartItem(category_id, "blackhole"))
	{
		Shop_SetInfo("Black Hole", "", g_iPrice, _, Item_BuyOnly, _, _, _);
		Shop_SetCallbacks(_, _, _, _, _, _, ItemBuyCallback);
		Shop_EndItem();
	}
}

public bool ItemBuyCallback(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value, int gold_price, int gold_sell_price)
{
	if(!IsPlayerAlive(iClient))
	{
		PrintToChat(iClient, "Black Hole недоступен мертвым!");
		return false;
	}

	if(g_bBlackHole[iClient]) {
		PrintToChat(iClient, "Black Hole уже куплен!");
		return false;
	}

	if(GetClientTeam(iClient) == 2)
	{
		if(g_iLimitRound[0] < 1)
		{
			PrintToChat(iClient, "Black Hole закончился в раунде для зомби!");
		}
		else
		{
			--g_iLimitRound[0];
			g_bBlackHole[iClient] = true;
			PrintToChat(iClient, "Black Hole куплен для зомби, осталось %i!", g_iLimitRound[0]);
			return true;
		}
	}

	if(GetClientTeam(iClient) == 3)
	{
		if(g_iLimitRound[1] < 1)
		{
			PrintToChat(iClient, "Black Hole закончился в раунде для людей!");
		}
		else
		{
			--g_iLimitRound[1];
			g_bBlackHole[iClient] = true;
			PrintToChat(iClient, "Black Hole куплен для людей, осталось %i!", g_iLimitRound[1]);
			return true;
		}
	}
	return false;
}

void Event_PlayerHurt(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if(g_bBlackHole[iAttacker])
	{
		char sWpnName[16];
		hEvent.GetString("weapon", sWpnName, sizeof(sWpnName));

		if(strcmp(sWpnName, "knife") == 0)
		{
			//g_bBlackHole[iAttacker] = false;
			int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
			float fPos[3];
			GetClientEyePosition(iClient, fPos);
			if(ZR_IsClientHuman(iClient)) ZR_InfectClient(iClient);
			OS_BlackHole(iAttacker, GetClientTeam(iAttacker), fPos);
		}
	}
}

public Action ZR_OnClientInfect(int &iClient, int &iAttacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(!(0 < iClient <= MaxClients)) return Plugin_Continue;
	if(!(0 < iAttacker <= MaxClients)) return Plugin_Continue;

	if(g_bBlackHole[iAttacker])
	{
		ZR_HumanClient(iClient);

		int iHp = GetClientHealth(iClient);

		if(iHp < 1) {
			ForcePlayerSuicide(iClient);
		}
		else {
			SetEntityHealth(iClient, iHp);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
