//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import "NSDocument+AlertsAdditions.h"
#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"
#import "PreferenceKeys.h"

@implementation PlainTextWindow

+ (NSSet *)keyPathsForValuesAffectingHasSheets {
    NSLog(@"OH REALLY");
    return [NSSet setWithArray:@[@"attachedSheet", @"document.alerts"]];
}

- (BOOL)hasSheets {
    NSLog(@"here... %d", self.sheets.count > 0 ||
          ((NSDocument *)self.windowController.document).alerts.count > 0);
    return  self.attachedSheet != nil ||
            ((NSDocument *)self.windowController.document).alerts.count > 0;
}

- (void)windowWillBeginSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasSheets"];
    // The sheet doesn't animate with this. Probably not great.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //NSLog(@"WILL SHOW SHEET: %d", self.hasSheets);
        [self didChangeValueForKey:@"hasSheets"];
        NSLog(@"DID CHANGE VALUE FOR KEY!!!");
        NSLog(@"WILL SHOW SHEET: %d", self.hasSheets);
    });
}

- (void)windowDidEndSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasSheets"];
    [self didChangeValueForKey:@"hasSheets"];
}

- (void)awakeFromNib
{
    self.tab.accessoryView = self.cuationView;

    NSNotificationCenter * defaultCenter = NSNotificationCenter.defaultCenter;

    [defaultCenter addObserver:self
                      selector:@selector(windowDidBecomeMain:)
                          name:NSWindowDidBecomeMainNotification
                        object:self];

    [defaultCenter addObserver:self
                      selector:@selector(windowWillBeginSheet:)
                          name:NSWindowWillBeginSheetNotification
                        object:self];

    [defaultCenter addObserver:self
                      selector:@selector(windowDidEndSheet:)
                          name:NSWindowDidEndSheetNotification
                        object:self];
}

- (IBAction)performClose:(id)sender {
    if ([[self windowController] isKindOfClass:[PlainTextWindowController class]]) {
        [(PlainTextWindowController *)[self windowController] closeTab:sender];
    } else {
        [super performClose:sender];
    }
}

- (void)sendEvent:(NSEvent *)event {
    //NSLog(@"%d", self.hasSheets);
    // Handle ⌘ 1 ... ⌘ 9, ⌘ 0 shortcuts to select tabs
    if ([event type] == NSEventTypeKeyDown) {
        int flags = [event modifierFlags];
        if ((flags & NSEventModifierFlagCommand) &&
            !(flags & NSEventModifierFlagControl) &&
            [[event characters] length] == 1) {
            
            NSUInteger tabIndex = [@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0"] indexOfObject:event.characters];
            NSArray *tabbedWindows = self.tabbedWindows;
            if (tabIndex != NSNotFound &&
                tabIndex < tabbedWindows.count) {
                [[tabbedWindows objectAtIndex:tabIndex] makeKeyAndOrderFront:nil];
                return;
            }
        }
        
    }
    [super sendEvent:event];
}

- (void)setDocumentEdited:(BOOL)flag {
    NSDocument *document = [[self windowController] document];
    if (document) {
        [super setDocumentEdited:[document isDocumentEdited]];
    } else {
        [super setDocumentEdited:flag];
    }
}

static NSPoint placeWithCascadePoint(NSWindow *window, NSPoint cascadePoint) {
    NSScreen *screen = [NSScreen screenContainingPoint:cascadePoint] ?: [NSScreen menuBarContainingScreen];
    NSRect visibleFrame = [screen visibleFrame];

    // check if the top plain text window window is on the same screen, if not, cascading from the top window
    for (NSWindow *window in NSApp.orderedWindows) {
        if ([window isKindOfClass:[PlainTextWindow class]]) {
            if ([window screen] != screen) {
                screen = [window screen];
                visibleFrame = [screen visibleFrame];
                cascadePoint = NSMakePoint(MAX(NSMinX([window frame]), NSMinX(visibleFrame)),
                                               NSMaxY([window frame]));
            }
            break;
        }
    }
    
    NSPoint placementPoint = cascadePoint;
    
    NSRect currentFrame = window.frame;

    // Contstrain top to Visible frame
    placementPoint.y = MIN(placementPoint.y, NSMaxY(visibleFrame));
    
    // Wrap back to left edge if we would move out on the right
    if (placementPoint.x + NSWidth(currentFrame) > NSMaxX(visibleFrame)) {
        placementPoint.x = NSMinX(visibleFrame);
    }
    
    // Constrain left to visible Frame
    placementPoint.x = MAX(placementPoint.x,
                   NSMinX(visibleFrame));
    
    // Warp back to top if we shoot over the bottom
    if (placementPoint.y - NSHeight(currentFrame) < NSMinY(visibleFrame)) {
        placementPoint.y = NSMaxY(visibleFrame);
    }
    
    [window setFrameTopLeftPoint:placementPoint];
    return placementPoint;
}

- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)cascadeFromPoint {
    // 0.0 is supposed to not cascade and just move/resize to visible
    if (NSEqualPoints(cascadeFromPoint, NSZeroPoint)) {
        return [super cascadeTopLeftFromPoint:cascadeFromPoint];
    }

    NSPoint placedPoint = placeWithCascadePoint(self, cascadeFromPoint);
    CGVector offset = (CGVector){.dx = 21, .dy = -23.};
    return (NSPoint){ .x = placedPoint.x + offset.dx, .y = placedPoint.y + offset.dy};
}

