//
//  dj_zombie_object_cache.h
//  DJZombieCheck
//
//  advance implementation for __dealloc_zombie
//
//  Created by Dokay on 2017/3/26.
//  Copyright © 2017年 dj226. All rights reserved.

#ifndef dj_zombie_object_cache_h
#define dj_zombie_object_cache_h

#include <stdio.h>

/*
 There are two kind of objects, one is biz object ,the other is base object, they are all free when app receive memory warning, base object will free first.
 */

/**
 init curent zombie object memeory manage
 */
void dj_zombie_init_current(void);

/**
 add zombie object address for class not biz.

 @param address zombie object address
 @param name zombie object class name
 */
void dj_zombie_add_base(void *address,const char *name);

/**
 add zombie object for class biz

 @param address zombie object address
 @param name zombie object class name
 */
void dj_zombie_add_biz(void *address,const char *name);

/**
 release zombie objects for memeory warning.
 */
void dj_zombie_release_memory_for_memory_warning(void);

/**
 free all zombie objects memory
 */
void dj_zombie_free_all(void);

#endif /* dj_zombie_object_cache_h */
