//
//  hd_zombie_queue.c
//  eif-ios-app
//
//  Created by Dokay on 2017/11/15.
//  Copyright © 2017年 Ever Grande. All rights reserved.
//

#include "hd_zombie_queue.h"
#include <stdlib.h>
#include <assert.h>
#include <limits.h>

bool hd_zombie_queue_init(HD_ZOMBIE_QUEUE *queue)
{
    if (queue == NULL) {
        queue = (HD_ZOMBIE_QUEUE*)calloc(1,sizeof(HD_ZOMBIE_QUEUE));
        if (queue == NULL) {
            assert("calloc error");
            return false;
        }
    }
    queue->count = 0;
    queue->max_count = UINT_MAX;
    queue->head = NULL;
    queue->tail = NULL;
    return true;
}

void hd_zombie_queue_append(HD_ZOMBIE_QUEUE *queue,void *data)
{
    if (queue == NULL) {
        assert("queue is not init");
    }
    
    if (data == NULL) {
        assert("data is null");
    }
    
    if (queue->count >= queue->max_count) {
        assert("queue full");
    }
    
    HD_ZOOMBIE_LIST_NODE *new_node = (HD_ZOOMBIE_LIST_NODE*)calloc(1,sizeof(HD_ZOOMBIE_LIST_NODE));
    
    if (new_node == NULL) {
        assert("calloc error");
    }
    new_node->data = data;
    new_node->next = NULL;
    
    if (queue->head == NULL) {
        queue->head = queue->tail = new_node;
    }else{
        HD_ZOOMBIE_LIST_NODE *tmp_tail = queue->tail;
        tmp_tail->next = new_node;
        queue->tail = new_node;
    }
    
    queue->count += 1;
}

void * hd_zombie_queue_dequeue(HD_ZOMBIE_QUEUE *queue)
{
    if (queue == NULL) {
        assert("queue is not init");
        return NULL;
    }
    
    if (queue->count == 0) {
        return NULL;
    }
    
    HD_ZOOMBIE_LIST_NODE *tmp_head = queue->head;
    queue->head = queue->head->next;
    
    void *data = tmp_head->data;
    
    queue->count -= 1;
    free(tmp_head);
    tmp_head = NULL;
    
    if (queue->count == 0) {
        queue->head = NULL;
        queue->tail = NULL;
    }
    
    return data;
}
