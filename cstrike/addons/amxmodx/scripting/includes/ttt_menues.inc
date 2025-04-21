#if defined _ttt_menues_included
	#endinput
#endif

#define _ttt_menues_included

ShowMenuBody(const iId){
	oldmenu_create("MenuBody", "%L", LANG_PLAYER, "BODY_MENU_TITLE");

	oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "BODY_MENU_REPORT");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuBody(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0 || !GetPlayerBit(g_bIsAlive, iId))
		return;

	new iEnt = IsAimingAt(iId, MAX_BODY_DIST, szDeadBodyClassName);

	if (iEnt > 0) {
		new iOwner = entity_get_edict(iEnt, EV_ENT_owner);

		if (g_iDeadBodyEnt[iOwner][BODY_STATUS] == BODY_NOT_REPORTED) {
			g_iDeadBodyEnt[iOwner][BODY_STATUS] = BODY_REPORTED;
			entity_set_int(iEnt, EV_INT_impulse, IMPULSE_REPORTED);

			client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "BODY_MENU_REPORT_SUCCESS");
		}
		else client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "BODY_MENU_ALREADY_REPORTED");
	}
	else client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "BODY_MENU_NO_BODY");
}

ShowMenuBodyInfo(const iId, const iVictim)
{
	oldmenu_create("MenuBodyInfo", "\y%L", LANG_PLAYER, "BODY_MENU_INFO_TITLE");

	oldmenu_additem(1, 1, "\r- \%L:\y %s", LANG_PLAYER, "BODY_MENU_INFO_NAME_OPTION", g_iDeadBodyEnt[iVictim][BODY_NAME]);
	oldmenu_additem(2, 2, "\r- \w%L:\y %s", LANG_PLAYER, "BODY_MENU_INFO_ROL_OPTION", szPlayerStatus[g_iDeadBodyEnt[iVictim][BODY_OWNER_STATUS]]);
	oldmenu_additem(3, 3, "\r- \w%L:\y %s", LANG_PLAYER, "BODY_MENU_INFO_KILLER_OPTION", g_iDeadBodyEnt[iVictim][BODY_WEAPON]);
	oldmenu_additem(4, 4, "\r- \w%L", LANG_PLAYER, "BODY_MENU_INFO_DEATH_TIME_OPTION", get_gametime() - g_iDeadBodyEnt[iVictim][BODY_SECONDS]);

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuBodyInfo(const iId, const iItemNum, const iValue, const iPage) {}

ShowMainMenu(const iId)
{
	oldmenu_create("MainMenu", "\rTTT \w%L", LANG_PLAYER, "MAIN_MENU_TITLE");

	if(g_iPlayerStatus[iId] != STATUS_INNOCENT) oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "MAIN_MENU_SHOP");
	else oldmenu_additem(1, 1, "\d1. \w%L", LANG_PLAYER, "MAIN_MENU_SHOP");

	oldmenu_additem(2, 2, "\r2. \w%L", LANG_PLAYER, "MAIN_MENU_WARNINGS");

	if (GetPlayerBit(g_bIsAlive, iId)) 
		oldmenu_additem(3, 3, "\d3. %L", LANG_PLAYER, "MAIN_MENU_MURDERS");
	else 
		oldmenu_additem(3, 3, "\r3. \w%L", LANG_PLAYER, "MAIN_MENU_MURDERS");

	oldmenu_additem(4, 4, "\r4. \w%L", LANG_PLAYER, "MAIN_MENU_ACCOUNT");
	oldmenu_additem(5, 5, "\r5. \w%L", LANG_PLAYER, "MAIN_MENU_RULES");
	oldmenu_additem(6, 6, "\r6. \w%L", LANG_PLAYER, "MAIN_MENU_TOPS");
	oldmenu_additem(7, 7, "\r7. \w%L", LANG_PLAYER, "MAIN_MENU_PREVIOUS_STATUS");
	oldmenu_additem(8, 8, "\r8. \w%L", LANG_PLAYER, "MAIN_MENU_ADMIN");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

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
			else client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "MAIN_MENU_ADMIN_NO_PERM");
		}
	}
}

