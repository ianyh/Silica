//
//  SISystemWideElement.h
//  Silica
//

#import "SIAccessibilityElement.h"

/**
 *  Wrapper around the system-wide element.
 */
@interface SISystemWideElement : SIAccessibilityElement

/**
 *  Returns a globally shared reference to the system-wide accessibility element.
 *
 *  @return A globally shared reference to the system-wide accessibility element.
 */
+ (SISystemWideElement *)systemWideElement;

@end
