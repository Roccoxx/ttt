#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <xs>
#include <sqlx>
#include <api_oldmenu>
#include "includes/ttt_shop"
#include "includes/ttt_coreconst"
#include <hamsandwich>

#pragma semicolon 1

/*
WEAPON_UID:
130: DNA - C4 - DETECTIVE
131: PROTOTYPE - UMP45 - DETECTIVE 
132: REVOLVER - DEAGLE - DETECTIVE
133: GOLDEN - DEAGLE - DETECTIVE
134: DISARMER - DEAGLE - DETECTIVE
135: AWP - AWP - TRAIDOR8
136: SILENCED USP - USP - TRAIDOR
137: UNMARKER - DEAGLE - TRAIDOR
138: NEWTON - FIVESEVEN - TRAIDOR
139: Transportadora - DEAGLE - TRAIDOR
*/

/*
En GENERAL LA RELACION: ESTADISTICA - LOGRO - PROGRESO
*/

native ttt_is_holding_knife(const iId);

// GLOBAL VARS
new bool:g_bRoundEnd, bool:g_bRoundStart, bool:bForceRoundEnd, bool:g_bPrintCannotStartRound;
new g_bIsAlive, g_bIsConnected, g_bIsLogged, g_bIgnoreFS, g_bHaveMaxKarma, g_bMuteCountDown, g_bHideMotd, g_bHaveFakeName, g_bIsSpecialTalking;
new szName[MAX_NAME_LENGTH], szEndRoundMotd[MAX_MOTD_LENGTH], g_szDetectivesNames[162], g_szTraitorsNames[258], g_szKillerName[32], g_iKillerStatus, g_iKillerKills;
new g_iCountDown, g_SyncHud[Data_SyncHud], g_iUserMessages[Data_Messages], g_iSurvivalTaskRepeats, g_iKillBonusCredits, g_iDeadBodyEnt[33][Data_DeadBody];
new g_iTraitorSpr, g_iDetectiveSpr, g_iCallSprite;
new Array:g_aMurders, Array:g_aPreviusRoundStatus, Array:g_aRoundStatus, Array:g_aPreviusRoundDamage, Array:g_aRoundDamage, Trie:g_tSlayData, Trie:g_tDisconnectData;
new Handle:g_hTuple, Handle:g_hConnection;

// PLAYER VARS
new g_iPlayerStatus[33] = {STATUS_NONE, ...}, g_iCredits[33], g_iKarma[33][Data_Karma], g_iFreeShots[33], /*g_iHealth[33],*/ g_iTeamKills[33][TEAM_KILLS];
new g_iId[33], g_iPlayerAchievements[33][Data_Achievements], g_iPlayerStatistics[33][Statistics_List], g_szPlayerTarget[33][32], g_szPlayerFakeName[33][32];
new Float:g_fWaitTime[33];

#include "includes/ttt_menues"