ShowMenuWarnings(const iId)
{
	oldmenu_create("MenuWarnings", "\rTTT \w%L", LANG_PLAYER, "MENU_WARNINGS_TITLE");

	oldmenu_additem(1, 1, "\r- \w%L^n", LANG_PLAYER, "MENU_WARNINGS_TEAM_KILLS");

	oldmenu_additem(1, 1, "\r- \w%L:\y %d\d/\y%d", LANG_PLAYER, "MENU_WARNINGS_INNOCENTS", g_iTeamKills[iId][TEAM_KILLS_COUNT], TEAM_KILLS_INNOCENT_LIMIT);
	oldmenu_additem(1, 1, "\r- \w%L:\y %d\d/\y%d", LANG_PLAYER, "MENU_WARNINGS_TEAMMATES", g_iTeamKills[iId][TEAM_TEAMMATES_KILLED], TEAMMATES_KILLS_LIMIT);

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuWarnings(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuMurders(const iId)
{
	if (g_iPlayerStatus[iId] == STATUS_NONE)
		return;

	new iSize = ArraySize(g_aMurders);
	
	if (iSize <= 0)
		return;

	oldmenu_create("MenuMurders", "\rTTT \w%L", LANG_PLAYER, "MENU_MURDERS_TITLE");

	new iData[ArrayMurdersData], bool:bHaveMurders;

	for(new i; i < iSize; i++){
		ArrayGetArray(g_aMurders, i, iData);

		if(iData[iMurderAttacker] == iId){
			bHaveMurders = true;
			oldmenu_additem(i+1, i+1, "\r%d \w%s \r%L:\w %s", i+1, iData[szMurderVictimName], LANG_PLAYER, "MENU_MURDERS_ROLE", szPlayerStatus[iData[iMuerderVictimStatus]]);
		}
	}

	if (!bHaveMurders)
		oldmenu_additem(1, 1, "\d%L", LANG_PLAYER, "MENU_MURDERS_NO_MURDERS");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuMurders(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuAccount(const iId)
{
	oldmenu_create("MenuAccount", "\rTTT \w%L", LANG_PLAYER, "MENU_ACCOUNT_TITLE");

	oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "MENU_ACCOUNT_ACHIEVEMENTS");
	oldmenu_additem(2, 2, "\r2. \w%L", LANG_PLAYER, "MENU_ACCOUNT_STATISTICS");
	oldmenu_additem(3, 3, "\r3. \w%L", LANG_PLAYER, "MENU_ACCOUNT_COUNTDOWN");
	oldmenu_additem(4, 4, "\r4. \w%L", LANG_PLAYER, "MENU_ACCOUNT_HIDE_MOTD");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

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

ShowMenuAchievements(const iId, iPage)
{
	oldmenu_create("MenuAchievements", "\rTTT \w%L", LANG_PLAYER, "MENU_ACHIEVEMENTS_TITLE");

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, AchievementsList);

	for(new i=0+iStart, iCount=1; i < iEnd; i++, iCount++)
		oldmenu_additem(iCount, i, "\r%d. \w%s", iCount, g_DataAchievements[i][ACHIEVEMENT_NAME]);

	AddNextBackExitOptions(iPage, iMaxPages);

	oldmenu_display(iId, iPage);
}

public MenuAchievements(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0)
		return;

	if (iItemNum == 8) {
		ShowMenuAchievements(iId, iPage-1);
		return;
	}

	if (iItemNum == 9) {
		ShowMenuAchievements(iId, iPage+1);
		return;
	}

	ShowMenuAchievementInfo(iId, iValue);
}

ShowMenuAchievementInfo(const iId, const iAchievement)
{
	oldmenu_create("MenuAchievementInfo", "\y%s: \w%s", g_DataAchievements[iAchievement][ACHIEVEMENT_NAME], g_DataAchievements[iAchievement][ACHIEVEMENT_DESCRIPTION]);

	oldmenu_additem(1, 1, "\r1. \w%L:\y %L", LANG_PLAYER, "MENU_ACHIEVEMENTS_INFO_STATUS_OPTION", LANG_PLAYER, g_iPlayerAchievements[iId][iAchievement] ? "MENU_ACHIEVEMENTS_INFO_STATUS_OPTION_COMPLETED" : "MENU_ACHIEVEMENTS_INFO_STATUS_OPTION_INCOMPLETE");
	oldmenu_additem(2, 2, "\r2. \w%L:\y %d", LANG_PLAYER, "MENU_ACHIEVEMENTS_INFO_STATUS_PROGRESS", GetAchievementProgress(iId, iAchievement));

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuAchievementInfo(const iId, const iItemNum, const iValue, const iPage) {}

ShowMenuStatistics(const iId, iPage)
{
	oldmenu_create("MenuStatistics", "\rTTT \w%L", LANG_PLAYER, "MENU_STATISTICS_TITLE");

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, Statistics_List);

	for (new i=0+iStart, iCount=1; i < iEnd; i++, iCount++) {
		if (i == SECONDS_PLAYED) {
			new iDays, iHours, iMins, iSegs;
			iSegs = g_iPlayerStatistics[iId][SECONDS_PLAYED]; iMins = iSegs/60; iHours = iMins/60; iDays = iHours/24;
			iSegs = iSegs-iMins*60; iMins = iMins-iHours*60; iHours = iHours-iDays*24;

			oldmenu_additem(iCount, i, "\r-\w%L: %i %L%s - %s%i:%s%i:%s%i",
			LANG_PLAYER, "MENU_STATISTICS_PLAYED_OPTION",
			iDays,
			LANG_PLAYER, "MENU_STATISTICS_PLAYED_DAYS_OPTION",
			iDays == 1 ? "" : "s", iHours > 9 ? "" : "0", iHours, iMins > 9 ? "" : "0", iMins, iSegs > 9 ? "" : "0", iSegs);
		}
		else
			oldmenu_additem(iCount, i, "\r-\w%s: \y%d", szStatistics[i], g_iPlayerStatistics[iId][i]);
	}

	AddNextBackExitOptions(iPage, iMaxPages);

	oldmenu_display(iId, iPage);
}

public MenuStatistics(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0)
		return;

	if (iItemNum == 8) {
		ShowMenuStatistics(iId, iPage-1);
		return;
	}

	if (iItemNum == 9) {
		ShowMenuStatistics(iId, iPage+1);
		return;
	}
}

ShowMenuCountDown(const iId)
{
	oldmenu_create("MenuCountDown", "\rTTT \w%L^n\w%L:\y %L",
	LANG_PLAYER, "MENU_COUNTDOWN_TITLE",
	LANG_PLAYER, "MENU_COUNTDOWN_DESCRIPTION",
	LANG_PLAYER, GetPlayerBit(g_bMuteCountDown, iId) ? "MENU_COUNTDOWN_DISABLED" : "MENU_COUNTDOWN_ENABLED");

	oldmenu_additem(1, 1, "\r1. \r%L \w%L",
	LANG_PLAYER, GetPlayerBit(g_bMuteCountDown, iId) ? "MENU_COUNTDOWN_ENABLED_OPTION" : "MENU_COUNTDOWN_DISABLED_OPTION",
	LANG_PLAYER, "MENU_COUNTDOWN_OPTION");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuCountDown(const iId, const iItemNum, const iValue, const iPage)
{
	if(iItemNum == 0)
		return;

	if (GetPlayerBit(g_bMuteCountDown, iId))
		ClearPlayerBit(g_bMuteCountDown, iId);
	else
		SetPlayerBit(g_bMuteCountDown, iId);

	ShowMenuCountDown(iId);
}

ShowMenuHideMotd(const iId)
{
	oldmenu_create("MenuHideMotd", "\rTTT \w%L^n\w%L:\y %L",
	LANG_PLAYER, "MENU_HIDE_MOTD_TITLE",
	LANG_PLAYER, "MENU_HIDE_MOTD_DESCRIPTION",
	LANG_PLAYER, GetPlayerBit(g_bHideMotd, iId) ? "MENU_HIDE_MOTD_DISABLED" : "MENU_HIDE_MOTD_ENABLED");

	oldmenu_additem(1, 1, "\r1. \r%L \wMotd", LANG_PLAYER, GetPlayerBit(g_bHideMotd, iId) ? "MENU_HIDE_MOTD_ENABLED_OPTION" : "MENU_HIDE_MOTD_DISABLED_OPTION");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuHideMotd(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0)
		return;

	if (GetPlayerBit(g_bHideMotd, iId))
		ClearPlayerBit(g_bHideMotd, iId);
	else
		SetPlayerBit(g_bHideMotd, iId);

	ShowMenuHideMotd(iId);
}

ShowMenuRules(const iId)
{
	oldmenu_create("MenuRules", "\rTTT \w%L", LANG_PLAYER, "MENU_RULES_TITLE");

	oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "MENU_RULES_HOW_TO_PLAY");
	oldmenu_additem(2, 2, "\r1. \w%L", LANG_PLAYER, "MENU_RULES_RULES");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuRules(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0)
		return;

	if (iItemNum == 1)
		show_motd(iId, "http://comunidad24hs.com.ar/comojugar.html", "Como Jugar");
	else
		show_motd(iId, "http://comunidad24hs.com.ar/reglas.html", "Reglas");
}

ShowMenuPreviusStatus(const iId, iPage)
{
	new iSize = ArraySize(g_aPreviusRoundStatus);
	
	if(iSize <= 0)
		return;

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, iSize, 6);
 	
	oldmenu_create("MenuPreviusStatus", "\rTTT \w%L \r%d/%d", LANG_PLAYER, "MENU_PREVIUS_STATUS_TITLE", iPage, iMaxPages);
 	
 	new iData[ArrayStatusRoundData];
	for(new i=0+iStart, count=1; i < iEnd; i++, count++)
	{
		ArrayGetArray(g_aPreviusRoundStatus, i, iData);
		oldmenu_additem(i+1, i+1, "\r- \w%s:\y %s", iData[PlayerRoundName], szPlayerStatus[iData[PlayerRoundStatus]]);
	}
 
	AddNextBackExitOptions(iPage, iMaxPages);
 
	oldmenu_display(iId, iPage);
}

