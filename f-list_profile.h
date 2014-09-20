/*
 * F-List Pidgin - a libpurple protocol plugin for F-Chat
 *
 * Copyright 2011 F-List Pidgin developers.
 *
 * This file is part of F-List Pidgin.
 *
 * F-List Pidgin is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * F-List Pidgin is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with F-List Pidgin.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef FLIST_PROFILE_H
#define	FLIST_PROFILE_H

#include "f-list.h"
#define FLIST_CHARACTER_INFO_URL "https://www.f-list.net/json/api/character-info.php"
#define FLIST_INFO_LIST_URL "https://www.f-list.net/json/api/info-list.php"

gboolean flist_process_PRD(PurpleConnection *, JsonObject *);

void flist_profile_process_flood(FListAccount *, const gchar*);

void flist_profile_load(PurpleConnection *);
void flist_profile_unload(PurpleConnection *);

#endif	/* F_LIST_PROFILE_H */

