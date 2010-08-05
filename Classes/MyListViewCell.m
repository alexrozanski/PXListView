//
//  MyListViewCell.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "MyListViewCell.h"

#import <iso646.h>


@implementation MyListViewCell

@synthesize title = _title;

#if DEBUG
// Counter for the amount of current cells
+ (void)updateCount:(BOOL)status {
	static NSInteger count = 0;
	if (status) {
		count++;
	} else {
		count--;
	}
	NSLog(@"Current amount of allocated cells: %d", count);
}
#endif

#pragma mark -
#pragma mark Init/Dealloc

- (id)	initWithReusableIdentifier: (NSString*)identifier
{
	if(( self = [super initWithReusableIdentifier: identifier] ))
	{
#if DEBUG
		NSLog(@"Allocating cell");
		[MyListViewCell updateCount:YES];
#endif
	}
	
	return self;
}

- (void)	dealloc
{
#if DEBUG
	NSLog(@"Deallocating cell");
	[MyListViewCell updateCount:NO];
#endif
	[_title release];
	[super dealloc];
}

#pragma mark -
#pragma mark Reuse

- (void)	prepareForReuse
{
#if DEBUG
	NSLog(@"Reusing cell");
#endif
	[_title release];
	_title = nil;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect bounds = [self bounds];
	NSDictionary *attributes = nil;
	
	//Draw the border and background
	if([self isSelected]) {
		[[NSColor redColor] set];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, nil];
	}
	else {
		[[NSColor whiteColor] set];
	}
	NSRectFill(dirtyRect);
	[[NSColor blackColor] set];
	NSFrameRect(bounds);
	
	//Draw the title
	NSSize titleSize = [_title sizeWithAttributes:attributes];
	[_title drawAtPoint:NSMakePoint(5.0f, NSMaxY(bounds)-titleSize.height-5) withAttributes:attributes];
	[attributes release];
	
	[super drawRect: dirtyRect];
}


#pragma mark -
#pragma mark Accessibility

-(NSArray*)	accessibilityAttributeNames
{
	NSMutableArray*	attribs = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	
	[attribs addObject: NSAccessibilityRoleAttribute];
	[attribs addObject: NSAccessibilityDescriptionAttribute];
	[attribs addObject: NSAccessibilityTitleAttribute];
	[attribs addObject: NSAccessibilityEnabledAttribute];
	
	return attribs;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute]
		or [attribute isEqualToString: NSAccessibilityDescriptionAttribute]
		or [attribute isEqualToString: NSAccessibilityTitleAttribute]
		or [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return NO;
	}
	else
		return [super accessibilityIsAttributeSettable: attribute];
}

-(id)	accessibilityAttributeValue: (NSString *)attribute
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute] )
	{
		return NSAccessibilityButtonRole;
	}
	else if( [attribute isEqualToString: NSAccessibilityDescriptionAttribute]
			or [attribute isEqualToString: NSAccessibilityTitleAttribute] )
	{
		return _title;
	}
	else if( [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return [NSNumber numberWithBool: YES];
	}
	else
		return [super accessibilityAttributeValue: attribute];
}

@end
