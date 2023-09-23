#include <amxmodx>
#include "includes/ttt_shop"
#include "includes/ttt_core"
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

enum _:KNIFE_SOUNDS{
	KNIFE_PICKUP, KNIFE_HIT, KNIFE_THROW
}

new const szKnifeSounds[][] = {
	"items/gunpickup2.wav", "weapons/knife_hit1.wav", "weapons/knife_slash1.wav"
}

const KNIFE_IDLE = 12;
const Float:KNIFE_THROW_DELAY = 0.6;
const Float:KNIFE_ATTACK2_DAMAGE = 1000.0;

new g_iItemKnife, g_bHaveKnife, g_bEquipTraitorKnife;
new Float:g_fKnifeThrowDelay[33];

public plugin_init(){
	register_plugin("TTT: Item Knife", "1.0", "Roccoxx");

	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, szWeaponName, "fwdPrimaryAttack_Pre", false);

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);

	register_touch(szKnifeThrowClassName, "*", "KnifeTouch");

	register_clcmd("weapon_knife", "clcmd_knife");
}

public plugin_precache(){
	g_iItemKnife = ttt_register_item("Knife", STATUS_TRAITOR, 1, 0);

	new i;

	for(i = 0; i < sizeof(szKnifeModels); i++) precache_model(szKnifeModels[i]);
	for(i = 0; i < sizeof(szKnifeSounds); i++) precache_sound(szKnifeSounds[i]);
}

public plugin_natives(){
	register_native("ttt_is_holding_knife", "HoldingKnife", 1);
}

public HoldingKnife(const iId) return GetPlayerBit(g_bEquipTraitorKnife, iId) ? 1 : 0;

public ttt_shop_item_selected(const iId, const iItem)
	if(iItem == g_iItemKnife) GiveKnife(iId);

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) 
{
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveKnife, i);
		ClearPlayerBit(g_bEquipTraitorKnife, i);
	}

	new iEnt = NULLENT;

	while((iEnt = rg_find_ent_by_class(iEnt, szKnifeThrowClassName)))
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveKnife, iId);
	ClearPlayerBit(g_bEquipTraitorKnife, iId);
	g_fKnifeThrowDelay[iId] = 0.0;
}

public clcmd_knife(const iId){
	if(ttt_get_user_status(iId) != STATUS_TRAITOR || !GetPlayerBit(g_bHaveKnife, iId)) return PLUGIN_CONTINUE;

	if(get_user_weapon(iId) == CSW_KNIFE)
	{
		if(GetPlayerBit(g_bEquipTraitorKnife, iId))
			ClearPlayerBit(g_bEquipTraitorKnife, iId);
		else
			SetPlayerBit(g_bEquipTraitorKnife, iId);

		ResetKnife(iId);
	}

	return PLUGIN_CONTINUE;
}

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveKnife, iOwner) || !GetPlayerBit(g_bEquipTraitorKnife, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szKnifeModels[KNIFE_V_MODEL]);
	set_entvar(iOwner, var_weaponmodel, szKnifeModels[KNIFE_P_MODEL]);
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(GetPlayerBit(g_bHaveKnife, iAttacker) && GetPlayerBit(g_bEquipTraitorKnife, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_KNIFE){
		SetHookChainArg(4, ATYPE_FLOAT, KNIFE_ATTACK2_DAMAGE);
		ttt_update_statistic(iAttacker, KNIFE_KILLS); ttt_check_achievement_type(iAttacker, Achievement_type_kills);
	}
}

public fwdPrimaryAttack_Pre(const iWeaponEnt){
	if(!is_entity(iWeaponEnt)) return HAM_IGNORED;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveKnife, iOwner) || !GetPlayerBit(g_bEquipTraitorKnife, iOwner)) return HAM_IGNORED;

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
			client_print_color(iTouched, iTouched, "%s Has recogido un cuchillo!", szModPrefix);
			PlaySound(iTouched, szKnifeSounds[KNIFE_PICKUP]);
		}
		else{
			new iOwner = entity_get_edict(iEnt, EV_ENT_owner);

			emit_sound(iTouched, CHAN_BODY, szKnifeSounds[KNIFE_HIT], 1.0, ATTN_NORM, 0, PITCH_NORM);

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

GiveKnife(const iId) SetPlayerBit(g_bHaveKnife, iId);

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

	velocity_by_aim(iId, 1000, fVelocity); fVelocity[2] -= 80;
	entity_set_vector(iEnt, EV_VEC_velocity, fVelocity);

	entity_set_edict(iEnt, EV_ENT_owner, iId);

	set_entvar(iEnt, var_renderfx, kRenderFxGlowShell);
	set_entvar(iEnt, var_rendercolor, Float:{255.0, 0.0, 0.0});

	LaunchPush(iId, 50);

	PlaySound(iId, szKnifeSounds[KNIFE_THROW]);

	ClearPlayerBit(g_bEquipTraitorKnife, iId);
	ClearPlayerBit(g_bHaveKnife, iId);

	// ACTUALIZAMOS A CROWBAR
	ResetKnife(iId);
}

LaunchPush(const iId, const iVelAmount)
{
	new Float:flNewVelocity[3]; velocity_by_aim(iId, -iVelAmount, flNewVelocity);
	new Float:flCurrentVelocity[3]; get_user_velocity(iId, flCurrentVelocity);
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity);
	set_user_velocity(iId, flNewVelocity);
}

ResetKnife(const iId){
	if(user_has_weapon(iId, CSW_KNIFE))
		ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(-1, "weapon_knife", iId));

	engclient_cmd(iId, "weapon_knife");
	UTIL_PlayWeaponAnimation(iId, 3);

	emessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, iId);
	ewrite_byte(1);
	ewrite_byte(CSW_KNIFE);
	ewrite_byte(-1);
	emessage_end();
}

stock UTIL_PlayWeaponAnimation(const id, const seq)
{
	entity_set_int(id, EV_INT_weaponanim, seq);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
	write_byte(seq);
	write_byte(entity_get_int(id, EV_INT_body));
	message_end();
}

PlaySound(const iId, const szSound[])
{
	if (equal(szSound[strlen(szSound)-4], ".mp3")){
		client_cmd(iId, "mp3 stop");
		client_cmd(iId, "mp3 play ^"%s^"", szSound);
	}
	else client_cmd(iId, "spk ^"%s^"", szSound);
}