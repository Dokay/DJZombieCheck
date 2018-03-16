//
//  dj_queue.h
//  DJZombieCheck
//
//  advance implementation for __dealloc_zombie
//
//  Created by Dokay on 2017/3/26.
//  Copyright © 2017年 dj226. All rights reserved.

#ifndef dj_queue_h
#define dj_queue_h

#include <stdio.h>
#include <stdbool.h>

typedef struct DJ_ZOMBIE_LIST_NODE{
    void *data;
    struct DJ_ZOMBIE_LIST_NODE *next;
}DJ_ZOOMBIE_LIST_NODE;

typedef struct DJ_ZOOMBIE_QUEUE{
    struct DJ_ZOMBIE_LIST_NODE *head;
    struct DJ_ZOMBIE_LIST_NODE *tail;
    unsigned count;
    unsigned max_count;
}DJ_ZOMBIE_QUEUE;

bool dj_zombie_queue_init(DJ_ZOMBIE_QUEUE *queue);
void dj_zombie_queue_append(DJ_ZOMBIE_QUEUE *queue,void *data);
void dj_zombie_queue_clear(DJ_ZOMBIE_QUEUE *queue);
void * dj_zombie_queue_dequeue(DJ_ZOMBIE_QUEUE *queue);


#endif /* dj_queue_h */