public plugin_init(){
	register_plugin("TTT Base", "1.1.0", "Roccoxx");

	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_event("DeathMsg", "EventDeathMsg", "a");
	register_event("StatusValue", "EventShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "EventHideStatus", "be", "1=1", "2=0");
	register_event("ClCorpse", "EventClCorpse", "a", "10=0");

	register_message(get_user_msgid("Health"), "message_Health");
	register_message(get_user_msgid("HostagePos"), "message_HostagePos");
	register_message(get_user_msgid("Scenario"), "message_Scenario");
	register_message(get_user_msgid("TextMsg"), "message_TextMsg");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fwdItemDeploy_Post", true);
	RegisterHam(Ham_TraceAttack, "player", "fwdTraceAttack_Pre", false);

	RegisterHookChain(RG_ShowMenu, "fwdShowMenu_Pre", false);
	RegisterHookChain(RG_ShowVGUIMenu, "fwdShowVGUIMenu_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "fwdPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "fwdPlayerKilled_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "fwdPlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Post", true);
	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "fwdPlayerSetUserInfoName_Post", true);

	register_forward(FM_AddToFullPack, "fwdAddToFullPack_Post", true);
	register_forward(FM_EmitSound, "fwdEmitSound_Pre", false);
	register_forward(FM_Voice_SetClientListening, "Forward_SetClientListening_pre", 0);

	register_clcmd("chooseteam", "clcmd_changeteam");
	register_clcmd("jointeam", "clcmd_changeteam");
	register_clcmd("say_team", "clcmd_sayTeam");
	register_clcmd("SlayReason", "SlayPlayer");
	register_clcmd("+specialvoice", "clcmd_voiceon");
	register_clcmd("-specialvoice", "clcmd_voiceoff");
	register_clcmd("radio1", "clcmd_radio"); register_clcmd("radio2", "clcmd_radio"); register_clcmd("radio3", "clcmd_radio");

	register_concmd("ttt_shots", "concmd_Shots", ADMIN_FLAG, "ver los daños recibidos y realizados");
	register_concmd("ttt_items", "concmd_Items", ADMIN_FLAG, "ver los ítems comprados");
	register_concmd("ttt_quit", "concmd_Quit", ADMIN_FLAG, "ver los daños del que kiteo");
	register_concmd("ttt_conflict", "concmd_Conflict", ADMIN_FLAG, "ver los daños que se realizaron entre 2 jugadores");

	g_iUserMessages[MSG_DEATHMSG] = get_user_msgid("DeathMsg");
	g_iUserMessages[MSG_SCOREATTRIB] = get_user_msgid("ScoreAttrib");
	g_iUserMessages[MSG_SCREENFADE] = get_user_msgid("ScreenFade");
	g_iUserMessages[MSG_TUTORTEXT] = get_user_msgid("TutorText");
	g_iUserMessages[MSG_TUTORCLOSE] = get_user_msgid("TutorClose");
	g_iUserMessages[MSG_TEAMINFO] = get_user_msgid("TeamInfo");
	g_iUserMessages[MSG_SCOREINFO] = get_user_msgid("ScoreInfo");
	g_iUserMessages[MSG_STATUSTEXT] = get_user_msgid("StatusText");

	new iEnt = create_entity("info_target");
	if(is_valid_ent(iEnt)){
		SetThink(iEnt, "HudEnt");
		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
	}

	iEnt = create_entity("hostage_entity");
	if(is_valid_ent(iEnt))
	{
		entity_set_origin(iEnt, Float:{8192.0,8192.0,8192.0});
		dllfunc(DLLFunc_Spawn, iEnt);
	}

	g_SyncHud[SYNCHUD_PRINCIPAL] = CreateHudSyncObj();
	g_SyncHud[SYNCHUD_STATUSVALUE] = CreateHudSyncObj();

	new i;
	for(i = 0; i < sizeof(g_szBlockSet); i++) set_msg_block(get_user_msgid(g_szBlockSet[i]), BLOCK_SET);

	for(i = 0; i <= charsmax(g_szMessageBlock); i++) register_message(get_user_msgid(g_szMessageBlock[i]), "Block_Messages");

	oldmenu_register();

	g_aMurders = ArrayCreate(ArrayMurdersData);
	g_aRoundStatus = ArrayCreate(ArrayStatusRoundData);
	g_aPreviusRoundStatus = ArrayCreate(ArrayStatusRoundData);
	g_aPreviusRoundDamage = ArrayCreate(ArrayDamageData);
	g_aRoundDamage = ArrayCreate(ArrayDamageData);
	g_tSlayData = TrieCreate();
	g_tDisconnectData = TrieCreate();

	MySQLx_Init();

	// FIX Non-sprite set to glow by xPawn
	new szModel[2], iEntity = get_maxplayers(), iMaxEntities = get_global_int(GL_maxEntities);
	
	while( ++iEntity <= iMaxEntities ) {
		if( is_valid_ent( iEntity ) && entity_get_int( iEntity, EV_INT_rendermode ) == kRenderGlow ) {
			entity_get_string( iEntity, EV_SZ_model, szModel, 1 );
			
			if( szModel[ 0 ] == '*' )
				entity_set_int( iEntity, EV_INT_rendermode, kRenderNormal );
		}
	}
	
	register_dictionary("ttt_main.txt");
}

public plugin_precache(){
	new i;

	g_iTraitorSpr = precache_model(szSpriteTraitor);
	g_iDetectiveSpr = precache_model(szSpriteDetective);
	g_iCallSprite = precache_model(szDnaCallSprite);

	for(i = 0; i < sizeof(szTutorPrecache); i++) precache_generic(szTutorPrecache[i]);
	for(i = 0; i < sizeof(szCrowbarModels); i++) precache_model(szCrowbarModels[i]);

	precache_model(fmt("models/player/%s/%s.mdl", szPlayerModel, szPlayerModel));
	precache_sound(szTutorSound);
	precache_sound(szTraitorsWinSound);
	precache_sound(szInnocentsWinSound);
	precache_sound(szSoundGetAchievemment);

	for(i = 0; i < sizeof(szCountdownSounds); i++) precache_generic(szCountdownSounds[i]);
	for(i = 0; i < sizeof(g_szCrowbarSound); i++) precache_sound(g_szCrowbarSound[i]);
}

public plugin_cfg(){
	set_task(0.5, "EventRoundStart");

	new i;

	for(i = 0; i < sizeof(g_DataIntegerCvars); i++) set_cvar_num(g_DataIntegerCvars[i][INTEGER_CVAR_NAME], g_DataIntegerCvars[i][INTEGER_CVAR_VALUE]);
	for(i = 0; i < sizeof(g_DataStringCvars); i++) set_cvar_string(g_DataStringCvars[i][STRING_CVAR_NAME], g_DataStringCvars[i][STRING_CVAR_VALUE]);
}

public plugin_end(){
	if(g_hConnection != Empty_Handle) SQL_FreeHandle(g_hConnection);

	ArrayDestroy(g_aMurders); 
	ArrayDestroy(g_aPreviusRoundStatus); 
	ArrayDestroy(g_aRoundStatus); 
	ArrayDestroy(g_aPreviusRoundDamage); 
	ArrayDestroy(g_aRoundDamage);
}

public plugin_natives(){
	register_native("ttt_get_user_status", "GetUserStatus", 1);
	register_native("ttt_get_user_credits", "GetUserCredits", 1);
	register_native("ttt_set_user_credits", "SetUserCredits", 1);
	register_native("ttt_fix_user_freeshots", "FixUserFreeShots", 1);
	register_native("ttt_set_user_fake_name", "SetFakeName", 1);
	register_native("ttt_get_user_fake_name", "GetFakeName");
	register_native("ttt_update_statistic", "UpdateStatistics", 1);
	register_native("ttt_check_achievement_type", "CheckAchievementType", 1);
	register_native("ttt_update_user_points", "UpdatePoints", 1);

	register_native("ttt_is_round_end", "IsRoundEnd", 1);

	register_native("ttt_find_body", "FindDeadBody", 1);
	register_native("ttt_is_body_analized", "IsBodyAnalized", 1);
	register_native("ttt_get_body_killer", "GetBodyKiller", 1);
	register_native("ttt_get_body_name", "GetBodyName");
	register_native("ttt_get_body_time", "GetBodyTime", 1);
	register_native("ttt_update_body_weapon", "UpdateBodyWeapon", 1);

	register_native("ttt_set_karma_and_fs", "SetKarmaAndFs", 1);
	register_native("ttt_get_damage_by_karma", "GetDamageByKarma", 1);
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											NATIVES
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public GetUserStatus(const iId) return g_iPlayerStatus[iId];
public GetUserCredits(const iId) return g_iCredits[iId];
public SetUserCredits(const iId, const iAmount) g_iCredits[iId] = iAmount;
public FixUserFreeShots(const iAttacker) SetPlayerBit(g_bIgnoreFS, iAttacker);

public IsRoundEnd() return g_bRoundEnd ? true : false;

public FindDeadBody(const iId){
	new iEnt = IsAimingAt(iId, MAX_BODY_DIST, szDeadBodyClassName);

	return iEnt;
}
public IsBodyAnalized(const iOwner) return g_iDeadBodyEnt[iOwner][BODY_STATUS] == BODY_ANALIZED ? true : false;
public GetBodyKiller(const iOwner) return  g_iDeadBodyEnt[iOwner][BODY_KILLER] == DEATH_SUICIDE ? 0 : g_iDeadBodyEnt[iOwner][BODY_KILLER];
public Float:GetBodyTime(const iOwner) return g_iDeadBodyEnt[iOwner][BODY_SECONDS];
public UpdateBodyWeapon(const iOwner, const szWeapon[]){
	param_convert(2);
	copy(g_iDeadBodyEnt[iOwner][BODY_WEAPON], 15, szWeapon);
}

public GetBodyName(iPlugin, iParams){
	if(iParams != 3) return log_error(AMX_ERR_NATIVE, "Bad native parameters");

	new iOwner = get_param(1);

	if(!IsPlayer(iOwner)) return log_error(AMX_ERR_NATIVE, "Bad native id %d", iOwner);

	set_string(2, g_iDeadBodyEnt[iOwner][BODY_NAME], get_param(3));

	return 1;
}

public SetFakeName(const iId, const szName[]){
	param_convert(2);
	SetPlayerBit(g_bHaveFakeName, iId);
	copy(g_szPlayerFakeName[iId], charsmax(g_szPlayerFakeName[]), szName);
}

public GetFakeName(iPlugin, iParams){
	if(iParams != 3) return log_error(AMX_ERR_NATIVE, "Bad native parameters");

	new iId = get_param(1);

	if(!IsPlayer(iId)) return log_error(AMX_ERR_NATIVE, "Bad native id %d", iId);

	if(GetPlayerBit(g_bHaveFakeName, iId)){
		set_string(2, g_szPlayerFakeName[iId], get_param(3));
	}
	else{
		new szName2[32]; get_user_name(iId, szName2, charsmax(szName2));
		set_string(2, szName2, get_param(3));
	}

	return 1;
}

public UpdateStatistics(const iId, const iStatistics) g_iPlayerStatistics[iId][iStatistics]++;
public CheckAchievementType(const iId, const iType) UpdateAchievementProgress(iId, iType);

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											FORWARD HOOKS
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public fwdShowMenu_Pre( iId, iSlots, iDisplayTime, iNeedMore, szText[ ] )
{	
	if(containi(szText, "Team_Select") == -1) return HC_CONTINUE;

	if(is_user_bot(iId)) return HC_CONTINUE;
 	   
	SetHookChainReturn( ATYPE_INTEGER, 0 );
	return HC_BREAK;
}

public fwdShowVGUIMenu_Pre( iId, VGUIMenu:iMenuType, iSlots, szOldMenu[ ] )
{
	if( ( iMenuType != VGUI_Menu_Team ) && ( iMenuType != VGUI_Menu_Class_CT ) && ( iMenuType != VGUI_Menu_Class_T ) ) return HC_CONTINUE;
	
	if(is_user_bot(iId)) return HC_CONTINUE;

	SetHookChainReturn( ATYPE_INTEGER, 0 );
	return HC_BREAK;
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(iVictim == iAttacker || !GetPlayerBit(g_bIsAlive, iVictim) || !GetPlayerBit(g_bIsConnected, iAttacker)) return HC_CONTINUE;

	if(!g_bRoundStart || g_bRoundEnd){
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	fDamage = GetDamageByKarma(iAttacker, iVictim, fDamage);

	SetHookChainArg(4, ATYPE_FLOAT, fDamage);
	
	return HC_CONTINUE;
}

public fwdPlayerTakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(iVictim == iAttacker || !GetPlayerBit(g_bIsAlive, iVictim) || !GetPlayerBit(g_bIsConnected, iAttacker)) return HC_CONTINUE;

	SetKarmaAndFs(iAttacker, iVictim, fDamage);
	return HC_CONTINUE;
}

public fwdPlayerSpawn_Post(const iId)
{
	if(!is_user_alive(iId)) return;

	SetPlayerBit(g_bIsAlive, iId);

	remove_task(iId+TASK_SPAWN);

	new szReason[50]; get_user_name(iId, szName, charsmax(szName));
	if(TrieGetString(g_tSlayData, szName, szReason, charsmax(szReason))){
		user_kill(iId);

		TrieDeleteKey(g_tSlayData, szName);
		client_print_color(0, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "SLAY_MESSAGE", szName, szReason);
		ClearPlayerBit(g_bIsAlive, iId);

		message_begin(MSG_ALL, g_iUserMessages[MSG_TEAMINFO]);
		write_byte(iId);
		write_string("TERRORIST");
		message_end();

		FinishRound();
		return;
	}

	g_iKarma[iId][CURRENT_KARMA] = g_iKarma[iId][TEMP_KARMA];

	message_begin(MSG_ALL, g_iUserMessages[MSG_SCOREINFO]);
	write_byte(iId);
	write_short(g_iKarma[iId][CURRENT_KARMA]);
	write_short(get_user_deaths(iId));
	write_short(0);
	write_short(get_user_team(iId));
	message_end();

	rg_remove_all_items(iId);
	rg_give_item(iId, "weapon_knife");

	new iSecondaryWeapon = random_num(0, 4), iPrimaryWeapon = random_num(5, 12);
	
	rg_give_item(iId, g_szListWeapons[iSecondaryWeapon][WEAPON_ENT]);
	rg_set_user_bpammo(iId, g_szListWeapons[iSecondaryWeapon][WEAPON_CSW], g_szListWeapons[iSecondaryWeapon][WEAPON_AMMO]);
	
	rg_give_item(iId, g_szListWeapons[iPrimaryWeapon][WEAPON_ENT]);
	rg_set_user_bpammo(iId, g_szListWeapons[iPrimaryWeapon][WEAPON_CSW], g_szListWeapons[iPrimaryWeapon][WEAPON_AMMO]);

	set_entvar(iId, var_viewmodel, szCrowbarModels[CROWBAR_V_MODEL]);
	set_entvar(iId, var_weaponmodel, szCrowbarModels[CROWBAR_P_MODEL]);

	// FIX
	if(!g_bRoundEnd && g_bRoundStart){
		g_iPlayerStatus[iId] = STATUS_INNOCENT;
		FixTeamInfo(iId); 
	}

	static szCurrentModel[32], bool:bAlreadyHasModel; bAlreadyHasModel = false;
	get_entvar(iId, var_model, szCurrentModel, charsmax(szCurrentModel));

	if(equal(szCurrentModel, szPlayerModel)) bAlreadyHasModel = true;

	if(!bAlreadyHasModel) rg_set_user_model(iId, szPlayerModel);
}

public fwdPlayerKilled_Pre(const iVictim, const iAttacker, const iGib){
	if(!GetPlayerBit(g_bIsConnected, iVictim)) return;

	ClearPlayerBit(g_bIsAlive, iVictim);
	ClearPlayerBit(g_bIsSpecialTalking, iVictim);

	CheckTraitorsRewards();
	
	g_iPlayerStatistics[iVictim][DEATHS_COUNT]++;

	if(GetPlayerBit(g_bIsConnected, iAttacker)){
		if(iVictim == iAttacker){
			copy(g_iDeadBodyEnt[iVictim][BODY_WEAPON], 15, "Suicidio");
			g_iDeadBodyEnt[iVictim][BODY_KILLER] = DEATH_SUICIDE;
			return;
		}

		///////////////////// VICTIMA /////////////////////
		get_user_name(iVictim, szName, 31);
		
		if(g_iPlayerStatus[iAttacker] == STATUS_TRAITOR) 
			client_print_color(iAttacker, iAttacker, "%s %L", szModPrefix, LANG_PLAYER, "ATTACKER_KILL", szName, szPlayerStatus[g_iPlayerStatus[iVictim]]);

		new iData[ArrayMurdersData];
		iData[iMurderAttacker] = iAttacker; iData[iMuerderVictimStatus] = g_iPlayerStatus[iVictim];
		copy(iData[szMurderVictimName], 31, szName);

		///////////////////// END /////////////////////

		get_user_name(iAttacker, szName, 31);
		client_print_color(iVictim, iVictim, "%s %L", szModPrefix, LANG_PLAYER, "VICTIM_DEATH", szName, szPlayerStatus[g_iPlayerStatus[iAttacker]]);

		iData[iMurderAttackerStatus] = g_iPlayerStatus[iAttacker]; copy(iData[iMurderAttackerName], 31, szName);
		ArrayPushArray(g_aMurders, iData);
	}
	else
		return;

	g_iDeadBodyEnt[iVictim][BODY_KILLER] = iAttacker;

	new iKarmaMlp = KARMA_KILL_MULTIPLIER * (g_iKarma[iVictim][TEMP_KARMA] / 1000);
	new iModifier = (3 * (MAX_PLAYERS-1) - (GetConnectedUsers()-1)) / (MAX_PLAYERS-1);

	if(g_iPlayerStatus[iAttacker] < STATUS_TRAITOR && g_iPlayerStatus[iVictim] < STATUS_TRAITOR){
		UpdateKarma(iAttacker, float(iKarmaMlp*iModifier), false);
		
		if(g_iPlayerStatus[iVictim] == STATUS_DETECTIVE) UpdateTeamKills(iAttacker, 1);
		else UpdateTeamKills(iAttacker, 0);

		g_iPlayerStatistics[iAttacker][KILLS_INCORRECT]++;
		UpdateAchievementProgress(iAttacker, Achievement_type_incorrect);
		UpdatePoints(iAttacker, -100);
	}
	else if(g_iPlayerStatus[iAttacker] == STATUS_TRAITOR && g_iPlayerStatus[iVictim] == STATUS_TRAITOR){
		UpdateKarma(iAttacker, float(iKarmaMlp*iModifier), false);
		UpdateTeamKills(iAttacker, 1);

		g_iPlayerStatistics[iAttacker][KILLS_INCORRECT]++;
		UpdateAchievementProgress(iAttacker, Achievement_type_incorrect);
		UpdatePoints(iAttacker, -100);
	}
	else{
		UpdateKarma(iAttacker, float(iKarmaMlp/iModifier), true);

		if(g_iPlayerStatus[iAttacker] == STATUS_TRAITOR && g_iPlayerStatus[iVictim] == STATUS_DETECTIVE) 
			g_iCredits[iAttacker] += CREDITS_BY_KILLING_DETECTIVE;

		if(g_iPlayerStatus[iAttacker] == STATUS_DETECTIVE && g_iPlayerStatus[iVictim] == STATUS_TRAITOR) 
			g_iCredits[iAttacker] += CREDITS_BY_KILLING_TRAITOR;

		g_iPlayerStatistics[iAttacker][KILLS_CORRECT]++;
		UpdateAchievementProgress(iAttacker, Achievement_type_correct);

		UpdatePoints(iAttacker, g_iPlayerStatus[iAttacker] == STATUS_INNOCENT ? 150 : 100);
	}

	UpdateKillStatistics(iAttacker, iVictim);
}

public fwdPlayerKilled_Post(const iVictim, const iAttacker, const iGib){
	if(GetPlayerBit(g_bIsConnected, iVictim)){
		SetScoreAttrib(iVictim, 0);
		UpdateScoreAttribToVictim(iVictim);
	}

	FinishRound();
}

public fwdAddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	// !IsPlayer(host) Siempre va a ser un player.
	if(!get_orig_retval()) return FMRES_IGNORED;

	if(g_iPlayerStatus[host] == STATUS_DETECTIVE && entity_get_int(ent, EV_INT_impulse) == IMPULSE_REPORTED){
		static Float:vOrigin[3]; entity_get_vector(ent, EV_VEC_origin, vOrigin);
		ShowGlobalSprite(host, vOrigin, g_iCallSprite, 35.0);
	}
	
	if(!player || host == ent || !GetPlayerBit(g_bIsAlive, ent)) return FMRES_IGNORED;

	if(g_iPlayerStatus[ent] != STATUS_TRAITOR || g_iPlayerStatus[host] != STATUS_TRAITOR) return FMRES_IGNORED;
    
	set_es(es, ES_RenderFx, kRenderFxGlowShell);
	set_es(es, ES_RenderColor, {255, 50, 0});
	set_es(es, ES_RenderAmt, 30);

	return FMRES_IGNORED;
}

public fwdEmitSound_Pre(const iId, const iChannel, const szSample[])
{
	if(!GetPlayerBit(g_bIsAlive, iId)) return FMRES_IGNORED;

	if(szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i' && !ttt_is_holding_knife(iId)){
		switch(szSample[17])
		{
			case('b'): emit_sound(iId, CHAN_WEAPON, g_szCrowbarSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case('w'): emit_sound(iId, CHAN_WEAPON, g_szCrowbarSound[1], 1.0, ATTN_NORM, 0, PITCH_LOW);
			case('s'): emit_sound(iId, CHAN_WEAPON, g_szCrowbarSound[3], 1.0, ATTN_NORM, 0, PITCH_NORM);
			case('1', '2'): emit_sound(iId, CHAN_WEAPON, g_szCrowbarSound[2], random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
		}

		return FMRES_SUPERCEDE;
	}

	if(g_bRoundEnd) return FMRES_IGNORED;

	if(g_fWaitTime[iId] < get_gametime() && equal(szSample, "common/wpn_denyselect.wav"))
	{	
		new iEnt = IsAimingAt(iId, MAX_BODY_DIST, szDeadBodyClassName);

		if(iEnt > 0){
			new iOwner = entity_get_edict(iEnt, EV_ENT_owner);

			if(g_iDeadBodyEnt[iOwner][BODY_STATUS] == BODY_ANALIZED) ShowMenuBodyInfo(iId, iOwner);
			else if(g_iPlayerStatus[iId] == STATUS_DETECTIVE) AnalizeBody(iId, iOwner, iEnt);
			else ShowMenuBody(iId);
		}

		g_fWaitTime[iId] = get_gametime() + 1.0;
	}

	return FMRES_IGNORED;
}

public fwdPlayerSetUserInfoName_Post(const iId, infobuffer[], szNewName[]) UpdateName(iId, szNewName);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!GetPlayerBit(g_bIsConnected, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szCrowbarModels[CROWBAR_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szCrowbarModels[CROWBAR_P_MODEL]);
}

public fwdTraceAttack_Pre(const iVictim, const iAttacker, const Float:fDamage, const Float:fDirection[3], const iTracehandle, const iDamage_type)
{
	if(iVictim == iAttacker || !GetPlayerBit(g_bIsConnected, iAttacker)) return HAM_IGNORED;

	if(!g_bRoundStart || g_bRoundEnd) return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public Forward_SetClientListening_pre(const iReceiver, const iSender, bool:bListen)
{
	if(!GetPlayerBit(g_bIsConnected, iReceiver) || !GetPlayerBit(g_bIsConnected, iSender) || iSender == iReceiver) return FMRES_SUPERCEDE;

	if(get_speak(iSender) == SPEAK_MUTED)
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
		return FMRES_SUPERCEDE;
	}

	switch(GetPlayerBit(g_bIsAlive, iSender))
	{
		case 1: // ALIVE
		{
			if(GetPlayerBit(g_bIsAlive, iReceiver))
			{
				if(GetPlayerBit(g_bIsSpecialTalking, iSender))
				{
					if(g_iPlayerStatus[iSender] == g_iPlayerStatus[iReceiver])
						bListen = true;
					else bListen = false;
				}
				else bListen = true;
			}
			else bListen = true;
		}
		case 0: 
		{
			if(GetPlayerBit(g_bIsAlive, iReceiver)) bListen = false; 
			else bListen = true;
		}
	}
	
	engfunc(EngFunc_SetClientListening, iReceiver, iSender, bListen);
	return FMRES_SUPERCEDE;
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											EVENTOS
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public EventShowStatus(const iId){
	if (!GetPlayerBit(g_bIsConnected, iId))
		return;

	message_begin(MSG_ONE, g_iUserMessages[MSG_STATUSTEXT], _, iId);
	write_byte(0);
	write_string("");
	message_end();
	
	static iTarget; iTarget = read_data(2);

	if (!GetPlayerBit(g_bIsAlive, iTarget)) 
		return;

	new szName[32];

	if (GetPlayerBit(g_bHaveFakeName, iTarget)) 
		copy(szName, charsmax(szName), g_szPlayerFakeName[iTarget]);
	else 
		get_user_name(iTarget, szName, charsmax(szName));

	if (g_iPlayerStatus[iId] == STATUS_TRAITOR) {
		set_hudmessage(0, 50, 255, -1.0, 0.6, 1, 0.01, 3.0, 0.01, 0.01, -1);
		ShowSyncHudMsg(iId, g_SyncHud[SYNCHUD_STATUSVALUE], "[%s] %s [KARMA = %d]", 
		szPlayerStatus[g_iPlayerStatus[iTarget]], szName, g_iKarma[iTarget][CURRENT_KARMA]);

		if(g_iPlayerStatus[iTarget] == STATUS_TRAITOR) ShowSprite(iId, iTarget, STATUS_TRAITOR);
		else if(g_iPlayerStatus[iTarget] == STATUS_DETECTIVE) ShowSprite(iId, iTarget, STATUS_DETECTIVE);
	}
	else {
		if(g_iPlayerStatus[iTarget] == STATUS_DETECTIVE) {
			set_hudmessage(0, 50, 255, -1.0, 0.6, 1, 0.01, 3.0, 0.01, 0.01, -1);
			ShowSyncHudMsg(iId, g_SyncHud[SYNCHUD_STATUSVALUE], "[%L] %s [KARMA = %d]", 
			LANG_PLAYER, "ROL_DETECTIVE",
			szName, g_iKarma[iTarget][CURRENT_KARMA]);

			ShowSprite(iId, iTarget, STATUS_DETECTIVE);
		}
		else{
			set_hudmessage(0, 50, 255, -1.0, 0.6, 1, 0.01, 3.0, 0.01, 0.01, -1);
			ShowSyncHudMsg(iId, g_SyncHud[SYNCHUD_STATUSVALUE], "[%L] %s [KARMA = %d]",
			LANG_PLAYER, "ROL_INNOCENT",
			szName, g_iKarma[iTarget][CURRENT_KARMA]);
		}
	}
}

public EventHideStatus(const iId) ClearSyncHud(iId, g_SyncHud[SYNCHUD_STATUSVALUE]);

public EventDeathMsg(){
	new iAttacker = read_data(1); 
	new iVictim = read_data(2);
	new szWeapon[16]; read_data(4, szWeapon, charsmax(szWeapon));

	copy(g_iDeadBodyEnt[iVictim][BODY_WEAPON], 15, szWeapon);

	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(!GetPlayerBit(g_bIsConnected, i)) continue;

		if(i == iVictim || g_iPlayerStatus[i] == STATUS_TRAITOR || !GetPlayerBit(g_bIsAlive, i)){
			message_begin(MSG_ONE_UNRELIABLE, g_iUserMessages[MSG_DEATHMSG], _, i);
			write_byte(iAttacker);
			write_byte(iVictim);
			write_byte(read_data(3));
			write_string(szWeapon);
			message_end();
		}
	}
}

public EventClCorpse()
{
	if(g_bRoundEnd) return;

	new iId = read_data(12);

	if(!GetPlayerBit(g_bIsConnected, iId)) return;

	new szModel[32]; read_data(1, szModel, charsmax(szModel));

	new Float:fOrigin[3]; fOrigin[0] = read_data(2)/128.0; fOrigin[1] = read_data(3)/128.0; fOrigin[2] = read_data(4)/128.0;
	new iSeq = read_data(9);

	CreateBody(iId, fOrigin, szModel, iSeq);
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											MESSAGES
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public message_Scenario()
{
	if(get_msg_args() > 1)
	{
		static szSprite[8]; get_msg_arg_string(2, szSprite, charsmax(szSprite));
		
		if(equal(szSprite, "hostage"))  return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public message_TextMsg()
{
	static szText[22]; get_msg_arg_string(2, szText, charsmax(szText));
	
	if(equal(szText, "#Killed_Teammate") || equal(szText, "#Hostages_Not_Rescued") || equal(szText, "#Round_Draw") || equal(szText, "#Game_teammate_attack") || equal(szText, "#Terrorists_Win") || equal(szText, "#CTs_Win"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public message_HostagePos() return PLUGIN_HANDLED;

public message_Health(msg_id, msg_dest, msg_entity)
{
	static health; health = get_msg_arg_int(1); //g_iHealth[msg_entity] = get_user_health(msg_entity);

	if (health < 256) return;
	
	// get_user_health(msg_entity) reemplazarlo por g_iHealth si lo activo
	if (health % 256 == 0) set_entvar(msg_entity, var_health, float(get_user_health(msg_entity)+1));
	
	set_msg_arg_int(1, get_msg_argtype(1), 255);
}

public Block_Messages(msgid, dest, id)
{
	if(get_msg_args() > 1)
	{
		static message[128];
		if(get_msg_args() == 5)
			get_msg_arg_string(5, message, charsmax(message));

		if(equal(message, "#Fire_in_the_hole"))
			return PLUGIN_HANDLED;

		get_msg_arg_string(2, message, charsmax(message));
		if(equal(message, "%!MRAD_BOMBPL") || equal(message, "%!MRAD_BOMBDEF") || equal(message, "%!MRAD_terwin") || equal(message, "%!MRAD_ctwin") || equal(message, "%!MRAD_FIREINHOLE"))
			return PLUGIN_HANDLED;

		if(equal(message, "#Killed_Teammate") || equal(message, "#Game_teammate_kills") || equal(message, "#Game_teammate_attack") || equal(message, "#C4_Plant_At_Bomb_Spot"))
			return PLUGIN_HANDLED;

		if(equal(message, "#Bomb_Planted") || equal(message, "#Game_bomb_drop") || equal(message, "#Game_bomb_pickup") || equal(message, "#Got_bomb") || equal(message, "#C4_Plant_Must_Be_On_Ground"))
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											FUNCIONES DEL CLIENTE
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public client_putinserver(iId){
	client_cmd(iId, "_cl_autowepswitch 0");
	SetPlayerBit(g_bIsConnected, iId);

	g_iKarma[iId][TEMP_KARMA] = g_iKarma[iId][CURRENT_KARMA] = STARTING_KARMA;

	LoadData(iId);
}

public client_disconnected(iId){
	if (GetPlayerBit(g_bIsConnected, iId)) {
		get_user_name(iId, szName, charsmax(szName));

		if (GetPlayerBit(g_bIsLogged, iId) ){
			SaveData(iId);
			ClearPlayerBit(g_bIsLogged, iId);
		}

		client_print_color(0, print_team_default, "%s %L", 
		szModPrefix, LANG_PLAYER, GetPlayerBit(g_bIsAlive, iId) ? "DISCONNECT_ALIVE_STATUS": "DISCONNECT_DEATH_STATUS", 
		szName, szPlayerStatus[g_iPlayerStatus[iId]]);

		if(g_iPlayerStatus[iId] != STATUS_NONE)
			TrieSetString(g_tDisconnectData, szName, szPlayerStatus[g_iPlayerStatus[iId]]);

		ResetVars(iId);
		ClearPlayerBit(g_bIsConnected, iId);

		FinishRound();
	}
}

ResetVars(const iId){
	ClearPlayerBit(g_bIsAlive, iId);
	ClearPlayerBit(g_bMuteCountDown, iId);
	ClearPlayerBit(g_bHideMotd, iId);
	ClearPlayerBit(g_bHaveFakeName, iId);
	ClearPlayerBit(g_bHaveMaxKarma, iId);
	ClearPlayerBit(g_bIgnoreFS, iId);
	ClearPlayerBit(g_bIsSpecialTalking, iId);

	remove_task(iId+TASK_TUTOR);
	remove_task(iId+TASK_SPAWN);

	g_iPlayerStatus[iId] = STATUS_NONE;
	g_iFreeShots[iId] = 0;
	//g_iHealth[iId] = 0;
	g_szPlayerFakeName[iId][0] = EOS;

	new i;

	for(i = 0; i < TEAM_KILLS; i++) g_iTeamKills[iId][i] = 0;
	for(i = 0; i < AchievementsList; i++) g_iPlayerAchievements[iId][i] = false;
	for(i = 0; i < Statistics_List; i++) g_iPlayerStatistics[iId][i] = 0;
}

SetPlayerClass(const iId, const iClass){
	get_user_name(iId, szName, 31);

	switch(iClass){
		case STATUS_DETECTIVE:{
			rg_set_user_rendering(iId, kRenderFxGlowShell, {0.0, 50.0, 255.0}, kRenderNormal, 30.0);
			g_iCredits[iId] = DETECTIVE_STARTING_CREDITS;
			g_iPlayerStatistics[iId][DETECTIVE_ROUNDS]++;

			format(g_szDetectivesNames, charsmax(g_szDetectivesNames), "%s %s-", g_szDetectivesNames, szName);
		}
		case STATUS_TRAITOR:{
			rg_set_user_rendering(iId);
			g_iCredits[iId] = TRAITOR_STARTING_CREDITS;
			g_iPlayerStatistics[iId][TRAITOR_ROUNDS]++; UpdateAchievementProgress(iId, Achievement_type_traitor);

			format(g_szTraitorsNames, charsmax(g_szTraitorsNames), "%s %s-", g_szTraitorsNames, szName);
		}
		case STATUS_INNOCENT:{
			rg_set_user_rendering(iId);
			g_iPlayerStatistics[iId][INNOCENT_ROUNDS]++;
		}
	}

	rg_set_user_armor(iId, 0, ARMOR_NONE);

	client_print_color(iId, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "YOUR_ROUND_CLASS", szPlayerStatus[iClass]);
	SetScreenFadeByClass(iId, iClass);

	new iData[ArrayStatusRoundData];
	iData[PlayerRoundStatus] = iClass; copy(iData[PlayerRoundName], 31, szName);
	ArrayPushArray(g_aRoundStatus, iData);

	g_iPlayerStatus[iId] = iClass;
	g_iPlayerStatistics[iId][ROUNDS_PLAYED]++;
	UpdatePoints(iId, 10);
}

AnalizeBody(const iId, const iOwner, const iEnt){
	if(is_nullent(iEnt)) return;

	g_iDeadBodyEnt[iOwner][BODY_STATUS] = BODY_ANALIZED;
	entity_set_int(iEnt, EV_INT_impulse, 0);
	rg_set_user_rendering(iEnt, kRenderFxGlowShell, g_fBodyColors[g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]], kRenderNormal, 30.0);
	
	get_user_name(iId, szName, charsmax(szName));
	client_print_color(iId, print_team_default, "%s %L",
	szModPrefix, LANG_PLAYER, "ANALIZE_BODY_RESULT",
	szName, g_iDeadBodyEnt[iOwner][BODY_NAME], szPlayerStatus[g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]]);

	switch(g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]){
		case STATUS_DETECTIVE:{
			MakeTutor(0, TUTOR_BLUE, 3.0, "%L", LANG_PLAYER, "TUTOR_ANALIZE_BODY", szName, g_iDeadBodyEnt[iOwner][BODY_NAME], szPlayerStatus[g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]]);
		}
		case STATUS_INNOCENT:{
			MakeTutor(0, TUTOR_GREEN, 3.0, "%L", LANG_PLAYER, "TUTOR_ANALIZE_BODY", szName, g_iDeadBodyEnt[iOwner][BODY_NAME], szPlayerStatus[g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]]);
		}
		case STATUS_TRAITOR:{
			MakeTutor(0, TUTOR_RED, 3.0, "%L", LANG_PLAYER, "TUTOR_ANALIZE_BODY", szName, g_iDeadBodyEnt[iOwner][BODY_NAME], szPlayerStatus[g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS]]);
		}
	}

	if(g_iDeadBodyEnt[iOwner][BODY_OWNER_STATUS] == STATUS_TRAITOR){
		g_iCredits[iId] += CREDITS_BY_IDENTIEING_TRAITOR;
		UpdateKarma(iId, KARMA_BY_IDENTIEING_TRAITOR, true);
	}

	if(GetPlayerBit(g_bIsConnected, iOwner)) SetScoreAttrib(iOwner, 1);

	ShowMenuBodyInfo(iId, iOwner);
}

UpdateKarma(const iId, Float:fCount, bool:Add){
	if(fCount < 1) fCount = 1.0;

	new iCount = floatround(fCount);

	if(Add){
		if((g_iKarma[iId][TEMP_KARMA] + iCount) >= KARMA_LIMIT){
			g_iKarma[iId][TEMP_KARMA] = KARMA_LIMIT;

			if(!GetPlayerBit(g_bHaveMaxKarma, iId)){
				g_iPlayerStatistics[iId][MAX_KARMA_COUNT]++;
				SetPlayerBit(g_bHaveMaxKarma, iId);
			}
		}
		else g_iKarma[iId][TEMP_KARMA] += iCount;
	}
	else{
		if((g_iKarma[iId][TEMP_KARMA] - iCount) < 0) {
			server_cmd("kick #%i ^"Negative karma^"", get_user_userid(iId));
		}
		else g_iKarma[iId][TEMP_KARMA] -= iCount;
	}
}

UpdateFreeShots(const iId){
	g_iFreeShots[iId]++;

	if (g_iFreeShots[iId] >= FS_LIMIT) {
		get_user_name(iId, szName, 31);
		if(!TrieKeyExists(g_tSlayData, szName)) {
			new szReason[64]; 
			format(szReason, charsmax(szReason), "%L", LANG_SERVER, "FS_REASON", szName);
			TrieSetString(g_tSlayData, szName, szReason);
		}
	}
}

UpdateTeamKills(const iId, const iTeam){
	if(iTeam) g_iTeamKills[iId][TEAM_TEAMMATES_KILLED]++;
	
	g_iTeamKills[iId][TEAM_KILLS_COUNT]++;
	
	new szAddress[32]; get_user_ip(iId, szAddress, charsmax(szAddress), 1);

	if(g_iTeamKills[iId][TEAM_TEAMMATES_KILLED] >= TEAMMATES_KILLS_LIMIT)
		server_cmd("kick #%d ^"Incorrect killing^";wait;addip ^"%d^" ^"%s^";wait;writeip", get_user_userid(iId), BAN_TIME, szAddress);
	else if(g_iTeamKills[iId][TEAM_KILLS_COUNT] >= TEAM_KILLS_INNOCENT_LIMIT)
		server_cmd("kick #%d ^"Incorrect killing^";wait;addip ^"%d^" ^"%s^";wait;writeip", get_user_userid(iId), BAN_TIME, szAddress);
	/*
	new szName[32]; get_user_name(iId, szName, charsmax(szName));

	if(g_iTeamKills[iId][TEAM_TEAMMATES_KILLED] >= TEAMMATES_KILLS_LIMIT)
		server_cmd("amx_banip ^"%s^" ^"%d^" ^"Matar incorrectamente^"", szName, BAN_TIME);
	else if(g_iTeamKills[iId][TEAM_KILLS_COUNT] >= TEAM_KILLS_INNOCENT_LIMIT)
		server_cmd("amx_banip ^"%s^" ^"%d^" ^"Matar incorrectamente^"", szName, BAN_TIME);
	*/
}

public Float:GetDamageByKarma(const iAttacker, const iVictim, Float:fDamage){
	/* ANTES
	if(fDamage > 0.1)
	{
		new Float:fModifier = (g_iKarma[iAttacker][CURRENT_KARMA] - g_iKarma[iVictim][CURRENT_KARMA]) / 1000.0;

		fDamage += (fDamage *= fModifier);

		if(fDamage < 1.0) fDamage = 1.0;
	}*/
	
	if(fDamage > 0.1 && (fDamage / 3.0) > 0.1)
	{
		fDamage /= 3.0;

		new Float:fModifier = (g_iKarma[iAttacker][CURRENT_KARMA] - g_iKarma[iVictim][CURRENT_KARMA]) / 1000.0;

		fDamage += (fDamage *= fModifier);

		if(fDamage < 1.0) fDamage = 1.0;
	}

	return fDamage;
}

public SetKarmaAndFs(const iAttacker, const iVictim, const Float:fDamage){
	if(g_iPlayerStatus[iAttacker] < STATUS_TRAITOR && g_iPlayerStatus[iVictim] < STATUS_TRAITOR){
		g_iPlayerStatistics[iAttacker][DAMAGE_INCORRECT] += floatround(fDamage);
		UpdateKarma(iAttacker, fDamage * KARMA_DAMAGE_MULTIPLIER, false);
		
		if(!GetPlayerBit(g_bIgnoreFS, iAttacker)) UpdateFreeShots(iAttacker);
	}
	else if(g_iPlayerStatus[iAttacker] == STATUS_TRAITOR && g_iPlayerStatus[iVictim] == STATUS_TRAITOR){
		g_iPlayerStatistics[iAttacker][DAMAGE_INCORRECT] += floatround(fDamage);
		UpdateKarma(iAttacker, fDamage * KARMA_DAMAGE_MULTIPLIER, false);
		if(!GetPlayerBit(g_bIgnoreFS, iAttacker)) UpdateFreeShots(iAttacker);
	}
	else{
		g_iPlayerStatistics[iAttacker][DAMAGE_CORRECT] += floatround(fDamage);
		UpdateKarma(iAttacker, fDamage * KARMA_DAMAGE_MULTIPLIER, true);
	}

	ClearPlayerBit(g_bIgnoreFS, iAttacker);
	StoreDamage(iAttacker, iVictim, fDamage);
}

StoreDamage(const iAttacker, const iVictim, const Float:fDamage){
	new iData[ArrayDamageData];
	get_user_name(iAttacker, szName, 31); copy(iData[szDamageAttackerName], 31, szName);
	get_user_name(iVictim, szName, 31); copy(iData[szDamageVictimName], 31, szName);
	iData[iDamageAttackerStatus] = g_iPlayerStatus[iAttacker]; iData[iDamageVictimStatus] = g_iPlayerStatus[iVictim];
	iData[fDamageCount] = fDamage;
	ArrayPushArray(g_aRoundDamage, iData);
}

UpdateKillStatistics(const iAttacker, const iVictim){
	switch(g_iPlayerStatus[iVictim]){
		case STATUS_INNOCENT: g_iPlayerStatistics[iAttacker][INNOCENTS_KILLED]++;
		case STATUS_TRAITOR: g_iPlayerStatistics[iAttacker][TRAITORS_KILLED]++;
		case STATUS_DETECTIVE: g_iPlayerStatistics[iAttacker][DETECTIVES_KILLED]++;
	}

	g_iPlayerStatistics[iAttacker][KILLS_COUNT]++;
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											CLIENT COMMANDS
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public clcmd_radio(const iId) return PLUGIN_HANDLED;

public clcmd_changeteam(const iId)
{
	if (is_user_bot(iId)) 
		return PLUGIN_CONTINUE;

	if (!GetPlayerBit(g_bIsConnected, iId) || !GetPlayerBit(g_bIsLogged, iId)) 
		return PLUGIN_HANDLED;

	new TeamName:iTeam = get_member(iId, m_iTeam);	
	if(iTeam == TEAM_UNASSIGNED || iTeam == TEAM_SPECTATOR) 
		return PLUGIN_CONTINUE;
	
	ShowMainMenu(iId);
	client_cmd(iId, "spk ^"%s^"", szMainMenuOpenSound);
	return PLUGIN_HANDLED;
}

public clcmd_sayTeam(const iId)
{
	if (!GetPlayerBit(g_bIsConnected, iId)) 
		return PLUGIN_HANDLED;

	if (g_iPlayerStatus[iId] == STATUS_NONE || g_iPlayerStatus[iId] == STATUS_INNOCENT) 
		return PLUGIN_HANDLED;

	static szSay[192]; 
	read_args(szSay, charsmax(szSay)); 
	remove_quotes(szSay);

	if (!ValidMessage(szSay)) 
		return PLUGIN_HANDLED;

	get_user_name(iId, szName, charsmax(szName));
	
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (GetPlayerBit(g_bIsAlive, i) && g_iPlayerStatus[i] == g_iPlayerStatus[iId])
			client_print_color(i, iId, "^4[%L]^3 %s^1: %s", LANG_PLAYER, g_iPlayerStatus[iId] == STATUS_DETECTIVE ? "TEAM_DETECTIVES" : "TEAM_TRAITORS", szName, szSay);
	}

	return PLUGIN_HANDLED;
}

public SlayPlayer(const iId)
{
	new szReason[MAX_REASON_LENGTH]; 
	read_args(szReason, charsmax(szReason)); 
	remove_quotes(szReason); 
	trim(szReason);
	
	if (strlen(szReason) > MAX_REASON_LENGTH) {
		client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "REASON_TOO_LONG");
		return PLUGIN_HANDLED;
	}

	if (!ValidMessage(szReason)) {
		client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "REASON_INVALID");
		return PLUGIN_HANDLED;
	}

	if (TrieKeyExists(g_tSlayData, g_szPlayerTarget[iId])) {
		client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "ALREADY_SLAYED");
		return PLUGIN_HANDLED;
	}

	TrieSetString(g_tSlayData, g_szPlayerTarget[iId], szReason);
	get_user_name(iId, szName, MAX_NAME_LENGTH);
	log_to_file(SLAY_LOG_FILE, "%L", LANG_SERVER, "SLAY_PLAYER_LOG", szName, g_szPlayerTarget[iId], szReason);
	
	return PLUGIN_HANDLED;
}

public concmd_Shots(const iId, const iLevel, const cid)
{
	if ((get_user_flags(iId) & iLevel) != iLevel) 
		return PLUGIN_HANDLED;

	new iData[ArrayDamageData];
	for(new i; i < ArraySize(g_aPreviusRoundDamage); i++) {
		ArrayGetArray(g_aPreviusRoundDamage, i, iData);
		console_print(iId, "%s: %s -> %s: %s | %.2f Dmg^n", szPlayerStatus[iData[iDamageAttackerStatus]], iData[szDamageAttackerName], 
		szPlayerStatus[iData[iDamageVictimStatus]], iData[szDamageVictimName], iData[fDamageCount]);
	}

	return PLUGIN_HANDLED;
}

public concmd_Items(const iId, const iLevel, const cid)
{
	if ((get_user_flags(iId) & iLevel) != iLevel) 
		return PLUGIN_HANDLED;

	ttt_print_items_buyed(iId);
	return PLUGIN_HANDLED;
}

public concmd_Quit(const iId, const iLevel, const cid)
{
	if ((get_user_flags(iId) & iLevel) != iLevel) 
		return PLUGIN_HANDLED;

	new iData[ArrayDamageData], iTarget;
	for(new i; i < ArraySize(g_aRoundDamage); i++) {
		ArrayGetArray(g_aRoundDamage, i, iData);
		
		iTarget = cmd_target(iId, iData[szDamageAttackerName], CMDTARGET_ALLOW_SELF);
		
		if (!iTarget){
			console_print(iId, "%s: %s -> %s: %s | %.2f Dmg^n", szPlayerStatus[iData[iDamageAttackerStatus]], iData[szDamageAttackerName], 
			szPlayerStatus[iData[iDamageVictimStatus]], iData[szDamageVictimName], iData[fDamageCount]);
		}
	}

	return PLUGIN_HANDLED;
}

public concmd_Conflict(const iId, const iLevel, const cid)
{
	if ((get_user_flags(iId) & iLevel) != iLevel) 
		return PLUGIN_HANDLED;

	if (read_argc() != 3) 
		return PLUGIN_HANDLED;

	new szName[2][MAX_NAME_LENGTH];
	read_argv(1, szName[0], MAX_NAME_LENGTH-1); 
	read_argv(2, szName[1], MAX_NAME_LENGTH-1);
	remove_quotes(szName[0]); 
	remove_quotes(szName[1]);

	log_amx("%s-%s", szName[0], szName[1]);

	new iData[ArrayDamageData], bool:bPlayerFind;
	for(new i; i < ArraySize(g_aPreviusRoundDamage); i++) {
		ArrayGetArray(g_aPreviusRoundDamage, i, iData);

		if (equal(szName[0], iData[szDamageAttackerName]) && equal(szName[1], iData[szDamageVictimName]) || equal(szName[1], iData[szDamageAttackerName]) && equal(szName[0], iData[szDamageVictimName]) ){
			bPlayerFind = true;
			console_print(iId, "%s: %s -> %s: %s | %.2f Dmg^n", szPlayerStatus[iData[iDamageAttackerStatus]], iData[szDamageAttackerName], 
			szPlayerStatus[iData[iDamageVictimStatus]], iData[szDamageVictimName], iData[fDamageCount]);
		}
	}

	if (!bPlayerFind)
		console_print(iId, "%s %L", szModPrefix, LANG_PLAYER, "CONFLICT_PLAYER_NOT_FOUND");

	return PLUGIN_HANDLED;
}

public clcmd_voiceon(const iId)
{
	if(g_iPlayerStatus[iId] == STATUS_TRAITOR)
	{
		client_cmd(iId, "+voicerecord");
		SetPlayerBit(g_bIsSpecialTalking, iId);
		VoiceCheck(iId, 0);
	}

	return PLUGIN_HANDLED;
}

public clcmd_voiceoff(const iId)
{
	if(g_iPlayerStatus[iId] == STATUS_TRAITOR)
	{
		client_cmd(iId, "-voicerecord");
		ClearPlayerBit(g_bIsSpecialTalking, iId);
		VoiceCheck(iId, 1);
	}

	return PLUGIN_HANDLED;
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											FUNCIONES DE RONDA
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public EventRoundStart()
{
	bForceRoundEnd = g_bRoundStart = g_bRoundEnd = false;
	g_iCountDown = 10; remove_task(TASK_ROUND);
	LaunchNextRound();

	set_member_game(m_bTCantBuy, false); set_member_game(m_bCTCantBuy, false);

	for (new i = 1; i <= MAX_PLAYERS; i++) 
		if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) 
			SaveData(i);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	if (!bForceRoundEnd) {
		for(new i = 1; i <= MAX_PLAYERS; i++) {
			if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) {
				if (g_iPlayerStatus[i] < STATUS_TRAITOR) {
					g_iPlayerStatistics[i][ROUNDS_WIN]++; UpdateAchievementProgress(i, Achievement_type_round);
				}

				ShowEndRoundMotd(i, STATUS_INNOCENT);
			}
		}
	}
	
	g_bRoundEnd = true;
	g_bRoundStart = false;

	remove_task(TASK_ROUND);
	remove_task(TASK_SURVIVAL);

	ResetVarsOnRoundEnd();
	RemoveDeadBodies();

	g_aPreviusRoundStatus = ArrayClone(g_aRoundStatus);
	ArrayClear(g_aRoundStatus);

	g_aPreviusRoundDamage = ArrayClone(g_aRoundDamage);
	ArrayClear(g_aRoundDamage);

	rg_balance_teams();
	rg_swap_all_players();
}

ResetVarsOnRoundEnd(){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		g_iPlayerStatus[i] = STATUS_NONE;
		g_iFreeShots[i] = 0;
		g_iCredits[i] = 0;
		ClearPlayerBit(g_bHaveFakeName, i);
		ClearPlayerBit(g_bIgnoreFS, i);
		ClearPlayerBit(g_bIsSpecialTalking, i);
	}

	ArrayClear(g_aMurders);
	TrieClear(g_tDisconnectData);
}

