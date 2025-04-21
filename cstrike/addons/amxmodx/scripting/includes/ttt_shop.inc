#if defined _ttt_shop_included
	#endinput
#endif

#define _ttt_shop_included

enum _:Player_Status{
	STATUS_INNOCENT,
	STATUS_DETECTIVE,
	STATUS_TRAITOR,
	STATUS_NONE
}

new const szModPrefix[] = "^1[^4TTT PIJUDO^1]";

native ttt_register_item(const szName[], const iStatus, const iCost, const iInventoryItem);
native ttt_print_items_buyed(const iId);
native ttt_remove_item_from_inventory(const iId, const iItem);

forward ttt_shop_item_selected(const iId, const iItem);
forward ttt_inventory_item_selected(const iId, const iItem);