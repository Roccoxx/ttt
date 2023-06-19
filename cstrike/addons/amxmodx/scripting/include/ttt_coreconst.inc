#if defined _ttt_coreconst_included
	#endinput
#endif

#define _ttt_coreconst_included

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_PASS ""
#define MYSQL_DATEBASE "ttt_pijudo"

new const szTableAccounts[] = "ttt_ermec_accounts";
new const szTableStatistics[] = "ttt_ermec_statistics";

enum{
	REGISTRAR_CUENTA,
	CARGAR_CUENTA,
	CARGAR_ESTADISTICAS,
	GUARDAR_DATOS,
	ACTUALIZAR_NOMBRE
};

enum{
	REMOVER_TEAM_KILLS
};

const ADMIN_FLAG = ADMIN_SLAY;

enum (+= 312){
	TASK_ROUND = 1234,
	TASK_SURVIVAL,
	TASK_TUTOR,
	TASK_SPAWN
};

#define ID_TUTOR (taskid - TASK_TUTOR)
#define ID_SPAWN (taskid - TASK_SPAWN)

new const szCountdownSounds[][] = 
{	
	"sound/ttt/zero.mp3",
    "sound/ttt/one.mp3",
    "sound/ttt/two.mp3",
    "sound/ttt/three.mp3",
    "sound/ttt/four.mp3",
    "sound/ttt/five.mp3"
};

new const g_szCrowbarSound[][] = {"weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit2.wav",  "weapons/cbar_miss1.wav"};

new const szTraitorsWinSound[] = "ttt/win_traitors.wav";
new const szInnocentsWinSound[] = "ttt/win_innocent.wav";

new const szSoundGetAchievemment[] = "ttt/logro-cumplido.wav";

new const szMainMenuOpenSound[] = "events/enemy_died.wav";

new const szSpriteDetective[] = "sprites/ttt/team_d.spr";
new const szSpriteTraitor[] = "sprites/ttt/team_t.spr";

new const szDnaCallSprite[] = "sprites/ttt/dna_call.spr"

enum TutorColor { TUTOR_RED = 1, TUTOR_BLUE, TUTOR_YELLOW, TUTOR_GREEN };

new const szTutorPrecache[][] = 
{  
    "gfx/career/icon_!.tga", 
    "gfx/career/icon_!-bigger.tga", 
    "gfx/career/icon_i.tga",  
    "gfx/career/icon_i-bigger.tga", 
    "gfx/career/icon_skulls.tga",
    "gfx/career/round_corner_ne.tga", 
    "gfx/career/round_corner_nw.tga", 
    "gfx/career/round_corner_se.tga", 
    "gfx/career/round_corner_sw.tga", 
    "resource/TutorScheme.res", 
    "resource/UI/TutorTextWindow.res"
};

new const szTutorSound[] = "player/tutor.wav";

enum _:CROWBAR_MODELS{
	CROWBAR_V_MODEL, CROWBAR_P_MODEL
}

new szCrowbarModels[CROWBAR_MODELS][] = {
	"models/ttt/v_crowbar.mdl", "models/ttt/p_crowbar.mdl"
};

new const szPlayerModel[] = "terror";

enum _:Data_Karma{
	TEMP_KARMA,
	CURRENT_KARMA
}

const STARTING_KARMA = 500;
const KARMA_LIMIT = 1000;
const Float:KARMA_DAMAGE_MULTIPLIER = 0.25;
const KARMA_KILL_MULTIPLIER = 70;
const Float:KARMA_BY_IDENTIEING_TRAITOR = 10.0

const DETECTIVE_STARTING_CREDITS = 1;
const TRAITOR_STARTING_CREDITS = 2;
const CREDITS_BY_KILLING_DETECTIVE = 1;
const CREDITS_BY_KILLING_TRAITOR = 1;
const CREDITS_BY_IDENTIEING_TRAITOR = 1;
const CREDITS_REWARD_BY_KILLING_TEAM = 1;
const Float:REWARDS_SURVIVAL_TIME = 45.0;
const CREDITS_BY_STAY_ALIVE = 1;

