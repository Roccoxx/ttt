#include <amxmodx>
#include "ttt/ttt_shop"
#include "ttt/ttt_core"
#include <hamsandwich>
#include <reapi>
#include <engine>
#include <xs>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:KNIFE_MODELS{
	KNIFE_V_MODEL, KNIFE_P_MODEL, KNIFE_W_MODEL
}

new szKnifeModels[KNIFE_MODELS][] = {
	"models/v_knife.mdl", "models/p_knife.mdl", "models/ttt/w_throwingknife.mdl"
};

new const szWeaponName[] = "weapon_knife";
new const szKnifeThrowClassName[] = "knifethrow";

const KNIFE_IDLE = 12;
const Float:KNIFE_THROW_DELAY = 0.6;
const Float:KNIFE_ATTACK2_DAMAGE = 1000.0;

new g_iItemKnife, g_bHaveKnife;
new Float:g_fKnifeThrowDelay[33];

public plugin_init(){
	register_plugin("TTT: Item Knife", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fwdPrimaryAttack_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);

	register_touch(szKnifeThrowClassName, "*", "KnifeTouch");
}

public plugin_precache(){
	g_iItemKnife = ttt_register_item("Knife", STATUS_TRAITOR, 1, 0);

	for(new i; i < sizeof(szKnifeModels); i++) precache_model(szKnifeModels[i]);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveKnife, iId);
	g_fKnifeThrowDelay[iId] = 0.0;
}

public ttt_shop_item_selected(const iId, const iItem)
	if(iItem == g_iItemKnife) GiveKnife(iId);

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) 
	for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_bHaveKnife, i);

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveKnife, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szKnifeModels[KNIFE_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szKnifeModels[KNIFE_P_MODEL]);
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveKnife, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_KNIFE){
		SetHookChainArg(4, ATYPE_FLOAT, KNIFE_ATTACK2_DAMAGE);
		ttt_update_statistic(iAttacker, KNIFE_KILLS); ttt_check_achievement_type(iAttacker, Achievement_type_kills);
	}
}

public fwdPrimaryAttack_Pre(const iWeaponEnt){
	if(!is_entity(iWeaponEnt)) return HAM_IGNORED;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveKnife, iOwner)) return HAM_IGNORED;

	static Float:fGametime; fGametime = get_gametime();
	
	if(g_fKnifeThrowDelay[iOwner] <= fGametime){
		LaunchKnife(iOwner);
		g_fKnifeThrowDelay[iOwner] = fGametime + KNIFE_THROW_DELAY;
	}

	return HAM_SUPERCEDE;
}

public KnifeTouch(const iEnt, const iTouched)
{
	if(!is_valid_ent((iEnt))) return PLUGIN_HANDLED;

	if(IsPlayer(iTouched)){
		if(entity_get_int(iEnt, EV_INT_iuser1) == KNIFE_IDLE && !GetPlayerBit(g_bHaveKnife, iTouched) && is_user_alive(iTouched)){
			remove_entity(iEnt);
			
			GiveKnife(iTouched);
		}
		else{
			new iOwner = entity_get_edict(iEnt, EV_ENT_owner);

			ExecuteHamB(Ham_Killed, iTouched, iOwner, 0);
			ttt_update_statistic(iOwner, KNIFE_KILLS); ttt_check_achievement_type(iOwner, Achievement_type_kills);

			entity_set_int(iEnt, EV_INT_iuser1, KNIFE_IDLE);
			entity_set_edict(iEnt, EV_ENT_owner, 0);
			entity_set_vector(iEnt, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
			drop_to_floor(iEnt);
		}	
	}
	else{
		if(entity_get_int(iEnt, EV_INT_iuser1) == KNIFE_IDLE) return PLUGIN_HANDLED;
		
		entity_set_int(iEnt, EV_INT_iuser1, KNIFE_IDLE);
		entity_set_edict(iEnt, EV_ENT_owner, 0);
		entity_set_vector(iEnt, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
		drop_to_floor(iEnt);
	}
	
	return PLUGIN_HANDLED;
}

GiveKnife(const iId){
	SetPlayerBit(g_bHaveKnife, iId);
	rg_give_custom_item(iId, szWeaponName, GT_REPLACE);
}

LaunchKnife(const iId){
	new iEnt = create_entity("info_target");

	if(!is_valid_ent(iEnt)) return;

	new Float:fOrigin[3], Float:fVelocity[3], Float:vAngle[3];
	
	entity_get_vector(iId, EV_VEC_origin , fOrigin);
	entity_get_vector(iId, EV_VEC_v_angle, vAngle);

	entity_set_string(iEnt, EV_SZ_classname, szKnifeThrowClassName);
	entity_set_model(iEnt, szKnifeModels[KNIFE_W_MODEL]);
	entity_set_size(iEnt, Float:{-10.0, -10.0, -10.0}, Float:{10.0, 10.0, 10.0});
	entity_set_origin(iEnt, fOrigin);
	entity_set_vector(iEnt, EV_VEC_angles, vAngle);
	entity_set_int(iEnt, EV_INT_solid, 2);
	entity_set_float(iEnt, EV_FL_scale, 1.00);
	entity_set_int(iEnt, EV_INT_movetype, 5);
	velocity_by_aim(iId, 1000, fVelocity);
	entity_set_vector(iEnt, EV_VEC_velocity, fVelocity);
	entity_set_edict(iEnt, EV_ENT_owner, iId);

	LaunchPush(iId, 50);

	ClearPlayerBit(g_bHaveKnife, iId);
	rg_give_custom_item(iId, szWeaponName, GT_REPLACE);
}

LaunchPush(const iId, const iVelAmount)
{
	new Float:flNewVelocity[3]; velocity_by_aim(iId, -iVelAmount, flNewVelocity);
	new Float:flCurrentVelocity[3]; get_user_velocity(iId, flCurrentVelocity);
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity);
	set_user_velocity(iId, flNewVelocity);
}
