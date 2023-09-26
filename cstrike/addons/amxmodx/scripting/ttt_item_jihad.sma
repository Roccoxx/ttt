#include <amxmodx>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <engine>
#include <hamsandwich>

enum _:JIHAD_SOUNDS{
	JIHAD_EXPLODE,
	JIHAD_HEY
}

new const szJiHadSounds[JIHAD_SOUNDS][] = {
	"ttt/jihad.wav",
	"ttt/heyoverhere.wav"
}

const Float:JIHAD_DAMAGE = 400.0;
const Float:JIHAD_RADIUS = 300.0;
const Float:JIHAD_TIMER = 3.0;

const TASK_JIHAD = 20312031;
#define ID_JIHAD (taskid-TASK_JIHAD)

new g_iItemJiHad, g_iMenuJiHad;

new Float:g_fSoundPlaying[33];

public plugin_init(){
	register_plugin("TTT item: Jihad", "1.0", "Roccoxx");

	RegisterHam(Ham_Killed, "player", "fwdPlayerKilled_Pre");

	ShowMenuJiHad();
}

public plugin_precache(){
	g_iItemJiHad = ttt_register_item("JiHad", STATUS_TRAITOR, 2, 1);

	for(new i; i < JIHAD_SOUNDS; i++) precache_sound(szJiHadSounds[i]);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem == g_iItemJiHad){
		new szName[32]; get_user_name(iId, szName, charsmax(szName));

		log_amx("%s El jugador^4 %s^1 ha comprado un JiHad!", szModPrefix, szName);

		for(new i = 1; i <= MAX_PLAYERS; i++){
			if(!is_user_connected(i) || ttt_get_user_status(i) != STATUS_TRAITOR) continue;

			client_print_color(i, print_team_default, "%s El jugador^4 %s^1 ha comprado un JiHad!", szModPrefix, szName);
		}
	}
}

public ttt_inventory_item_selected(const iId, const iItem){
	if(iItem == g_iItemJiHad)
		menu_display(iId, g_iMenuJiHad);
}

public client_disconnected(iId){
	remove_task(iId+TASK_JIHAD);
}

public fwdPlayerKilled_Pre(const iVictim, const iAttacker, const iShouldgib)
{
	remove_task(iVictim+TASK_JIHAD);
}

ShowMenuJiHad(){
	g_iMenuJiHad = menu_create("\yMenu Jihad", "MenuJiHad");

	menu_additem(g_iMenuJiHad, "Explotar"); menu_additem(g_iMenuJiHad, "Emitir Sonido");

	menu_setprop(g_iMenuJiHad, MPROP_EXITNAME, "Salir");	
}

public MenuJiHad(const iId, const iMenu, const iItem){
	if(!is_user_connected(iId) || iItem == MENU_EXIT) return PLUGIN_HANDLED;

	if(!iItem){
		// BUM
		emit_sound(iId, CHAN_AUTO, szJiHadSounds[JIHAD_EXPLODE], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_task(JIHAD_TIMER, "Explode", iId+TASK_JIHAD);
	}
	else{
		new Float:fGameTime = get_gametime();
		if(g_fSoundPlaying[iId] < fGameTime)
		{
			g_fSoundPlaying[iId] = fGameTime+1.0;
			emit_sound(iId, CHAN_AUTO, szJiHadSounds[JIHAD_HEY], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	return PLUGIN_HANDLED;
}

public Explode(taskid){
	new iOrigin[3]; get_user_origin(ID_JIHAD, iOrigin, 0);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TAREXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	message_end();

	new Float:fOrigin[3]; IVecFVec(iOrigin, fOrigin);
	new iVictim = -1;
	new Float:fDamage;

	while((iVictim = find_ent_in_sphere(iVictim, fOrigin, JIHAD_RADIUS)) != 0){
		if(is_user_alive(iVictim) && iVictim != ID_JIHAD){
			fDamage = (JIHAD_DAMAGE/JIHAD_RADIUS) * (JIHAD_RADIUS - entity_range(ID_JIHAD, iVictim));

			if(fDamage > 0.0){
				new Float:fHealth; fHealth = entity_get_float(iVictim, EV_FL_health);
				if(fHealth > fDamage){
					ExecuteHamB(Ham_TakeDamage, iVictim, ID_JIHAD, ID_JIHAD, fDamage, DMG_BLAST);
					ttt_fix_user_freeshots(ID_JIHAD);
				}
				else{
					ExecuteHamB(Ham_Killed, iVictim, ID_JIHAD, 0);
					ttt_update_statistic(ID_JIHAD, JIHAD_KILLS); ttt_check_achievement_type(ID_JIHAD, Achievement_type_kills);
				}
			}
		}
	}

	ExecuteHamB(Ham_Killed, ID_JIHAD, ID_JIHAD, 0);
}