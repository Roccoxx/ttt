#include <amxmodx>
#include <reapi>
#include <engine>
#include <xs>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include "includes/ttt_shop"
#include "includes/ttt_core"

#pragma semicolon 1

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

const TASK_DNA = 12333221;

#define ID_DNA (taskid-TASK_DNA)

enum _:DNA_MODELS{
	DNA_MODEL_V, DNA_MODEL_P, DNA_MODEL_W
}

new const szDNAModels[DNA_MODELS][] = {
	"models/ttt/v_dnascanner.mdl", "models/ttt/p_dnascanner.mdl", "models/ttt/w_dnascanner.mdl"
};

new const szDNATraceSprite[] = "sprites/ttt/dna_trace.spr";

new const szWeaponName[] = "weapon_c4";
const WeaponIdType:WEAPON_ID = WEAPON_C4;
const WEAPON_UID = 130;

const Float:DELAY_USE_TIME = 10.0;

new g_iItemDnaScanner, g_iTraceSprite, g_iMsgStatusIcon, g_iMsgBarTime, g_bHaveDNA;
new Float:g_fDNAUsedDelay[33], Float:g_iTargetOrigin[33][3], Float:g_fWaitTime[33], g_iTargetIndex[33];

public plugin_precache()
{
	for(new i; i < DNA_MODELS; i++) precache_model(szDNAModels[i]);

	g_iTraceSprite = precache_model(szDNATraceSprite);

	g_iItemDnaScanner = ttt_register_item("DNA Scanner", STATUS_DETECTIVE, 1, 0);
}

public plugin_init()
{
	register_plugin("[TTT] Item: DNA Scanner", "1.0", "GuskiS & Roccoxx");

	RegisterHookChain(RG_CBasePlayer_Killed, "fwdPlayerKilled_Post", true);
	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Post", true);

	RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);
	RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "fwdPrimaryAttack_Pre", false);

	g_iMsgStatusIcon = get_user_msgid("StatusIcon");
	g_iMsgBarTime = get_user_msgid("BarTime");
}

public client_disconnected(iId){
	ClearPlayerBit(g_bHaveDNA, iId);
	g_fDNAUsedDelay[iId] = 0.0;
	remove_task(iId+TASK_DNA);

	g_iTargetIndex[iId] = 0;

	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(i == iId) continue;

		if(g_iTargetIndex[i] == iId){
			g_iTargetIndex[i] = 0;
			remove_task(i+TASK_DNA);
		}
	}
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
	for(new i = 1; i <= MAX_PLAYERS; i++){
		ClearPlayerBit(g_bHaveDNA, i);
		g_iTargetIndex[i] = 0;
		remove_task(i+TASK_DNA);
	}
}

public fwdPlayerTakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
	if(iVictim == iAttacker || !is_user_alive(iVictim) || !is_user_connected(iAttacker)) return HC_CONTINUE;

	if(iVictim == g_iTargetIndex[iAttacker]){
		g_iTargetIndex[iAttacker] = 0;
		remove_task(iAttacker+TASK_DNA);
	}

	return HC_CONTINUE;
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
	new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
	if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
		new iOwner = get_entvar(iWeapon, var_owner); 
		remove_task(iOwner+TASK_DNA); g_iTargetIndex[iOwner] = 0;
		ClearPlayerBit(g_bHaveDNA, iOwner);
		SetHookChainArg(2, ATYPE_STRING, szDNAModels[DNA_MODEL_W]);
	}
}

public fwdPlayerKilled_Post(const iVictim, iAttacker, iGib){
	if(!is_user_connected(iVictim)) return;
	
	new iEnt = rg_find_weapon_bpack_by_name(iVictim, szWeaponName);

	if(iEnt && is_entity(iEnt)){
		ClearPlayerBit(g_bHaveDNA, iVictim);
		g_iTargetIndex[iVictim] = 0;
		remove_task(iVictim+TASK_DNA);
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
		set_entvar(iEnt, var_nextthink, get_gametime());
	}
}

public fwdItemDeploy_Post(const iWeaponEnt)
{
	if(!is_entity(iWeaponEnt)) return;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
	
	if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveDNA, iOwner)) return;
	
	set_entvar(iOwner, var_viewmodel, szDNAModels[DNA_MODEL_V]);
	set_entvar(iOwner, var_weaponmodel, szDNAModels[DNA_MODEL_P]);
}

public fwdPrimaryAttack_Pre(const iWeaponEnt){
	if(ttt_is_round_end()) return HAM_IGNORED;

	static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);

	if(!is_user_alive(iOwner) || !GetPlayerBit(g_bHaveDNA, iOwner)) return HAM_IGNORED;

	if(g_fDNAUsedDelay[iOwner] < get_gametime()) MakeTrace(iOwner);

	return HAM_SUPERCEDE;
}

public fwdTouchWeapon_Pre(const iWeaponBox, const iId){
	if(!is_entity(iWeaponBox) || !is_user_alive(iId)) return HAM_IGNORED;

	static iWeapon; iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_ID || get_entvar(iWeapon, var_impulse) != WEAPON_UID) return HAM_IGNORED;

	static iAmmoId; iAmmoId = ExecuteHam(Ham_Item_PrimaryAmmoIndex, iWeapon);

	if(get_member(iWeapon, m_Weapon_iClip) == 0 && get_member(iId, m_rgAmmo, iAmmoId) == 0) return HAM_SUPERCEDE;

	SetPlayerBit(g_bHaveDNA, iId);

	return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
	if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

	if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

	if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
		remove_task(iId+TASK_DNA); g_iTargetIndex[iId] = 0;
		ClearPlayerBit(g_bHaveDNA, iId);
	}

	return HC_CONTINUE;
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem != g_iItemDnaScanner) return;
	
	rg_give_custom_item(iId, szWeaponName, GT_REPLACE, WEAPON_UID);

	SetPlayerBit(g_bHaveDNA, iId);

	cs_set_user_plant(iId, 0);
	cs_set_user_submodel(iId, 0);

	message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusIcon, _, iId);
	write_byte(0);
	write_string("c4");
	message_end();
}