public LaunchNextRound(){
	if (g_bRoundEnd) {
		remove_task(TASK_ROUND);
		return;
	}

	if (g_iCountDown <= 5) {
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!GetPlayerBit(g_bMuteCountDown, i) && GetPlayerBit(g_bIsConnected, i)) 
				PlaySound(i, szCountdownSounds[g_iCountDown]);
		}
		
		set_dhudmessage(0, 255, 0, _, 0.2, 0, 1.0, 0.1, 0.1, 0.9);
		show_dhudmessage(0, "%L", LANG_PLAYER, "COUNTDOWN_HUD_MESSAGE", g_iCountDown);
	}

	if (--g_iCountDown < 0) {
		g_bPrintCannotStartRound = false;
		StartRound();
	}
	else {
		set_task(1.0, "LaunchNextRound", TASK_ROUND);
	}
}

public StartRound(){
	new iAlivePlayers = GetAlivePlayers();

	if (iAlivePlayers < TRAITORS_COUNT_PER_PLAYER) {
		if (!g_bPrintCannotStartRound) {
			client_print_color(0, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "CANNOT_START_ROUND", TRAITORS_COUNT_PER_PLAYER);
			log_amx("%L", LANG_SERVER, "CANNOT_START_ROUND", TRAITORS_COUNT_PER_PLAYER);
			g_bPrintCannotStartRound = true;
		}

		set_task(1.0, "StartRound", TASK_ROUND);
		return;
	}

	new iTraitors, iDetectives, iPlayerIndex; 

	new iMaxTraitors = iAlivePlayers / TRAITORS_COUNT_PER_PLAYER;
	new iMaxDetectives = iAlivePlayers / DETECTIVES_COUNT_PER_PLAYER;

	formatex(g_szTraitorsNames, charsmax(g_szTraitorsNames), "%L", LANG_SERVER, "TEAM_TRAITORS");
	while(iTraitors < iMaxTraitors)
	{
		iPlayerIndex = GetRandomAliveUser();
					
		if(g_iPlayerStatus[iPlayerIndex] == STATUS_TRAITOR) 
			continue;
		
		SetPlayerClass(iPlayerIndex, STATUS_TRAITOR);
		iTraitors++;
	}

	if (iMaxDetectives) {
		formatex(g_szDetectivesNames, charsmax(g_szDetectivesNames), "%L", LANG_SERVER, "TEAM_DETECTIVES");
		while(iDetectives < iMaxDetectives)
		{
			iPlayerIndex = GetRandomAliveUser();
					
			if(g_iPlayerStatus[iPlayerIndex] == STATUS_TRAITOR || g_iPlayerStatus[iPlayerIndex] == STATUS_DETECTIVE) 
				continue;
		
			SetPlayerClass(iPlayerIndex, STATUS_DETECTIVE);
			iDetectives++;
		}
	}

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!GetPlayerBit(g_bIsAlive, i)) 
			continue;

		if (g_iPlayerStatus[i] == STATUS_TRAITOR || g_iPlayerStatus[i] == STATUS_DETECTIVE) 
			continue;

		SetPlayerClass(i, STATUS_INNOCENT);
	}

	g_bRoundStart = true;

	ResetSurvivalCreditsTask();

	g_iKillBonusCredits = 0;

	UpdateTeamInfo();
}

