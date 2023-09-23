#include <amxmodx>
#include "includes/ttt_shop"
#include "includes/ttt_core"
#include <reapi>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:UNMARKER_MODELS{
	UNMARKER_V_MODEL, UNMARKER_P_MODEL, UNMARKER_W_MODEL
}

new szUnMarkerModels[UNMARKER_MODELS][] = {
	"models/ttt/v_unmarker.mdl", "models/p_deagle.mdl", "models/ttt/w_unmarker.mdl"
};

new const szWeaponName[] = "weapon_deagle";
const WeaponIdType:WEAPON_ID = WEAPON_DEAGLE;

const WEAPON_UID = 137;

new g_iItemUnMarker, g_bHaveUnMarker;

new const szUnMarkerSound[] = "ttt/desmarcar.wav";

// SI CAMBIAS EL MODELO BORRAR ESTO
new const szModelSounds[][] = {
	"weapons/ja_clipin.wav",
	"weapons/ja_clipout.wav",
	"weapons/ja_deploy.wav",
	"weapons/ja_sliderelease.wav"
}

public plugin_init(){
	register_plugin("Item: UnMarker", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);
}

public plugin_precache(){
	g_iItemUnMarker = ttt_register_item("UnMarker", STATUS_TRAITOR, 2, 0);

	new i;

	for(i = 0; i < sizeof(szUnMarkerModels); i++) precache_model(szUnMarkerModels[i]);
	for(i = 0; i < sizeof(szModelSounds); i++) precache_sound(szModelSounds[i]);

	precache_sound(szUnMarkerSound);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveUnMarker, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemUnMarker) return;

	SetPlayerBit(g_bHaveUnMarker, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
	rg_set_user_ammo(iId, WEAPON_ID, 1);
	rg_set_user_bpammo(iId, WEAPON_ID, 0);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveUnMarker, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveUnMarker, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szUnMarkerModels[UNMARKER_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szUnMarkerModels[UNMARKER_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveUnMarker, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szUnMarkerModels[UNMARKER_W_MODEL]);
	}
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveUnMarker, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_DEAGLE){
		if(ttt_get_user_status(iAttacker) != STATUS_TRAITOR) ExecuteHamB(Ham_Killed, iAttacker, iAttacker, 2);
		else{
			if(ttt_get_user_status(iVictim) == STATUS_TRAITOR){
				rg_set_user_rendering(iVictim);
				ttt_update_statistic(iAttacker, PLAYERS_UNMARKED); ttt_check_achievement_type(iAttacker, Achievement_type_unmarked);
				client_cmd(iAttacker, "spk ^"%s^"", szUnMarkerSound);
			}
			else{
				rg_set_user_ammo(iAttacker, WEAPON_ID, 1);
				client_print_color(iAttacker, iAttacker, "%s Esta arma solo puede desmarcar traidores!", szModPrefix);
			}
		}

		ttt_fix_user_freeshots(iAttacker);
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon);

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveUnMarker, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveUnMarker, iId); 
	}

	return HC_CONTINUE;
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

stock rg_set_user_rendering(index, fx = kRenderFxNone, {Float,_}:color[3] = {0.0,0.0,0.0}, render = kRenderNormal, Float:amount = 0.0)
{
	set_entvar(index, var_renderfx, fx);
	set_entvar(index, var_rendercolor, color);
	set_entvar(index, var_rendermode, render);
	set_entvar(index, var_renderamt, amount);
}