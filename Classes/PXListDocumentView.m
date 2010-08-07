//
//  PXListDocumentView.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListDocumentView.h"

#import "PXListView.h"
#import "PXListView+Private.h"

@implementation PXListDocumentView

@synthesize listView = _listView;
@synthesize dropHighlight = _dropHighlight;

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent*)theEvent
{
	[[self listView] handleMouseDownOutsideCells: theEvent];
}


- (void)drawRect:(NSRect)dirtyRect
{
#pragma unused(dirtyRect)
	
	// We always show the outline:
	if( _dropHighlight != PXListViewDropNowhere )
	{
		CGFloat		lineWidth = 2.0f;
		CGFloat		lineWidthHalf = lineWidth / 2.0f;
		
		[[NSColor selectedControlColor] set];
		[NSBezierPath setDefaultLineWidth: lineWidth];
		[NSBezierPath strokeRect: NSInsetRect([self visibleRect], lineWidthHalf, lineWidthHalf)];
	}
	
	if( _dropHighlight == PXListViewDropAbove )	// DropAbove means after last cell.
	{
		CGFloat		lineWidth = 2.0f;
		NSRect		theBox = [_listView rectOfRow: [_listView numberOfRows] -1];
		
		theBox.origin.y += theBox.size.height -2.0f;
		theBox.size.height = 2.0f;
		
		[[NSColor alternateSelectedControlColor] set];
		[NSBezierPath setDefaultLineWidth: lineWidth];
		[NSBezierPath strokeRect: theBox];
	}
}

- (void)setDropHighlight:(PXListViewDropHighlight)inState
{
	_dropHighlight = inState;
	[self setNeedsDisplayInRect: [self visibleRect]];
}

@end