ResetSurvivalCreditsTask()
{
	g_iSurvivalTaskRepeats = 0; 
	remove_task(TASK_SURVIVAL); 
	set_task(REWARDS_SURVIVAL_TIME, "GiveSurvivalCredits", TASK_SURVIVAL, _, _, "b");
}

FinishRound()
{
	if (g_bRoundEnd) 
		return;

	if (GetAliveTraitors() <= 0) {
		GetRoundKiller();
		
		for (new i = 1; i <= MAX_PLAYERS; i++){
			if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) {
				if (g_iPlayerStatus[i] < STATUS_TRAITOR) {
					g_iPlayerStatistics[i][ROUNDS_WIN]++;
					
					if(GetPlayerBit(g_bIsAlive, i)) g_iKarma[i][TEMP_KARMA] += 20;

					UpdateAchievementProgress(i, Achievement_type_round);
					ShowEndRoundMotd(i, STATUS_INNOCENT);
				}

				ShowEndRoundMotd(i, STATUS_INNOCENT);
			}
		}

		bForceRoundEnd = true;
		rg_round_end(7.0, WINSTATUS_CTS, ROUND_CTS_WIN, "", "", true);
	}
	else if (GetAliveInnocentsAndDetectives() <= 0) {
		GetRoundKiller();

		for (new i = 1; i <= MAX_PLAYERS; i++){
			if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) {
				if(g_iPlayerStatus[i] == STATUS_TRAITOR) {
					g_iPlayerStatistics[i][ROUNDS_WIN]++;
					g_iPlayerStatistics[i][TRAITOR_ROUNDS_WIN]++;
					
					if(GetPlayerBit(g_bIsAlive, i)) g_iKarma[i][TEMP_KARMA] += 20;

					UpdateAchievementProgress(i, Achievement_type_round);
					ShowEndRoundMotd(i, STATUS_TRAITOR);
				}

				ShowEndRoundMotd(i, STATUS_TRAITOR);
			}
		}

		bForceRoundEnd = true;
		rg_round_end(7.0, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "", "", true);
	}
}

