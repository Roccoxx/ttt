#if defined _ttt_core_included
	#endinput
#endif

#define _ttt_core_included

native ttt_get_user_status(const iId);
native ttt_get_user_credits(const iId);
native ttt_set_user_credits(const iId, const iAmount);
native ttt_fix_user_freeshots(const iAttacker);
native ttt_is_round_end();
native ttt_find_body(const iId);
native ttt_is_body_analized(const iOwner);
native ttt_get_body_killer(const iOwner);
native Float:ttt_get_body_time(const iOwner);
native ttt_get_body_name(const iOwner, szName[], szNameSize);
native ttt_update_body_weapon(const iOwner, const szWeapon[]);
native ttt_update_user_points(const iId, const iValue);

native ttt_set_user_fake_name(const iId, const szName[]);
native ttt_get_user_fake_name(const iId, szName[], szNameSize);
native ttt_set_karma_and_fs(const iAttacker, const iVictim, const Float:fDamage);
native ttt_get_damage_by_karma(const iAttacker, const iVictim, Float:fDamage);

// update from ttt_coreconst.inc
enum _:Statistics_List{
	SECONDS_PLAYED,
	POINTS,
	DETECTIVES_KILLED,
	INNOCENTS_KILLED,
	TRAITORS_KILLED,
	KILLS_COUNT,
	DEATHS_COUNT,
	DAMAGE_CORRECT,
	DAMAGE_INCORRECT,
	KILLS_CORRECT,
	KILLS_INCORRECT,
	TRAITOR_ROUNDS,
	INNOCENT_ROUNDS,
	DETECTIVE_ROUNDS,
	ROUNDS_PLAYED,
	ROUNDS_WIN,
	TRAITOR_ROUNDS_WIN,
	MAX_KARMA_COUNT,
	C4_PLANTED,
	C4_EXPLODED,
	C4_DEFUSED,
	C4_KILLS,
	KNIFE_KILLS,
	NEWTON_KILLS,
	JIHAD_KILLS,
	USP_KILLS,
	GOLDEN_KILLS,
	MINE_KILLS,
	STATION_KILLS,
	MORTAL_HIT_KILLS,
	FALSE_DETECTIVE_BUYS,
	PLAYERS_DISARMED,
	PLAYERS_UNMARKED
}

native ttt_update_statistic(const iId, const iStatistics);

// update from ttt_coreconst.inc
enum _:Achievement_type{
	Achievement_type_time,
	Achievement_type_correct,
	Achievement_type_round,
	Achievement_type_traitor,
	Achievement_type_incorrect,
	Achievement_type_kills,
	Achievement_type_fake_detective,
	Achievement_type_disarmed,
	Achievement_type_unmarked
}

native ttt_check_achievement_type(const iId, const iType);