public MenuPreviusStatus(const iId, const iItemNum, const iValue, const iPage)
{
	switch(iItemNum)
	{
		case 8: ShowMenuPreviusStatus(iId, iPage-1);
		case 9: ShowMenuPreviusStatus(iId, iPage+1);
	}
}

ShowMenuAdmin(const iId)
{
	oldmenu_create("MenuAdmin", "\rTTT \w%L", LANG_PLAYER, "MENU_ADMIN_TITLE");

	oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "MENU_ADMIN_SLAY");
	oldmenu_additem(2, 2, "\r2. \w%L", LANG_PLAYER, "MENU_ADMIN_DAMAGE_LIST");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public MenuAdmin(const iId, const iItemNum, const iValue, const iPage)
{
	switch(iItemNum){
		case 1: ShowMenuSlay(iId, 0);
		case 2: ShowMenuDamageList(iId, 0);
	}
}

public ShowMenuSlay(const iId, iPage)
{
	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, MAX_PLAYERS);
 	
	oldmenu_create("MenuSlay", "\rTTT \w%L \r%d/%d", LANG_PLAYER, "MENU_SLAY_TITLE", iPage, iMaxPages);
 
	for (new i=1+iStart, count=1; i <= iEnd; i++, count++)
	{
		if (!GetPlayerBit(g_bIsConnected, i))
			continue;
 
		get_user_name(i, szName, 31);
		oldmenu_additem(count, i, "\r%d. \w%s", count, szName);
	}
 
	AddNextBackExitOptions(iPage, iMaxPages);
 
	oldmenu_display(iId, iPage);
}