GetRoundKiller()
{
	new iSize = ArraySize(g_aMurders);
	
	if(iSize <= 0){
		formatex(g_szKillerName, charsmax(g_szKillerName), "");
		return;
	}

	new iData[ArrayMurdersData], iKills[33], iKiller;

	for(new i; i < iSize; i++){
		ArrayGetArray(g_aMurders, i, iData);

		iKills[iData[iMurderAttacker]]++;

		if(iKills[iData[iMurderAttacker]] >= iKills[iKiller]){
			iKiller = iData[iMurderAttacker];
			copy(g_szKillerName, charsmax(g_szKillerName), iData[iMurderAttackerName]);
			g_iKillerStatus = iData[iMurderAttackerStatus];
			g_iKillerKills = iKills[iData[iMurderAttacker]];
		}
	}
}

public GiveSurvivalCredits()
{
	g_iSurvivalTaskRepeats++;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!GetPlayerBit(g_bIsAlive, i) || g_iPlayerStatus[i] != STATUS_DETECTIVE) 
			continue;

		g_iCredits[i] += CREDITS_BY_STAY_ALIVE;
		client_print_color(i, i, "%s %L", LANG_PLAYER, "SURVIVAL_CREDITS_REWARD", szModPrefix, CREDITS_BY_STAY_ALIVE, floatround(REWARDS_SURVIVAL_TIME * g_iSurvivalTaskRepeats));
	}
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											SAVE SYSTEM
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

LoadData(const iId)
{
	new szQuery[128], iData[2]; 
	iData[0] = iId; 
	iData[1] = LOAD_ACCOUNT;

	get_user_name(iId, szName, MAX_NAME_LENGTH-1); 
	new szSafeName[64]; 
	SQL_QuoteString(g_hConnection, szSafeName, charsmax(szSafeName), szName);

	formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s WHERE Jugador=^"%s^"", szTableAccounts, szSafeName);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
}

SaveData(const iId)
{
	new szQuery[1024], iData[2], i; 
	iData[0] = iId; 
	iData[1] = SAVE_DATA;

	new szAchievementsData[200];
	formatex(szAchievementsData, charsmax(szAchievementsData), "%d", g_iPlayerAchievements[iId][0]);
	for(i = 1; i < AchievementsList; i++){
		format(szAchievementsData, charsmax(szAchievementsData), "%s %d", szAchievementsData, g_iPlayerAchievements[iId][i]);
	}

	formatex(szQuery, charsmax(szQuery), "UPDATE %s SET TeamKill=^"%s^", MutearCR='%d', OcultarMotd='%d', Logros=^"%s^" WHERE id_user='%d'", 
	szTableAccounts, fmt("%d %d", g_iTeamKills[iId][TEAM_TEAMMATES_KILLED], g_iTeamKills[iId][TEAM_KILLS_COUNT]), 
	GetPlayerBit(g_bMuteCountDown, iId) ? 1 : 0, GetPlayerBit(g_bHideMotd, iId) ? 1 : 0, szAchievementsData, g_iId[iId]);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);

	formatex(szQuery, charsmax(szQuery), "UPDATE %s SET `Segundos`='%d', `Puntos`='%d', `det_asesinados`='%d',\
	`inn_asesinados`='%d', `tra_asesinados`='%d', `cantidad_asesinatos`='%d',\
	`cantidad_muertes`='%d', `damage_correcto`='%d', `damage_incorrecto`='%d',\
	`asesinatos_correctos`='%d', `asesinatos_incorrectos`='%d', `rondas_de_innocente`='%d', `rondas_de_detective`='%d',\
	`rondas_de_traidor`='%d', `rondas_jugadas`='%d' WHERE id_user='%d'", 
	szTableStatistics, g_iPlayerStatistics[iId][SECONDS_PLAYED], g_iPlayerStatistics[iId][POINTS], g_iPlayerStatistics[iId][DETECTIVES_KILLED], 
	g_iPlayerStatistics[iId][INNOCENTS_KILLED], g_iPlayerStatistics[iId][TRAITORS_KILLED], g_iPlayerStatistics[iId][KILLS_COUNT], 
	g_iPlayerStatistics[iId][DEATHS_COUNT], g_iPlayerStatistics[iId][DAMAGE_CORRECT], g_iPlayerStatistics[iId][DAMAGE_INCORRECT],
	g_iPlayerStatistics[iId][KILLS_CORRECT], g_iPlayerStatistics[iId][KILLS_INCORRECT], g_iPlayerStatistics[iId][INNOCENT_ROUNDS],
	g_iPlayerStatistics[iId][DETECTIVE_ROUNDS], g_iPlayerStatistics[iId][TRAITOR_ROUNDS], g_iPlayerStatistics[iId][ROUNDS_PLAYED],
	g_iId[iId]);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);

	formatex(szQuery, charsmax(szQuery), "UPDATE %s SET `rondas_ganadas`='%d', `rondas_ganadas_traidor`='%d', `maximo_karma`='%d',\
	`c4_plantadas`='%d', `c4_explotadas`='%d', `c4_defuseadas`='%d',\
	`c4_asesinatos`='%d', `knife_asesinatos`='%d', `newton_asesinatos`='%d', `jihad_asesinatos`='%d',\
	`usp_asesinatos`='%d', `golden_asesinatos`='%d', `mina_asesinatos`='%d', `estacion_asesinatos`='%d',\
	`hit_mortal_asesinatos`='%d', `falso_detective`='%d', `jugadores_desarmados`='%d', `jugadores_desmarcados`='%d' WHERE id_user='%d'", 
	szTableStatistics, g_iPlayerStatistics[iId][ROUNDS_WIN], g_iPlayerStatistics[iId][TRAITOR_ROUNDS_WIN],
	g_iPlayerStatistics[iId][MAX_KARMA_COUNT], g_iPlayerStatistics[iId][C4_PLANTED], g_iPlayerStatistics[iId][C4_EXPLODED], g_iPlayerStatistics[iId][C4_DEFUSED],
	g_iPlayerStatistics[iId][C4_KILLS], g_iPlayerStatistics[iId][KNIFE_KILLS], g_iPlayerStatistics[iId][NEWTON_KILLS], g_iPlayerStatistics[iId][JIHAD_KILLS], 
	g_iPlayerStatistics[iId][USP_KILLS], g_iPlayerStatistics[iId][GOLDEN_KILLS], g_iPlayerStatistics[iId][MINE_KILLS], g_iPlayerStatistics[iId][STATION_KILLS],
	g_iPlayerStatistics[iId][MORTAL_HIT_KILLS], g_iPlayerStatistics[iId][FALSE_DETECTIVE_BUYS], g_iPlayerStatistics[iId][PLAYERS_DISARMED], g_iPlayerStatistics[iId][PLAYERS_UNMARKED],
	g_iId[iId]);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
}

UpdateName(const iId, const szNewName[]){
	new szQuery[128], iData[2]; iData[0] = iId; iData[1] = UPDATE_NAME;
	
	formatex(szQuery, charsmax(szQuery), "UPDATE %s SET Jugador=^"%s^", WHERE id_user='%d'", szTableAccounts, szNewName, g_iId[iId]);
	SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
}

ClearTeamKills(){
	new szQuery[128], iData[1]; 
	iData[0] = REMOVE_TEAM_KILLS;
		
	formatex(szQuery, charsmax(szQuery), "UPDATE %s SET TeamKill=^"0 0^"", szTableAccounts);
	SQL_ThreadQuery(g_hTuple, "LoadData_Without_PlayerIndex", szQuery, iData, 1);
}

