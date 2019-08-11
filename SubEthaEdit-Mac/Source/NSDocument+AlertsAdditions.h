//
//  NSDocument+Alerts.h
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/8/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDocument (Alerts)

@property (nonatomic, readonly) NSArray * alerts;

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(void (^)(NSDocument *, NSModalResponse))then;

@end

NS_ASSUME_NONNULL_END
