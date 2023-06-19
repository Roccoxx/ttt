#include <amxmodx>
#include <ttt_shop>
#include <ttt_core>
#include <reapi>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:GOLDEN_MODELS{
	GOLDEN_V_MODEL, GOLDEN_P_MODEL, GOLDEN_W_MODEL
}

new szGoldenModels[GOLDEN_MODELS][] = {
	"models/ttt/v_golden2.mdl", "models/ttt/p_golden2.mdl", "models/ttt/w_golden2.mdl"
};

new const szWeaponName[] = "weapon_deagle";
const WeaponIdType:WEAPON_ID = WEAPON_DEAGLE;

const WEAPON_UID = 133;

new g_iItemGolden, g_bHaveGolden;

public plugin_init(){
	register_plugin("Item: Golden", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);
}

public plugin_precache(){
	g_iItemGolden = ttt_register_item("Golden", STATUS_DETECTIVE, 2, 0);

	for(new i; i < sizeof(szGoldenModels); i++) precache_model(szGoldenModels[i]);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveGolden, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemGolden) return;

	SetPlayerBit(g_bHaveGolden, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
	rg_set_user_ammo(iId, WEAPON_ID, 1);
	rg_set_user_bpammo(iId, WEAPON_ID, 0);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveGolden, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveGolden, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szGoldenModels[GOLDEN_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szGoldenModels[GOLDEN_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveGolden, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szGoldenModels[GOLDEN_W_MODEL]);
	}
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveGolden, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_DEAGLE){
		switch(ttt_get_user_status(iVictim)){
			case STATUS_INNOCENT: rg_set_user_rendering(iVictim, kRenderFxGlowShell, {0.0, 255.0, 0.0}, kRenderNormal, 30.0);
			case STATUS_TRAITOR:{
				ExecuteHamB(Ham_Killed, iVictim, iAttacker, 2);
				ttt_update_statistic(iAttacker, GOLDEN_KILLS);
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

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon)

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveGolden, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveGolden, iId); 
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