public DataHandler(failstate, Handle:Query, error[], error2, data[], datasize, Float:time) {
	static iId; 
	iId = data[0];
	
	if (!GetPlayerBit(g_bIsConnected, iId)) 
		return;

	if (failstate != TQUERY_SUCCESS) {
		switch (failstate) {
			case TQUERY_CONNECT_FAILED:{
				log_to_file(SQL_LOG_FILE, "MySQL connection Error [%i]: %s", error2, error);
			}
			case TQUERY_QUERY_FAILED: {
				log_to_file(SQL_LOG_FILE, "MySQL query error [%i]: %s", error2, error);
			}
		}

		return;
	}
	
	switch(data[1]){
		case CREATE_ACCOUNT:{
			if (failstate < TQUERY_SUCCESS) {
				client_print_color(iId, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "ERROR_CREATE_ACCOUNT");
				client_cmd(iId, "spk buttons/button10.wav");
			}
			else {
				client_print_color(iId, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "ACCOUNT_CREATED");

				new szQuery[128], iData[2]; 
				iData[0] = iId; 
				iData[1] = LOAD_ACCOUNT;

				get_user_name(iId, szName, 31); 
				new szSafeName[64]; 
				SQL_QuoteString(g_hConnection, szSafeName, charsmax(szSafeName), szName);

				formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s WHERE Jugador=^"%s^"", szTableAccounts, szSafeName);
				SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
			}
		}
		case LOAD_ACCOUNT: {
			if(SQL_NumResults(Query)){
				g_iId[iId] = SQL_ReadResult(Query, 0);

				new i;
				new szAchievementsData[200], szAchievements[AchievementsList][4];
				SQL_ReadResult(Query, 2, szAchievementsData, charsmax(szAchievementsData)); StoreBySpaces(szAchievementsData, szAchievements);

				for(i = 0; i < AchievementsList; i++) g_iPlayerAchievements[iId][i] = str_to_num(szAchievements[i]);

				new szTeamKill[2][12]; SQL_ReadResult(Query, 3, szTeamKill, charsmax(szTeamKill[]));
				for(i = 0; i < TEAM_KILLS; i++) g_iTeamKills[iId][i] = str_to_num(szTeamKill[i]);

				if(SQL_ReadResult(Query, 4) > 0) SetPlayerBit(g_bMuteCountDown, iId);
				else ClearPlayerBit(g_bMuteCountDown, iId);

				if(SQL_ReadResult(Query, 5) > 0) SetPlayerBit(g_bHideMotd, iId);
				else ClearPlayerBit(g_bHideMotd, iId);

				new szQuery[128], iData[2]; iData[0] = iId; iData[1] = LOAD_STATISTICS;

				formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s WHERE id_user='%d'", szTableStatistics, g_iId[iId]);
				SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
			}
			else{
				new szQuery[256], iData[2]; iData[0] = iId; iData[1] = CREATE_ACCOUNT;

				get_user_name(iId, szName, 31); new szSafeName[64]; SQL_QuoteString(g_hConnection, szSafeName, charsmax(szSafeName), szName);

				formatex(szQuery, charsmax(szQuery), "INSERT INTO %s (Jugador) VALUES (^"%s^")", szTableAccounts, szSafeName);
				SQL_ThreadQuery(g_hTuple, "DataHandler", szQuery, iData, 2);
			}
		}
		case LOAD_STATISTICS: {
			if(SQL_NumResults(Query)){
				// i+2 porque 0 es id y 1 es Jugador
				for(new i = 0; i < Statistics_List; i++)
					g_iPlayerStatistics[iId][i] = SQL_ReadResult(Query, i+2);

				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "ACCOUNT_LOADED");

				SetPlayerBit(g_bIsLogged, iId);

				set_task(5.0, "JoinTeamAndRespawnPlayer", iId+TASK_SPAWN);

				UpdateAchievementProgress(iId, Achievement_type_time);
			}
			else
				client_print_color(iId, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "ERROR_LOAD_ACCOUNT");
		}
		case SAVE_DATA:{
			if (failstate < TQUERY_SUCCESS) 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "ERROR_SAVE_ACCOUNT");
			else 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "ACCOUNT_SAVED");
		}
		case UPDATE_NAME:{
			if (failstate < TQUERY_SUCCESS) 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "ERROR_UPDATE_NAME");
			else if (SQL_NumResults(Query) == 0) 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "NAME_NOT_FOUND");
			else if (SQL_NumResults(Query) > 1) 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "NAME_ALREADY_EXISTS");
			else 
				client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "NAME_UPDATED");
		}
	}
}

public LoadData_Without_PlayerIndex(failstate, Handle:Query, error[], error2, data[], datasize, Float:time){
	if (failstate != TQUERY_SUCCESS) {
		switch (failstate) {
			case TQUERY_CONNECT_FAILED:{
				log_to_file(SQL_LOG_FILE, "MySQL connection Error [%i]: %s", error2, error);
			}
			case TQUERY_QUERY_FAILED: {
				log_to_file(SQL_LOG_FILE, "MySQL query error [%i]: %s", error2, error);
			}
		}
		
		return;
	}
}

public MySQLx_Init()
{
	g_hTuple = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATEBASE);
	
	if (!g_hTuple) {
		log_to_file(SQL_LOG_FILE, "%L", LANG_SERVER, "MYSQL_CONNECTION_ERROR", MYSQL_HOST, MYSQL_USER, MYSQL_DATEBASE);
		return pause("a");
	}

	new err[512], err_code;
	g_hConnection = SQL_Connect(g_hTuple, err_code, err, charsmax(err));
	
	if(g_hConnection == Empty_Handle) 
		log_to_file(SQL_LOG_FILE, "%L", LANG_SERVER, "MYSQL_CONNECTION_ERROR_EMPTY_HANDLE", err, err_code);

	ClearTeamKills();
	
	return PLUGIN_CONTINUE;
}

public JoinTeamAndRespawnPlayer(taskid)
{	
	rg_join_team(ID_SPAWN, rg_get_join_team_priority());

	set_task(5.0, "RespawnPlayerTask", ID_SPAWN+TASK_SPAWN);

	if (GetConnectedUsers() >= TRAITORS_COUNT_PER_PLAYER) 
		FinishRound();
}

public RespawnPlayerTask(taskid)
{
	if (GetPlayerBit(g_bIsAlive, ID_SPAWN) || g_bRoundEnd || g_bRoundStart) 
		return;

	new TeamName:iTeam = get_member(ID_SPAWN, m_iTeam);	
	
	if (iTeam == TEAM_UNASSIGNED || iTeam == TEAM_SPECTATOR) 
		return;

	rg_round_respawn(ID_SPAWN);
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											OTHER FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

public HudEnt(iEnt)
{
	if (!is_valid_ent(iEnt)) 
		return;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) 	
			g_iPlayerStatistics[i][SECONDS_PLAYED]++;

		if (!GetPlayerBit(g_bIsAlive, i) || g_iPlayerStatus[i] == STATUS_NONE) 
			continue;
		
		set_hudmessage(g_iHudColors[g_iPlayerStatus[i]][0], g_iHudColors[g_iPlayerStatus[i]][1], g_iHudColors[g_iPlayerStatus[i]][2], 
		HUD_POSITION_X, HUD_POSITION_Y, 0, 1.0, 0.1, 0.1, 2.0, -1);

		if (g_iPlayerStatus[i] == STATUS_INNOCENT) 
			ShowSyncHudMsg(i, g_SyncHud[SYNCHUD_PRINCIPAL], "[KARMA = %d] [%L: %s]", 
			g_iKarma[i][CURRENT_KARMA], 
			LANG_PLAYER, "ROL_NAME",
			szPlayerStatus[g_iPlayerStatus[i]]);
		else 
			ShowSyncHudMsg(i, g_SyncHud[SYNCHUD_PRINCIPAL], "[KARMA = %d] [%L: %s] [%L = %d]", 
			g_iKarma[i][CURRENT_KARMA], 
			LANG_PLAYER, "ROL_NAME",
			LANG_PLAYER, "CREDITS_NAME",
			szPlayerStatus[g_iPlayerStatus[i]], g_iCredits[i]);
	}
	
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0);
}

CheckTraitorsRewards()
{
	if(g_bRoundEnd) 
		return;

	new iEnemiesCount = (GetConnectedUsers() - GetAliveTraitors()), iEnemiesAliveCount = GetAliveInnocentsAndDetectives();
	new Float:fPercentage = (float(iEnemiesAliveCount) / float(iEnemiesCount)) * 100.0;

	if(fPercentage <= 75.0 && g_iKillBonusCredits < 1){
		g_iKillBonusCredits = 1;
		GiveCreditsForKillTeam(25);
	}
	
	if(fPercentage <= 50 && g_iKillBonusCredits < 2){
		g_iKillBonusCredits = 2;
		GiveCreditsForKillTeam(50);
	}

	if(fPercentage <= 25 && g_iKillBonusCredits < 3){
		g_iKillBonusCredits = 3;
		GiveCreditsForKillTeam(75);
	}
}

GiveCreditsForKillTeam(const iCount)
{
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!GetPlayerBit(g_bIsAlive, i) || g_iPlayerStatus[i] != STATUS_TRAITOR) 
			continue;

		g_iCredits[i] += CREDITS_REWARD_BY_KILLING_TEAM;

		client_print_color(i, i, "%s %L", szModPrefix, LANG_PLAYER, "TRAITOR_KILL_TEAM_REWARD", CREDITS_REWARD_BY_KILLING_TEAM, iCount);
	}
}

CreateBody(iId, const Float:fOrigin[3], const szModel[], const iSeq)
{
	// MANEJAR ENTIDADES POR INDICES MUY ARRIESGADO; ME DIO FALSOS POSITIVOS
	new iEnt = create_entity("info_target");

	if(!is_entity(iEnt)) return;

	entity_set_string(iEnt, EV_SZ_classname, szDeadBodyClassName);
	entity_set_model(iEnt, fmt("models/player/%s/%s.mdl", szModel, szModel));
	entity_set_origin(iEnt, fOrigin);
	entity_set_size(iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	entity_set_float(iEnt, EV_FL_frame, 255.0);
	entity_set_int(iEnt, EV_INT_sequence, iSeq);
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_int(iEnt, EV_INT_solid, SOLID_TRIGGER);
	entity_set_edict(iEnt, EV_ENT_owner, iId);

	get_user_name(iId, szName, 31);
	copy(g_iDeadBodyEnt[iId][BODY_NAME], 31, szName);

	g_iDeadBodyEnt[iId][BODY_SECONDS] = get_gametime();
	g_iDeadBodyEnt[iId][BODY_OWNER_STATUS] = g_iPlayerStatus[iId];
	g_iDeadBodyEnt[iId][BODY_STATUS] = BODY_NOT_REPORTED;
}

RemoveDeadBodies(){
	new iEnt = NULLENT;

	while((iEnt = rg_find_ent_by_class(iEnt, szDeadBodyClassName)))
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////
											STOCKS AND MORE
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

ShowSprite(const iId, const iTarget, const iStatus)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, iId);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(iTarget);
	write_coord(45);
	if(iStatus == STATUS_TRAITOR) write_short(g_iTraitorSpr);
	else write_short(g_iDetectiveSpr);
	write_short(30);
	message_end();
}

SetScoreAttrib(const iId, const iAttrib){
	// UPDATE SCORE ATTRIB FOR INNOCENTS AND DETECTIVES.
	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(i == iId || !GetPlayerBit(g_bIsConnected, i) || g_iPlayerStatus[i] == STATUS_TRAITOR) continue;

		message_begin(MSG_ONE, g_iUserMessages[MSG_SCOREATTRIB], _, i);
		write_byte(iId);
		write_byte(iAttrib);
		message_end();
	}
}

UpdateScoreAttribToVictim(const iId){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(i == iId || !GetPlayerBit(g_bIsConnected, i) || GetPlayerBit(g_bIsAlive, i)) continue;

		message_begin(MSG_ONE, g_iUserMessages[MSG_SCOREATTRIB], _, iId);
		write_byte(i);
		write_byte(1);
		message_end();
	}
}

UpdateTeamInfo(){
	new TeamName:iTeam;

	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(!GetPlayerBit(g_bIsAlive, i)) continue;

		iTeam = get_member(i, m_iTeam);

		if(g_iPlayerStatus[i] == STATUS_DETECTIVE){
			if(iTeam != TEAM_CT){
				message_begin(MSG_ALL, g_iUserMessages[MSG_TEAMINFO]);
				write_byte(i);
				write_string("CT");
				message_end();
			}
		}
		else{
			if(g_iPlayerStatus[i] == STATUS_TRAITOR){
				if(iTeam != TEAM_CT){
					for(new j = 1; j <= MAX_PLAYERS; j++){
						if(!GetPlayerBit(g_bIsConnected, j)) continue;

						if(g_iPlayerStatus[j] != STATUS_TRAITOR) continue;

						message_begin(MSG_ONE, g_iUserMessages[MSG_TEAMINFO], _, j);
						write_byte(i);
						write_string("CT");
						message_end();

						message_begin(MSG_ONE, g_iUserMessages[MSG_SCOREATTRIB], _, j);
						write_byte(i);
						write_byte(4);
						message_end();
					}
				}
				else{
					for(new j = 1; j <= MAX_PLAYERS; j++){
						if(!GetPlayerBit(g_bIsConnected, j)) continue;

						if(g_iPlayerStatus[j] == STATUS_TRAITOR){
							message_begin(MSG_ONE, g_iUserMessages[MSG_SCOREATTRIB], _, j);
							write_byte(i);
							write_byte(4);
							message_end();
						}
						else{
							message_begin(MSG_ONE, g_iUserMessages[MSG_TEAMINFO], _, j);
							write_byte(i);
							write_string("TERRORIST");
							message_end();
						}
					}
				}
			}
			else if(iTeam != TEAM_TERRORIST){
				message_begin(MSG_ALL, g_iUserMessages[MSG_TEAMINFO]);
				write_byte(i);
				write_string("TERRORIST");
				message_end();
			}
		}
	}
}

