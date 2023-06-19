#include <amxmodx>
#include <fakemeta>
#include <ttt_core>
#include <reapi>
#include <engine>

#pragma compress 1

#define MAX_EXTRA_ITEMS 50
#define MENU_ITEMS_OPTION_LENGHT 20

#define IsPlayer(%0)            (1 <= %0 <= MAX_PLAYERS)

#define GetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 & (1 << (%1 & 31))))
#define SetPlayerBit(%0,%1)     (IsPlayer(%1) && (%0 |= (1 << (%1 & 31))))
#define ClearPlayerBit(%0,%1)   (IsPlayer(%1) && (%0 &= ~(1 << (%1 & 31))))

enum _:Player_Status{
	STATUS_INNOCENT,
	STATUS_DETECTIVE,
	STATUS_TRAITOR,
	STATUS_NONE
}

enum _:Data_Array{
	ARRAY_ITEM_NAME[40],
	ARRAY_ITEM_STATUS,
	ARRAY_ITEM_COST,
	ARRAY_ITEM_TO_INVENTORY
}

const IMPULSE_FLASHLIGHT = 100;

new Array:g_aItemData;
new g_iItemsCount, g_fwItemSelectedFromShop, g_fwItemSelectedFromInventory, g_fwDummyResult

new const szServerPrefix[] = "^1[^4TTT^1]";

new g_iExtraItemsBuyed[33][MAX_EXTRA_ITEMS], g_iPreviusExtraItemsBuyed[33][MAX_EXTRA_ITEMS], g_iInventoryItems[33][MAX_EXTRA_ITEMS];

new const g_szBuyCommands[][] =  
{ 
    "buy", "buyequip", "usp", "glock", "deagle", "p228", "elites", "fn57", "m3", "xm1014", "mp5", "tmp", "p90", "mac10", "ump45", "ak47",  
    "galil", "famas", "sg552", "m4a1", "aug", "scout", "awp", "g3sg1", "sg550", "m249", "vest", "vesthelm", "flash", "hegren", 
    "sgren", "defuser", "nvgs", "shield", "primammo", "secammo", "km45", "9x19mm", "nighthawk", "228compact", "12gauge", 
    "autoshotgun", "smg", "mp", "c90", "cv47", "defender", "clarion", "krieg552", "bullpup", "magnum", "d3au1", "krieg550", 
    "buyammo1", "buyammo2", "cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy"
};

new const szBuySound[] = "ttt/buy.wav";
new const szSelectSound[] = "ttt/select.wav";
new const szMainMenuOpenSound[] = "events/enemy_died.wav";

/* ===================================================================================
									PLUGIN FORWARDS
======================================================================================*/

public plugin_init(){
	register_plugin("TTT Shop And Inventory", "1.0", "Roccoxx");

	register_clcmd("say /shop", "ShowShopMenu");
	register_clcmd("say shop", "ShowShopMenu");
	register_clcmd("say !shop", "ShowShopMenu");
	for(new i; i < sizeof(g_szBuyCommands); i++) register_clcmd(g_szBuyCommands[i], "ShowShopMenu"); 

	g_fwItemSelectedFromShop = CreateMultiForward("ttt_shop_item_selected", ET_CONTINUE, FP_CELL, FP_CELL);
	g_fwItemSelectedFromInventory = CreateMultiForward("ttt_inventory_item_selected", ET_CONTINUE, FP_CELL, FP_CELL);

	register_impulse(IMPULSE_FLASHLIGHT, "HookFlashLight");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", false);
}

public plugin_natives(){
	register_native("ttt_register_item", "RegisterItem", 1);
	register_native("ttt_print_items_buyed", "PrintItems", 1);
	register_native("ttt_remove_item_from_inventory", "RemoveItemFromInventory", 1);
}

public plugin_precache(){
	g_aItemData = ArrayCreate(Data_Array);

	precache_sound(szBuySound);
	precache_sound(szSelectSound);
}

public plugin_end(){
	ArrayDestroy(g_aItemData);
}

/* ===================================================================================
									CLIENT FORWARDS
======================================================================================*/

public client_putinserver(iId){
	arrayset(g_iExtraItemsBuyed[iId], 0, MAX_EXTRA_ITEMS);
	arrayset(g_iPreviusExtraItemsBuyed[iId], 0, MAX_EXTRA_ITEMS);
	arrayset(g_iInventoryItems[iId], 0, MAX_EXTRA_ITEMS);

	client_cmd(iId,"setinfo _vgui_menus 0");
}