// This window has its usual -constrainFrameRect:toScreen: behavior temporarily suppressed.
// This enables our window's custom Full Screen Exit animations to avoid being constrained by the
// top edge of the screen and the menu bar.
//
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    if (self.constrainingToScreenSuspended) {
        return frameRect;
    }
    else {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}

- (IBAction)toggleTabBar:(id)sender {
    // Actual update is a side effect of the change
    SEEDocumentController.shouldAlwaysShowTabBar = !SEEDocumentController.shouldAlwaysShowTabBar;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(toggleTabBar:)) {
        BOOL alwaysShowTabBar = SEEDocumentController.shouldAlwaysShowTabBar;
        [menuItem setState:alwaysShowTabBar ? NSOnState : NSOffState];
        return YES;
    }
    return [super validateMenuItem:menuItem];
}

- (void)ensureTabBarVisiblity:(BOOL)shouldAlwaysBeVisible {
    NSWindowTabGroup *group = self.tabGroup;
    if (group.windows.count == 1) {
        BOOL isVisible = group.isTabBarVisible;
        if ((isVisible && !shouldAlwaysBeVisible) ||
            (!isVisible && shouldAlwaysBeVisible)) {
            [super toggleTabBar:nil];
        }
    }
}

@end

typedef void (^AlertCompletionHandler) (NSModalResponse returnCode);

@implementation PlainTextWindow (Alerts)

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(void (^)(PlainTextWindow *, NSModalResponse))then {

    NSAlert *alert = [[NSAlert alloc] init];

    [alert setAlertStyle:style];
    [alert setMessageText:message];
    [alert setInformativeText:details];

    for (NSString * button in buttons) {
        [alert addButtonWithTitle: button];
    }

    __unsafe_unretained PlainTextWindow *weakSelf = self;
    AlertCompletionHandler handler = ^(NSModalResponse returnCode) {
          PlainTextWindow *strongSelf = weakSelf;
          if (strongSelf && then) {
              then(strongSelf, returnCode);
          }
    };

    if (self.tabGroup.selectedWindow != self) {
        self.presentScheduledAlertForWindow = ^(NSWindow * self){
            [alert beginSheetModalForWindow:self completionHandler:handler];
        };

        return;
    }

    [alert beginSheetModalForWindow:self completionHandler:handler];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
}
/*
    for (NSAlert * )
    - (void)windowDidBecomeMain:(NSNotification *)notification {
        .
    }

    
    if (!self.presentScheduledAlertForWindow)
        return;

    typeof(_presentScheduledAlertForWindow) action = [self.presentScheduledAlertForWindow copy];
    self.presentScheduledAlertForWindow = nil;
    
    // The sheet doesn't animate with this. Probably not great.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        action(self);
    });
}*/

@end
