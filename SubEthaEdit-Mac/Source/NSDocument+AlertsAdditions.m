//
//  NSDocument+Alerts.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/8/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <objc/runtime.h>
#import "NSDocument+AlertsAdditions.h"

@interface ConsequentialAlert : NSAlert

@property (readonly, copy) AlertConsequence then;

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
                           then:(AlertConsequence)then;

@end

@implementation ConsequentialAlert

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
                           then:(AlertConsequence)then
{
    self = [super init];

    if (self) {
        self.messageText = message;
        self.alertStyle = style;
        self.informativeText = details;

        for (NSString * button in buttons)
            [self addButtonWithTitle:button];

        _then = [then copy];
    }

    return self;
}

@end

//@interface QueueableAlert : NSAlert
//@property (nonatomic, copy) void (^then)(NSWindow *);
//@end

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
         then:(AlertConsequence)then
{
    ConsequentialAlert * alert =
        [[ConsequentialAlert alloc] initWithMessage:message
                                              style:style
                                            details:details
                                            buttons:buttons
                                               then:then];

    [self.mutableAlerts addObject:alert];

    if (self.mutableAlerts.count > 1)
        return;

    NSUInteger index = [self.windowControllers indexOfObjectPassingTest:
                        ^(NSWindowController * WC, NSUInteger index, BOOL * stop) {
                            return (BOOL)(WC.window == NSApp.mainWindow);
                        }];

    if (index == NSNotFound)
        return;

    NSWindow * window = self.windowControllers[index].window;
    __unsafe_unretained NSDocument * weakSelf = self;

    [alert beginSheetModalForWindow:window
                  completionHandler:^(NSModalResponse returnCode) {
                      NSDocument * strongSelf = weakSelf;
                      [strongSelf.mutableAlerts removeObjectAtIndex:0];

                      if (strongSelf && then) {
                          then(strongSelf, returnCode);
                      }
                  }];
}

@end