const TRAITORS_COUNT_PER_PLAYER = 4;
const DETECTIVES_COUNT_PER_PLAYER = 6;

const FS_LIMIT = 9;

enum _:TEAM_KILLS{
	TEAM_TEAMMATES_KILLED,
	TEAM_KILLS_COUNT
}

const TEAM_KILLS_INNOCENT_LIMIT = 3;
const TEAMMATES_KILLS_LIMIT = 2;
const BAN_TIME = 10;

new const szPlayerStatus[][] = {
	"Inocente",
	"Detective",
	"Traidor",
	"Ninguno"
}

new const g_iHudColors[][] = {
	{0, 255, 0},
	{0, 160, 230},
	{255, 125, 0}
};

new const Float:g_fBodyColors[][] = {
	{0.0, 255.0, 0.0},
	{0.0, 50.0, 255.0},
	{255.0, 50.0, 0.0}
};

const Float:HUD_POSITION_Y = 0.9;
const Float:HUD_POSITION_X = 0.02;

enum _:DATA_INTEGER_CVARS{
	INTEGER_CVAR_NAME[20],
	INTEGER_CVAR_VALUE
}

new g_DataIntegerCvars[][DATA_INTEGER_CVARS] = {
	{"mp_autoteambalance", 0},
	{"mp_buytime", -1},
	{"mp_buy_anywhere", 1},
	{"mp_auto_join_team", 0},
	{"mp_max_teamkills", 0},
	{"mp_give_player_c4", 0},
	{"mp_friendlyfire", 1},
	{"mp_freezetime", 0},
	{"sv_alltalk", 4}
};

enum _:DATA_STRING_CVARS{
	STRING_CVAR_NAME[40],
	STRING_CVAR_VALUE[10]
}

new g_DataStringCvars[][DATA_STRING_CVARS] = {
	{"mp_t_default_weapons_secondary", ""},
	{"mp_ct_default_weapons_secondary", ""},
	{"mp_round_infinite", "bcdefhij"}
};

enum _:Data_Messages{
	MSG_DEATHMSG,
	MSG_SCOREATTRIB,
	MSG_SCOREINFO,
	MSG_SCREENFADE,
	MSG_TUTORTEXT,
	MSG_TUTORCLOSE,
	MSG_TEAMINFO,
	MSG_STATUSTEXT
}

enum _:Data_SyncHud{
	SYNCHUD_PRINCIPAL,
	SYNCHUD_STATUSVALUE
}

enum{
	BODY_NOT_REPORTED = 0,
	BODY_REPORTED,
	BODY_ANALIZED
}

enum _:Data_DeadBody{
	BODY_NAME[32],
	BODY_WEAPON[16],
	Float:BODY_SECONDS,
	BODY_OWNER_STATUS,
	BODY_STATUS,
	BODY_KILLER
}

const Float:MAX_BODY_DIST = 100.0;
const DEATH_SUICIDE = 7070;

new const szDeadBodyClassName[] = "DeadBody";

const IMPULSE_REPORTED = 696969;

const UNIT_SECOND = (1<<12);
const FFADE_IN = 0x0000;

new const g_szBlockSet[][] =
{
	"BombDrop",
	"BombPickup",
	"DeathMsg",
	"ScoreInfo",
	"Radar",
	"Money",
	"ClCorpse"
};

new const g_szMessageBlock[][] =
{
	"TextMsg",
	"SendAudio",
	"Scenario",
	"StatusIcon",
	"StatusText"
};

enum _:ArrayMurdersData
{
	iMurderAttacker,
	iMurderAttackerStatus,
	iMurderAttackerName[32],
	szMurderVictimName[32],
	iMuerderVictimStatus
}

enum _:ArrayStatusRoundData
{
	PlayerRoundName[32],
	PlayerRoundStatus
}

