#include <amxmodx>
#include "includes/ttt_shop"
#include "includes/ttt_core"
#include <reapi>
#include <cstrike>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:USP_MODELS{
	USP_V_MODEL, USP_P_MODEL, USP_W_MODEL
}

new szSilencedUspModels[USP_MODELS][] = {
	"models/ttt/v_silencedusp.mdl", "models/ttt/p_silencedusp.mdl", "models/ttt/w_silencedusp.mdl"
};

new const szWeaponName[] = "weapon_usp";
const WeaponIdType:WEAPON_ID = WEAPON_USP;

const WEAPON_UID = 136;

new g_iItemSilencedUsp, g_bHaveSilencedUsp;

const Float:USP_EXTRA_DAMAGE = 20.0;

public plugin_init(){
	register_plugin("Item: Usp", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);
	//RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fwdPrimary_Attack_Post", true);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "fwdPlayerKilled_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);

	register_clcmd("drop", "clcmd_Drop");
}

public plugin_precache(){
	g_iItemSilencedUsp = ttt_register_item("Usp Silenciosa", STATUS_TRAITOR, 2, 0);

	for(new i; i < sizeof(szSilencedUspModels); i++) precache_model(szSilencedUspModels[i]);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveSilencedUsp, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemSilencedUsp) return;

	SetPlayerBit(g_bHaveSilencedUsp, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 10);
	rg_set_user_ammo(iId, WEAPON_ID, 10);
	rg_set_user_bpammo(iId, WEAPON_ID, 50);
	cs_set_weapon_silen(iWeapon, 1);
	set_member(iWeapon, m_Weapon_bSecondarySilencerOn, true);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveSilencedUsp, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveSilencedUsp, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szSilencedUspModels[USP_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szSilencedUspModels[USP_P_MODEL]);
}

/*
public fwdPrimary_Attack_Post(const iWeaponEnt){
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveSilencedUsp, iOwner)) return;

	set_member(iWeaponEnt, m_Weapon_flNextPrimaryAttack, 0.9);
}*/

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveSilencedUsp, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szSilencedUspModels[USP_W_MODEL]);
	}
}

public fwdPlayerKilled_Pre(const iVictim, const iAttacker, const iGib)
	if(GetPlayerBit(g_bHaveSilencedUsp, iAttacker) && get_user_weapon(iAttacker) == CSW_USP)
		ttt_update_statistic(iAttacker, USP_KILLS);

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type)
	if(GetPlayerBit(g_bHaveSilencedUsp, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_USP)
		SetHookChainArg(4, ATYPE_FLOAT, ttt_get_damage_by_karma(iAttacker, iVictim, fDamage + USP_EXTRA_DAMAGE));

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon)

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveSilencedUsp, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveSilencedUsp, iId); 
	}

	return HC_CONTINUE;
}

public clcmd_Drop(const iId){
	if(GetPlayerBit(g_bHaveSilencedUsp, iId) && is_user_alive(iId) && get_user_weapon(iId) == CSW_USP) return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
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