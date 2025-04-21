#include <amxmodx>
#include "includes/ttt_shop"
#include "includes/ttt_core"
#include <reapi>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

new g_iItemDisguiser, g_bHaveDisguiser;
new Float:g_fDelayDisguiserTime[33];

new const szSoundBuyDisguiser[] = "ttt/camouflage.wav";

public plugin_init(){
	register_plugin("TTT: Item Camuflaje", "1.0", "Roccoxx");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
}

public plugin_precache(){
	g_iItemDisguiser = ttt_register_item("Camuflaje", STATUS_TRAITOR, 1, 1);

	precache_sound(szSoundBuyDisguiser);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveDisguiser, iId);
	g_fDelayDisguiserTime[iId] = 0.0;
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveDisguiser, i);
		g_fDelayDisguiserTime[i] = 0.0;
	}
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemDisguiser) return;
	
	client_cmd(iId, "spk ^"%s^"", szSoundBuyDisguiser);
}

public ttt_inventory_item_selected(const iId, const iItem){
	if(iItem != g_iItemDisguiser) return;

	SetPlayerBit(g_bHaveDisguiser, iId);
	ShowMenuDisguiser(iId);
}

ShowMenuDisguiser(const iId){
	if(!is_user_alive(iId) || !GetPlayerBit(g_bHaveDisguiser, iId)) return PLUGIN_HANDLED;

	new iMenu = menu_create("\rTTT \wAcercate a un cuerpo para cambiar el nombre", "MenuDisguiser");

	menu_additem(iMenu, "Reajustar nombre", "1");
	menu_additem(iMenu, "Quedarme sin nombre^n", "2");

	new szName[32]; ttt_get_user_fake_name(iId, szName, charsmax(szName));
	menu_addtext(iMenu, fmt("Nombre actual: %s", szName), 0);

	menu_display(iId, iMenu);
	return PLUGIN_HANDLED;
}

public MenuDisguiser(const iId, const iMenu, const iItemNum){
	if(iItemNum == MENU_EXIT || !is_user_alive(iId) || !GetPlayerBit(g_bHaveDisguiser, iId)){
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new Float:fGameTime; fGameTime = get_gametime();
	
	if(g_fDelayDisguiserTime[iId] >= fGameTime){
		client_print_color(iId, iId, "%s Espera %.2f segundos para volver a usar el camuflaje!", szModPrefix, g_fDelayDisguiserTime[iId] - fGameTime);
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	if(iItemNum){
		g_fDelayDisguiserTime[iId] = fGameTime + 10.0;

		ttt_set_user_fake_name(iId, "");
	}
	else{
		new iEnt = ttt_find_body(iId);

		if(iEnt > 0)
		{
			new iOwner = get_entvar(iEnt, var_owner);

			new szName[32]; ttt_get_body_name(iOwner, szName, charsmax(szName));

			ttt_set_user_fake_name(iId, szName);

			g_fDelayDisguiserTime[iId] = fGameTime + 10.0;
		}
		else
			client_print_color(iId, iId, "%s Acercate a un cuerpo para usar el camuflaje!", szModPrefix);
	}

	menu_destroy(iMenu);
	ShowMenuDisguiser(iId);
	return PLUGIN_HANDLED;
}