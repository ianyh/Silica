//
//  SISystemWideElement.h
//  Silica
//

#import "SIAccessibilityElement.h"

NS_ASSUME_NONNULL_BEGIN

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

/**
 *  Shifts to space at the provided index.
 *
 *  @param space The space to switch to.
 */
+ (void)switchToSpace:(NSUInteger)space;

/**
 *  Generates an event with the relevant shortcut information to switch to the space at the given index.
 *
 *  @param space The space to switch to.
 */
+ (nullable NSEvent *)eventForSwitchingToSpace:(NSUInteger)space;

/**
 *  Perform a space switch event.
 *
 *  @param event The event to perform the keyboard shortcut
 */
+ (void)switchToSpaceWithEvent:(NSEvent *)event;

@end

NS_ASSUME_NONNULL_END
