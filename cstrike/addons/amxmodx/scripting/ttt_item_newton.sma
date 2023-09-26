#include <amxmodx>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <hamsandwich>
#include <reapi>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:NEWTON_MODELS{
	NEWTON_V_MODEL, NEWTON_P_MODEL, NEWTON_W_MODEL
}

new szNewtonModels[NEWTON_MODELS][] = {
	"models/ttt/v_newton.mdl", "models/ttt/p_newton.mdl", "models/ttt/w_newton.mdl"
};

new const szWeaponName[] = "weapon_fiveseven";
const WeaponIdType:WEAPON_ID = WEAPON_FIVESEVEN;

const WEAPON_UID = 138;
const Float:NEWTON_FORCE = 200.0;

new g_iItemNewton, g_bHaveNewton;
new g_iPusher[33];

public plugin_init(){
	register_plugin("TTT: Item Newton", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fwdPrimary_Attack_Post", true);
	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);

	register_clcmd("drop", "clcmd_Drop");
}

public plugin_precache(){
	g_iItemNewton = ttt_register_item("Newton", STATUS_TRAITOR, 1, 0);

	for(new i; i < sizeof(szNewtonModels); i++) precache_model(szNewtonModels[i]);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveNewton, iId);
	g_iPusher[iId] = 0;
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemNewton) return;

	SetPlayerBit(g_bHaveNewton, iId);

	rg_remove_item(iId, szWeaponName, false);
	new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

	if(is_nullent(iWeapon)) return;

	rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
	rg_set_user_ammo(iId, WEAPON_ID, 1);
	rg_set_user_bpammo(iId, WEAPON_ID, 10);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveNewton, i);
		g_iPusher[i] = 0;
	}

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveNewton, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szNewtonModels[NEWTON_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szNewtonModels[NEWTON_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveNewton, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szNewtonModels[NEWTON_W_MODEL]);
	}
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if((iDamage_Type & (1<<5)) && g_iPusher[iVictim] != 0){
		if(is_user_connected(g_iPusher[iVictim])) ttt_set_karma_and_fs(g_iPusher[iVictim], iVictim, fDamage);
		
		if(Float:get_entvar(iVictim, var_health) <= fDamage){
			ttt_update_statistic(g_iPusher[iVictim], NEWTON_KILLS); ttt_check_achievement_type(g_iPusher[iVictim], Achievement_type_kills);
			SetHookChainReturn(ATYPE_INTEGER, 0);
			ExecuteHamB(Ham_Killed, iVictim, g_iPusher[iVictim], 2);
			g_iPusher[iVictim] = 0;
			return HC_SUPERCEDE;
		}
		
		g_iPusher[iVictim] = 0;
	}

	if(GetPlayerBit(g_bHaveNewton, iAttacker) && is_user_alive(iVictim) && is_user_alive(iAttacker) && get_user_weapon(iAttacker) == CSW_FIVESEVEN){
		// Gusk1s
		new Float:fVelocity[3]; get_entvar(iVictim, var_velocity, fVelocity);
		new Float:fPush[3]; CreateVelocityVector(iVictim, iAttacker, fPush);
		fPush[0] += fVelocity[0]; fPush[1] += fVelocity[1]; set_entvar(iVictim, var_velocity, fPush);

		g_iPusher[iVictim] = iAttacker;
		ttt_fix_user_freeshots(iAttacker);
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		ClearPlayerBit(g_bHaveNewton, iId); 
	}

	return HC_CONTINUE;
}

public fwdPrimary_Attack_Post(const iWeaponEnt){
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveNewton, iOwner)) return;

	set_member(iWeaponEnt, m_Weapon_flNextPrimaryAttack, 2.0);
}

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon)

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveNewton, iId);

	return HAM_IGNORED;
}

public clcmd_Drop(const iId){
	if(GetPlayerBit(g_bHaveNewton, iId) && is_user_alive(iId) && get_user_weapon(iId) == CSW_FIVESEVEN) return PLUGIN_HANDLED;

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

stock CreateVelocityVector(const iVictim, const iAttacker, Float:fVelocity[3])
{
	new Float:fVictimOrigin[3]; get_entvar(iVictim, var_origin, fVictimOrigin);
	new Float:fAttackerOrigin[3]; get_entvar(iAttacker, var_origin, fAttackerOrigin);

	new Float:fDistance[3]; fDistance[0] = fVictimOrigin[0] - fAttackerOrigin[0]; fDistance[1] = fVictimOrigin[1] - fAttackerOrigin[1];
	fDistance[0] /= floatabs(fDistance[1]); fDistance[1] /= floatabs(fDistance[1]);

	fVelocity[0] = (fDistance[0] * NEWTON_FORCE * 3000) / get_distance_f(fVictimOrigin, fAttackerOrigin);
	fVelocity[1] = (fDistance[1] * NEWTON_FORCE * 30000) / get_distance_f(fVictimOrigin, fAttackerOrigin);
	
	if(fVelocity[0] <= 20.0 || fVelocity[1] <= 20.0) fVelocity[2] = random_float(800.0, 1000.0);
}