FixTeamInfo(const iId){
	message_begin(MSG_ALL, g_iUserMessages[MSG_TEAMINFO]);
	write_byte(iId);
	write_string("TERRORIST");
	message_end();

	new TeamName:iTeam;

	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(i == iId) continue;

		if(!GetPlayerBit(g_bIsAlive, i)) continue;

		iTeam = get_member(i, m_iTeam);

		if(g_iPlayerStatus[i] == STATUS_DETECTIVE){
			if(iTeam != TEAM_CT){
				message_begin(MSG_ONE, g_iUserMessages[MSG_TEAMINFO], _ ,iId);
				write_byte(i);
				write_string("CT");
				message_end();
			}
		}
		else{
			if(iTeam != TEAM_TERRORIST){
				message_begin(MSG_ONE, g_iUserMessages[MSG_TEAMINFO], _, iId);
				write_byte(i);
				write_string("TERRORIST");
				message_end();
			}
		}
	}
}

SetScreenFadeByClass(const iId, const iClass){
	message_begin(MSG_ONE_UNRELIABLE, g_iUserMessages[MSG_SCREENFADE], _, iId);
	write_short(UNIT_SECOND);
	write_short(0);
	write_short(FFADE_IN);
	write_byte(g_iHudColors[iClass][0]);
	write_byte(g_iHudColors[iClass][1]);
	write_byte(g_iHudColors[iClass][2]);
	write_byte(100);
	message_end();
}

GetRandomAliveUser()
{
	new iAlive;

	while(!iAlive){
		iAlive = random_num(1, MAX_PLAYERS);

		if(GetPlayerBit(g_bIsAlive, iAlive)) break;

		iAlive = 0;
	}

	return iAlive;
}

GetAlivePlayers()
{
	new iAliveCount;

	for(new i = 1; i <= MAX_PLAYERS; i++) if(GetPlayerBit(g_bIsAlive, i)) iAliveCount++;

	return iAliveCount;
}

GetConnectedUsers()
{
	new iConnectedCount;

	for (new i = 1; i <= MAX_PLAYERS; i++) 
		if (GetPlayerBit(g_bIsConnected, i) && GetPlayerBit(g_bIsLogged, i)) 
			iConnectedCount++;

	return iConnectedCount;
}

GetAliveTraitors()
{
	new iAliveCount;

	for(new i = 1; i <= MAX_PLAYERS; i++) if(GetPlayerBit(g_bIsAlive, i) && g_iPlayerStatus[i] == STATUS_TRAITOR) iAliveCount++;

	return iAliveCount;
}

GetAliveInnocentsAndDetectives()
{
	new iAliveCount;

	for(new i = 1; i <= MAX_PLAYERS; i++) if(GetPlayerBit(g_bIsAlive, i) && (g_iPlayerStatus[i] == STATUS_INNOCENT || g_iPlayerStatus[i] == STATUS_DETECTIVE)) iAliveCount++;

	return iAliveCount;
}

PlaySound(const iId, const szSound[])
{
	if (equal(szSound[strlen(szSound)-4], ".mp3")){
		client_cmd(iId, "mp3 stop");
		client_cmd(iId, "mp3 play ^"%s^"", szSound);
	}
	else client_cmd(iId, "spk ^"%s^"", szSound);
}

rg_set_user_rendering(index, fx = kRenderFxNone, {Float,_}:color[3] = {0.0,0.0,0.0}, render = kRenderNormal, Float:amount = 0.0)
{
	set_entvar(index, var_renderfx, fx);
	set_entvar(index, var_rendercolor, color);
	set_entvar(index, var_rendermode, render);
	set_entvar(index, var_renderamt, amount);
}

// thx Rolnaaba
stock IsAimingAt(const iId, const Float:fDist, const szClassName[])
{
	new Float:fOrigin[2][3]; entity_get_vector(iId, EV_VEC_origin, fOrigin[0]);
	new iOrigin[3]; get_user_origin(iId, iOrigin, 3); IVecFVec(iOrigin, fOrigin[1]);
	
	if(get_distance_f(fOrigin[0], fOrigin[1]) > fDist) return 0;

	new iEnt = -1;

	new Float:fMinDistance = fDist, Float:fDistance, iLastEnt;

	while((iEnt = find_ent_in_sphere(iEnt, fOrigin[1], fDist)) != 0)
	{
		if(!is_nullent(iEnt)){
        	new szHitClassname[32]; entity_get_string(iEnt, EV_SZ_classname, szHitClassname, charsmax(szHitClassname));
        
        	if(equali(szHitClassname, szClassName)){
        		entity_get_vector(iEnt, EV_VEC_origin, fOrigin[0]);
        		fDistance = get_distance_f(fOrigin[0], fOrigin[1]);

        		if(fDistance <= fMinDistance){
        			fMinDistance = fDistance;
        			iLastEnt = iEnt;
        		}
        	}
        }
    }

	return iLastEnt;
}

stock ShowGlobalSprite( const iId, const Float:flOrigin[ 3 ], const iSprite, const Float:flScale = 1.0 )
{
    static Float:flPlayerOrigin[ 3 ];
    static Float:flViewOfs[ 3 ];
    
    static Float:flBuffer[ 3 ];
    static Float:flDifference[ 3 ];
    
    static Float:flDistanceToPoint;
    static Float:flDistanceToOrigin;
    
    static iScale;
    
    entity_get_vector( iId, EV_VEC_origin, flPlayerOrigin );
    entity_get_vector( iId, EV_VEC_view_ofs, flViewOfs );
    
    xs_vec_add( flPlayerOrigin, flViewOfs, flPlayerOrigin );
    
    if ( vector_distance( flPlayerOrigin, flOrigin ) > 4096.0 )
    {
        return false;
    }
    
    new iTrace = create_tr2( );
    
    engfunc( EngFunc_TraceLine, flPlayerOrigin, flOrigin, IGNORE_MONSTERS, iId, iTrace );
    
    get_tr2( iTrace, TR_vecEndPos, flBuffer );
    free_tr2( iTrace );
    
    flDistanceToPoint = vector_distance( flPlayerOrigin, flBuffer ) - 10.0;
    flDistanceToOrigin = vector_distance( flPlayerOrigin, flOrigin );
    
    xs_vec_sub( flOrigin, flPlayerOrigin, flDifference );
    
    xs_vec_normalize( flDifference, flDifference );
    xs_vec_mul_scalar( flDifference, flDistanceToPoint, flDifference );
    
    xs_vec_add( flPlayerOrigin, flDifference, flBuffer );
    
    iScale = floatround( 2.0 * floatmax( ( flDistanceToPoint / flDistanceToOrigin ), 0.25 ) * flScale );
    
    message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = iId );
    write_byte( TE_SPRITE );
    write_coord_f( flBuffer[ 0 ] );
    write_coord_f( flBuffer[ 1 ] );
    write_coord_f( flBuffer[ 2 ] );
    write_short( iSprite );
    write_byte( iScale );
    write_byte( 255 );
    message_end( );
    
    return true;
}

MakeTutor(const iId, TutorColor:Colorz, Float:fTime = 0.0, const szText[], any:...)
{
	new szMessage[512]; vformat(szMessage, charsmax(szMessage), szText, 5);

	if(!iId){
		message_begin(MSG_BROADCAST, g_iUserMessages[MSG_TUTORTEXT]);
		write_string(szMessage);
		write_byte(0);
		write_short(0);
		write_short(0);
		write_short(1<<_:Colorz);
		message_end();

		PlaySound(0, szTutorSound);

		for(new i = 1; i <= MAX_PLAYERS; i++){
			remove_task(i+TASK_TUTOR);
			set_task(fTime,"TutorClose", TASK_TUTOR);
		}
	}
	else if(GetPlayerBit(g_bIsConnected, iId))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iUserMessages[MSG_TUTORTEXT], _, iId);
		write_string(szMessage);
		write_byte(0);
		write_short(0);
		write_short(0);
		write_short(1<<_:Colorz);
		message_end();

		PlaySound(iId, szTutorSound);

		remove_task(iId+TASK_TUTOR);
		set_task(fTime, "TutorClose", iId+TASK_TUTOR);
	}
}

public TutorClose(taskid){
	if(!ID_TUTOR)
 	{
		message_begin(MSG_BROADCAST, g_iUserMessages[MSG_TUTORCLOSE]);
		message_end();
	}
	else if(GetPlayerBit(g_bIsConnected, ID_TUTOR))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iUserMessages[MSG_TUTORCLOSE], _, ID_TUTOR);
		message_end();
	}
}

ShowEndRoundMotd(const iId, const iTeamWinner){
	if(GetPlayerBit(g_bHideMotd, iId)) return;

	new iLen;

	iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<body bgcolor=#000000><pre><center>");

	if(iTeamWinner == STATUS_TRAITOR){
		PlaySound(iId, szTraitorsWinSound);
		
		//iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<body bgcolor=#000000><font color=FF0000><pre><center><h1>Ganaron los traidores!</h1>^n");
		iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<h1><span style=background-color:#FF0000>\
		Ganaron los traidores!</span></h1>^n");
	}
	else{
		PlaySound(iId, szInnocentsWinSound);
		
		iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<h1><span style=background-color:#00FF00>\
		Ganaron los innocentes!</span></h1>^n");

		//iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<body bgcolor=#000000><font color=00FF00><pre><center><h1>Ganaron los innocentes!</h1>^n");
	}

	iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=3399ff><font-size:20px>%s^n", g_szDetectivesNames);
	iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=FF0000>%s^n^n", g_szTraitorsNames);

	if(!equal(g_szKillerName, "")){
		switch(g_iKillerStatus){
			case STATUS_DETECTIVE: iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=3399ff>[Detective] %s \
				fue el asesino con %d muertes^n", g_szKillerName, g_iKillerKills);
			case STATUS_INNOCENT: iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=000000>[Innocente] %s \
				fue el asesino con %d muertes^n", g_szKillerName, g_iKillerKills);
			case STATUS_TRAITOR: iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=FF0000>[Traidor] %s \
				fue el asesino con %d muertes^n", g_szKillerName, g_iKillerKills);
		}
	}

	new iData[ArrayMurdersData], bool:bHaveMurders;

	for(new i; i < ArraySize(g_aMurders); i++){
		ArrayGetArray(g_aMurders, i, iData);

		if(iData[iMurderAttacker] == iId){
			if(!bHaveMurders){
				iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=FFFFFF> Mataste a: ");
				iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "%s-", iData[szMurderVictimName]);
				bHaveMurders = true;
			}
			else iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "%s-", iData[szMurderVictimName]);
		}
	}

	if(!bHaveMurders)
		iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "<font color=FFFFFF> No mataste a nadie en esta ronda");

	iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "^nKarma obtenido: %d^n", g_iKarma[iId][TEMP_KARMA] - g_iKarma[iId][CURRENT_KARMA]);

	new iTrieSize = TrieGetSize(g_tDisconnectData);
	if(iTrieSize > 0){
		iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), "Desconectado:");

		new TrieIter:iter = TrieIterCreate(g_tDisconnectData);{
			new szKey[32], szValue[15];

			while (!TrieIterEnded(iter)){
				TrieIterGetKey(iter, szKey, charsmax(szKey));
				TrieIterGetString(iter, szValue, charsmax(szValue));
				iLen += formatex(szEndRoundMotd[iLen], charsmax(szEndRoundMotd), " %s como %s", szKey, szValue);

				TrieIterNext(iter);
			}
		}

		TrieIterDestroy(iter);
	}

	show_motd(iId, szEndRoundMotd, "End Motd");
}

stock bool:ValidMessage(const szText[]){
	new iLen = strlen(szText);

	if (!iLen) return false;
    
	for(new i; i < iLen; i++) if (szText[i] != ' ') return true;

	return false;
}

StoreBySpaces(const szString[], szStringDest[][]){
	new iSpaces, iLen;
	for(new i; i < strlen(szString); i++){
		if(szString[i] == ' '){
			iSpaces++;
			iLen = 0;
		}
		else{
			szStringDest[iSpaces][iLen] = szString[i];
			iLen++;
		}
	}
}

