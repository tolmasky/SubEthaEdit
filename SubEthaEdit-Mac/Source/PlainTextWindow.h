//  PlainTextWindow.h
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import <Cocoa/Cocoa.h>


@interface PlainTextWindow : NSWindow
@property BOOL constrainingToScreenSuspended;

@property (retain) IBOutlet  NSView * cuationView;
@property (readonly) BOOL hasSheets;

@property (nonatomic, copy) void (^presentScheduledAlertForWindow)(NSWindow *);

- (void)ensureTabBarVisiblity:(BOOL)shouldAlwaysBeVisible;

@end

@interface PlainTextWindow (Alerts)
- (void)alert:(NSString *)message style:(NSAlertStyle)style details:(NSString *)details buttons:(NSArray *)buttons then:(void (^)(PlainTextWindow *, NSModalResponse))then;
@end
