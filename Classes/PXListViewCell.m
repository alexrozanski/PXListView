//
//  PXListViewCell.m
//  PXListView
//
//  Created by Alex Rozanski on 29/05/2010.
//  Copyright 2010 Alex Rozanski. http://perspx.com. All rights reserved.
//

#import "PXListViewCell.h"
#import "PXListViewCell+Private.h"

#import "PXListView.h"

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
	PXListView *listView = [self listView];
	[listView setSelectedRow:[self row]];
}

- (BOOL)isSelected
{
	return [self row]==[[self listView] selectedRow];
}

#pragma mark -
#pragma mark Reusing Cells

- (void)prepareForReuse
{
}

@end
