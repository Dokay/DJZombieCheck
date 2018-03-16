//
//  hd_zombie_object_cache.c
//  eif-ios-app
//
//  Created by Dokay on 2017/11/14.
//  Copyright © 2017年 Ever Grande. All rights reserved.
//

#include "hd_zombie_object_cache.h"
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>
#include <dispatch/semaphore.h>
#include <assert.h>
#include <limits.h>
#include "hd_zombie_queue.h"

typedef struct zombie_struct{
    void *zombie_address;
    struct zombie_struct *next;
}zombie_struct;

HD_ZOMBIE_QUEUE hd_zombies_queue;
HD_ZOMBIE_QUEUE other_zombie_queue;

bool hd_zombie_advance_manage_enable = false;

//dealloc is not thread safe, https://developer.apple.com/library/content/technotes/tn2109/_index.html
dispatch_semaphore_t hd_zombie_semaphore;
dispatch_queue_t zombieSerialDispatchQueue;

void hd_zombie_add_address(void *zombie_address,HD_ZOMBIE_QUEUE *queue);
void hd_zombie_free(HD_ZOMBIE_QUEUE *queue, unsigned free_count);
void hd_zombie_add(void *zombie_address,const char *name, HD_ZOMBIE_QUEUE *queue);

void hd_zombie_init_current()
{
    hd_zombie_queue_init(&hd_zombies_queue);
    hd_zombie_queue_init(&other_zombie_queue);
    
    hd_zombie_semaphore = dispatch_semaphore_create(1);
    zombieSerialDispatchQueue = dispatch_queue_create("com.dj226.zombie",DISPATCH_QUEUE_SERIAL);
    hd_zombie_advance_manage_enable = true;
}

void hd_zombie_add_base(void *zombie_address,const char *name)
{
    hd_zombie_add(zombie_address,name,&other_zombie_queue);
}

void hd_zombie_add_biz(void *address,const char *name)
{
    hd_zombie_add(address,name,&hd_zombies_queue);
}

void hd_zombie_add(void *zombie_address,const char *name, HD_ZOMBIE_QUEUE *queue)
{
    if (!hd_zombie_advance_manage_enable) {
        return;
    }
    
    if (zombie_address != NULL && strlen(name) > 2) {
        dispatch_semaphore_wait(hd_zombie_semaphore, DISPATCH_TIME_FOREVER);
        hd_zombie_add_address(zombie_address, queue);
        dispatch_semaphore_signal(hd_zombie_semaphore);
    }
}

void hd_zombie_release_memory_for_memory_warning()
{
    if (!hd_zombie_advance_manage_enable) {
        return;
    }
    //大量对象释放如果在主线程会卡顿；
    //由于对象已经释放，可以在后台线程释放；
    //避免多次MemoryWarning短时间内多次调用卡住线程城池里面的多个线程，使用自定义同步队列
    dispatch_async(zombieSerialDispatchQueue, ^{
        dispatch_semaphore_wait(hd_zombie_semaphore, DISPATCH_TIME_FOREVER);
        
        if (hd_zombies_queue.count < 2 * other_zombie_queue.count) {
            hd_zombie_free(&other_zombie_queue,other_zombie_queue.count/4);
        }else{
            hd_zombie_free(&hd_zombies_queue,hd_zombies_queue.count/4);
        }
        
        dispatch_semaphore_signal(hd_zombie_semaphore);
    });
}

void hd_zombie_free_all()
{
    if (!hd_zombie_advance_manage_enable) {
        return;
    }
    
    dispatch_semaphore_wait(hd_zombie_semaphore, DISPATCH_TIME_FOREVER);
    
    hd_zombie_free(&hd_zombies_queue,hd_zombies_queue.count);
    hd_zombie_free(&other_zombie_queue,other_zombie_queue.count);
    
    dispatch_semaphore_signal(hd_zombie_semaphore);
}

void hd_zombie_add_address(void *zombie_address,HD_ZOMBIE_QUEUE *queue)
{
    if (zombie_address == NULL) {
        assert("zombie_address is null");
        return;
    }
    
    if (queue->count == queue->max_count) {
        hd_zombie_free(queue,1);// queue full
    }
    
    zombie_struct *new_node = (zombie_struct*)calloc(1,sizeof(zombie_struct));
    new_node->zombie_address = zombie_address;
    hd_zombie_queue_append(queue, new_node);
}

void hd_zombie_free(HD_ZOMBIE_QUEUE *queue, unsigned free_count)
{
    if (free_count == 0) {
        return;
    }
    
    while (free_count > 0) {
        
        zombie_struct *tmp_head = (zombie_struct *)hd_zombie_queue_dequeue(queue);

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

