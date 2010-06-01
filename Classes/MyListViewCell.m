//
//  MyListViewCell.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "MyListViewCell.h"


@implementation MyListViewCell

@synthesize title;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithReusableIdentifier:(NSString*)identifier
{
	if(self = [super initWithReusableIdentifier:identifier]) {
	}
	
	return self;
}

- (void)dealloc
{
	[title release];
	[super dealloc];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
	[title release], title=nil;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor redColor] set];
	NSRectFill(dirtyRect);
	
	NSRect bounds = [self bounds];
	NSSize titleSize = [title sizeWithAttributes:nil];
	
	[title drawAtPoint:NSMakePoint(NSMaxX(bounds)-titleSize.width, NSMaxY(bounds)-titleSize.height) withAttributes:nil];
}

@end
