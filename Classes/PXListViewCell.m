//
//  PXListViewCell.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListViewCell.h"
#import "PXListViewCell+Private.h"

#import <iso646.h>

#import "PXListView.h"
#import "PXListView+Private.h"

#pragma mark -

@implementation PXListViewCell

@synthesize reusableIdentifier = _reusableIdentifier;
@synthesize listView = _listView;
@synthesize row = _row;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithReusableIdentifier:(NSString*)identifier
{
	if(self = [super initWithFrame:NSZeroRect]) {
		_reusableIdentifier = [identifier copy];
	}
	
	return self;
}

- (void)dealloc
{
	[_reusableIdentifier release];
	[super dealloc];
}

#pragma mark -
#pragma mark Handling Selection

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self listView] handleMouseDown: theEvent inCell: self];
}

- (BOOL)isSelected
{
	return [[[self listView] selectedRows] containsIndex: [self row]];
}

#pragma mark -
#pragma mark Reusing Cells

- (void)prepareForReuse
{
}

#pragma mark -
#pragma mark Accessibility

-(NSArray*)	accessibilityAttributeNames
{
	NSMutableArray*	attribs = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	
	[attribs addObject: NSAccessibilityRoleAttribute];
	[attribs addObject: NSAccessibilityEnabledAttribute];
	
	return attribs;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute;
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute]
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
		return NSAccessibilityRowRole;
	}
	else if( [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return [NSNumber numberWithBool: YES];
	}
	else
		return [super accessibilityAttributeValue: attribute];
}


-(NSArray *)	accessibilityActionNames
{
	return [NSArray arrayWithObjects: NSAccessibilityPressAction, nil];
}


-(NSString *)	accessibilityActionDescription: (NSString *)action
{
	return NSAccessibilityActionDescription(action);
}


-(void)	accessibilityPerformAction: (NSString *)action
{
	if( [action isEqualToString: NSAccessibilityPressAction] )
	{
		[[self listView] handleMouseDown: nil inCell: self];
	}
}


- (BOOL)accessibilityIsIgnored
{
	return NO;
}

@end
