#include <amxmodx>
#include <reapi>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define station_charge var_iuser1
#define station_status var_iuser2

enum _:STATIONS_TYPE{
	STATION_TRAITOR,
	STATION_DETECTIVE
}

new const szStationModel[] = "models/ttt/hpbox.mdl";
new const szStationClassName[] = "tttstation"; 

new const szHealSprite[] = "sprites/restore_health.spr";

const TASK_HEALING = 12344321;
#define ID_HEALING (taskid - TASK_HEALING)

new g_iItemsId[STATIONS_TYPE], g_iMsgStatusIcon, iHealSprite, g_iModelIndex;

new Float:g_fWaitTime[33];

public plugin_init(){
	register_plugin("[TTT] Item: Stations", "1.0", "GuskiS & Roccoxx");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);

	register_forward(FM_EmitSound, "fwdEmitSound_Pre", false);
	register_forward(FM_AddToFullPack, "fwdAddToFullPack_Post", true);

	g_iMsgStatusIcon = get_user_msgid("StatusIcon");
}

public plugin_precache(){
	g_iItemsId[STATION_TRAITOR] = ttt_register_item("Estacion de muerte", STATUS_TRAITOR, 2, 1);
	g_iItemsId[STATION_DETECTIVE] = ttt_register_item("Kit medico", STATUS_DETECTIVE, 2, 1);

	g_iModelIndex = precache_model(szStationModel);

	iHealSprite = precache_model(szHealSprite);
}

public client_disconnected(iId){
	g_fWaitTime[iId] = 0.0;
	remove_task(iId+TASK_HEALING);
}

public ttt_inventory_item_selected(const iId, const iItem){
	if(iItem != g_iItemsId[STATION_TRAITOR] && iItem != g_iItemsId[STATION_DETECTIVE]) return;

	new iPlayerViewOrigin[3]; get_user_origin(iId, iPlayerViewOrigin, 3);
	new Float:fPlayerViewOrigin[3]; IVecFVec(iPlayerViewOrigin, fPlayerViewOrigin);

	new Float:fPlayerOrigin[3]; get_entvar(iId, var_origin, fPlayerOrigin);

	if(40.0 < get_distance_f(fPlayerOrigin, fPlayerViewOrigin) < 100.0)
		CreateStation(fPlayerViewOrigin, iItem == g_iItemsId[STATION_TRAITOR] ? STATION_TRAITOR : STATION_DETECTIVE, iId, iItem);
	else
		client_print_color(iId, iId, "%s Estas colocando la estacion muy lejos o muy cerca tuyo!", szModPrefix);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{	
	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(is_user_connected(i)){
			remove_task(i+TASK_HEALING);
			RemoveStations();
		}
	}
}

public fwdAddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	// !IsPlayer(host) Siempre va a ser un player.
	if(!get_orig_retval()) return FMRES_IGNORED;

	if(player || host == ent) return FMRES_IGNORED;

	if(ttt_get_user_status(host) != STATUS_TRAITOR) return FMRES_IGNORED;

	static szClassName[32]; get_entvar(ent, var_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, szStationClassName)){
		if(get_entvar(ent, station_status) == STATION_DETECTIVE){
			set_es(es, ES_RenderFx, kRenderFxGlowShell);
			set_es(es, ES_RenderColor, {0, 50, 255});
			set_es(es, ES_RenderAmt, 30);
		}
		else{
			set_es(es, ES_RenderFx, kRenderFxGlowShell);
			set_es(es, ES_RenderColor, {255, 50, 0});
			set_es(es, ES_RenderAmt, 30);
		}
	}
	
	return FMRES_IGNORED;
}

public fwdEmitSound_Pre(const iId, const iChannel, const szSample[])
{
	if(!is_user_alive(iId) || ttt_is_round_end()) return;

	if(g_fWaitTime[iId] < get_gametime() && equal(szSample, "common/wpn_denyselect.wav"))
	{
		if(get_user_health(iId) >= 100) return;

		new iEnt = IsAimingAt(iId, 50.0, szStationClassName);

		if(iEnt > 0){
			new iStationStatus = get_entvar(iEnt, station_status);

			if(iStationStatus == STATION_DETECTIVE){
				new iArray[1]; iArray[0] = iEnt; set_task(0.1, "HealUser", iId+TASK_HEALING, iArray, 1, "b");
				ShowHealEffects(iId);
			}
			else{
				new iUserStatus = ttt_get_user_status(iId);

				if(iUserStatus == STATUS_TRAITOR){
					new iCharge = get_entvar(iEnt, station_charge);

					if(iCharge > 0){
						new iArray[1]; iArray[0] = iEnt; set_task(0.1, "HealUser", iId+TASK_HEALING, iArray, 1, "b");
						ShowHealEffects(iId);
					}
				}
				else{
					new iOwner = get_entvar(iEnt, var_owner);
					ExecuteHamB(Ham_Killed, iId, iOwner, 2);
					ttt_update_statistic(iOwner, STATION_KILLS);
				}
			}
		}

		g_fWaitTime[iId] = get_gametime() + 1.0;
	}
}

