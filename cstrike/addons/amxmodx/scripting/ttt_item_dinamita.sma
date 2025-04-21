#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include "includes/ttt_shop"
#include "includes/ttt_core"
#include <reapi>
#include <xs>

#define SetPlayerBit(%1,%2) ( %1 |= ( 1 << ( %2 & 31 ) ) )
#define ClearPlayerBit(%1,%2) ( %1 &= ~( 1 << ( %2 & 31 ) ) )
#define GetPlayerBit(%1,%2) ( %1 & ( 1 << ( %2 & 31 ) ) )

#define WEAPON_CSWID CSW_C4
#define WEAPON_NAME "weapon_c4"

#define shouldEmitSound(%0) ( %0 % 30 == 0 )
#define findDynamite find_ent_by_class( -1, g_szDynamiteClassname )
#define isPlayerCrouching(%0) ( entity_get_int( %0, EV_INT_flags ) & FL_DUCKING )

const OFFSET_WEAPONOWNER = 41;
const EXTRAOFFSET_WEAPONS = 4;
const DEFUSE_KEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5;

new const g_szDynamiteSound[ ] = "ttt/beep.wav";
new const g_szDynamiteDefused[ ] = "ttt/defused.wav";
new const g_szDynamiteClassname[ ] = "Dynamite";
new const g_szDynamiteClasstype[ ] = "func_button";

enum _:DYNAMITE_MODELS{
    DYNAMITE_V_MODEL, DYNAMITE_P_MODEL, DYNAMITE_W_MODEL
}

new szDynamiteModels[DYNAMITE_MODELS][] = {
    "models/v_c4.mdl", "models/p_c4.mdl", "models/w_c4.mdl"
};

new g_iItemID, g_iDynamite, g_iMaxPlayers, g_iStatusIcon, g_iC4Sprite, g_iSyncObj;

const Float:fC4ExplotionRange = 1000.0;

public plugin_precache( )
{
    g_iC4Sprite = precache_model("sprites/ttt/c4_sprite.spr");
    
    for(new i; i < DYNAMITE_MODELS; i++) precache_model( szDynamiteModels[i] );
    
    precache_sound( g_szDynamiteSound );
    precache_sound( g_szDynamiteDefused );

    g_iItemID = ttt_register_item("C4", STATUS_TRAITOR, 3, 0);
}

public plugin_init( )
{
    register_plugin( "[TTT] Item: Dynamite", "1.0", "Manu" );
    
    RegisterHam( Ham_Use, "func_button", "fw_PlayerButton_Pre", false );
    RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_NAME, "fw_DynamiteAttack_Pre", false );
    RegisterHam( Ham_Item_Deploy, WEAPON_NAME, "fwdItemDeploy_Post", true);
    
    register_think( g_szDynamiteClassname, "fw_DynamiteThink" );
    
    register_menucmd( register_menuid( "Defuse Menu" ), DEFUSE_KEYS, "DefuseHandler" );
    
    g_iSyncObj = CreateHudSyncObj( );
    g_iMaxPlayers = get_maxplayers( );
    g_iStatusIcon = get_user_msgid( "StatusIcon" );

    RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
}

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay){
    for(new i = 1; i <= MAX_PLAYERS; i++) ClearPlayerBit(g_iDynamite, i);

    new iEnt = NULLENT; while((iEnt = rg_find_ent_by_class(iEnt, "c4_sprite"))) set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);

    iEnt = NULLENT; while((iEnt = rg_find_ent_by_class(iEnt, g_szDynamiteClassname))) set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
}

