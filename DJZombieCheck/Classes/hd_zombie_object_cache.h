//
//  hd_zombie_object_cache.h
//  eif-ios-app
//
//  Created by Dokay on 2017/11/14.
//  Copyright © 2017年 Ever Grande. All rights reserved.
//

#ifndef hd_zombie_object_cache_h
#define hd_zombie_object_cache_h

#include <stdio.h>

/*
 There are two kind of objects, one is biz object ,the other is base object, they are all free when app receive memory warning, base object will free first.
 */

/**
 init curent zombie object memeory manage
 */
void hd_zombie_init_current(void);

/**
 add zombie object address for class not biz.

 @param address zombie object address
 @param name zombie object class name
 */
void hd_zombie_add_base(void *address,const char *name);

/**
 add zombie object for class biz

 @param address zombie object address
 @param name zombie object class name
 */
void hd_zombie_add_biz(void *address,const char *name);

/**
 release zombie objects for memeory warning.
 */
void hd_zombie_release_memory_for_memory_warning(void);

/**
 free all zombie objects memory
 */
void hd_zombie_free_all(void);

#endif /* hd_zombie_object_cache_h */