enum _:ArrayDamageData
{
	szDamageAttackerName[32],
	szDamageVictimName[32],
	iDamageAttackerStatus,
	iDamageVictimStatus,
	Float:fDamageCount
}

enum _:AchievementsList{
	SOY_NUEVO,
	JUGADO_COMO_UN_CAMPEON,
	VICIADO,
	PEOR_QUE_UNA_DROGA,
	VIDA_SOCIAL,

	DISPAROS_DE_SUERTE,
	TE_MATE,
	PONGO_EL_OJO_Y_PONGO_LA_BALA,
	MAQUINA_IMPARABLE,

	SUERTE_DE_PRINCIPANTE,
	GANARME_VOS_A_MI,
	EN_ESTE_SERVIDOR_MANDO_YO,
	FUI_HECHO_PARA_ESTE_JUEGO,

	NO_CONFIES_EN_MI,
	ICARDI_FUE_MI_MAESTRO,
	NI_JUDAS_SE_ATREVIO_A_TANTO,

	AHI_LO_TENES_AL_PELOTUDO,

	ASESINO_SILENCIOSO,
	EL_MAESTRO_DE_LA_MINA,
	LAS_VACAS_NO_VUELAN,
	ALAHU_AKBAR,

	MAS_FALSO_QUE_EL_AMOR_DE_ELLA,

	DESARMO_LAS_24_7,
	A_MI_NO_ME_MARCAS
}

enum _:Data_Achievements{
	ACHIEVEMENT_NAME[30],
	ACHIEVEMENT_DESCRIPTION[50],
	ACHIEVEMENT_REQUIRED_COUNT
}

new g_DataAchievements[][Data_Achievements] = {
	{"Soy nuevo, no me juzguen", "Consigue un total de 1 hora de juego jugadas", 1},
	{"Jugando como un campeón", "Consigue un total de 10 horas de juego", 10},
	{"¿Viciado? ¿Donde?", "Consigue un total de 2 dias de juego", 2},
	{"Peor que una droga", "Consigue un total de 6 dias de juego", 6},
	{"¿Vida social? ¿Que es eso?", "Consigue un total de 30 dias de juego", 30},

	{"Disparos de suerte", "Mata 10 jugadores correctamente", 10},
	{"¿Te mate?", "Mata 100 jugadores correctamente", 100},
	{"Pongo el ojo y pongo la bala", "Mata 1000 jugadores correctamente", 1000},
	{"Maquina imparable", "Mata 10.000 jugadores correctamente", 10000},

	{"Suerte de principiante", "Gana 3 rondas", 3},
	{"¿Ganarme vos a mi?", "Gana 30 rondas", 30},
	{"En este servidor mando yo", "Gana 300 rondas", 300},
	{"Fui hecho para este juego", "Gana 3000 rondas", 3000},

	{"No confies en mi", "Se traidor 100 veces", 100},
	{"Icardi fue mi maestro", "Se traidor 500 veces", 500},
	{"Ni judas se atrevio a tanto", "Se traidor 1000 veces", 1000},
	
	{"Ahi lo tenes al pelotudo", "Matar por error 15 veces", 15},

	{"Asesino silencioso", "Asesina 1000 jugadores con cuchillo", 1000},
	{"El maestro de la mina", "Asesina 1000 jugadores con la mina", 1000},
	{"Las vacas no vuelan", "Asesina 1000 jugadores con newton", 1000},
	{"Alahu akbar", "Asesina 1000 jugadores con jihad", 1000},

	{"Mas falso que el amor de ella", "Se detective falso 1000 veces", 1000},

	{"Desarmo las 24/7", "Desarma a 1000 jugadores", 1000},
	{"A mi no me marcas", "Desmarca a 1000 traidores", 1000}
};

enum _:Achievement_type{
	Achievement_type_time,
	Achievement_type_correct,
	Achievement_type_round,
	Achievement_type_traitor,
	Achievement_type_incorrect,
	Achievement_type_kills,
	Achievement_type_fake_detective,
	Achievement_type_disarmed,
	Achievement_type_unmarked
}

