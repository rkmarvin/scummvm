/* Copyright (C) 1994-2003 Revolution Software Ltd
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Header$
 */

//=============================================================================
//
//	Filename	:	keyboard.h
//	Created		:	19th September 1996
//	By			:	P.R.Porter
//
//	Version	Date		By		Description
//	------- ---------	---		-----------------------------------------------
//	1.0		19-Sep-96	PRP		Internal driver interface to the keyboard driver
//								functions and data.
//
//
//	Summary		:	This include file defines links to all data which is
//					defined in the keyboard.c module, but can be accessed by
//					other parts of the driver96 library.
//
//
//=============================================================================


#ifndef KEYBOARD_H
#define KEYBOARD_H

void WriteKey(char key);		// Adds a keypress to the buffer

#endif