public MakeTrace(const iId)
{
	client_cmd(iId, "-attack");

	new iEnt = ttt_find_body(iId);

	if(iEnt > 0)
	{
		new iOwner = get_entvar(iEnt, var_owner);

		if(ttt_is_body_analized(iOwner)){
			remove_task(iId+TASK_DNA);

			g_iTargetIndex[iId] = ttt_get_body_killer(iOwner);

			if(!is_user_alive(g_iTargetIndex[iId])){
				g_iTargetIndex[iId] = 0;
				client_print_color(iId, iId, "%s El asesino murio o se ha desconectado!", szModPrefix);
				g_fDNAUsedDelay[iId] = get_gametime() + 1.0;
				return;
			}

			client_print_color(iId, iId, "%s Analizando Muestra de ADN!", szModPrefix);

			message_begin(MSG_ONE_UNRELIABLE, g_iMsgBarTime, _, iId);
			write_short(1);
			message_end();

			g_fDNAUsedDelay[iId] = get_gametime() + DELAY_USE_TIME;

			client_print_color(iId, iId, "%s Muestra analizada!", szModPrefix);
			client_print_color(iId, iId, "%s Escanner en recarga, espera un momento!", szModPrefix);

			new iData[1]; iData[0] = iOwner;

			get_entvar(g_iTargetIndex[iId], var_origin, g_iTargetOrigin[iId]);

			set_task(1.0, "FindKiller", iId+TASK_DNA, iData, 1);
		}
		else{
			client_print_color(iId, iId, "%s El cuerpo no ha sido analizado todavia!", szModPrefix);
			g_fDNAUsedDelay[iId] = get_gametime() + 1.0;
		}
	}
}

public FindKiller(iArray[], taskid){
	if(!is_user_alive(g_iTargetIndex[ID_DNA])){
		g_iTargetIndex[ID_DNA] = 0;
		client_print_color(ID_DNA, ID_DNA, "%s El asesino murio o se ha desconectado!", szModPrefix);
		return;
	}

	new iOwner = iArray[0];

	get_entvar(g_iTargetIndex[ID_DNA], var_origin, g_iTargetOrigin[ID_DNA]);

	new Float:fDistance = ttt_get_body_time(iOwner) / 0.05;
	set_task(20.0-fDistance/120.0, "FindKiller", taskid, iArray, 2);
}

public client_PostThink(iId)
{
	if(!is_user_alive(iId) || ttt_get_user_status(iId) != STATUS_DETECTIVE || !GetPlayerBit(g_bHaveDNA, iId) || g_fWaitTime[iId] + 0.1 > get_gametime())
		return;

	g_fWaitTime[iId] = get_gametime();

	if(!g_iTargetIndex[iId]) return;

	ShowGlobalSprite(iId, g_iTargetOrigin[iId], g_iTraceSprite, 35.0);
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

stock ShowGlobalSprite( const iId, const Float:flOrigin[ 3 ], const iSprite, const Float:flScale = 1.0 )
{
    static Float:flPlayerOrigin[ 3 ];
    static Float:flViewOfs[ 3 ];
    
    static Float:flBuffer[ 3 ];
    static Float:flDifference[ 3 ];
    
    static Float:flDistanceToPoint;
    static Float:flDistanceToOrigin;
    
    static iScale;
    
    entity_get_vector( iId, EV_VEC_origin, flPlayerOrigin );
    entity_get_vector( iId, EV_VEC_view_ofs, flViewOfs );
    
    xs_vec_add( flPlayerOrigin, flViewOfs, flPlayerOrigin );
    
    if ( vector_distance( flPlayerOrigin, flOrigin ) > 4096.0 )
    {
        return false;
    }
    
    new iTrace = create_tr2( );
    
    engfunc( EngFunc_TraceLine, flPlayerOrigin, flOrigin, IGNORE_MONSTERS, iId, iTrace );
    
    get_tr2( iTrace, TR_vecEndPos, flBuffer );
    free_tr2( iTrace );
    
    flDistanceToPoint = vector_distance( flPlayerOrigin, flBuffer ) - 10.0;
    flDistanceToOrigin = vector_distance( flPlayerOrigin, flOrigin );
    
    xs_vec_sub( flOrigin, flPlayerOrigin, flDifference );
    
    xs_vec_normalize( flDifference, flDifference );
    xs_vec_mul_scalar( flDifference, flDistanceToPoint, flDifference );
    
    xs_vec_add( flPlayerOrigin, flDifference, flBuffer );
    
    iScale = floatround( 2.0 * floatmax( ( flDistanceToPoint / flDistanceToOrigin ), 0.25 ) * flScale );
    
    message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = iId );
    write_byte( TE_SPRITE );
    write_coord_f( flBuffer[ 0 ] );
    write_coord_f( flBuffer[ 1 ] );
    write_coord_f( flBuffer[ 2 ] );
    write_short( iSprite );
    write_byte( iScale );
    write_byte( 255 );
    message_end( );
    
    return true;
}