enum _:Statistics_List{
	SECONDS_PLAYED,
	POINTS,
	DETECTIVES_KILLED,
	INNOCENTS_KILLED,
	TRAITORS_KILLED,
	KILLS_COUNT,
	DEATHS_COUNT,
	DAMAGE_CORRECT,
	DAMAGE_INCORRECT,
	KILLS_CORRECT,
	KILLS_INCORRECT,
	TRAITOR_ROUNDS,
	INNOCENT_ROUNDS,
	DETECTIVE_ROUNDS,
	ROUNDS_PLAYED,
	ROUNDS_WIN,
	TRAITOR_ROUNDS_WIN,
	MAX_KARMA_COUNT,
	C4_PLANTED,
	C4_EXPLODED,
	C4_DEFUSED,
	C4_KILLS,
	KNIFE_KILLS,
	NEWTON_KILLS,
	JIHAD_KILLS,
	USP_KILLS,
	GOLDEN_KILLS,
	MINE_KILLS,
	STATION_KILLS,
	MORTAL_HIT_KILLS,
	FALSE_DETECTIVE_BUYS,
	PLAYERS_DISARMED,
	PLAYERS_UNMARKED
}

new const szStatistics[Statistics_List][] = {
	"Excepcion",
	"Puntos",
	"Detectives asesinados",
	"Inocentes asesinados",
	"Traidores Asesinados",
	"Asesintatos total",
	"Muertes",
	"Daño correcto",
	"Daño incorrecto",
	"Asesinatos correctos",
	"Asesinatos incorrectos",
	"Rondas siendo traidor",
	"Rondas siendo inocente",
	"Rondas detective",
	"Rondas jugadas",
	"Rondas ganadas",
	"Rondas ganadas de traidor",
	"Veces con maximo karma",
	"C4 plantados",
	"C4 detonados",
	"C4 desactivados",
	"Asesinatos con C4",
	"Asesinatos con cuchillo",
	"Asesinatos con Newton",
	"Asesinatos con Jihad",
	"Asesinatos con usp",
	"Asesinatos con dorada",
	"Asesinatos con mina",
	"Asesinatos con estacion",
	"Asesinatos con hit mortal",
	"Compras dt falso",
	"Jugadores desarmados",
	"Jugadores desmarcados"
};

enum _:STRUCT_WEAPONS
{
	WEAPON_NAME[20],
	WEAPON_ENT[20],
	WeaponIdType:WEAPON_CSW,
	WEAPON_AMMO
}

new const g_szListWeapons[][ STRUCT_WEAPONS ] = 
{
	{ "SIG-Sauer P228", "weapon_p228", WEAPON_P228, 52 },
	{ "Beretta 92", "weapon_elite", WEAPON_ELITE, 120 },
	{ "FN Five-seven", "weapon_fiveseven", WEAPON_FIVESEVEN, 100 },
	{ "Glock 18", "weapon_glock18", WEAPON_GLOCK18, 120 },
	{ "Desert Eagle", "weapon_deagle", WEAPON_DEAGLE, 35 },
	
	{ "M3 Super 90", "weapon_m3", WEAPON_M3, 32 },
	{ "XM1014", "weapon_xm1014", WEAPON_XM1014, 32 },
	{ "MAC-10", "weapon_mac10", WEAPON_MAC10, 100 },
	{ "UMP45", "weapon_ump45", WEAPON_UMP45, 100 },
	{ "Steyr TMP", "weapon_tmp", WEAPON_TMP, 120 },
	{ "P90", "weapon_p90", WEAPON_P90, 100 },
	{ "FN M249", "weapon_m249", WEAPON_M249, 200 },
	{ "SCOUT", "weapon_scout", WEAPON_SCOUT, 30 }
};

new const g_szObjetiveEnts[][] = {"armoury_entity", "hostage_entity", "func_hostage_rescue", "info_hostage_rescue"};