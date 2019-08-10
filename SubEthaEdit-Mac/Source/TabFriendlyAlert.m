//
//  TabFriendlyAlert.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/8/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <objc/runtime.h>
#import "TabFriendlyAlert.h"

@interface TabFriendlySheet : NSPanel
@end

@implementation TabFriendlySheet

- (BOOL)canBecomeKeyWindow {
    NSWindow * sheetParent = self.sheetParent;

    NSLog(@"%@", sheetParent.tabGroup.selectedWindow.title);
    NSLog(@"HERE!! %d", sheetParent.tabGroup.selectedWindow == sheetParent);
    return  sheetParent.tabGroup.selectedWindow == self &&
            [super canBecomeKeyWindow];
}

- (void)orderWindow:(NSWindowOrderingMode)place
         relativeTo:(NSInteger)otherWin
{
    if ([self canBecomeKeyWindow]) {
        NSLog(@"ordering front...");
        [super orderWindow:place
                relativeTo:otherWin];
    }else{
        NSLog(@"NOPE!");
    }
}

@end

@implementation TabFriendlyAlert

- (id)init{
    self = [super init];
    
    if (self) {
        object_setClass(self.window, [TabFriendlySheet class]);
    }
    
    return self;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
//    [self.window selectNextTab:self];
    NSLog(@"WINDOW BECAME KEY");
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
//    [self.window selectNextTab:self];
    NSLog(@"WINDOW BECAME MAIN");
}

- (void)windowDidOrderFront:(NSNotification *)notification
{
//    [self.window selectNextTab:self];
    NSLog(@"WINDOW ORDERED FRONT");
}


@end