public HookFlashLight(const iId){
	if(!is_user_alive(iId)) return PLUGIN_HANDLED;

	ShowInventoryMenu(iId);
	return PLUGIN_HANDLED;
}

/* ===================================================================================
									ROUND FORWARDS
======================================================================================*/

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	new i, j;
	for(i = 1; i <= MAX_PLAYERS; i++){
		for(j = 0; j < MAX_EXTRA_ITEMS; j++){
			g_iPreviusExtraItemsBuyed[i][j] = g_iExtraItemsBuyed[i][j];

			g_iExtraItemsBuyed[i][j] = 0;
			g_iInventoryItems[i][j] = 0;
		}
	}
}

/* ===================================================================================
									MENUS
======================================================================================*/

public ShowShopMenu(const iId)
{
	if(!is_user_alive(iId)) return PLUGIN_HANDLED;

	new iPlayerStatus = ttt_get_user_status(iId);

	if(iPlayerStatus == STATUS_INNOCENT || iPlayerStatus == STATUS_NONE) return PLUGIN_HANDLED;

	new iMenu = menu_create(fmt("\rTTT \wTienda^nTus Creditos:\y %d", ttt_get_user_credits(iId)), "ShopMenu");

	new pos[6], Data[Data_Array];

	for(new i; i < g_iItemsCount; i++){
		ArrayGetArray(g_aItemData, i, Data);

		if(iPlayerStatus != Data[ARRAY_ITEM_STATUS]) continue;

		num_to_str(i, pos, charsmax(pos));
		menu_additem(iMenu, fmt("\w%s \r[Creditos: $%d]", Data[ARRAY_ITEM_NAME], Data[ARRAY_ITEM_COST]), pos);
	}

	menu_setprop(iMenu, MPROP_PERPAGE, 6);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "Salir");
	menu_setprop(iMenu, MPROP_BACKNAME, "Atras");
	menu_setprop(iMenu, MPROP_NEXTNAME, "Siguiente");

	menu_display(iId, iMenu); client_cmd(iId, "spk ^"%s^"", szMainMenuOpenSound);
	return PLUGIN_HANDLED;
}

