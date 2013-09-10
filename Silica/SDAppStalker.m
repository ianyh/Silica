//
//  SDAppStalker.m
//  Zephyros
//
//  Created by Steven on 4/21/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import "SDAppStalker.h"

#import "SDApp.h"

@interface SDAppStalker ()

@property NSMutableArray* apps;

@end

@implementation SDAppStalker

+ (SDAppStalker*) sharedAppStalker {
    static SDAppStalker* sharedAppStalker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAppStalker = [[SDAppStalker alloc] init];
    });
    return sharedAppStalker;
}

- (void) beginStalking {
    self.apps = [NSMutableArray array];
    
    for (NSRunningApplication* runningApp in [[NSWorkspace sharedWorkspace] runningApplications]) {
        SDApp* app = [[SDApp alloc] initWithRunningApp:runningApp];
        [self.apps addObject:app];
        [app startObservingStuff];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeScreenParams:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appDied:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}

- (void) appLaunched:(NSNotification*)note {
    NSRunningApplication *launchedApp = [[note userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    SDApp* app = [[SDApp alloc] initWithRunningApp:launchedApp];
    [self.apps addObject:app];
    [app startObservingStuff];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SDListenEventAppOpened
                                                        object:nil
                                                      userInfo:@{@"thing": app}];
}

- (void) appDied:(NSNotification*)note {
    NSRunningApplication *deadApp = [[note userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SDListenEventAppClosed
                                                        object:nil
                                                      userInfo:@{@"thing": [[SDApp alloc] initWithRunningApp:deadApp]}];
    
    SDApp* app;
    for (SDApp* couldBeThisApp in self.apps) {
        if ([deadApp processIdentifier] == couldBeThisApp.pid) {
            app = couldBeThisApp;
            break;
        }
    }
    
    if (app) {
        [app stopObservingStuff];
        [self.apps removeObject:app];
    }
    else {
        NSLog(@"This app died, but we have no record of ever storing it internally, even though we should have: name = %@, pid = %d, ident = %@",
              [deadApp localizedName],
              [deadApp processIdentifier],
              [deadApp bundleIdentifier]);
        return;
    }
}

- (void) didChangeScreenParams:(NSNotification*)note {
    [[NSNotificationCenter defaultCenter] postNotificationName:SDListenEventScreensChanged
                                                        object:nil
                                                      userInfo:nil];
}

@end
