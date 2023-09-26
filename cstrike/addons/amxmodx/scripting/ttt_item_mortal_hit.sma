#include <amxmodx>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <reapi>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

const TASK_MORTAL = 28102031;
const Float:KILL_TIME = 3.0;

const UNIT_SECOND = (1<<12);
const FFADE_IN = 0x0000;

const ITEM_COST = 1;

#define ID_MORTAL (taskid - TASK_MORTAL)

new const szSoundHitMortal[] = "ttt/hit_mortal.wav";

new g_iItemMortalHit, g_bHaveMortalHit, bool:g_bAlreadyBuyHit;
new g_iMsgScreenFade, g_iMsgScreenShake;

public plugin_init(){
	register_plugin("TTT: Mortal Hit", "1.0", "Roccoxx");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);

	g_iMsgScreenFade = get_user_msgid("ScreenFade");
	g_iMsgScreenShake = get_user_msgid("ScreenShake");
}

public plugin_precache(){
	g_iItemMortalHit = ttt_register_item("Hit Mortal", STATUS_TRAITOR, ITEM_COST, 0);

	precache_sound(szSoundHitMortal);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveMortalHit, iId);
	remove_task(iId+TASK_MORTAL);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemMortalHit) return;

	if(g_bAlreadyBuyHit){
		ttt_set_user_credits(iId, ttt_get_user_credits(iId) + ITEM_COST);
		client_print_color(iId, iId, "%s Un jugador ya compro el Hit Mortal!", szModPrefix);
		return;
	}

	SetPlayerBit(g_bHaveMortalHit, iId);
	client_print_color(iId, iId, "%s Haz comprado el Hit Mortal!", szModPrefix);
	g_bAlreadyBuyHit = true;
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveMortalHit, i);
		remove_task(i+TASK_MORTAL);
	}

	g_bAlreadyBuyHit = false;
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveMortalHit, iAttacker) && is_user_alive(iVictim) && ttt_get_user_status(iVictim) != STATUS_TRAITOR){
		ClearPlayerBit(g_bHaveMortalHit, iAttacker);
		ttt_update_statistic(iAttacker, MORTAL_HIT_KILLS);

		//emit_sound(iVictim, CHAN_VOICE, szSoundHitMortal, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new iOrigin[3]; get_user_origin(iVictim, iOrigin);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BLOODSTREAM);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_coord(iOrigin[0] + 20);
		write_coord(iOrigin[1] + 20);
		write_coord(iOrigin[2] + 20);
		write_byte(70);
		write_byte(22);
		message_end();

		message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, iVictim);
		write_short(UNIT_SECOND * 3);
		write_short(0);
		write_short(FFADE_IN);
		write_byte(200);
		write_byte(0);
		write_byte(0);
		write_byte(100);
		message_end();

		message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenShake, _, iVictim);
		write_short(UNIT_SECOND*4);
		write_short(UNIT_SECOND*2);
		write_short(UNIT_SECOND*10);
		message_end();

		new iData[1]; iData[0] = iAttacker; set_task(KILL_TIME, "KillUser", iVictim+TASK_MORTAL, iData, 1);
		new szName[32]; get_user_name(iAttacker, szName, charsmax(szName));
		client_print_color(iVictim, iVictim, "%s^4 %s^1 te ha marcado con el hit mortal!", szModPrefix, szName);

		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public KillUser(iData[], taskid){
	if(!is_user_alive(ID_MORTAL)) return;

	new iOrigin[3]; get_user_origin(ID_MORTAL, iOrigin);

	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_LAVASPLASH);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	message_end();

	ExecuteHamB(Ham_Killed, ID_MORTAL, iData[0], 2);
}