//
//  hd_queue.h
//  eif-ios-app
//
//  Created by Dokay on 2017/11/15.
//  Copyright © 2017年 Ever Grande. All rights reserved.
//

#ifndef hd_queue_h
#define hd_queue_h

#include <stdio.h>
#include <stdbool.h>

typedef struct HD_ZOMBIE_LIST_NODE{
    void *data;
    struct HD_ZOMBIE_LIST_NODE *next;
}HD_ZOOMBIE_LIST_NODE;

typedef struct HD_ZOOMBIE_QUEUE{
    struct HD_ZOMBIE_LIST_NODE *head;
    struct HD_ZOMBIE_LIST_NODE *tail;
    unsigned count;
    unsigned max_count;
}HD_ZOMBIE_QUEUE;

bool hd_zombie_queue_init(HD_ZOMBIE_QUEUE *queue);
void hd_zombie_queue_append(HD_ZOMBIE_QUEUE *queue,void *data);
void hd_zombie_queue_clear(HD_ZOMBIE_QUEUE *queue);
void * hd_zombie_queue_dequeue(HD_ZOMBIE_QUEUE *queue);


#endif /* hd_queue_h */
