#include <amxmodx>
#include "includes/ttt_shop"
#include "includes/ttt_core"
#include <reapi>
#include <hamsandwich>

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:DISARMER_MODELS{
    DISARMER_V_MODEL, DISARMER_P_MODEL, DISARMER_W_MODEL
}

new szDisarmerModels[DISARMER_MODELS][] = {
    "models/ttt/v_desarmadora.mdl", "models/p_deagle.mdl", "models/ttt/w_desarmadora.mdl"
};

// ELIMINAR SI CAMBIO EL MODELO
new const szSoundModel[] = "weapons/desp_reload_m.wav";

const TASK_DISARM = 29112911;
#define ID_DISARM (taskid-TASK_DISARM)

new const szWeaponName[] = "weapon_deagle";
const WeaponIdType:WEAPON_ID = WEAPON_DEAGLE;

const WEAPON_UID = 134;

new g_iItemDisarmer, g_bHaveDisarmer, g_bIsDisarmed;

new Float:g_fRenderColor[33][3];

public plugin_init(){
    register_plugin("Item: Disarmer", "1.0", "Manu");

    RegisterHam(Ham_Item_Deploy, szWeaponName, "fwdItemDeploy_Post", true);
    RegisterHam(Ham_Touch, "weaponbox", "fwdTouchWeapon_Pre", false);

    RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
    RegisterHookChain(RG_CWeaponBox_SetModel, "fwdCWeaponBox_SetModel_Pre", false);
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "fwdPlayerTakeDamage_Pre", false);
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "fwdPlayerAddPlayerItem_Pre", false);
}

public plugin_precache(){
    g_iItemDisarmer = ttt_register_item("Desarmadora", STATUS_DETECTIVE, 1, 0);

    for(new i; i < sizeof(szDisarmerModels); i++) precache_model(szDisarmerModels[i]);

    precache_sound(szSoundModel);
}

public client_disconnected(iId){
    ClearPlayerBit(g_bHaveDisarmer, iId);
    remove_task(iId+TASK_DISARM); ClearPlayerBit(g_bIsDisarmed, iId);

    g_fRenderColor[iId][0] = g_fRenderColor[iId][1] = g_fRenderColor[iId][2] = 0.0;
}

public ttt_shop_item_selected(const iId, const iItem){
    if(iItem != g_iItemDisarmer) return;

    SetPlayerBit(g_bHaveDisarmer, iId);

    rg_remove_item(iId, szWeaponName, false);
    new iWeapon = rg_give_custom_item(iId, szWeaponName, GT_APPEND, WEAPON_UID);

    if(is_nullent(iWeapon)) return;

    rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, 1);
    rg_set_user_ammo(iId, WEAPON_ID, 1);
    rg_set_user_bpammo(iId, WEAPON_ID, 0);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
    for(new i = 1; i <= MAX_PLAYERS; i++){
        ClearPlayerBit(g_bHaveDisarmer, i);
        remove_task(i+TASK_DISARM); ClearPlayerBit(g_bIsDisarmed, i);
    }

public fwdItemDeploy_Post(const iWeaponEnt)
{
    if(!is_entity(iWeaponEnt)) return;

    static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
    
    if(!is_user_connected(iOwner) || !GetPlayerBit(g_bHaveDisarmer, iOwner)) return;
    
    set_entvar(iOwner, var_viewmodel, szDisarmerModels[DISARMER_V_MODEL]);
    set_entvar(iOwner, var_weaponmodel, szDisarmerModels[DISARMER_P_MODEL]);
}

public fwdCWeaponBox_SetModel_Pre(const iWeaponBox, const szModel[])
{
    new iWeapon = func_GetWeaponBoxWeapon(iWeaponBox);
    if(iWeapon != NULLENT && get_entvar(iWeapon, var_impulse) == WEAPON_UID){
        new iOwner = get_entvar(iWeapon, var_owner); ClearPlayerBit(g_bHaveDisarmer, iOwner);
        SetHookChainArg(2, ATYPE_STRING, szDisarmerModels[DISARMER_W_MODEL]);
    }
}

public fwdPlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type){
    if(GetPlayerBit(g_bHaveDisarmer, iAttacker) && is_user_alive(iVictim) && get_user_weapon(iAttacker) == CSW_DEAGLE && !GetPlayerBit(g_bIsDisarmed, iVictim)){
        new Float:fColor[3]; get_entvar(iVictim, var_rendercolor, fColor);

        if(fColor[0] != 255.0 && fColor[1] != 0.0 && fColor[2] != 128.0){
            g_fRenderColor[iVictim][0] = fColor[0]; g_fRenderColor[iVictim][1] = fColor[1]; g_fRenderColor[iVictim][2] = fColor[2];
        }

        rg_drop_items_by_slot(iVictim, PRIMARY_WEAPON_SLOT); rg_drop_items_by_slot(iVictim, PISTOL_SLOT);
        SetPlayerBit(g_bIsDisarmed, iVictim);
        set_task(5.0, "RemoveEffect", iVictim+TASK_DISARM);
        client_print_color(iVictim, iVictim, "%s Un detective te ha hecho tirar las armas!", szModPrefix);
        client_print_color(iVictim, iVictim, "%s No podras agarrar ningun arma por^4 cinco^1 segundos!", szModPrefix);
        rg_set_user_rendering(iVictim, kRenderFxGlowShell, {255.0, 0.0, 128.0}, kRenderNormal, 30.0);
        ttt_update_statistic(iAttacker, PLAYERS_DISARMED); ttt_check_achievement_type(iAttacker, Achievement_type_disarmed);
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

    SetPlayerBit(g_bHaveDisarmer, iId);

    return HAM_IGNORED;
}

public fwdPlayerAddPlayerItem_Pre(const iId, const iWeapon){
    if(!is_entity(iWeapon) || !is_user_alive(iId)) return HC_CONTINUE;

    if(iWeapon <= 0 || get_member(iWeapon, m_iId) != WEAPON_ID) return HC_CONTINUE;

    if(get_entvar(iWeapon, var_impulse) != WEAPON_UID){
        ClearPlayerBit(g_bHaveDisarmer, iId); 
    }

    return HC_CONTINUE;
}

public RemoveEffect(taskid)
{
    if(!is_user_alive(ID_DISARM)) return;
    
    if(ttt_get_user_status(ID_DISARM) == STATUS_DETECTIVE) rg_set_user_rendering(ID_DISARM, kRenderFxGlowShell, {0.0, 50.0, 255.0}, kRenderNormal, 30.0);
    else rg_set_user_rendering(ID_DISARM, kRenderFxGlowShell, g_fRenderColor[ID_DISARM], kRenderNormal, 30.0);

    ClearPlayerBit(g_bIsDisarmed, ID_DISARM);
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