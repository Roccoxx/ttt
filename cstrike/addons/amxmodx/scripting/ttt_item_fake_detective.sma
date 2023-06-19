#include <amxmodx>
#include <reapi>
#include <ttt_shop>
#include <ttt_core>

const MAX_FAKE_DETECTIVE = 1;
const ITEM_COST = 2;

new g_iItemFakeDetective, g_iFakeDetectiveCount;

public plugin_init(){
	register_plugin("TTT: Fake Detective", "1.0", "Roccoxx");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
}

public plugin_precache(){
	g_iItemFakeDetective = ttt_register_item("Falso detective", STATUS_TRAITOR, ITEM_COST, 0);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) g_iFakeDetectiveCount = 0;

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemFakeDetective) return;

	if(g_iFakeDetectiveCount >= MAX_FAKE_DETECTIVE){
		client_print_color(iId, iId, "%s Ya se compro un falso detective esta ronda!", szModPrefix);
		ttt_set_user_credits(iId, ttt_get_user_credits(iId) + ITEM_COST);
		return;
	}

	ttt_update_statistic(iId, FALSE_DETECTIVE_BUYS); ttt_check_achievement_type(iId, Achievement_type_fake_detective);
	rg_set_user_rendering(iId, kRenderFxGlowShell, {0.0, 50.0, 255.0}, kRenderNormal, 30.0);
	g_iFakeDetectiveCount++;
}

stock rg_set_user_rendering(index, fx = kRenderFxNone, {Float,_}:color[3] = {0.0,0.0,0.0}, render = kRenderNormal, Float:amount = 0.0)
{
	set_entvar(index, var_renderfx, fx);
	set_entvar(index, var_rendercolor, color);
	set_entvar(index, var_rendermode, render);
	set_entvar(index, var_renderamt, amount);
}