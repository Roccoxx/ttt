#if defined _ttt_menues_included
	#endinput
#endif

#define _ttt_menues_included

ShowMenuBody(const iId){
	oldmenu_create("MenuBody", "Menu del Cuerpo");

	oldmenu_additem(1, 1, "\r1. \wLlamar Detective");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuBody(const iId, const iItemNum, const iValue, const iPage)
{
	if(iItemNum == 0 || !GetPlayerBit(g_bIsAlive, iId)) return;

	new iEnt = IsAimingAt(iId, MAX_BODY_DIST, szDeadBodyClassName);

	if(iEnt > 0){
		new iOwner = entity_get_edict(iEnt, EV_ENT_owner);

		if(g_iDeadBodyEnt[iOwner][BODY_STATUS] == BODY_NOT_REPORTED){
			g_iDeadBodyEnt[iOwner][BODY_STATUS] = BODY_REPORTED;
			entity_set_int(iEnt, EV_INT_impulse, IMPULSE_REPORTED);

			client_print_color(iId, iId, "%s Has reportado el cuerpo!", szModPrefix);
		}
		else client_print_color(iId, iId, "%s El cuerpo ya fue reportado!", szModPrefix);
	}
	else client_print_color(iId, iId, "%s Debes apuntar a un cuerpo y estar lo suficientemente cerca para realizar esta acción!", szModPrefix);
}

ShowMenuBodyInfo(const iId, const iVictim){
	oldmenu_create("MenuBodyInfo", "\yEncontraste un cuerpo!");

	oldmenu_additem(1, 1, "\r- \wNombre:\y %s", g_iDeadBodyEnt[iVictim][BODY_NAME]);
	oldmenu_additem(2, 2, "\r- \wRol:\y %s", szPlayerStatus[g_iDeadBodyEnt[iVictim][BODY_OWNER_STATUS]]);
	oldmenu_additem(3, 3, "\r- \wAsesinado por:\y %s", g_iDeadBodyEnt[iVictim][BODY_WEAPON]);
	oldmenu_additem(4, 4, "\r- \wMuerto hace:\y %.2f Segundos", get_gametime() - g_iDeadBodyEnt[iVictim][BODY_SECONDS]);

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuBodyInfo(const iId, const iItemNum, const iValue, const iPage) {}

ShowMainMenu(const iId){
	oldmenu_create("MainMenu", "\rTTT \wMenu Principal");

	if(g_iPlayerStatus[iId] != STATUS_INNOCENT) oldmenu_additem(1, 1, "\r1. \wTienda");
	else oldmenu_additem(1, 1, "\d1. Tienda");

	oldmenu_additem(2, 2, "\r2. \wAdvertencias");

	if(GetPlayerBit(g_bIsAlive, iId)) oldmenu_additem(3, 3, "\d3. Mis asesinatos");
	else oldmenu_additem(3, 3, "\r3. \wMis asesinatos");

	oldmenu_additem(4, 4, "\r4. \wMi cuenta");
	oldmenu_additem(5, 5, "\r5. \wReglas");
	oldmenu_additem(6, 6, "\r6. \wTops");
	oldmenu_additem(7, 7, "\r7. \wUltimos estados");
	oldmenu_additem(8, 8, "\r8. \wAdministracion");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MainMenu(const iId, const iItemNum, const iValue, const iPage)
{
	switch(iItemNum){
		//case 0 == EXIT
		case 1:{
			if(g_iPlayerStatus[iId] == STATUS_INNOCENT) return;

			amxclient_cmd(iId, "say", "/shop");
		}
		case 2: ShowMenuWarnings(iId);
		case 3:{
			// solo los muertos pueden ver este menu
			if(GetPlayerBit(g_bIsAlive, iId)) return;

			ShowMenuMurders(iId);
		}
		case 4: ShowMenuAccount(iId);
		case 5: ShowMenuRules(iId);
		case 6: ShowTopMenu(iId);
		case 7: ShowMenuPreviusStatus(iId, 0);
		case 8:{
			if(is_user_admin(iId) && (get_user_flags(iId) & ADMIN_FLAG)) ShowMenuAdmin(iId);
			else client_print_color(iId, iId, "%s Solo disponible para administradores!", szModPrefix);
		}
	}
}

ShowMenuWarnings(const iId){
	oldmenu_create("MenuWarnings", "\rTTT \wAdvertencias");

	oldmenu_additem(1, 1, "\r- \wEvita asesinar a tus compañeros de equipo para\r ser expulsado del servidor:^n");

	oldmenu_additem(1, 1, "\r- \wInocentes:\y %d\d/\y%d", g_iTeamKills[iId][TEAM_KILLS_COUNT], TEAM_KILLS_INNOCENT_LIMIT);
	oldmenu_additem(1, 1, "\r- \wCompañeros:\y %d\d/\y%d", g_iTeamKills[iId][TEAM_TEAMMATES_KILLED], TEAMMATES_KILLS_LIMIT);

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuWarnings(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuMurders(const iId){
	if(g_iPlayerStatus[iId] == STATUS_NONE) return;

	new iSize = ArraySize(g_aMurders);
	
	if(iSize <= 0) return;

	oldmenu_create("MenuMurders", "\rTTT \wMis Asesinatos");

	new iData[ArrayMurdersData], bool:bHaveMurders;

	for(new i; i < iSize; i++){
		ArrayGetArray(g_aMurders, i, iData);

		if(iData[iMurderAttacker] == iId){
			bHaveMurders = true;
			oldmenu_additem(i+1, i+1, "\r%d \w%s \rRol:\w %s", i+1, iData[szMurderVictimName], szPlayerStatus[iData[iMuerderVictimStatus]]);
		}
	}

	if(!bHaveMurders) oldmenu_additem(1, 1, "\dNo asesinaste a nadie esta ronda!");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuMurders(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuAccount(const iId){
	oldmenu_create("MenuAccount", "\rTTT \wCuenta");

	oldmenu_additem(1, 1, "\r1. \wLogros");
	oldmenu_additem(2, 2, "\r2. \wEstadísticas");
	oldmenu_additem(3, 3, "\r3. \wReproducir cuenta regresiva");
	oldmenu_additem(4, 4, "\r4. \wOcultar Motd");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuAccount(const iId, const iItemNum, const iValue, const iPage) 
{
	switch(iItemNum){
		case 1: ShowMenuAchievements(iId, 0);
		case 2: ShowMenuStatistics(iId, 0);
		case 3: ShowMenuCountDown(iId);
		case 4: ShowMenuHideMotd(iId);
	}
}

ShowMenuAchievements(const iId, iPage){
	oldmenu_create("MenuAchievements", "\rTTT \wLogros");

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, AchievementsList);

	for(new i=0+iStart, iCount=1; i < iEnd; i++, iCount++)
		oldmenu_additem(iCount, i, "\r%d. \w%s", iCount, g_DataAchievements[i][ACHIEVEMENT_NAME]);

	if(iPage > 1) oldmenu_additem(8, 0, "^n\r8. \wAtras");
	else oldmenu_additem(-1, 0, "^n\d8. Atras");
	if(iPage < iMaxPages) oldmenu_additem(9, 0, "\r9. \wSiguiente");
	else oldmenu_additem(-1, 0, "\d9. Siguiente");

	oldmenu_additem(0, 0, "\r0. \wSalir");

	oldmenu_display(iId, iPage);
}

public MenuAchievements(const iId, const iItemNum, const iValue, const iPage) {
	if(iItemNum == 0) return;

	if(iItemNum == 8){
		ShowMenuAchievements(iId, iPage-1);
		return;
	}

	if(iItemNum == 9){
		ShowMenuAchievements(iId, iPage+1);
		return;
	}

	ShowMenuAchievementInfo(iId, iValue);
}

ShowMenuAchievementInfo(const iId, const iAchievement){
	oldmenu_create("MenuAchievementInfo", "\y%s: \w%s", g_DataAchievements[iAchievement][ACHIEVEMENT_NAME], g_DataAchievements[iAchievement][ACHIEVEMENT_DESCRIPTION]);

	oldmenu_additem(1, 1, "\r1. \wEstado:\y %s", g_iPlayerAchievements[iId][iAchievement] ? "Completo" : "Incompleto");
	oldmenu_additem(2, 2, "\r2. \wProgreso:\y %d", GetAchievementProgress(iId, iAchievement));

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuAchievementInfo(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuStatistics(const iId, iPage){
	oldmenu_create("MenuStatistics", "\rTTT \wEstadisticas");

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, Statistics_List);

	for(new i=0+iStart, iCount=1; i < iEnd; i++, iCount++){
		if(i == SECONDS_PLAYED){
			new iDays, iHours, iMins, iSegs;
			iSegs = g_iPlayerStatistics[iId][SECONDS_PLAYED]; iMins = iSegs/60; iHours = iMins/60; iDays = iHours/24;
			iSegs = iSegs-iMins*60; iMins = iMins-iHours*60; iHours = iHours-iDays*24;

			oldmenu_additem(iCount, i, "\r-\wHaz Jugado: %i Dia%s con %s%i:%s%i:%s%i",
			iDays, iDays == 1 ? "" : "s", iHours > 9 ? "" : "0", iHours, iMins > 9 ? "" : "0", iMins, iSegs > 9 ? "" : "0", iSegs);
		}
		else oldmenu_additem(iCount, i, "\r-\w%s: \y%d", szStatistics[i], g_iPlayerStatistics[iId][i]);
	}

	if(iPage > 1) oldmenu_additem(8, 0, "^n\r8. \wAtras");
	else oldmenu_additem(-1, 0, "^n\d8. Atras");
	if(iPage < iMaxPages) oldmenu_additem(9, 0, "\r9. \wSiguiente");
	else oldmenu_additem(-1, 0, "\d9. Siguiente");

	oldmenu_additem(0, 0, "\r0. \wSalir");

	oldmenu_display(iId, iPage);
}

public MenuStatistics(const iId, const iItemNum, const iValue, const iPage) {
	if(iItemNum == 0) return;

	if(iItemNum == 8){
		ShowMenuStatistics(iId, iPage-1);
		return;
	}

	if(iItemNum == 9){
		ShowMenuStatistics(iId, iPage+1);
		return;
	}
}

ShowMenuCountDown(const iId){
	oldmenu_create("MenuCountDown", "\rTTT \wCuenta Regresiva^n\wActualmente tu cuenta regresiva se encuentra:\y %s", GetPlayerBit(g_bMuteCountDown, iId) ? "Desactivada" : "Activada");

	oldmenu_additem(1, 1, "\r1. \r%s \wCuenta regresiva", GetPlayerBit(g_bMuteCountDown, iId) ? "Activar" : "Desactivar");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuCountDown(const iId, const iItemNum, const iValue, const iPage){
	if(iItemNum == 0) return;

	if(GetPlayerBit(g_bMuteCountDown, iId)) ClearPlayerBit(g_bMuteCountDown, iId);
	else SetPlayerBit(g_bMuteCountDown, iId);

	ShowMenuCountDown(iId);
}

ShowMenuHideMotd(const iId){
	oldmenu_create("MenuHideMotd", "\rTTT \wOcultar Motd^n\wActualmente el motd se encuentra:\y %s", GetPlayerBit(g_bHideMotd, iId) ? "Oculto" : "Activado");

	oldmenu_additem(1, 1, "\r1. \r%s \wMotd", GetPlayerBit(g_bHideMotd, iId) ? "Mostrar" : "Ocultar");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuHideMotd(const iId, const iItemNum, const iValue, const iPage){
	if(iItemNum == 0) return;

	if(GetPlayerBit(g_bHideMotd, iId)) ClearPlayerBit(g_bHideMotd, iId);
	else SetPlayerBit(g_bHideMotd, iId);

	ShowMenuHideMotd(iId);
}

ShowMenuRules(const iId){
	oldmenu_create("MenuRules", "\rTTT \wReglas");

	oldmenu_additem(1, 1, "\r1. \w¿Como Jugar?");
	oldmenu_additem(2, 2, "\r1. \wReglas del servidor");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuRules(const iId, const iItemNum, const iValue, const iPage){
	if(iItemNum == 0) return;

	if(iItemNum == 1) show_motd(iId, "http://comunidad24hs.com.ar/comojugar.html", "Como Jugar");
	else show_motd(iId, "http://comunidad24hs.com.ar/reglas.html", "Reglas");
}

ShowMenuPreviusStatus(const iId, iPage)
{
	new iSize = ArraySize(g_aPreviusRoundStatus);
	if(iSize <= 0) return;

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, iSize, 6);
 	
	oldmenu_create("MenuPreviusStatus", "\rTTT \wUltimos estados \r%d/%d", iPage, iMaxPages);
 	
 	new iData[ArrayStatusRoundData];
	for(new i=0+iStart, count=1; i < iEnd; i++, count++)
	{
		ArrayGetArray(g_aPreviusRoundStatus, i, iData);
		oldmenu_additem(i+1, i+1, "\r- \w%s:\y %s", iData[PlayerRoundName], szPlayerStatus[iData[PlayerRoundStatus]]);
	}
 
	if(iPage > 1) oldmenu_additem(8, 0, "^n\r8. \wAtras");
	else oldmenu_additem(-1, 0, "^n\d8. Atras");
	if(iPage < iMaxPages) oldmenu_additem(9, 0, "\r9. \wSiguiente");
	else oldmenu_additem(-1, 0, "\d9. Siguiente");
	oldmenu_additem(0, 0, "\r0. \wSalir");
 
	oldmenu_display(iId, iPage);
}

public MenuPreviusStatus(const iId, const iItemNum, const iValue, const iPage)
{	
	switch(iItemNum){
		case 8: ShowMenuPreviusStatus(iId, iPage-1);
		case 9: ShowMenuPreviusStatus(iId, iPage+1);
	}
}

ShowMenuAdmin(const iId){	
	oldmenu_create("MenuAdmin", "\rTTT \wMenu Administracion");

	oldmenu_additem(1, 1, "\r1. \wDar Slay");
	oldmenu_additem(2, 2, "\r2. \wRegistro de Daños");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public MenuAdmin(const iId, const iItemNum, const iValue, const iPage){
	switch(iItemNum){
		case 1: ShowMenuSlay(iId, 0);
		case 2: ShowMenuDamageList(iId, 0);
	}
}

public ShowMenuSlay(const iId, iPage)
{
	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, MAX_PLAYERS);
 	
	oldmenu_create("MenuSlay", "\rTTT \wMenu Slay \r%d/%d", iPage, iMaxPages);
 
	for(new i=1+iStart, count=1; i <= iEnd; i++, count++)
	{
		if(!GetPlayerBit(g_bIsConnected, i)) continue;
 
		get_user_name(i, szName, 31);
		oldmenu_additem(count, i, "\r%d. \w%s", count, szName);
	}
 
	if(iPage > 1) oldmenu_additem(8, 0, "^n\r8. \wAtras");
	else oldmenu_additem(-1, 0, "^n\d8. Atras");
	if(iPage < iMaxPages) oldmenu_additem(9, 0, "\r9. \wSiguiente");
	else oldmenu_additem(-1, 0, "\d9. Siguiente");
	oldmenu_additem(0, 0, "\r0. \wSalir");
 
	oldmenu_display(iId, iPage);
}

public MenuSlay(const iId, const iItemNum, const iValue, const iPage)
{
	if(iItemNum == 0) return;

	if(iItemNum == 8)
	{
		ShowMenuSlay(iId, iPage-1);
		return;
	}
 
	if(iItemNum == 9)
	{
		ShowMenuSlay(iId, iPage+1);
		return;
	}
 	
 	if(GetPlayerBit(g_bIsConnected, iValue)){
 		client_cmd(iId, "messagemode SlayReason");
 		get_user_name(iValue, szName, 31);
 		copy(g_szPlayerTarget[iId], 31, szName);
 	}
 	else client_print_color(iId, iId, "%s Jugador no válido!", szModPrefix);
}

ShowMenuDamageList(const iId, iPage)
{
	new iSize = ArraySize(g_aPreviusRoundDamage);
	if(iSize <= 0) return;

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, iSize, 6);
 	
	oldmenu_create("DamageList", "\rTTT \wRegistro de daños \r%d/%d", iPage, iMaxPages);
 	
 	new iData[ArrayDamageData];
	for(new i=0+iStart, count=1; i < iEnd; i++, count++)
	{	
		ArrayGetArray(g_aPreviusRoundDamage, i, iData);
		oldmenu_additem(count, i, "\r-. \w%s: %s -> %s: %s | %.2f Daño^n", szPlayerStatus[iData[iDamageAttackerStatus]], iData[szDamageAttackerName], 
		szPlayerStatus[iData[iDamageVictimStatus]], iData[szDamageVictimName], iData[fDamageCount]);
	}
 
	if(iPage > 1) oldmenu_additem(8, 0, "^n\r8. \wAtras");
	else oldmenu_additem(-1, 0, "^n\d8. Atras");
	if(iPage < iMaxPages) oldmenu_additem(9, 0, "\r9. \wSiguiente");
	else oldmenu_additem(-1, 0, "\d9. Siguiente");
	oldmenu_additem(0, 0, "\r0. \wSalir");
 
	oldmenu_display(iId, iPage);
}

public DamageList(const iId, const iItemNum, const iValue, const iPage)
{	
	switch(iItemNum){
		case 8: ShowMenuDamageList(iId, iPage-1);
		case 9: ShowMenuDamageList(iId, iPage+1);
	}
}

ShowTopMenu(const iId){	
	oldmenu_create("TopMenu", "\rTTT \wMenu De Tops");

	oldmenu_additem(1, 1, "\r1. \wTop por puntos");
	oldmenu_additem(2, 2, "\r2. \wMaximo karma");
	oldmenu_additem(3, 3, "\r3. \wFreekill");
	oldmenu_additem(4, 4, "\r4. \wGeneral");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\wSalir");

	oldmenu_display(iId);
}

public TopMenu(const iId, const iItemNum, const iValue, const iPage){
	if(iItemNum == 0) return;

	switch(iItemNum){
		case 1: show_motd(iId, "http://comunidad24hs.com.ar/toppuntos.php", "Top Puntos");
		case 2: show_motd(iId, "http://comunidad24hs.com.ar/topkarma.php", "Top MaxKarma");
		case 3: show_motd(iId, "http://comunidad24hs.com.ar/topfreekill.php", "Top Freekill");
		case 4: show_motd(iId, "http://comunidad24hs.com.ar/topgeneral.php", "Top General");
	}
}