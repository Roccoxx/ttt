#include <amxmodx>
#include "ttt/ttt_shop"
#include <cstrike>

#pragma semicolon 1

new g_iItemArmorTraitor, g_iItemArmorDetective, g_iItemDefuse;

new const szSoundBuyArmor[] = "items/ammopickup2.wav";

public plugin_init(){
	register_plugin("Defuse and Armor", "1.0", "Roccoxx");
}

public plugin_precache(){
	g_iItemArmorTraitor = ttt_register_item("Chaleco T", STATUS_TRAITOR, 1, 0);
	g_iItemArmorDetective = ttt_register_item("Chaleco D", STATUS_DETECTIVE, 1, 0);
	g_iItemDefuse = ttt_register_item("Kit de desactivacion", STATUS_DETECTIVE, 1, 0);

	precache_sound(szSoundBuyArmor);
}

public ttt_shop_item_selected(const iId, const iItem){
	if(iItem == g_iItemArmorTraitor || iItem == g_iItemArmorDetective){
		cs_set_user_armor(iId, cs_get_user_armor(iId) + 100, CS_ARMOR_KEVLAR);
		client_cmd(iId, "spk ^"%s^"", szSoundBuyArmor);
	}
	else if(iItem == g_iItemDefuse) cs_set_user_defuse(iId);
}