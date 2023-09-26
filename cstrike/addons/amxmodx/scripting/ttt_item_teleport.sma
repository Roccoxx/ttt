#include <amxmodx>
#include "ttt/ttt_shop"
#include <reapi>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

new const Float:g_flVelocity[ ] = { 0.0, 0.0, 16.0 };

new const szSoundTeleport[] = "ttt/transportar.wav";

new g_iItemTeleport, g_bHaveTeleport;
new Float:g_fDelayTeleportTime[33], Float:g_fTeleportOrigin[33][3];

public plugin_init(){
	register_plugin("Item: Teleport", "1.0", "Gusk1s");
	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
}

public plugin_precache(){
	g_iItemTeleport = ttt_register_item("Teletransportador", STATUS_DETECTIVE, 1, 1);

	precache_sound(szSoundTeleport);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveTeleport, iId);
	g_fDelayTeleportTime[iId] = 0.0;
	g_fTeleportOrigin[iId] = Float:{0.0, 0.0, 0.0};
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveTeleport, i);
		g_fDelayTeleportTime[i] = 0.0;
		g_fTeleportOrigin[i] = Float:{0.0, 0.0, 0.0};
	}
}

public ttt_inventory_item_selected(const iId, const iItem){
	if(iItem != g_iItemTeleport) return;

	SetPlayerBit(g_bHaveTeleport, iId);
	ShowMenuTeleport(iId);
}

ShowMenuTeleport(const iId){
	if(!is_user_alive(iId) || !GetPlayerBit(g_bHaveTeleport, iId)) return PLUGIN_HANDLED;

	new iMenu = menu_create("\rTTT \wTeleport Menu", "MenuTeleport");

	menu_additem(iMenu, "Guardar ubicacion", "1");
	
	if(g_fTeleportOrigin[iId][0] != 0.0 && g_fTeleportOrigin[iId][1] != 0.0 && g_fTeleportOrigin[iId][2] != 0.0)
		menu_additem(iMenu, fmt("Teletransportar a ubicacion X:%.2f Y:%.2f Z:%.2f", g_fTeleportOrigin[iId][0], g_fTeleportOrigin[iId][1], g_fTeleportOrigin[iId][2]), "2");

	menu_display(iId, iMenu);
	return PLUGIN_HANDLED;
}

public MenuTeleport(const iId, const iMenu, const iItemNum){
	if(iItemNum == MENU_EXIT || !is_user_alive(iId) || !GetPlayerBit(g_bHaveTeleport, iId)){
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new Float:fGameTime; fGameTime = get_gametime();
	
	if(g_fDelayTeleportTime[iId] >= fGameTime){
		client_print_color(iId, iId, "%s Espera %.2f segundos para volver a usar el teleport!", szModPrefix, g_fDelayTeleportTime[iId] - fGameTime);
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	if(iItemNum){
		if(g_fTeleportOrigin[iId][0] == 0.0 && g_fTeleportOrigin[iId][1] == 0.0 && g_fTeleportOrigin[iId][2] == 0.0){
			client_print_color(iId, iId, "%s Guarda una ubicacion primero!", szModPrefix);
			menu_destroy(iMenu);
			return PLUGIN_HANDLED;
		}

		emit_sound(iId, CHAN_VOICE, szSoundTeleport, 1.0, ATTN_NORM, 0, PITCH_NORM);

		new iOrigin[3]; get_user_origin(iId, iOrigin);

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_byte(128);
		write_byte(20);
		write_byte(3);
		message_end();

		g_fDelayTeleportTime[iId] = fGameTime + 10.0;

		set_entvar(iId, var_velocity, g_flVelocity);
		set_entvar(iId, var_gravity, 0.0);
		set_entvar(iId, var_origin, g_fTeleportOrigin[iId]);
		set_entvar(iId, var_gravity, 1.0);

		client_print_color(iId, iId, "%s Has sido teletransportado a ^3x%0.1f y%0.1f z%0.1f^1!", 
		szModPrefix, g_fTeleportOrigin[iId][0], g_fTeleportOrigin[iId][1], g_fTeleportOrigin[iId][2]);

		emit_sound(iId, CHAN_VOICE, szSoundTeleport, 1.0, ATTN_NORM, 0, PITCH_NORM);

		FVecIVec(g_fTeleportOrigin[iId], iOrigin);

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_byte(128);
		write_byte(20);
		write_byte(3);
		message_end();
	}
	else{
		g_fDelayTeleportTime[iId] = fGameTime + 1.0;
		get_entvar(iId, var_origin, g_fTeleportOrigin[iId]);
		client_print_color(iId, iId, "%s Ubicacion guardada!", szModPrefix);
	}

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}