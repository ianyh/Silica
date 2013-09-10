//
//  MyUniversalAccessHelper.m
//  Zephyros
//
//  Created by Steven Degutis on 3/1/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDUniversalAccessHelper.h"

@implementation SDUniversalAccessHelper

+ (BOOL) complainIfNeeded {
    Boolean enabled = AXAPIEnabled();
    
    if (!enabled) {
        [NSApp activateIgnoringOtherApps:YES];
        
        NSInteger result = NSRunAlertPanel(@"Zephyros Requires Universal Access",
                                           @"For Zephyros to function properly, access for assistive devices must be enabled first.\n\n"
                                           @"To enable this feature, click \"Enable access for assistive devices\" in the Universal Access pane of System Preferences.",
                                           @"Open Universal Access",
                                           @"Dismiss",
                                           nil);
        
        if (result == NSAlertDefaultReturn) {
            NSString* src = @"tell application \"System Preferences\"\nactivate\nset current pane to pane \"com.apple.preference.universalaccess\"\nend tell";
            NSAppleScript *a = [[NSAppleScript alloc] initWithSource:src];
            [a executeAndReturnError:nil];
        }
        
        return YES;
    }
    
    return NO;
}

@end
