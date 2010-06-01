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
	NSRect bounds = [self bounds];
	
	//Do a white fill and a black stroke
	[[NSColor whiteColor] set];
	NSRectFill(dirtyRect);
	[[NSColor blackColor] set];
	NSFrameRect(bounds);
	
	NSSize titleSize = [title sizeWithAttributes:nil];
	[title drawAtPoint:NSMakePoint(0, NSMaxY(bounds)-titleSize.height) withAttributes:nil];
}

@end