public HealUser(iArray[], taskid){
	if(!is_user_alive(ID_HEALING)){
		remove_task(taskid);
		return;
	}

	new Float:fHealth = Float:get_entvar(ID_HEALING, var_health);

	if(fHealth >= 100.0){
		remove_task(taskid);
		return;
	}

	new iEnt = iArray[0];

	if(!is_entity(iEnt)){
		remove_task(taskid);
		return;
	}

	new szClassName[32]; get_entvar(iEnt, var_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, szStationClassName)){
		remove_task(taskid);
		return;
	}

	new iCharge = get_entvar(iEnt, station_charge);

	if(iCharge <= 0){
		if(get_entvar(iEnt, station_status) == STATION_DETECTIVE) set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
		
		remove_task(taskid);
		return;
	}

	set_entvar(ID_HEALING, var_health, fHealth + 1.0);
	set_entvar(iEnt, station_charge, (iCharge - 1));
}

CreateStation(const Float:fOrigin[3], const iStatus, const iOwner, const iItem)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt))
		return;

	set_entvar(iEnt, var_classname, szStationClassName);
	//set_entvar(iEnt, var_model, szStationModel);
	set_entvar(iEnt, var_modelindex, g_iModelIndex);
	new Float:fMins[3] = {-5.0, -5.0, 0.0 };
	new Float:fSize[3]; math_mins_maxs(fMins, Float:{ 5.0, 5.0, 5.0 }, fSize);
	set_entvar(iEnt, var_size, fSize);
	set_entvar(iEnt, var_solid, SOLID_BBOX);
	set_entvar(iEnt, var_movetype, MOVETYPE_FLY);

	set_entvar(iEnt, var_origin, fOrigin);
	set_entvar(iEnt, station_status, iStatus);
	set_entvar(iEnt, station_charge, iStatus == STATION_DETECTIVE ? random_num(50, 200) : 25);
	set_entvar(iEnt, var_owner, iOwner);
	
	drop_to_floor(iEnt);

	set_entvar(iEnt, var_renderfx, kRenderFxGlowShell);
	new Float:fColors[3]; fColors[0] = random_float(1.0, 255.0); fColors[1] = random_float(1.0, 255.0); fColors[2] = random_float(1.0, 255.0);
	set_entvar(iEnt, var_rendercolor, fColors);

	ttt_remove_item_from_inventory(iOwner, iItem);
}

RemoveStations(){
	new iEnt = NULLENT;

	while((iEnt = rg_find_ent_by_class(iEnt, szStationClassName)))
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
}

ShowHealEffects(const iId){
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusIcon, {0,0,0}, iId);
	write_byte(1);
	write_string("cross");
	write_byte(0);
	write_byte(255);
	write_byte(0);
	message_end();

	message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusIcon, {0,0,0}, iId);
	write_byte(0);
	write_string("cross");
	message_end();

	new iOrigin[3]; get_user_origin(iId, iOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin, 0);
	write_byte(TE_SPRITE);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	//ANTES write_coord(iOrigin[2]+65);
	write_coord(iOrigin[2]+20);
	write_short(iHealSprite);
	write_byte(10);
	write_byte(250);
	message_end();
}

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

math_mins_maxs(const Float:mins[3], const Float:maxs[3], Float:size[3])
{
    size[0] = (xs_fsign(mins[0]) * mins[0]) + maxs[0]; size[1] = (xs_fsign(mins[1]) * mins[1]) + maxs[1]; size[2] = (xs_fsign(mins[2]) * mins[2]) + maxs[2];
}

stock xs_fsign(Float:num) return (num < 0.0) ? -1 : ((num == 0.0) ? 0 : 1);