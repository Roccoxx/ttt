#include <amxmodx>
#include <ttt_shop>
#include <ttt_core>
#include <reapi>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:AWP_MODELS{
	AWP_V_MODEL, AWP_P_MODEL, AWP_W_MODEL
}

new szAwpModels[AWP_MODELS][] = {
	"models/v_awp.mdl", "models/p_awp.mdl", "models/w_awp.mdl"
};

new const szWeaponName[] = "weapon_awp";
const WeaponIdType:WEAPON_ID = WEAPON_AWP;

const WEAPON_UID = 135;

new g_iItemAwp, g_bHaveAwp;

public plugin_init(){
	register_plugin("Item: Awp", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
}

public plugin_precache(){
	g_iItemAwp = ttt_register_item("AWP", STATUS_TRAITOR, 1, 0);

	for(new i; i < sizeof(szAwpModels); i++) precache_model(szAwpModels[i]);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveAwp, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemAwp) return;

	SetPlayerBit(g_bHaveAwp, iId);

	rg_remove_item(iId, szWeaponName, false);

	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
	rg_set_user_ammo(iId, WEAPON_ID, 1);
	rg_set_user_bpammo(iId, WEAPON_ID, 15);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveAwp, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveAwp, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szAwpModels[AWP_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szAwpModels[AWP_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveAwp, iOwner); 
		SetHookChainArg(2, ATYPE_STRING, szAwpModels[AWP_W_MODEL]);
	}
}

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon)

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveAwp, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveAwp, iId); 
	}

	return HC_CONTINUE;
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type)
	if(GetPlayerBit(g_bHaveAwp, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_AWP)
		SetHookChainArg(4, ATYPE_FLOAT, ttt_get_damage_by_karma(iAttacker, iVictim, fDamage / 2.0));

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