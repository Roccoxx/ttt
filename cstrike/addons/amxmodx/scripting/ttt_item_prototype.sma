#include <amxmodx>
#include <ttt_shop>
#include <hamsandwich>
#include <reapi>
#include <ttt_core>
#include <fakemeta>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:PROTOTYPE_MODELS{
	PROTOTYPE_V_MODEL, PROTOTYPE_P_MODEL, PROTOTYPE_W_MODEL
}

new szPrototypeModels[PROTOTYPE_MODELS][] = {
	"models/ttt/v_ump.mdl", "models/ttt/p_ump.mdl", "models/ttt/w_ump.mdl"
};

new const szPrototypeFireSound[] = "ttt/prototype-fire.wav";

new const szWeaponName[] = "weapon_ump45";
const WeaponIdType:WEAPON_ID = WEAPON_UMP45;
const CUMP45_Members:MEMBER_FIRE = m_UMP45_usFire;

const WEAPON_UID = 131;

new g_iItemPrototype, g_bHavePrototype, g_iEventId;

public plugin_init(){
	register_plugin("Item: Ump45 Prototipo", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fwdPrimary_Attack_Post", true);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);

	register_forward(FM_PlaybackEvent, "fwdPlaybackEvent", false);
	register_forward(FM_UpdateClientData, "fw_update_clientdata", 1);
}

public plugin_precache(){
	g_iItemPrototype = ttt_register_item("Ump45 Prototipo", STATUS_DETECTIVE, 1, 0);

	for(new i; i < sizeof(szPrototypeModels); i++) precache_model(szPrototypeModels[i]);

	precache_sound(szPrototypeFireSound);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHavePrototype, iId);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemPrototype) return;

	SetPlayerBit(g_bHavePrototype, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 10);
	rg_set_user_ammo(iId, WEAPON_ID, 10);
	rg_set_user_bpammo(iId, WEAPON_ID, 0);

	if(!g_iEventId) g_iEventId = get_member(iWeapon, MEMBER_FIRE);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHavePrototype, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHavePrototype, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szPrototypeModels[PROTOTYPE_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szPrototypeModels[PROTOTYPE_P_MODEL]);
}

public fwdPrimary_Attack_Post(const iWeaponEnt){
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHavePrototype, iOwner)) return;

	set_member(iWeaponEnt, m_Weapon_flNextPrimaryAttack, 10.0);
	client_print_color(iOwner, iOwner, "%s Espera 10 Segundos para realizar el proximo disparo", szModPrefix);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHavePrototype, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szPrototypeModels[PROTOTYPE_W_MODEL]);
	}
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHavePrototype, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_UMP45){
		new Float:vAngles[3]; get_entvar(iVictim, var_angles, vAngles);

		vAngles[0] += random_float(-fDamage, fDamage); vAngles[1] += random_float(-fDamage, fDamage);
		set_entvar(iVictim, var_angles, vAngles);

		vAngles[2] += random_float(-fDamage, fDamage); set_entvar(iVictim, var_punchangle, vAngles);

		set_entvar(iVictim, var_fixangle, 1);

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

	SetPlayerBit(g_bHavePrototype, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHavePrototype, iId); 
	}

	return HC_CONTINUE;
}

public fwdPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(g_iEventId != eventid || !(1<=invoker<=MAX_PLAYERS) || !GetPlayerBit(g_bHavePrototype, invoker)) return FMRES_IGNORED;

	emit_sound(invoker, CHAN_WEAPON, szPrototypeFireSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return FMRES_SUPERCEDE;
}

public fw_update_clientdata(iId, sendweapons, cd_handle)
{
	if(!is_user_alive(iId) || !GetPlayerBit(g_bHavePrototype, iId)) return FMRES_IGNORED;
	
	if(get_user_weapon(iId) == CSW_UMP45)
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001 ); 
	
	return FMRES_IGNORED;
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