public ShopMenu(const iId, const iMenu, const iItemNum){
	if(iItemNum == MENU_EXIT || !is_user_alive(iId)){
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new szItemPos[6], iItemPos; menu_item_getinfo(iMenu, iItemNum, _, szItemPos, charsmax(szItemPos), _, _, _); iItemPos = str_to_num(szItemPos);

	new Data[Data_Array]; ArrayGetArray(g_aItemData, iItemPos, Data);

	if(ttt_get_user_status(iId) != Data[ARRAY_ITEM_STATUS])
	{
		client_print_color(iId, iId, "%s Item no disponible para tu rol", szServerPrefix);
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new iCredits = ttt_get_user_credits(iId);

	if(iCredits < Data[ARRAY_ITEM_COST])
	{
		client_print_color(iId, iId, "%s No tienes suficientes creditos para comprar este item!", szServerPrefix);
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}
	
	ttt_set_user_credits(iId, (iCredits-Data[ARRAY_ITEM_COST]));
	g_iExtraItemsBuyed[iId][iItemPos]++;

	client_cmd(iId, "spk ^"%s^"", szBuySound);

	if(Data[ARRAY_ITEM_TO_INVENTORY]){
		client_print_color(iId, iId, "%s^4 %s^1 Fue agregado a tu mochila", szServerPrefix, Data[ARRAY_ITEM_NAME]);
		client_print_color(iId, iId, "%s Recuerda abrir tu mochila con la letra^4 F", szServerPrefix);
		g_iInventoryItems[iId][iItemPos]++;
	}
	else
		client_print_color(iId, iId, "%s Compraste^4 %s", szServerPrefix, Data[ARRAY_ITEM_NAME]);

	ExecuteForward(g_fwItemSelectedFromShop, g_fwDummyResult, iId, iItemPos);

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

ShowInventoryMenu(const iId)
{	
	if(!is_user_alive(iId)) return PLUGIN_HANDLED;

	new iPlayerStatus = ttt_get_user_status(iId);

	if(iPlayerStatus == STATUS_INNOCENT || iPlayerStatus == STATUS_NONE) return PLUGIN_HANDLED;

	new bool:bHaveItems;
	for(new i; i < g_iItemsCount; i++){
		if(g_iInventoryItems[iId][i] >= 1){
			bHaveItems = true;
			break;
		}
	}

	if(!bHaveItems){
		client_print_color(iId, iId, "%s No tienes items!", szServerPrefix);
		return PLUGIN_HANDLED;
	}

	new iMenu = menu_create("\rTTT \wMochila", "InventoryMenu");

	new pos[6], Data[Data_Array];

	for(new i; i < g_iItemsCount; i++){
		if(g_iInventoryItems[iId][i] < 1) continue;

		ArrayGetArray(g_aItemData, i, Data);

		if(iPlayerStatus != Data[ARRAY_ITEM_STATUS]) continue;

		num_to_str(i, pos, charsmax(pos));
		menu_additem(iMenu, fmt("\w%s \r(%d)", Data[ARRAY_ITEM_NAME], g_iInventoryItems[iId][i]), pos);
	}

	menu_setprop(iMenu, MPROP_PERPAGE, 6);

	menu_setprop(iMenu, MPROP_EXITNAME, "Salir");
	menu_setprop(iMenu, MPROP_BACKNAME, "Atras");
	menu_setprop(iMenu, MPROP_NEXTNAME, "Siguiente");
	
	menu_display(iId, iMenu);
	return PLUGIN_HANDLED;
}

public InventoryMenu(const iId, const iMenu, const iItemNum){
	if(iItemNum == MENU_EXIT || !is_user_alive(iId)){
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new szItemPos[6], iItemPos; menu_item_getinfo(iMenu, iItemNum, _, szItemPos, charsmax(szItemPos), _, _, _); iItemPos = str_to_num(szItemPos);

	new Data[Data_Array]; ArrayGetArray(g_aItemData, iItemPos, Data);

	if(ttt_get_user_status(iId) != Data[ARRAY_ITEM_STATUS])
	{
		client_print_color(iId, iId, "%s Item no disponible para tu rol", szServerPrefix);
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}
	
	client_cmd(iId, "spk ^"%s^"", szSelectSound);
	ExecuteForward(g_fwItemSelectedFromInventory, g_fwDummyResult, iId, iItemPos);	

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

/* ===================================================================================
									NATIVE CALLBACK
======================================================================================*/

public RegisterItem(const szName[], const iStatus, const iCost, const iInventoryItem)
{
	param_convert(1);

	if(g_iItemsCount >= MAX_EXTRA_ITEMS){
		log_error(AMX_ERR_NATIVE, "%s Item limit reached!", szServerPrefix);
		return PLUGIN_HANDLED;
	}
	
	if (strlen(szName) < 1)
	{
		log_error(AMX_ERR_NATIVE, "%s Can't register item with an empty name", szServerPrefix);
		return PLUGIN_HANDLED;
	}
	
	new Data[Data_Array];
	for (new iIndex; iIndex < g_iItemsCount; iIndex++)
	{
		ArrayGetArray(g_aItemData, iIndex, Data);
		if(equali(szName, Data[ARRAY_ITEM_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "%s Extra item already registered (%s)", szServerPrefix, szName);
			return PLUGIN_HANDLED;
		}
	}

	copy(Data[ARRAY_ITEM_NAME], 39, szName); Data[ARRAY_ITEM_STATUS] = iStatus;  Data[ARRAY_ITEM_COST] = iCost; Data[ARRAY_ITEM_TO_INVENTORY] = iInventoryItem;
	ArrayPushArray(g_aItemData, Data);
	g_iItemsCount++;
	
	return g_iItemsCount-1;
}

public PrintItems(const iId){
	if(g_iItemsCount < 1) return;

	new i, j, szPlayerName[32], Data[Data_Array];
	for(i = 1; i <= MAX_PLAYERS; i++){
		get_user_name(i, szPlayerName, charsmax(szPlayerName));

		for(j = 0; j < g_iItemsCount; j++){
			if(g_iPreviusExtraItemsBuyed[i][j]){
				ArrayGetArray(g_aItemData, j, Data);
				console_print(iId, "%s - %s Cantidad: %d", szPlayerName, Data[ARRAY_ITEM_NAME], g_iPreviusExtraItemsBuyed[i][j]);
			}
		}
	}
}

public RemoveItemFromInventory(const iId, const iItem) g_iInventoryItems[iId][iItem]--;