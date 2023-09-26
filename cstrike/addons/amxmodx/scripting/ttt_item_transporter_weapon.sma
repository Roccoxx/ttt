#include <amxmodx>
#include <amxmisc>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <hamsandwich>
#include <reapi>
#include <fakemeta>

#pragma semicolon 1

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:TRANSPORTER_MODELS{
	TRANSPORTER_V_MODEL, TRANSPORTER_P_MODEL, TRANSPORTER_W_MODEL
}

new szTransporterModels[TRANSPORTER_MODELS][] = {
	"models/ttt/v_transportadora.mdl", "models/p_deagle.mdl", "models/ttt/w_transportadora.mdl"
};

new const szSoundTeleport[] = "ttt/transportar.wav";

new const szWeaponName[] = "weapon_deagle";
const WeaponIdType:WEAPON_ID = WEAPON_DEAGLE;

const WEAPON_UID = 139;
const Float:TELEPORTER_DAMAGE = 20.0;
const MAX_CSDM_SPAWNS = 128;
const Float:TELEPORT_DISTANCE = 500.0;

new g_iItemTransporter, g_bHaveTransporter, g_iSpawnsCount, Float:g_fSpawnsOrigin[MAX_CSDM_SPAWNS][3];

public plugin_init(){
	register_plugin("Item: Arma transportadora", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);

	LoadSpawns();
}

public plugin_precache(){
	g_iItemTransporter = ttt_register_item("Arma transportadora", STATUS_TRAITOR, 1, 0);

	for(new i; i < sizeof(szTransporterModels); i++) precache_model(szTransporterModels[i]);

	precache_sound(szSoundTeleport);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveTransporter, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemTransporter) return;

	SetPlayerBit(g_bHaveTransporter, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
	rg_set_user_ammo(iId, WEAPON_ID, 1);
	rg_set_user_bpammo(iId, WEAPON_ID, 0);

	client_print_color(iId, iId, "%s Has comprado la transportadora!", szModPrefix);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveTransporter, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveTransporter, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szTransporterModels[TRANSPORTER_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szTransporterModels[TRANSPORTER_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveTransporter, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szTransporterModels[TRANSPORTER_W_MODEL]);
	}
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveTransporter, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_DEAGLE){
		SetHookChainArg(4, ATYPE_FLOAT, TELEPORTER_DAMAGE);
		
		ttt_fix_user_freeshots(iAttacker);
		
		client_print_color(iVictim, iVictim, "%s te han disparado con transportadora!", szModPrefix);
		emit_sound(iVictim, CHAN_VOICE, szSoundTeleport, 1.0, ATTN_NORM, 0, PITCH_NORM);

		new iOrigin[3]; get_user_origin(iVictim, iOrigin);

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_TELEPORT);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		message_end();

		TeleporterToRandomOrigin(iVictim, iAttacker);
	}
}

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon);

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveTransporter, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveTransporter, iId); 
	}

	return HC_CONTINUE;
}

TeleporterToRandomOrigin(const iVictim, const iAttacker){
	if(!g_iSpawnsCount) return;

	new iHull = (get_entvar(iVictim, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	new Float:iVictimOrigin[3]; get_entvar(iAttacker, var_origin, iVictimOrigin);
	new iSpawnIndex, iLoops;

	while(iLoops < 50){
		iSpawnIndex = random_num(0, g_iSpawnsCount - 1);

		if(!is_hull_vacant(g_fSpawnsOrigin[iSpawnIndex], iHull)) continue;

		if(++iLoops >= 50){
			set_entvar(iVictim, var_origin, g_fSpawnsOrigin[iSpawnIndex]);

			new iOrigin[3]; FVecIVec(g_fSpawnsOrigin[iSpawnIndex], iOrigin);

			message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
			write_byte(TE_TELEPORT);
			write_coord(iOrigin[0]);
			write_coord(iOrigin[1]);
			write_coord(iOrigin[2]);
			message_end();

			emit_sound(iVictim, CHAN_VOICE, szSoundTeleport, 1.0, ATTN_NORM, 0, PITCH_NORM);
			break;
		}

		if(get_distance_f(iVictimOrigin, g_fSpawnsOrigin[iSpawnIndex]) < TELEPORT_DISTANCE) continue;

		set_entvar(iVictim, var_origin, g_fSpawnsOrigin[iSpawnIndex]);

		new iOrigin[3]; FVecIVec(g_fSpawnsOrigin[iSpawnIndex], iOrigin);

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_TELEPORT);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		message_end();

		emit_sound(iVictim, CHAN_VOICE, szSoundTeleport, 1.0, ATTN_NORM, 0, PITCH_NORM);

		iLoops = 50;
		break;
	}
}

LoadSpawns()
{
	new cfgdir[32], mapname[32], filepath[100]; get_configsdir(cfgdir, charsmax(cfgdir)); get_mapname(mapname, charsmax(mapname));
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname);
	
	if (file_exists(filepath))
	{
		new linedata[64];
		new csdmdata[10][6], file = fopen(filepath,"rt");
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata));
			
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5);
			
			g_fSpawnsOrigin[g_iSpawnsCount][0] = floatstr(csdmdata[0]);
			g_fSpawnsOrigin[g_iSpawnsCount][1] = floatstr(csdmdata[1]);
			g_fSpawnsOrigin[g_iSpawnsCount][2] = floatstr(csdmdata[2]);
			
			g_iSpawnsCount++;
			if (g_iSpawnsCount >= sizeof g_fSpawnsOrigin) break;
		}
		if (file) fclose(file);
	}
	else
	{
		CollectSpawnsEnts("info_player_start");
		CollectSpawnsEnts("info_player_deathmatch");
	}
}

CollectSpawnsEnts(const szClassname[])
{
	new iEnt = NULLENT;

	while((iEnt = rg_find_ent_by_class(iEnt, szClassname, true))){
		new Float:fOriginF[3]; get_entvar(iEnt, var_origin, fOriginF);
		g_fSpawnsOrigin[g_iSpawnsCount][0] = fOriginF[0]; g_fSpawnsOrigin[g_iSpawnsCount][1] = fOriginF[1]; g_fSpawnsOrigin[g_iSpawnsCount][2] = fOriginF[2];
		g_iSpawnsCount++;
		if (g_iSpawnsCount >= sizeof g_fSpawnsOrigin) break;
	}
}

stock func_GetWeaponBoxWeapon(const iWeaponBox)
{
    for(new i, iWeapon; i < MAX_ITEM_TYPES; i++)
    {
        iWeapon = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, i);
        if(!is_nullent(iWeapon))
            return iWeapon;
    }
    return NULLENT;
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str);
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++;
	}
	
	return count;
}