UpdateAchievementProgress(const iId, const iAchievement_type){
	switch(iAchievement_type){
		case Achievement_type_time:{
			if(!g_iPlayerAchievements[iId][SOY_NUEVO]){
				if((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 3600) >= g_DataAchievements[SOY_NUEVO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, SOY_NUEVO);

				return;
			}
			
			if(!g_iPlayerAchievements[iId][JUGADO_COMO_UN_CAMPEON]){
				if((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 3600) >= g_DataAchievements[JUGADO_COMO_UN_CAMPEON][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, JUGADO_COMO_UN_CAMPEON);

				return;
			}

			if(!g_iPlayerAchievements[iId][VICIADO]){
				if((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) >= g_DataAchievements[VICIADO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, VICIADO);

				return;
			}

			if(!g_iPlayerAchievements[iId][PEOR_QUE_UNA_DROGA]){
				if((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) >= g_DataAchievements[PEOR_QUE_UNA_DROGA][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, PEOR_QUE_UNA_DROGA);

				return;
			}

			if(!g_iPlayerAchievements[iId][VIDA_SOCIAL]){
				if((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) >= g_DataAchievements[VIDA_SOCIAL][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, VIDA_SOCIAL);
			}
		}
		case Achievement_type_correct:{
			if(!g_iPlayerAchievements[iId][DISPAROS_DE_SUERTE]){
				if(g_iPlayerStatistics[iId][KILLS_CORRECT] >= g_DataAchievements[DISPAROS_DE_SUERTE][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, DISPAROS_DE_SUERTE);

				return;
			}

			if(!g_iPlayerAchievements[iId][TE_MATE]){
				if(g_iPlayerStatistics[iId][KILLS_CORRECT] >= g_DataAchievements[TE_MATE][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, TE_MATE);

				return;
			}

			if(!g_iPlayerAchievements[iId][PONGO_EL_OJO_Y_PONGO_LA_BALA]){
				if(g_iPlayerStatistics[iId][KILLS_CORRECT] >= g_DataAchievements[PONGO_EL_OJO_Y_PONGO_LA_BALA][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, PONGO_EL_OJO_Y_PONGO_LA_BALA);

				return;
			}

			if(!g_iPlayerAchievements[iId][MAQUINA_IMPARABLE]){
				if(g_iPlayerStatistics[iId][KILLS_CORRECT] >= g_DataAchievements[MAQUINA_IMPARABLE][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, MAQUINA_IMPARABLE);
			}
		}
		case Achievement_type_round:{
			if(!g_iPlayerAchievements[iId][SUERTE_DE_PRINCIPANTE]){
				if(g_iPlayerStatistics[iId][ROUNDS_WIN] >= g_DataAchievements[SUERTE_DE_PRINCIPANTE][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, SUERTE_DE_PRINCIPANTE);

				return;
			}

			if(!g_iPlayerAchievements[iId][GANARME_VOS_A_MI]){
				if(g_iPlayerStatistics[iId][ROUNDS_WIN] >= g_DataAchievements[GANARME_VOS_A_MI][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, GANARME_VOS_A_MI);

				return;
			}

			if(!g_iPlayerAchievements[iId][EN_ESTE_SERVIDOR_MANDO_YO]){
				if(g_iPlayerStatistics[iId][ROUNDS_WIN] >= g_DataAchievements[EN_ESTE_SERVIDOR_MANDO_YO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, EN_ESTE_SERVIDOR_MANDO_YO);

				return;
			}

			if(!g_iPlayerAchievements[iId][FUI_HECHO_PARA_ESTE_JUEGO]){
				if(g_iPlayerStatistics[iId][ROUNDS_WIN] >= g_DataAchievements[FUI_HECHO_PARA_ESTE_JUEGO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, FUI_HECHO_PARA_ESTE_JUEGO);
			}
		}
		case Achievement_type_traitor:{
			if(!g_iPlayerAchievements[iId][NO_CONFIES_EN_MI]){
				if(g_iPlayerStatistics[iId][TRAITOR_ROUNDS] >= g_DataAchievements[NO_CONFIES_EN_MI][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, NO_CONFIES_EN_MI);

				return;
			}

			if(!g_iPlayerAchievements[iId][ICARDI_FUE_MI_MAESTRO]){
				if(g_iPlayerStatistics[iId][TRAITOR_ROUNDS] >= g_DataAchievements[ICARDI_FUE_MI_MAESTRO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, ICARDI_FUE_MI_MAESTRO);

				return;
			}

			if(!g_iPlayerAchievements[iId][NI_JUDAS_SE_ATREVIO_A_TANTO]){
				if(g_iPlayerStatistics[iId][TRAITOR_ROUNDS] >= g_DataAchievements[NI_JUDAS_SE_ATREVIO_A_TANTO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, NI_JUDAS_SE_ATREVIO_A_TANTO);
			}
		}
		case Achievement_type_incorrect:{
			if(!g_iPlayerAchievements[iId][AHI_LO_TENES_AL_PELOTUDO]){
				if(g_iPlayerStatistics[iId][KILLS_INCORRECT] >= g_DataAchievements[AHI_LO_TENES_AL_PELOTUDO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, AHI_LO_TENES_AL_PELOTUDO);
			}
		}
		case Achievement_type_kills:{
			if(!g_iPlayerAchievements[iId][ASESINO_SILENCIOSO]){
				if(g_iPlayerStatistics[iId][KNIFE_KILLS] >= g_DataAchievements[ASESINO_SILENCIOSO][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, ASESINO_SILENCIOSO);
			}

			if(!g_iPlayerAchievements[iId][EL_MAESTRO_DE_LA_MINA]){
				if(g_iPlayerStatistics[iId][MINE_KILLS] >= g_DataAchievements[EL_MAESTRO_DE_LA_MINA][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, EL_MAESTRO_DE_LA_MINA);
			}

			if(!g_iPlayerAchievements[iId][LAS_VACAS_NO_VUELAN]){
				if(g_iPlayerStatistics[iId][NEWTON_KILLS] >= g_DataAchievements[LAS_VACAS_NO_VUELAN][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, LAS_VACAS_NO_VUELAN);
			}

			if(!g_iPlayerAchievements[iId][ALAHU_AKBAR]){
				if(g_iPlayerStatistics[iId][JIHAD_KILLS] >= g_DataAchievements[ALAHU_AKBAR][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, ALAHU_AKBAR);
			}
		}
		case Achievement_type_fake_detective:{
			if(!g_iPlayerAchievements[iId][MAS_FALSO_QUE_EL_AMOR_DE_ELLA]){
				if(g_iPlayerStatistics[iId][FALSE_DETECTIVE_BUYS] >= g_DataAchievements[MAS_FALSO_QUE_EL_AMOR_DE_ELLA][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, MAS_FALSO_QUE_EL_AMOR_DE_ELLA);
			}
		}
		case Achievement_type_disarmed:{
			if(!g_iPlayerAchievements[iId][DESARMO_LAS_24_7]){
				if(g_iPlayerStatistics[iId][PLAYERS_DISARMED] >= g_DataAchievements[DESARMO_LAS_24_7][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, DESARMO_LAS_24_7);
			}
		}
		case Achievement_type_unmarked:{
			if(!g_iPlayerAchievements[iId][A_MI_NO_ME_MARCAS]){
				if(g_iPlayerStatistics[iId][PLAYERS_UNMARKED] >= g_DataAchievements[A_MI_NO_ME_MARCAS][ACHIEVEMENT_REQUIRED_COUNT])
					UserCompleteAchievement(iId, A_MI_NO_ME_MARCAS);
			}
		}
	}
}

UserCompleteAchievement(const iId, const iAchievement){
	g_iPlayerAchievements[iId][iAchievement] = 1;
	new szName[32]; get_user_name(iId, szName, charsmax(szName));
	client_print_color(0, print_team_default, "%s %L", szModPrefix, LANG_PLAYER, "COMPLETE_ACHIEVEMENT", szName, g_DataAchievements[iAchievement][ACHIEVEMENT_NAME]);

	PlaySound(0, szSoundGetAchievemment);
}

public UpdatePoints(const iId, const iValue) g_iPlayerStatistics[iId][POINTS] += iValue;

GetAchievementProgress(const iId, const iAchievement){
	if(g_iPlayerAchievements[iId][iAchievement]) return 100;

	switch(iAchievement){
		case SOY_NUEVO: return ((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 3600) * 100 / g_DataAchievements[SOY_NUEVO][ACHIEVEMENT_REQUIRED_COUNT]);
		case JUGADO_COMO_UN_CAMPEON: return ((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 3600) * 100 / g_DataAchievements[JUGADO_COMO_UN_CAMPEON][ACHIEVEMENT_REQUIRED_COUNT]);
		case VICIADO: return ((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) * 100 / g_DataAchievements[VICIADO][ACHIEVEMENT_REQUIRED_COUNT]);
		case PEOR_QUE_UNA_DROGA: return ((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) * 100 / g_DataAchievements[PEOR_QUE_UNA_DROGA][ACHIEVEMENT_REQUIRED_COUNT]);
		case VIDA_SOCIAL: return ((g_iPlayerStatistics[iId][SECONDS_PLAYED] / 86400) * 100 / g_DataAchievements[VIDA_SOCIAL][ACHIEVEMENT_REQUIRED_COUNT]);
		case DISPAROS_DE_SUERTE: return (g_iPlayerStatistics[iId][KILLS_CORRECT] * 100 / g_DataAchievements[DISPAROS_DE_SUERTE][ACHIEVEMENT_REQUIRED_COUNT]);
		case TE_MATE: return (g_iPlayerStatistics[iId][KILLS_CORRECT] * 100 / g_DataAchievements[TE_MATE][ACHIEVEMENT_REQUIRED_COUNT]);
		case PONGO_EL_OJO_Y_PONGO_LA_BALA: return (g_iPlayerStatistics[iId][KILLS_CORRECT] * 100 / g_DataAchievements[PONGO_EL_OJO_Y_PONGO_LA_BALA][ACHIEVEMENT_REQUIRED_COUNT]);
		case MAQUINA_IMPARABLE: return (g_iPlayerStatistics[iId][KILLS_CORRECT] * 100 / g_DataAchievements[MAQUINA_IMPARABLE][ACHIEVEMENT_REQUIRED_COUNT]);
		case SUERTE_DE_PRINCIPANTE: return (g_iPlayerStatistics[iId][ROUNDS_WIN] * 100 / g_DataAchievements[SUERTE_DE_PRINCIPANTE][ACHIEVEMENT_REQUIRED_COUNT]);
		case GANARME_VOS_A_MI: return (g_iPlayerStatistics[iId][ROUNDS_WIN] * 100 / g_DataAchievements[GANARME_VOS_A_MI][ACHIEVEMENT_REQUIRED_COUNT]);
		case EN_ESTE_SERVIDOR_MANDO_YO: return (g_iPlayerStatistics[iId][ROUNDS_WIN] * 100 / g_DataAchievements[EN_ESTE_SERVIDOR_MANDO_YO][ACHIEVEMENT_REQUIRED_COUNT]);
		case FUI_HECHO_PARA_ESTE_JUEGO: return (g_iPlayerStatistics[iId][ROUNDS_WIN] * 100 / g_DataAchievements[FUI_HECHO_PARA_ESTE_JUEGO][ACHIEVEMENT_REQUIRED_COUNT]);
		case NO_CONFIES_EN_MI: return (g_iPlayerStatistics[iId][TRAITOR_ROUNDS] * 100 / g_DataAchievements[NO_CONFIES_EN_MI][ACHIEVEMENT_REQUIRED_COUNT]);
		case ICARDI_FUE_MI_MAESTRO: return (g_iPlayerStatistics[iId][TRAITOR_ROUNDS] * 100 / g_DataAchievements[ICARDI_FUE_MI_MAESTRO][ACHIEVEMENT_REQUIRED_COUNT]);
		case NI_JUDAS_SE_ATREVIO_A_TANTO: return (g_iPlayerStatistics[iId][TRAITOR_ROUNDS] * 100 / g_DataAchievements[NI_JUDAS_SE_ATREVIO_A_TANTO][ACHIEVEMENT_REQUIRED_COUNT]);
		case AHI_LO_TENES_AL_PELOTUDO: return (g_iPlayerStatistics[iId][KILLS_INCORRECT] * 100 / g_DataAchievements[AHI_LO_TENES_AL_PELOTUDO][ACHIEVEMENT_REQUIRED_COUNT]);
		case ASESINO_SILENCIOSO: return (g_iPlayerStatistics[iId][KNIFE_KILLS] * 100 / g_DataAchievements[ASESINO_SILENCIOSO][ACHIEVEMENT_REQUIRED_COUNT]);
		case EL_MAESTRO_DE_LA_MINA: return (g_iPlayerStatistics[iId][MINE_KILLS] * 100 / g_DataAchievements[EL_MAESTRO_DE_LA_MINA][ACHIEVEMENT_REQUIRED_COUNT]);
		case LAS_VACAS_NO_VUELAN: return (g_iPlayerStatistics[iId][NEWTON_KILLS] * 100 / g_DataAchievements[LAS_VACAS_NO_VUELAN][ACHIEVEMENT_REQUIRED_COUNT]);
		case ALAHU_AKBAR: return (g_iPlayerStatistics[iId][JIHAD_KILLS] * 100 / g_DataAchievements[ALAHU_AKBAR][ACHIEVEMENT_REQUIRED_COUNT]);
		case MAS_FALSO_QUE_EL_AMOR_DE_ELLA: return (g_iPlayerStatistics[iId][FALSE_DETECTIVE_BUYS] * 100 / g_DataAchievements[MAS_FALSO_QUE_EL_AMOR_DE_ELLA][ACHIEVEMENT_REQUIRED_COUNT]);
		case DESARMO_LAS_24_7: return (g_iPlayerStatistics[iId][PLAYERS_DISARMED] * 100 / g_DataAchievements[DESARMO_LAS_24_7][ACHIEVEMENT_REQUIRED_COUNT]);
		case A_MI_NO_ME_MARCAS: return (g_iPlayerStatistics[iId][PLAYERS_UNMARKED] * 100 / g_DataAchievements[A_MI_NO_ME_MARCAS][ACHIEVEMENT_REQUIRED_COUNT]);
	}

	return 0;
}

VoiceCheck(const iId, const iType)
{	
	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(!GetPlayerBit(g_bIsConnected, i)) continue;

		if(g_iPlayerStatus[i] != STATUS_TRAITOR) continue;

		message_begin(MSG_ONE_UNRELIABLE, g_iUserMessages[MSG_TEAMINFO], _, i);
		write_byte(iId);
		if(!iType) write_string("SPECTATOR");
		else write_string("CT");
		message_end();
	}
}

public pfn_spawn(iEntity)
{
	if(is_valid_ent(iEntity)){
		static szClassName[32], iSize; iSize = sizeof(g_szObjetiveEnts);
		entity_get_string(iEntity, EV_SZ_classname, szClassName, charsmax(szClassName));
	
		for(new i = 0; i < iSize; i++)
		{
			if(equal(szClassName, g_szObjetiveEnts[i]))
			{
				remove_entity(iEntity);
				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}