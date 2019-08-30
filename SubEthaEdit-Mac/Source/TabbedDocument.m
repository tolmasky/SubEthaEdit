//
//  TabbedDocument.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "TabbedDocument.h"


static __auto_type windowHasAttachedSheet =
 ^ (NSWindow *window, NSUInteger index, BOOL *stop) {
        return (BOOL)(window.attachedSheet != nil);
};

@interface TabbedDocument () {
    NSMutableArray * _mutableAlerts;
}
@end

@implementation TabbedDocument

- (instancetype)init {
    self = [super init];

    if (self) {
        _mutableAlerts = [NSMutableArray new];
    }

    return self;
}

// As we have not implemented document-based alert queueing yet, this simply returns
// YES if any of it's associated windows has a sheet attached. The eventual theory is
// that if *any* window has a sheet, they (conceptually) *all should*. In a following
// commit, this will be expanded to the possibility that no window is *actively*
// showing a sheet, but may have one queued (in the case where every tab representing
// the document is hidden).
- (BOOL)hasAlerts {
    NSArray *windows = [self.windowControllers valueForKey:@"window"];
    NSUInteger index = [windows indexOfObjectPassingTest:windowHasAttachedSheet];
    BOOL anyWindowHasAttachedSheet = index != NSNotFound;

    return anyWindowHasAttachedSheet;
}

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(AlertConsequence)then {
    DocumentAlert *alert =
        [[DocumentAlert alloc] initWithMessage:message
                                         style:style
                                       details:details
                                       buttons:buttons
                                          then:then];

    __unsafe_unretained NSDocument *weakSelf = self;
    [self presentAlert:alert completionHandler:^(NSModalResponse returnCode) {
        NSDocument *strongSelf = weakSelf;
        if (strongSelf && then) {
            then(strongSelf, returnCode);
        }
    }];
}

- (void)inform:(NSString *)message details:(NSString *)details {
    [self alert:message
          style:NSAlertStyleInformational
        details:details
        buttons:@[NSLocalizedString(@"OK", nil)]
           then:nil];
}

- (void)warn:(NSString *)message
     details:(NSString *)details
     buttons:(NSArray *)buttons
        then:(AlertConsequence)then {
    [self alert:message
          style:NSAlertStyleWarning
        details:details
        buttons:buttons
           then:then];
}

- (void)presentAlert:(NSAlert *)alert completionHandler:(void (^)(NSModalResponse returnCode))completionHandler {
    NSArray *orderedWindows = NSApp.orderedWindows;
    NSSet *candidateWindows = [NSSet setWithArray:[self.windowControllers valueForKey:@"window"]];

    NSUInteger index = [orderedWindows indexOfObjectPassingTest:
                        ^(NSWindow *window, NSUInteger idx, BOOL *_stop) {
                            return [candidateWindows containsObject:window];
                        }];
    NSWindow *window = orderedWindows[index];

    [window makeKeyAndOrderFront:self];
    [alert beginSheetModalForWindow:window completionHandler:completionHandler];
}

@end


@implementation TabbedDocument (SheetSynchronization)

// We collect all the notification names and selectors we care about in this method
// to avoid potential bugs of forgetting to remove an observer we've added.
- (NSDictionary *)windowNotifications {
    return @{
             NSWindowWillBeginSheetNotification:
                 NSStringFromSelector(@selector(windowWillBeginSheet:)),
             NSWindowDidEndSheetNotification:
                 NSStringFromSelector(@selector(windowDidEndSheet:))
             };
}

- (void)addWindowController:(NSWindowController *)windowController {
    [super addWindowController:windowController];

    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    NSDictionary *notifications = self.windowNotifications;
    for (NSString *name in notifications) {
        [defaultCenter addObserver:self
                          selector:NSSelectorFromString(notifications[name])
                              name:name
                            object:windowController.window];
    }
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];

    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    for (NSString *name in self.windowNotifications) {
        [defaultCenter removeObserver:self
                                 name:name
                               object:windowController.window];
    }
}


// We actually would like window*Did*BeginSheet:, but unfortunately that notification
// doesn't exist, so at this point window.attachedSheet is still nil. For this reason
// the willChangeValueForKey: is correct, but we have to delay the didChangeValueForKey:.
- (void)windowWillBeginSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasAlerts"];

    [NSOperationQueue TCM_performBlockOnMainQueue:^{
        [self didChangeValueForKey:@"hasAlerts"];
    } afterDelay:0.0];
}

- (void)windowDidEndSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasAlerts"];
    [self didChangeValueForKey:@"hasAlerts"];
}

@end
