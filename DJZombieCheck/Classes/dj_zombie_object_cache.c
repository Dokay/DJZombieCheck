//
//  dj_zombie_object_cache.c
//  DJZombieCheck
//
//  advance implementation for __dealloc_zombie
//
//  Created by Dokay on 2017/3/26.
//  Copyright © 2017年 dj226. All rights reserved.

#include "dj_zombie_object_cache.h"
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>
#include <dispatch/semaphore.h>
#include <assert.h>
#include <limits.h>
#include "dj_zombie_queue.h"

typedef struct zombie_struct{
    void *zombie_address;
    struct zombie_struct *next;
}zombie_struct;

DJ_ZOMBIE_QUEUE biz_zombies_queue;
DJ_ZOMBIE_QUEUE other_zombie_queue;

bool dj_zombie_advance_manage_enable = false;

//dealloc is not thread safe, https://developer.apple.com/library/content/technotes/tn2109/_index.html
dispatch_semaphore_t dj_zombie_semaphore;
dispatch_queue_t zombieSerialDispatchQueue;

void dj_zombie_add_address(void *zombie_address,DJ_ZOMBIE_QUEUE *queue);
void dj_zombie_free(DJ_ZOMBIE_QUEUE *queue, unsigned free_count);
void dj_zombie_add(void *zombie_address,const char *name, DJ_ZOMBIE_QUEUE *queue);

void dj_zombie_init_current()
{
    dj_zombie_queue_init(&biz_zombies_queue);
    dj_zombie_queue_init(&other_zombie_queue);
    
    dj_zombie_semaphore = dispatch_semaphore_create(1);
    zombieSerialDispatchQueue = dispatch_queue_create("com.dj226.zombie",DISPATCH_QUEUE_SERIAL);
    dj_zombie_advance_manage_enable = true;
}

void dj_zombie_add_base(void *zombie_address,const char *name)
{
    dj_zombie_add(zombie_address,name,&other_zombie_queue);
}

void dj_zombie_add_biz(void *address,const char *name)
{
    dj_zombie_add(address,name,&biz_zombies_queue);
}

void dj_zombie_add(void *zombie_address,const char *name, DJ_ZOMBIE_QUEUE *queue)
{
    if (!dj_zombie_advance_manage_enable) {
        return;
    }
    
    if (zombie_address != NULL && strlen(name) > 2) {
        dispatch_semaphore_wait(dj_zombie_semaphore, DISPATCH_TIME_FOREVER);
        dj_zombie_add_address(zombie_address, queue);
        dispatch_semaphore_signal(dj_zombie_semaphore);
    }
}

void dj_zombie_release_memory_for_memory_warning()
{
    if (!dj_zombie_advance_manage_enable) {
        return;
    }
    //大量对象释放如果在主线程会卡顿；
    //由于对象已经释放，可以在后台线程释放；
    //避免多次MemoryWarning短时间内多次调用卡住线程城池里面的多个线程，使用自定义同步队列
    dispatch_async(zombieSerialDispatchQueue, ^{
        dispatch_semaphore_wait(dj_zombie_semaphore, DISPATCH_TIME_FOREVER);
        
        if (biz_zombies_queue.count < 2 * other_zombie_queue.count) {
            dj_zombie_free(&other_zombie_queue,other_zombie_queue.count/4);
        }else{
            dj_zombie_free(&biz_zombies_queue,biz_zombies_queue.count/4);
        }
        
        dispatch_semaphore_signal(dj_zombie_semaphore);
    });
}

void dj_zombie_free_all()
{
    if (!dj_zombie_advance_manage_enable) {
        return;
    }
    
    dispatch_semaphore_wait(dj_zombie_semaphore, DISPATCH_TIME_FOREVER);
    
    dj_zombie_free(&biz_zombies_queue,biz_zombies_queue.count);
    dj_zombie_free(&other_zombie_queue,other_zombie_queue.count);
    
    dispatch_semaphore_signal(dj_zombie_semaphore);
}

void dj_zombie_add_address(void *zombie_address,DJ_ZOMBIE_QUEUE *queue)
{
    if (zombie_address == NULL) {
        assert("zombie_address is null");
        return;
    }
    
    if (queue->count == queue->max_count) {
        dj_zombie_free(queue,1);// queue full
    }
    
    zombie_struct *new_node = (zombie_struct*)calloc(1,sizeof(zombie_struct));
    new_node->zombie_address = zombie_address;
    dj_zombie_queue_append(queue, new_node);
}

void dj_zombie_free(DJ_ZOMBIE_QUEUE *queue, unsigned free_count)
{
    if (free_count == 0) {
        return;
    }
    
    while (free_count > 0) {
        
        zombie_struct *tmp_head = (zombie_struct *)dj_zombie_queue_dequeue(queue);

        if (tmp_head->zombie_address == NULL) {
            assert("zombie_address in tmp_head is null");
        }
        free(tmp_head->zombie_address);
        tmp_head->zombie_address = NULL;

        free(tmp_head);
        tmp_head = NULL;

        free_count--;
    }
}

