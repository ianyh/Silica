//
//  NSRunningApplication+Manageable.m
//  Silica
//

#import "NSRunningApplication+Silica.h"

@implementation NSRunningApplication (Silica)

- (BOOL)isAgent {
    NSBundle *bundle = [NSBundle bundleWithURL:self.bundleURL];
    if (bundle.infoDictionary == nil) {
        return NO;
    }
    return [bundle.infoDictionary[@"LSUIElement"] boolValue];
}

@end
