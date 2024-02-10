#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Black Hole",
	author = "KiKiEEKi & NZ",
	version = "( PRIVATE 1.0 )"
};

ArrayList g_hBlackHoleList;

enum struct BlackHoleSetting
{
	int iOwner;
	int iTeam;
	float fPos[3];
}

BlackHoleSetting g_esBlackHoleSetting;

Handle g_hTimerTick; //Притягивание каждый N sec
//Handle g_hTimerDuration; //Продолжительность N sec
Handle g_hTimerDamage; //Урон каждые N sec

float g_fTick = 0.3; //Притягивание каждый N sec
float g_fDuration = 5.0; //Продолжительность N sec
float g_fTickDmg = 1.0; //Урон каждые N sec
int g_iDamage = 25; //Урон
float g_fRadius = 400.0; //Радиус

//============================
float g_fPosPlayer[3];
float g_fDirection[3];

public void CVarChanged_1(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fTick = cvar.FloatValue;
}
public void CVarChanged_2(ConVar cvar, const char[] oldVal, const char[] newVal) {
	g_fDuration = cvar.FloatValue;
}
public void CVarChanged_3(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fTickDmg = cvar.FloatValue;
}
public void CVarChanged_4(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iDamage = cvar.IntValue;
}
public void CVarChanged_5(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fRadius = cvar.FloatValue;
}

public void OnPluginStart()
{
	g_hBlackHoleList = new ArrayList(ByteCountToCells(32));
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	ConVar cvar;
	(cvar = CreateConVar("sm_bh_tick", "0.1", "Притягивание каждый N sec")).AddChangeHook(CVarChanged_1);
	CVarChanged_1(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gh_duration", "5.0", "Продолжительность N sec")).AddChangeHook(CVarChanged_2);
	CVarChanged_2(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_bh_tickdmg", "1.0", "Урон каждые N sec")).AddChangeHook(CVarChanged_3);
	CVarChanged_3(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_bh_damage", "500", "Урон")).AddChangeHook(CVarChanged_4);
	CVarChanged_4(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_bh_radius", "600.0", "Радиус")).AddChangeHook(CVarChanged_5);
	CVarChanged_5(cvar, NULL_STRING, NULL_STRING);
	AutoExecConfig(true, "[OS]BlackHole", "BlackHole");
}

public void OnMapStart()
{
	g_hBlackHoleList.Clear();

	delete g_hTimerTick;
	g_hTimerTick = CreateTimer(g_fTick, Timer_Tick, _, TIMER_REPEAT);

	delete g_hTimerDamage;
	g_hTimerDamage = CreateTimer(g_fTickDmg, Timer_Damage, _, TIMER_REPEAT);
}

void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	g_hBlackHoleList.Clear();
}

Action Timer_BlackHoleDel(Handle timer)
{
	if(g_hBlackHoleList.Length > 0) {
		g_hBlackHoleList.Erase(0);
	}

	return Plugin_Continue;
}

//============================
//
Action Timer_Tick(Handle timer)
{
	OSBlackHole(false);
	return Plugin_Continue;
}

Action Timer_Damage(Handle timer)
{
	OSBlackHole(true);
	return Plugin_Continue;
}

void OSBlackHole(bool bDamage)
{
	if(g_hBlackHoleList.Length < 1) return;

	for(int iIndex = 0; iIndex < g_hBlackHoleList.Length; ++iIndex)
	{
		g_hBlackHoleList.GetArray(iIndex, g_esBlackHoleSetting, sizeof(g_esBlackHoleSetting));

		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != g_esBlackHoleSetting.iTeam)
			{
				GetClientAbsOrigin(i, g_fPosPlayer);

				if(GetVectorDistance(g_esBlackHoleSetting.fPos, g_fPosPlayer) <= g_fRadius / 2)
				{
					if(!bDamage)
					{
						//Строит вектор из двух точек путем вычитания точек.
						MakeVectorFromPoints(g_fPosPlayer, g_esBlackHoleSetting.fPos, g_fDirection);
						//Нормализует вектор. Входной массив может быть таким же, как и выходной массив.
						NormalizeVector(g_fDirection, g_fDirection);
						//Масштабирует вектор или Сила притягивания
						ScaleVector(g_fDirection, g_fRadius / 2);
						TeleportEntity(i, g_fPosPlayer, NULL_VECTOR, g_fDirection);
					}
					else
					{
						int iHp = GetClientHealth(i);
						if(iHp < 1) {
							ForcePlayerSuicide(i);
						}
						else {
							iHp = iHp - g_iDamage;
							SetEntityHealth(i, iHp);
						}
						OSCreateiEnt(g_esBlackHoleSetting.fPos);
					}
				}
			}
		}
	}
}

void OSCreateiEnt(float fPos[3])
{
	int iEnt = CreateEntityByName("point_tesla");

	if(iEnt != -1)
	{
		DispatchKeyValue(iEnt, "m_flRadius", "200.0");
		DispatchKeyValue(iEnt, "m_SoundName", "DoSpark");
		DispatchKeyValue(iEnt, "beamcount_min", "42");
		DispatchKeyValue(iEnt, "beamcount_max", "62");
		DispatchKeyValue(iEnt, "texture", "sprites/physcannon_bluelight2.vmt");
		DispatchKeyValue(iEnt, "m_Color", "255 255 255");
		DispatchKeyValue(iEnt, "thick_min", "10.0");
		DispatchKeyValue(iEnt, "thick_max", "11.0");
		DispatchKeyValue(iEnt, "lifetime_min", "0.3");
		DispatchKeyValue(iEnt, "lifetime_max", "0.3");
		DispatchKeyValue(iEnt, "interval_min", "0.1");
		DispatchKeyValue(iEnt, "interval_max", "0.2");
		DispatchSpawn(iEnt);

		TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEnt, "TurnOn");
		AcceptEntityInput(iEnt, "DoSpark");

		char sBuf[32];
		FormatEx(sBuf, sizeof(sBuf), "OnUser1 !self:kill::%f:1", g_fDuration);
		SetVariantString(sBuf);
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
	}
}

//============================
//		API
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("OS_BlackHole", Native_OSBlackHole);
	RegPluginLibrary("osblackhole");
	return APLRes_Success;
}

public any Native_OSBlackHole(Handle plugin, int numParams)
{
	g_esBlackHoleSetting.iOwner = GetNativeCell(1);
	g_esBlackHoleSetting.iTeam = GetNativeCell(2);
	GetNativeArray(3, g_esBlackHoleSetting.fPos, sizeof(g_esBlackHoleSetting.fPos));
	g_hBlackHoleList.PushArray(g_esBlackHoleSetting, sizeof(g_esBlackHoleSetting));

	OSCreateiEnt(g_esBlackHoleSetting.fPos);
	CreateTimer(g_fDuration, Timer_BlackHoleDel, _, TIMER_FLAG_NO_MAPCHANGE);
	return 0;
}