public MenuSlay(const iId, const iItemNum, const iValue, const iPage)
{
	if (iItemNum == 0)
		return;

	if (iItemNum == 8) {
		ShowMenuSlay(iId, iPage-1);
		return;
	}
 
	if (iItemNum == 9) {
		ShowMenuSlay(iId, iPage+1);
		return;
	}
 	
 	if (GetPlayerBit(g_bIsConnected, iValue)) {
 		client_cmd(iId, "messagemode SlayReason");
 		get_user_name(iValue, szName, 31);
 		copy(g_szPlayerTarget[iId], 31, szName);
 	}
 	else 
		client_print_color(iId, iId, "%s %L", szModPrefix, LANG_PLAYER, "MENU_SLAY_NO_PLAYER");
}

ShowMenuDamageList(const iId, iPage)
{
	new iSize = ArraySize(g_aPreviusRoundDamage);
	
	if(iSize <= 0)
		return;

	new iMaxPages, iStart, iEnd; oldmenu_calculate_pages(iMaxPages, iStart, iEnd, iPage, iSize, 6);
 	
	oldmenu_create("DamageList", "\rTTT \w%L \r%d/%d", LANG_PLAYER, "MENU_DAMAGE_LIST_TITLE", iPage, iMaxPages);
 	
 	new iData[ArrayDamageData];
	for(new i=0+iStart, count=1; i < iEnd; i++, count++)
	{
		ArrayGetArray(g_aPreviusRoundDamage, i, iData);
		oldmenu_additem(count, i, "\r-. \w%s: %s -> %s: %s | %.2f Dmg^n", szPlayerStatus[iData[iDamageAttackerStatus]], iData[szDamageAttackerName], 
		szPlayerStatus[iData[iDamageVictimStatus]], iData[szDamageVictimName], iData[fDamageCount]);
	}
 
	AddNextBackExitOptions(iPage, iMaxPages);
 
	oldmenu_display(iId, iPage);
}

