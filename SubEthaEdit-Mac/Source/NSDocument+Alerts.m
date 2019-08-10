//
//  NSDocument+Alerts.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/8/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <objc/runtime.h>
#import "NSDocument+Alerts.h"

@interface QueueableAlert : NSAlert
@property (nonatomic, copy) void (^then)(NSWindow *);
@end

NSString const * DocumentAlertsKey = @"DocumentAlertsKey";

@implementation NSDocument (Alerts)

- (NSMutableArray *)mutableAlerts
{
    if (objc_getAssociatedObject(self, &DocumentAlertsKey) == nil)
        objc_setAssociatedObject(self, &DocumentAlertsKey, [NSMutableArray new], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return objc_getAssociatedObject(self, &DocumentAlertsKey);
}

- (NSArray *)alerts
{
    return [[self mutableAlerts] copy];
}

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(void (^)(NSDocument *, NSModalResponse))then
{
    NSAlert *alert = [[QueueableAlert alloc] init];

    alert.alertStyle = style;
    alert.messageText = message;
    alert.informativeText = details;

    for (NSString * button in buttons)
        [alert addButtonWithTitle:button];

    if (self.mutableAlerts.count > 0)
        [self.mutableAlerts addObject:alert];

    for (NSWindowController * windowController in self.windowControllers) {
        NSWindow * window = windowController.window;
        BOOL wontAwkwardlyOrderFront =
            window.sheets.count > 0 ||
            window.tabGroup.selectedWindow == window;
        
        if (wontAwkwardlyOrderFront) {
            [alert beginSheetModalForWindow:window
                          completionHandler:^(NSModalResponse returnCode) {
            }];
        }
    }
}

@end