public ttt_shop_item_selected(const iId, const iItem)
{
    if( g_iItemID == iItem )
    {
        if(user_has_weapon( iId, WEAPON_CSWID ) ) engclient_cmd( iId, "drop", WEAPON_NAME );
        
        rg_give_item(iId, WEAPON_NAME); SetDynamite( iId );
        
        client_print_color( iId, print_team_default, "%s Compraste un C4.", szModPrefix);
        client_print_color( iId, print_team_default, "%s Avisa a tu equipo cuando lo plantes y donde lo hiciste!", szModPrefix);
        
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

public fwdItemDeploy_Post(const iWeaponEnt)
{
    if(!is_entity(iWeaponEnt)) return;

    static iOwner; iOwner = get_entvar(iWeaponEnt, var_owner);
    
    if(!is_user_connected(iOwner) || !GetPlayerBit(g_iDynamite, iOwner)) return;
    
    set_entvar(iOwner, var_viewmodel, szDynamiteModels[DYNAMITE_V_MODEL]);
    set_entvar(iOwner, var_weaponmodel, szDynamiteModels[DYNAMITE_P_MODEL]);
}

public fw_DynamiteThink( iEnt )
{
    if(!is_valid_ent(iEnt)) return;

    static iLeft; iLeft = ( entity_get_int( iEnt, EV_INT_iuser1 ) - 1 );
    
    if( iLeft > 0 )
    {
        if( shouldEmitSound( iLeft ) )
            emit_sound( iEnt, CHAN_BODY, g_szDynamiteSound, VOL_NORM, ATTN_IDLE, 0, PITCH_NORM );
        
        SendInformation( iEnt, iLeft );
        
        entity_set_int( iEnt, EV_INT_iuser1, iLeft );
        entity_set_float( iEnt, EV_FL_nextthink, get_gametime( ) + 0.1 );
    }
    else
        CreateExplosion( iEnt );
}

public fw_DynamiteAttack_Pre( iEnt )
{
    if( pev_valid( iEnt ) != 2 ) return HAM_IGNORED;
    
    static iOwner; iOwner = get_pdata_cbase(iEnt, OFFSET_WEAPONOWNER, EXTRAOFFSET_WEAPONS);
    
    if(!is_user_alive(iOwner)) return HAM_IGNORED;

    static iDynamite;

    if( GetPlayerBit( g_iDynamite, iOwner ) )
    {
        if( is_valid_ent( findDynamite ) )
        {
            client_print_color( iOwner, print_team_default, "%s Solo puede haber un C4 a la vez en el mapa.", szModPrefix);
            
            return HAM_IGNORED;
        }

        rg_remove_item(iOwner, WEAPON_NAME, true);
       // engclient_cmd( iOwner, "drop", "weapon_c4" );
        
        if( is_valid_ent( ( iDynamite = find_ent_by_model( -1, "weaponbox", szDynamiteModels[ DYNAMITE_W_MODEL ] ) ) ) )
            remove_entity( iDynamite );
        
        CreateDynamite( iOwner );
        ClearPlayerBit( g_iDynamite, iOwner );
    }
    
    return HAM_SUPERCEDE;
}

public fw_PlayerButton_Pre( iEnt, iId, iActivator, iUseType, Float:fValue )
{
    if( iUseType == 2 && fValue == 1.0 && is_user_alive( iId ) && ttt_get_user_status(iId) != STATUS_TRAITOR )
    {
        static szClassname[ 16 ]; entity_get_string( iEnt, EV_SZ_classname, szClassname, charsmax( szClassname ) );
        
        if( equal( szClassname, g_szDynamiteClassname ) )
        {
            ShowDefuseMenu( iId );
            
            return HAM_SUPERCEDE;
        }
    }
    
    return HAM_IGNORED;
}

public ShowDefuseMenu( iId )
{
    static szData[ 192 ], iLen;
    
    iLen = formatex( szData, charsmax( szData ), "\wCable para desactivar el C4:^n^n" );
    
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[1] \wCable \yrojo^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[2] \wCable \yazul^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[3] \wCable \yverde^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[4] \wCable \yamarillo^n^n" );
    iLen += formatex( szData[ iLen ], charsmax( szData ) - iLen, "\r[5] \yCancelar" );
    
    show_menu( iId, DEFUSE_KEYS, szData, 5, "Defuse Menu" );
    
    return PLUGIN_HANDLED;
}

public DefuseHandler( iId,iKey )
{
    if( iKey > 3 || !is_user_connected( iId ) )
        return PLUGIN_HANDLED;
    
    static iEnt, szName[ 32 ]; get_user_name( iId, szName, charsmax( szName ) );
    
    if( is_valid_ent( ( iEnt = findDynamite ) ) )
    {
        if( random_num( 0, 3 ) != iKey )
        {
            entity_set_int( iEnt, EV_INT_iuser1, 0 );
            entity_set_float( iEnt, EV_FL_nextthink, get_gametime( ) + 0.1 );
            
            client_print_color( 0, print_team_default, "%s El C4 exploto porque^3 %s^1 se equivoco de cable.", szName, szModPrefix);
        }
        else
        {
            emit_sound( iEnt, CHAN_BODY, g_szDynamiteDefused, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
            set_entvar( iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
            
            client_print_color( 0, print_team_default, "%s El C4 fue desactivado por^3 %s^1.", szName, szModPrefix);

            ttt_update_statistic(iId, C4_DEFUSED); ttt_update_user_points(iId, 50);
        }
    }
    
    return PLUGIN_HANDLED;
}

SendInformation( iEnt, iLeft )
{   
    static Float:vOrigin[ 3 ], iPlayers[ 32 ], iNum, iState; iNum = 0; get_players( iPlayers, iNum );
    
    entity_get_vector( iEnt, EV_VEC_origin, vOrigin ); vOrigin[2] += 7.0;

    if( iLeft % 10 == 0 ){
        static iSprite; 

        if(!is_nullent(iSprite)){
            static szClassname[ 16 ]; entity_get_string(iSprite, EV_SZ_classname, szClassname, charsmax(szClassname));

            if(equal(szClassname, "c4_sprite")) remove_entity(iSprite);
        }

        iSprite = create_entity("info_target");
        
        if(!is_valid_ent(iSprite)) return;

        entity_set_string(iSprite, EV_SZ_classname, "c4_sprite");
        entity_set_origin(iSprite, vOrigin);
        entity_set_int(iSprite, EV_INT_rendermode, 5)
        entity_set_float(iSprite, EV_FL_renderamt, 200.0);
        entity_set_float(iSprite, EV_FL_scale, 0.3);
        entity_set_model(iSprite, "sprites/ledglow.spr");
        entity_set_int(iSprite, EV_INT_iuser1, 3);
        entity_set_float(iSprite, EV_FL_nextthink, get_gametime() + 0.1);
    }

    vOrigin[ 2 ] += 25.0; // 25 + 7 = 32.0

    for( iNum--; iNum >= 0; iNum-- )
    {
        iState = ttt_get_user_status( iPlayers[ iNum ] );
        
        if(iState != STATUS_TRAITOR && is_user_alive(iPlayers[ iNum ]) || !is_user_connected(iPlayers[ iNum ]))
            continue;
        
        ShowGlobalSprite( iPlayers[ iNum ], vOrigin, g_iC4Sprite, 1.0);
        if( iLeft % 10 == 0 )
        {
            set_hudmessage( 255, 50, 0, 0.02, 0.25, 1, 3.0, 1.1, 0.0, 0.0, -1 );
            ShowSyncHudMsg( iPlayers[ iNum ], g_iSyncObj, "[ El C4 explotara en %d ]", iLeft / 10 );
        }
    }
}

CreateDynamite( const iId )
{   
    static iEnt, Float:vOrigin[ 3 ];
    
    if( !is_valid_ent( ( iEnt = create_entity( g_szDynamiteClasstype ) ) ) )
        return 0;
    
    entity_set_string( iEnt, EV_SZ_classname, g_szDynamiteClassname );
    
    entity_set_model( iEnt, szDynamiteModels[ DYNAMITE_W_MODEL ] );
    entity_set_size( iEnt, Float:{ -5.0, -5.0, -1.0 }, Float:{ 5.0, 5.0, 1.0 } );
    
    entity_set_int( iEnt, EV_INT_movetype, MOVETYPE_FLY );
    entity_set_int( iEnt, EV_INT_solid, SOLID_TRIGGER );
    
    entity_get_vector( iId, EV_VEC_origin, vOrigin ); vOrigin[ 2 ] -= isPlayerCrouching( iId ) ? 14.0 : 30.0;
    entity_set_origin( iEnt, vOrigin );
    
    entity_set_int( iEnt, EV_INT_iuser1, 360 );
    entity_set_float( iEnt, EV_FL_health, 100.0 );
    entity_set_float( iEnt, EV_FL_takedamage, DAMAGE_NO );
    entity_set_float( iEnt, EV_FL_gravity, 1.0 );
    entity_set_edict( iEnt, EV_ENT_owner, iId );
    
    entity_set_float( iEnt, EV_FL_nextthink, get_gametime( ) + 1.0 );
    
    drop_to_floor( iEnt );
    
    ttt_update_statistic(iId, C4_PLANTED); ttt_update_user_points(iId, 50);
    client_print_color( iId, print_team_default, "%s El C4 explotara en 35 segundos.", szModPrefix);
    
    return 1;
}

SetDynamite( iId )
{
    cs_set_user_plant( iId, 0 );
    cs_set_user_submodel( iId, 0 );

    message_begin( MSG_ONE_UNRELIABLE, g_iStatusIcon, _, iId );
    write_byte( 0 );
    write_string( "c4" );
    message_end( );
    
    set_attrib_all( iId, 4 );
    
    SetPlayerBit( g_iDynamite, iId );
}

stock set_attrib_all(id, msg)
{
    if(!is_user_connected(id))
        return;

    static g_Msg_ScoreAttrib;
    if(!g_Msg_ScoreAttrib)
        g_Msg_ScoreAttrib = get_user_msgid("ScoreAttrib");

    message_begin(MSG_BROADCAST, g_Msg_ScoreAttrib);
    write_byte(id);
    write_byte(msg);
    message_end();
}

CreateExplosion( iThis )
{
    static iPlayer, iOwner, Float:flRange, Float:flDamage, Float:vOrigin[ 3 ], iEnt; 
    
    iOwner = entity_get_edict( iThis, EV_ENT_owner );

    iEnt = NULLENT;

    while((iEnt = rg_find_ent_by_class(iEnt, "c4_sprite"))) set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
    
    if( !is_user_connected( iOwner ) )
        return 0;
    
    entity_get_vector( iThis, EV_VEC_origin, vOrigin );
    iEnt = create_entity( "env_explosion" );
    
    if( !is_valid_ent( iEnt ) )
        return 0;
    
    entity_set_origin( iEnt, vOrigin );
    entity_set_int( iEnt, EV_INT_spawnflags, entity_get_int( iEnt, EV_INT_spawnflags ) | SF_ENVEXPLOSION_NODAMAGE );
    
    DispatchKeyValue( iEnt, "iMagnitude", "500" );
    DispatchSpawn( iEnt );
    
    force_use( iEnt, iEnt );
    remove_entity( iEnt );
    
    for( iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++ )
    {
        if( !is_user_alive( iPlayer ) )
            continue;
        
        flRange = entity_range( iPlayer, iThis );
        
        if( flRange < fC4ExplotionRange )
        {
            flDamage = floatmax( 1.0, ( ( fC4ExplotionRange - flRange ) / 3.33 ) );
            
            if(entity_get_float(iPlayer, EV_FL_health) <= flDamage){
                ttt_update_statistic(iOwner, C4_KILLS);
                ExecuteHamB(Ham_Killed, iPlayer, iOwner, 0);
            }
            else{
                ExecuteHamB( Ham_TakeDamage, iPlayer, iOwner, iOwner, flDamage, DMG_BLAST );
            }
            
            ttt_fix_user_freeshots(iOwner);
        }
    }
    
    ttt_update_statistic(iOwner, C4_EXPLODED); ttt_update_user_points(iOwner, 50);
    set_entvar(iThis, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
    
    return 1;
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