public DamageList(const iId, const iItemNum, const iValue, const iPage)
{
	switch(iItemNum){
		case 8: ShowMenuDamageList(iId, iPage-1);
		case 9: ShowMenuDamageList(iId, iPage+1);
	}
}

ShowTopMenu(const iId)
{
	oldmenu_create("TopMenu", "\rTTT \w%L", LANG_PLAYER, "MENU_TOP_TITLE");

	oldmenu_additem(1, 1, "\r1. \w%L", LANG_PLAYER, "MENU_TOP_POINTS");
	oldmenu_additem(2, 2, "\r2. \w%L", LANG_PLAYER, "MENU_TOP_MAX_KARMA");
	oldmenu_additem(3, 3, "\r3. \w%L", LANG_PLAYER, "MENU_TOP_FREE_KILL");
	oldmenu_additem(4, 4, "\r4. \w%L", LANG_PLAYER, "MENU_TOP_GENERAL");

	oldmenu_additem(0, MENU_EXIT, "^n\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");

	oldmenu_display(iId);
}

public TopMenu(const iId, const iItemNum, const iValue, const iPage){
	if(iItemNum == 0)
		return;

	switch(iItemNum){
		case 1: show_motd(iId, "http://comunidad24hs.com.ar/toppuntos.php", "Top Puntos");
		case 2: show_motd(iId, "http://comunidad24hs.com.ar/topkarma.php", "Top MaxKarma");
		case 3: show_motd(iId, "http://comunidad24hs.com.ar/topfreekill.php", "Top Freekill");
		case 4: show_motd(iId, "http://comunidad24hs.com.ar/topgeneral.php", "Top General");
	}
}

AddNextBackExitOptions(const iPage, const iMaxPages) {
	if (iPage > 1)
		oldmenu_additem(8, 0, "^n\r8. \%L", LANG_PLAYER, "MENU_BACK_OPTION");
	else
		oldmenu_additem(-1, 0, "^n\d8. %L", LANG_PLAYER, "MENU_BACK_OPTION");
	
	if (iPage < iMaxPages) 
		oldmenu_additem(9, 0, "\r9. \w%L", LANG_PLAYER, "MENU_NEXT_OPTION");
	else
		oldmenu_additem(-1, 0, "\d9. %L", LANG_PLAYER, "MENU_NEXT_OPTION");

	oldmenu_additem(0, 0, "\r0.\w%L", LANG_PLAYER, "MENU_EXIT_OPTION");
}