//
//  TXLChatTool.h
//  AiChat
//
//  Created by 庄彪 on 15/7/6.
//  Copyright (c) 2015年 XMPP. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XMPPJID;
@class RACSignal;

@interface TXLChatTool : NSObject

/**
 *  @brief  有新消息信号
 */
@property (nonatomic, strong, readonly) RACSignal *freshSignal;
/**
 *  @brief  获取到历史信息信号
 */
@property (nonatomic, strong, readonly) RACSignal *historySignal;
/**
 *  @brief  存储XMPPMessageArchiving_Message_CoreDataObject
 */
@property (nonatomic, strong, readonly) NSMutableArray *messages;

/**
 *  @brief  好友JID
 */
@property (nonatomic, strong) XMPPJID *friendJid;

/**
 *  @brief  发送消息
 *
 *  @param message 消息内容
 */
- (void)sendMessage:(NSString *)message;

- (void)loadHistoryMessages;

@end
