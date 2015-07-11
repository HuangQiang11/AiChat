//
//  XXMessagesTool.m
//  AiChat
//
//  Created by 庄彪 on 15/7/10.
//  Copyright (c) 2015年 XMPP. All rights reserved.
//

#import "XXMessagesTool.h"
#import "ZHBXMPPTool.h"
#import "ZHBXMPPConst.h"
#import "ZHBUserInfo.h"
#import "XXContactMessage.h"
#import <ReactiveCocoa.h>

@interface XXMessagesTool ()<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readwrite) RACSubject *rac_updateSignal;

@property (nonatomic, strong) NSManagedObjectContext *objectContext;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong, readwrite) NSArray *recentContacts;

@end

@implementation XXMessagesTool

#pragma mark -
#pragma mark Life Cycle
- (instancetype)init {
    if (self = [super init]) {
        [self loadRecentContacts];
    }
    return self;
}

#pragma mark -
#pragma mark NSFetchedResultsController Delegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    DDLOG_INFO
    [(RACSubject *)self.rac_updateSignal sendNext:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)loadRecentContacts {
    DDLOG_INFO
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        DDLogError(@"获取最近联系人失败");
        DDLogVerbose(@"error: %@", error);
    }
}

#pragma mark -
#pragma mark Getters

- (NSManagedObjectContext *)objectContext {
    if (nil == _objectContext) {
        _objectContext = [ZHBXMPPTool sharedXMPPTool].xmppMessageStorage.mainThreadManagedObjectContext;
    }
    return _objectContext;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (nil == _fetchedResultsController) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@", [ZHBUserInfo sharedUserInfo].jid];
        NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"mostRecentMessageTimestamp" ascending:NO];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:xmppMessageArchivingContactCoreDataObject];
        request.sortDescriptors = @[timeSort];
        request.predicate = predicate;
        
        DDLogInfo(@"查询条件:");
        DDLogVerbose(@"%@", request);
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.objectContext sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (RACSignal *)rac_updateSignal {
    if (nil == _rac_updateSignal) {
        _rac_updateSignal = [[RACSubject subject] setNameWithFormat:@"%@::%@", THIS_FILE, THIS_METHOD];
    }
    return _rac_updateSignal;
}

- (NSArray *)recentContacts {
    NSMutableArray *contactMessages = [NSMutableArray array];
    
    ZHBXMPPTool *xmppTool = [ZHBXMPPTool sharedXMPPTool];
    for (XMPPMessageArchiving_Contact_CoreDataObject *recentMessage in self.fetchedResultsController.fetchedObjects) {
        XXContactMessage *contactMessage = [[XXContactMessage alloc] init];
        XMPPUserCoreDataStorageObject *friendUser = [xmppTool.xmppRosterStorage userForJID:recentMessage.bareJid xmppStream:xmppTool.xmppStream managedObjectContext:xmppTool.xmppRosterStorage.mainThreadManagedObjectContext];
        contactMessage.recentMessage = recentMessage;
        contactMessage.friendUser = friendUser;
        [contactMessages addObject:contactMessage];
    }

    _recentContacts = contactMessages;
    return _recentContacts;
}

@end
